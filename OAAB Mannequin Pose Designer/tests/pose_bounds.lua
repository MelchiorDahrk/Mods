-- Body parts outside Bip01 must follow the posed skeleton's culling bounds.
package.path="./MWSE/mods/?.lua;"..package.path
local v=require("MannequinPoseDesigner.math3d")
local rig=require("MannequinPoseDesigner.rig")
local function vector(x,y,z)
    return {x=x,y=y,z=z,copy=function(self) return vector(self.x,self.y,self.z) end}
end
local function matrix(...)
    local a={...}
    if #a==0 then a=v.identity() end
    return {x=vector(unpack(a,1,3)),y=vector(unpack(a,4,6)),z=vector(unpack(a,7,9)),
        copy=function(self) return matrix(unpack(rig.matrix(self))) end}
end
tes3vector3={new=vector}
tes3matrix33={new=matrix}
tes3={niType={NiNode="node"},event={simulate="simulate",simulated="simulated"}}
local identity={translation={0,0,0},rotation=v.identity(),scale=1}
local function node(name,children)
    local result={name=name,children=children or {},translation=vector(0,0,0),rotation=matrix(),scale=1}
    function result:isInstanceOfType(kind) return kind=="node" end
    function result:update(args)
        assert(not args or not args.controllers,"Bounds updates must not evaluate animation controllers")
        local p=self.parent and self.parent.world or identity
        self.world={translation=v.add(p.translation,v.scale(v.transform(p.rotation,rig.vector(self.translation)),p.scale)),
            rotation=v.mul(p.rotation,rig.matrix(self.rotation)),scale=p.scale*self.scale}
        for _,child in pairs(self.children) do if child then child:update(args) end end
    end
    for _,child in pairs(result.children) do if child then child.parent=result end end
    return result
end
local function shape(bone)
    local result={appCulled=false}
    function result:isInstanceOfType() return false end
    function result:update(args)
        assert(not args or not args.controllers)
        -- A one-bone skinned limb: its culling sphere follows the bone,
        -- regardless of the mesh's own placement in the scene hierarchy.
        self.worldBoundOrigin=v.copy(bone.world.translation)
        self.worldBoundRadius=3*bone.world.scale
    end
    return result
end
local function actor(scale)
    local children={}
    for i=1,30 do children[i]=node("Bip01 Test"..i) end
    local bip=node("Bip01",children)
    local limb=shape(children[1])
    local outfit=shape(children[2])
    -- Both meshes precede the skeleton, and are outside its immediate parent.
    -- Updating the entire scene in one pass is insufficient with this order.
    local scene=node("Scene",{node("Body",{limb}),node("Outfit",{outfit}),node("Skeleton",{bip})})
    scene.translation=vector(1000,-500,200)
    scene.rotation=matrix(unpack(v.axisAngle({0,0,1},0.7)))
    scene.scale=scale
    bip:update()
    scene:update()
    return scene,bip,limb,outfit
end
local function checkBounds(scene,bip,limb,outfit)
    for i,mesh in ipairs({limb,outfit}) do
        local bone=bip.children[i]
        assert(v.length(v.sub(mesh.worldBoundOrigin,bone.world.translation))<1e-5,
            "Skinned sibling bounds must follow the new pose before rendering")
        assert(math.abs(mesh.worldBoundRadius-3*bone.world.scale)<1e-5,"Bounds must retain reference/bone scaling")
        assert(not mesh.appCulled,"Bounds refresh must preserve visibility flags")
    end
    assert(scene.scale~=1,"Exercise scaled mannequin references")
end
for _,scale in ipairs({0.5,2}) do
    local scene,bip,limb,outfit=actor(scale)
    local bones,nodes=rig.capture(scene)
    bones[1].translation={0,0,60}
    bones[2].translation={100,0,50}
    bones[2].scale=1.2
    bones[3].translation={0,70,-30}
    rig.apply(bones,nodes,scene)
    checkBounds(scene,bip,limb,outfit)
    bones[2].translation={-150,20,90}
    rig.apply(bones,nodes,scene)
    checkBounds(scene,bip,limb,outfit)
end
package.preload["OAAB.Mannequins.discovery"]=function()
    return {getMannequinProfile=function() return {id="full"} end}
end
local source,sourceBip=actor(1.1)
sourceBip.translation=vector(0,0,60)
sourceBip.children[1].translation=vector(100,0,50)
sourceBip.children[1].scale=1.2
sourceBip.children[2].translation=vector(0,70,-30)
tes3.loadMesh=function() return source end
tes3.makeSafeObjectHandle=function(ref) return {valid=function() return true end,getObject=function() return ref end} end
local callbacks={}
event={register=function(name,fn)
    callbacks[name]=callbacks[name] or {}
    callbacks[name][#callbacks[name]+1]=fn
end}
mwse={log=function() end}
local api=assert(loadfile(assert(arg[1],"Pass OAAB_Data poses.lua")))()
for _,scale in ipairs({0.5,2}) do
    local scene,bip,limb,outfit=actor(scale)
    local ref={sceneNode=scene,data={},updateLighting=function() end}
    assert(api.select(ref,"pose.nif"))
    checkBounds(scene,bip,limb,outfit)
    scene.translation=vector(-400,1000,20)
    bip.children[1].translation=vector(-150,20,90)
    scene:update() -- Simulate reference movement and a native animation frame.
    for _,fn in ipairs(callbacks.simulated) do fn() end
    checkBounds(scene,bip,limb,outfit)
end
print("PASS: editor/playback culling bounds for sibling body parts, outfits, moved and scaled references")
