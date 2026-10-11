package.path="./MWSE/mods/?.lua;"..package.path
local count=0
local function check(ok,reason) assert(ok,reason); count=count+1 end
tes3={uiEvent={destroy="destroy"}}
local fixture=dofile("tests/preview_fixture.lua").install()
local math3d=require("MannequinPoseDesigner.math3d")
local preview=require("MannequinPoseDesigner.preview")
mwse={log=function() end}
local function parent()
    local p={canvases={},layouts=0}
    function p:createNif(args)
        check(args.path==preview.canvasPath,"Canvas must be the bundled empty NIF")
        local file=assert(io.open("meshes/"..args.path,"rb"),"Native UI path must resolve beneath Meshes")
        file:close()
        local e={events={}}
        function e:register(name,fn) self.events[name]=fn end
        function e:destroy() if self.destroyed then return end; self.destroyed=true; if self.events.destroy then self.events.destroy() end end
        fixture.canvas(e); self.canvases[#self.canvases+1]=e
        return e
    end
    function p:updateLayout() self.layouts=self.layouts+1 end
    return p
end
local function same(a,b)
    for i,v in ipairs(a) do if math.abs(v-b[i])>1e-8 then return false end end
    return true
end
local function verify(file,width,height)
    local p=parent(); local canvas,motion=preview.create(p,file,width,height)
    local root=canvas.sceneNode; local view=root.children[1]
    local loaded=fixture.poses[#fixture.poses]
    local body=fixture.bodies[#fixture.bodies]
    check(view.children[1]==loaded.mesh and view.children[2]==body.mesh,"The actual pose NIF and visible mannequin body share the viewport")
    check(not loaded.prop.appCulled and not loaded.prop.collisionActive,"Embedded prop remains visible and retains its collision-disabled state")
    check(loaded.shadow.appCulled and not body.shape.appCulled,"The hidden animation shadow stays hidden while the body renders")
    for i=1,35 do
        check(same(body.bones[i].rotation,loaded.bones[i].rotation) and body.bones[i].translation.x==loaded.bones[i].translation.x and body.bones[i].translation.y==loaded.bones[i].translation.y and body.bones[i].translation.z==loaded.bones[i].translation.z and body.bones[i].scale==loaded.bones[i].scale,"The body receives each pose bone's transform")
    end
    check(loaded.mesh.frozen and body.mesh.frozen and not body.bones[1].controller,"The UI clock cannot overwrite the copied pose")
    check(loaded.collision.appCulled,"Collision geometry is excluded from display and fitting")
    local authored=fixture.rootTransform or {rotation=math3d.identity(),translation={x=0,y=0,z=0},scale=1}
    check(loaded.mesh.scale==authored.scale and loaded.mesh.translation.x==authored.translation.x and loaded.mesh.translation.y==authored.translation.y and loaded.mesh.translation.z==authored.translation.z and same(loaded.mesh.rotation,authored.rotation),"Authored root transforms survive fitting")
    check(root.translation.x==100 and root.translation.y==200 and root.translation.z==10 and same(root.rotation,math3d.axisAngle({1,0,0},math.rad(-90))),"Native UI transform is retained")
    check(canvas.scaleMode==nil and canvas.width==nil,"UI canvas is not stretched/resized as a 2D NIF")
    check(p.layouts==2 and p.childOffsetX==math.floor(width/2) and p.childOffsetY==-math.floor(height/2),"Layout centres the scene in a fixed card viewport")
    check(root.propertiesUpdated and root.effectsUpdated,"Native render properties and lighting are refreshed")
    check(root.properties[1].source==ni.sourceVertexMode.ambDiff and root.properties[1].lighting==ni.lightingMode.emiAmbDif,"Vertex colours retain ambient/diffuse shading")
    check(root.properties[2].flags[0] and root.properties[2].flags[1],"Depth test and depth writes are enabled")
    local lo,hi={math.huge,math.huge,math.huge},{-math.huge,-math.huge,-math.huge}
    for _,geometry in ipairs({body.shape,loaded.prop}) do
        for _,vertex in ipairs(geometry.vertices) do
            -- worldTransform includes the view fit after final UI scene update.
            -- Check fitting in the view's own frame, without native UI placement.
            local poseRoot=loaded.mesh; local bip=loaded.bones[1]
            local v=math3d.add(vertex,{bip.translation.x,bip.translation.y,bip.translation.z})
            v=math3d.add(math3d.scale(math3d.transform(poseRoot.rotation,v),poseRoot.scale),{poseRoot.translation.x,poseRoot.translation.y,poseRoot.translation.z})
            v=math3d.add(math3d.scale(math3d.transform(view.rotation,v),view.scale),{view.translation.x,view.translation.y,view.translation.z})
            for i=1,3 do lo[i]=math.min(lo[i],v[i]); hi[i]=math.max(hi[i],v[i]) end
        end
    end
    for i=1,3 do check(lo[i]>=-math.min(width,height)/2 and hi[i]<=math.min(width,height)/2,"Posed geometry and props fit the card on each axis") end
    local light=fixture.lights[#fixture.lights]
    check(light.affected[root] and root.effects[light] and light.enabled,"Local light affects only this canvas")
    local bounds=require("MannequinPoseDesigner.preview_scene").bounds(view)
    local startRotation=view.rotation:copy()
    local startTranslation=view.translation:copy()
    local scale=view.scale
    motion.update(1)
    check(same(view.rotation,startRotation),"Unselected previews do not animate")
    motion.setSpinning(true)
    motion.update(2.5)
    check(same(view.rotation,math3d.mul(startRotation,math3d.axisAngle({0,0,1},math.rad(60)))),"Rotation uses elapsed seconds at 24 degrees per second")
    for step=1,30 do
        motion.update(0.5)
        for _,x in ipairs({bounds.min.x,bounds.max.x}) do
            for _,y in ipairs({bounds.min.y,bounds.max.y}) do
                for _,z in ipairs({bounds.min.z,bounds.max.z}) do
                    local point=math3d.add(math3d.scale(math3d.transform(view.rotation,{x,y,z}),view.scale),{view.translation.x,view.translation.y,view.translation.z})
                    for i=1,3 do check(math.abs(point[i])<=math.min(width,height)*0.5,"Every heading keeps the posed bounds/props inside the viewport") end
                end
            end
        end
        check(view.scale==scale,"Rotation never changes the preview scale")
    end
    check(same(loaded.mesh.rotation,authored.rotation) and loaded.mesh.translation.x==authored.translation.x
        and loaded.mesh.translation.y==authored.translation.y and loaded.mesh.translation.z==authored.translation.z,
        "Spinning cannot modify the authored pose root")
    for i=1,35 do check(same(body.bones[i].rotation,loaded.bones[i].rotation),"Spin leaves pose/body bone transforms intact") end
    motion.setSpinning(false)
    check(same(view.rotation,startRotation) and math.abs(view.translation.x-startTranslation.x)<1e-8
        and math.abs(view.translation.y-startTranslation.y)<1e-8 and math.abs(view.translation.z-startTranslation.z)<1e-8,
        "Deselection restores the original viewing angle and centre")
    return canvas,root,view,p,motion
end
local first,firstRoot,firstView=verify("oaab/k/mann_adlocutio.nif",188,210)
local second,secondRoot,secondView,_,secondMotion=verify("pose/k/guardlean.nif",200,80)
check(firstRoot~=secondRoot and firstView.children[1]~=secondView.children[1],"Multiple previews own independent native scenes")
local firstScale=firstView.scale
secondMotion.setSpinning(true); second:destroy()
local updates=#secondRoot.updates
secondMotion.update(1); secondMotion.setSpinning(false)
check(#secondRoot.updates==updates,"Destroyed previews cannot update their native scene")
check(firstView.scale==firstScale and next(firstRoot.effects)~=nil,"Destroying one preview preserves another")
first:destroy()
for _,light in ipairs(fixture.lights) do check(not next(light.affected),"Destroy breaks native effect ownership links") end
fixture.vertices={{-140,-10,-60},{100,10,15}}; fixture.prop={{-250,-10,-20},{70,5,30}}
local lying=verify("pose/k/lying.nif",180,90); lying:destroy()
fixture.vertices={{90,110,130},{160,130,205}}; fixture.prop={{180,150,240},{185,155,250}}
local offset=verify("pose/k/offset.nif",180,210); offset:destroy()
fixture.rootTransform={rotation=math3d.axisAngle({0,0,1},math.rad(90)),translation={x=300,y=400,z=500},scale=2}
local transformed=verify("pose/k/roottransform.nif",180,100); transformed:destroy()
fixture.rootTransform=nil
fixture.bipTranslation={10,20,30}
local moved=verify("pose/k/movedroot.nif",200,210); moved:destroy()
fixture.bipTranslation=nil
local invalid=parent(); local loads=#fixture.loads
fixture.exists=false
check(not pcall(preview.create,invalid,"missing.nif",180,200) and #fixture.loads==loads and #invalid.canvases==0,"Missing main meshes fail before native scene creation")
fixture.exists=true; fixture.loadError="Bad mesh"
check(not pcall(preview.create,invalid,"bad.nif",180,200) and #invalid.canvases==0,"Mesh load failure leaves no canvas")
fixture.loadError=nil; fixture.bounds={min={x=0/0,y=0,z=0},max={x=1,y=1,z=1}}
check(not pcall(preview.create,invalid,"badbounds.nif",180,200) and #invalid.canvases==0,"Malformed bounds fail safely without retaining a native scene")
fixture.bounds=nil; fixture.vertices=nil; fixture.prop=nil
fixture.missing="Meshes/"..preview.canvasPath
local loadedBefore=#fixture.loads
check(not pcall(preview.create,invalid,"valid.nif",180,200) and #invalid.canvases==0 and #fixture.loads==loadedBefore,"Missing canvas fails before model/UI creation without loading an error marker")
fixture.missing="Meshes/oaab/b/mannequin.nif"
check(not pcall(preview.create,invalid,"valid.nif",180,200) and #invalid.canvases==0,"Missing body files fail clearly before canvas creation")
fixture.missing=nil; fixture.missingBone=20
check(not pcall(preview.create,invalid,"valid.nif",180,200) and #invalid.canvases==0,"Incompatible body skeletons cannot render a misleading partial pose")
fixture.missingBone=nil
local originalBounds=niNode.new
local temporary=originalBounds()
-- The native bounds failure path must restore disabled visual switches too.
local visual=fixture.node("NiCollisionSwitch"); visual.collisionActive=false; temporary:attachChild(visual)
temporary.createBoundingBox=function() check(visual.collisionActive,"Visible switch is enabled only during measurement"); error("Bounds failed") end
check(not pcall(require("MannequinPoseDesigner.preview_scene").bounds,temporary) and not visual.collisionActive,"Bounds errors restore every temporary collision flag")
local newLight=niPointLight.new
niPointLight.new=function() error("Light creation failed") end
check(not pcall(preview.create,invalid,"valid.nif",180,200) and invalid.canvases[1].destroyed,"Scene setup failure destroys the partial canvas")
niPointLight.new=newLight
niPointLight.new=function()
    local light=newLight()
    light.setRadius=function() error("Light setup failed") end
    return light
end
check(not pcall(preview.create,invalid,"valid.nif",180,200) and invalid.canvases[2].destroyed,"Failure after allocating a light releases the canvas")
check(not next(fixture.lights[#fixture.lights].affected),"Partial light setup leaves no effect links")
print("PASS: "..count.." actual NIF attachment, posed fitting, render setup, isolation and native cleanup assertions")
