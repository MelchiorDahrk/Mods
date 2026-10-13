-- Assemble a private mannequin body driven by the actual pose NIF. OAAB's
-- animation NIFs contain bones and a culled shadow skin, not the visible body.
local rig=require("MannequinPoseDesigner.rig")
local math3d=require("MannequinPoseDesigner.math3d")
local M={bodyFile="oaab/b/mannequin.nif"}
local identity={translation={0,0,0},rotation=math3d.identity(),scale=1}
local function visit(node,fn,seen)
    if not node or seen[node] then return end
    seen[node]=true; fn(node)
    if node:isInstanceOfType(tes3.niType.NiNode) then
        for _,child in pairs(node.children) do visit(child,fn,seen) end
    end
end
local function load(file)
    assert(tes3.getFileExists("Meshes/"..file),"Preview NIF not found: "..file)
    local mesh=assert(tes3.loadMesh(file,false),"Could not load preview NIF: "..file)
    mesh.appCulled=false
    visit(mesh,function(node)
        -- Neither the UI's clock nor a body replacer's controllers may replace
        -- the copied pose. Only uncached instances are changed, never files.
        node:removeAllControllers()
        if node:isInstanceOfType(tes3.niType.RootCollisionNode) then node.appCulled=true end
    end,{})
    mesh:update({controllers=false})
    return mesh
end
local function frame(node)
    if not node then return identity end
    local t=node.worldTransform
    return {translation=rig.vector(t.translation),rotation=rig.matrix(t.rotation),scale=t.scale}
end
local function compose(a,b)
    return {rotation=math3d.mul(a.rotation,b.rotation),scale=a.scale*b.scale,
        translation=math3d.add(a.translation,math3d.scale(math3d.transform(a.rotation,b.translation),a.scale))}
end
local function inverse(t)
    assert(t.scale>1e-6,"Invalid mannequin skeleton frame")
    local rotation=math3d.transpose(t.rotation)
    return {rotation=rotation,scale=1/t.scale,translation=math3d.scale(math3d.transform(rotation,t.translation),-1/t.scale)}
end
function M.build(file)
    assert(type(file)=="string" and file~="","Invalid pose NIF path")
    local pose=load(file)
    local bones,sourceNodes=rig.capture(pose)
    assert(#bones>=30,"Pose NIF has an incomplete mannequin skeleton")
    local body=load(M.bodyFile)
    local bodyBones,bodyNodes=rig.capture(body)
    local byName,targets={},{ }
    for i,bone in ipairs(bodyBones) do byName[bone.name:lower()]=bodyNodes[i] end
    for i,bone in ipairs(bones) do
        targets[i]=assert(byName[bone.name:lower()],"Preview body is missing bone: "..bone.name)
    end
    -- Align the body skeleton's parent frame to the pose's parent frame. This
    -- also handles authored transforms above Bip01 in imported pose NIFs.
    local correction=compose(frame(sourceNodes[1].parent),inverse(frame(targets[1].parent)))
    local placed=compose(correction,frame(body))
    body.translation=rig.engineVector(placed.translation)
    body.rotation=rig.engineMatrix(placed.rotation); body.scale=placed.scale
    body:update({controllers=false})
    rig.apply(bones,targets,body)
    -- Keep the entire pose graph: its embedded prop geometry and bone/free
    -- attachments remain in their authored places beside the posed body.
    local scene=niNode.new()
    scene.name="OAAB Pose Preview"
    scene:attachChild(pose); scene:attachChild(body)
    -- Bounds for skinned meshes need current bones before the scene refresh.
    targets[1]:update({controllers=false}); scene:update({controllers=false})
    return scene,{pose=pose,body=body,bones=#bones,bodyFile=M.bodyFile}
end
function M.bounds(scene)
    -- MWSE's bounding-box traversal skips disabled NiCollisionSwitch subtrees,
    -- including the visible, collision-disabled wrappers of embedded props.
    -- Enable them only for measurement on this private scene, then restore them.
    local switches={}
    visit(scene,function(node)
        if tes3.niType.NiCollisionSwitch and node:isInstanceOfType(tes3.niType.NiCollisionSwitch)
            and not node.collisionActive then
            switches[#switches+1]=node; node.collisionActive=true
        end
    end,{})
    local ok,bounds=pcall(scene.createBoundingBox,scene,{accurateSkinned=true,observeAppCullFlag=true,onlyActiveChildren=true})
    for _,node in ipairs(switches) do node.collisionActive=false end
    if not ok then error(bounds,0) end
    return bounds
end
return M
