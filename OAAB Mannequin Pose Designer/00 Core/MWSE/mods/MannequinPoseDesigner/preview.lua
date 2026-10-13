local log=require("MannequinPoseDesigner.logger")
-- A native UI scene hosting the actual pose NIF and its posed mannequin body.
-- Both are uncached, isolated instances. The empty
-- canvas/centred block pattern comes from fishing/ui/PreviewPane.lua. createNif
-- loads UI geometry; resizing it with scaleMode is not a 3D camera/mesh fit.
local math3d=require("MannequinPoseDesigner.math3d")
local previewScene=require("MannequinPoseDesigner.preview_scene")
-- createNif resolves custom models beneath Meshes, just like loadMesh.
local M={canvasPath="pose/h/pose_preview.nif"}
local rotation=math3d.mul(math3d.axisAngle({1,0,0},math.rad(-15)),math3d.axisAngle({0,0,1},math.rad(160)))
local spinRate=math.rad(24)
local function vector(v) return tes3vector3.new(unpack(v)) end
local function finite(n) return type(n)=="number" and n==n and math.abs(n)<1e30 end
local function fit(mesh,width,height)
    -- Assembly has copied the pose onto the visible body and updated its skin.
    local bounds=previewScene.bounds(mesh)
    local center,half={},{}
    for i,axis in ipairs({"x","y","z"}) do
        local lo,hi=bounds.min[axis],bounds.max[axis]
        assert(finite(lo) and finite(hi),"Pose has invalid preview bounds")
        assert(hi>=lo,"Pose has empty preview bounds")
        center[i]=(lo+hi)*0.5; half[i]=(hi-lo)*0.5
    end
    -- Fit the whole yaw sweep once. A cylinder around the bounds' centre keeps
    -- long props and offset/imported poses centred without resizing each frame.
    local radius=math.sqrt(half[1]^2+half[2]^2)
    local diameter=0
    for row=0,2 do
        local x,y,z=rotation[row*3+1],rotation[row*3+2],rotation[row*3+3]
        diameter=math.max(diameter,2*(math.sqrt(x*x+y*y)*radius+math.abs(z)*half[3]))
    end
    assert(diameter>1e-6,"Pose has no visible preview geometry")
    local scale=math.min(width,height)*0.82/diameter
    local translation=math3d.scale(math3d.transform(rotation,center),-scale)
    return scale,translation,diameter,center
end
function M.create(parent,file,width,height)
    width,height=width or 200,height or 230
    assert(finite(width) and finite(height) and width>0 and height>0,"Invalid preview size")
    -- Fail before creating UI rather than allowing the engine's error marker
    -- to become the canvas and obscure otherwise valid mannequin geometry.
    assert(tes3.getFileExists("Meshes/"..M.canvasPath),"Preview canvas NIF not installed: Meshes/"..M.canvasPath)
    -- cache=false isolates culling/controller evaluation from every other card,
    -- the mannequin and the metadata reader. No mesh is saved by this module.
    local view,assembled=previewScene.build(file)
    -- Bounding boxes are relative to their receiver. Measuring this identity
    -- wrapper also includes an imported NIF's authored root transform/scale.
    local scale,translation,diameter,center=fit(view,width,height)
    view.rotation=tes3matrix33.new(unpack(rotation))
    view.scale=scale; view.translation=vector(translation)
    parent.autoWidth=false; parent.autoHeight=false
    parent.width=width; parent.height=height
    parent.minWidth=width; parent.maxWidth=width
    parent.minHeight=height; parent.maxHeight=height
    parent.childOffsetX=math.floor(width/2); parent.childOffsetY=-math.floor(height/2)
    local element=assert(parent:createNif({path=M.canvasPath}),"Could not create preview canvas")
    local root,light
    local alive,spinning,angle=true,false,0
    local function orient()
        local facing=math3d.mul(rotation,math3d.axisAngle({0,0,1},angle))
        view.rotation=tes3matrix33.new(unpack(facing))
        view.translation=vector(math3d.scale(math3d.transform(facing,center),-scale))
        root:update({controllers=false})
    end
    local motion={}
    function motion.setSpinning(value)
        if not alive or spinning==value then return end
        spinning=value
        if not spinning then angle=0; orient() end
    end
    function motion.update(delta)
        if not alive or not spinning or not finite(delta) or delta<=0 then return end
        angle=(angle+spinRate*delta)%(2*math.pi)
        orient()
    end
    local function releaseLight()
        alive=false; spinning=false
        if light and root then
            light:detachAffectedNode(root)
            root:detachEffect(light)
            light=nil
        end
    end
    local ok,err=pcall(function()
        element.consumeMouseEvents=false
        -- Keep the empty canvas's native UI transform/size. In particular do not
        -- stretch its scene with scaleMode or rotate the UI root into game axes.
        parent:updateLayout()
        root=assert(element.sceneNode,"Preview canvas has no scene node")
        root:attachChild(view)
        local colors=niVertexColorProperty.new()
        colors.source=ni.sourceVertexMode.ambDiff
        colors.lighting=ni.lightingMode.emiAmbDif
        root:attachProperty(colors)
        local depth=niZBufferProperty.new()
        depth:setFlag(true,0); depth:setFlag(true,1)
        depth.testFunction=ni.zBufferPropertyTestFunction.lessEqual
        root:attachProperty(depth)
        -- A local fill makes previews independent of the current cell's light.
        -- It affects this canvas only; destroy breaks its native effect links.
        element:register(tes3.uiEvent.destroy,releaseLight)
        light=niPointLight.new()
        light.ambient=niColor.new(0.65,0.65,0.65)
        light.diffuse=niColor.new(0.6,0.6,0.6)
        light.dimmer=1; light.enabled=true
        light.translation=tes3vector3.new(0,-200,200)
        light:setRadius(1000)
        light.constantAttenuation=1; light.linearAttenuation=0; light.quadraticAttenuation=0
        root:attachChild(light)
        light:attachAffectedNode(root); root:attachEffect(light)
        root.appCulled=false
        root:updateProperties(); root:update({controllers=false}); root:updateEffects()
        parent:updateLayout()
        log("[OAAB Pose Library] Preview %s + %s: bones=%d, %dx%d, posed extent=%.3f, scale=%.4f",file,assembled.bodyFile,assembled.bones,width,height,diameter,scale)
    end)
    if not ok then
        releaseLight(); element:destroy()
        error(err,0)
    end
    return element,motion
end
return M
