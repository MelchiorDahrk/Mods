package.path="./MWSE/mods/?.lua;"..package.path
local v=require("MannequinPoseDesigner.math3d")
local rig=require("MannequinPoseDesigner.rig")
local props=require("MannequinPoseDesigner.props")
local F=dofile("tests/prop_fixture.lua")
local count=0
local function check(ok,reason) assert(ok,reason); count=count+1 end
local function near(a,b)
    for _,key in ipairs({"translation","rotation"}) do
        for i,n in ipairs(a[key]) do check(math.abs(n-b[key][i])<1e-5,"Preserve world "..key) end
    end
    check(math.abs(a.scale-b.scale)<1e-5,"Preserve world scale")
end
local bones={
    {name="Bip01",parent=0,translation={0,0,60},rotation=v.axisAngle({0,0,1},0.5),scale=1.1},
    {name="Bip01 R Hand",parent=1,translation={-25,4,10},rotation=v.axisAngle({0,1,0},1.2),scale=0.8},
    {name="Bip01 L Hand",parent=1,translation={25,-4,12},rotation=v.axisAngle({1,0,0},-0.7),scale=1.3},
    {name="Bip01 Head",parent=1,translation={0,0,35},rotation=v.identity(),scale=1},
    {name="Bip01 Pelvis",parent=1,translation={0,0,0},rotation=v.identity(),scale=1},
}
local root,nodes=F.scene(bones)
props.apply({translation={130,-70,25},rotation=v.axisAngle({0,0,1},0.8),scale=1.4},root); root:update()
local s={scene=root,nodes=nodes,bones=bones,props={},selected=2}
F.installLoader()
for _,item in ipairs({"sword","shield","book","ingredient","clutter"}) do
    local p=props.add(s,{id=item,name=item,mesh="items/"..item..".nif"})
    check(p.attachmentType=="root" and s.selectedProp==p.id,"Inventory source creates selected free prop")
end
local p=s.props[1]
p.translation={12,-7,2}; p.rotation=v.axisAngle({1,1,0},0.45); p.scale=0.6
props.apply(p,s.propScene.nodes[p.id]); root:update()
local original=props.nodeTransform(s.propScene.nodes[p.id])
for _,bone in ipairs({"Bip01 R Hand","Bip01 L Hand",false,"Bip01 Head","Bip01 Pelvis",false}) do
    props.reparent(s,p,bone); near(original,props.nodeTransform(s.propScene.nodes[p.id]))
end
props.reparent(s,p,"Bip01 R Hand")
local before=props.nodeTransform(s.propScene.nodes[p.id])
nodes[2].rotation=rig.engineMatrix(v.axisAngle({0,1,0},2)); root:update()
check(v.length(v.sub(before.translation,props.nodeTransform(s.propScene.nodes[p.id]).translation))>1,"Parent bone naturally carries prop")
for _,attachment in ipairs({"Bip01 R Hand",false}) do
    props.reparent(s,p,attachment)
    local old=s.propScene.nodes[p.id]
    local world=props.nodeTransform(old)
    local definition=props.clone({p})[1]
    local total,serial,selection=#s.props,s.propSerial,s.selectedProp
    props.replace(s,p,{id="new_book",name="New Book",mesh="items/new_book.nif"})
    check(p.id==definition.id and #s.props==total and s.propSerial==serial and s.selectedProp==selection,
        "Replacement preserves identity, prop count, serial and selection")
    check(p.objectId=="new_book" and p.name=="New Book" and p.mesh=="items/new_book.nif","Replacement updates inventory source metadata")
    check(p.parentBone==definition.parentBone and p.attachmentType==definition.attachmentType,"Replacement retains bone or free parenting")
    near(p,definition); near(world,props.nodeTransform(s.propScene.nodes[p.id]))
    check(not old.parent and s.propScene.nodes[p.id]~=old,"Replacement detaches the old visual and installs the new one")
    local replacement=s.propScene.nodes[p.id]
    local source=p.mesh
    check(not pcall(props.replace,s,p,{id="missing",mesh="missing.nif"}) and p.mesh==source and s.propScene.nodes[p.id]==replacement,
        "An unreadable replacement leaves the original definition and visual intact")
    local parent=replacement.parent
    local attach=parent.attachChild
    function parent:attachChild(child) attach(self,child); error("Native attach failed") end
    check(not pcall(props.replace,s,p,{id="failed",mesh="items/failed.nif"}) and p.mesh==source and replacement.parent==parent,
        "A failed native attachment retains the old visual and metadata")
    parent.attachChild=attach
    local wrappers=0
    for _,child in pairs(parent.children) do if child.name==props.prefix..p.id then wrappers=wrappers+1 end end
    check(wrappers==1,"A failed attachment removes the attempted replacement wrapper")
    local update=root.update
    local failed=false
    function root:update()
        if not failed then failed=true; error("Scene update failed") end
        return update(self)
    end
    check(not pcall(props.replace,s,p,{id="update_failed",mesh="items/failed.nif"}) and p.mesh==source
        and s.propScene.nodes[p.id]==replacement and replacement.parent==parent,
        "A failed scene update restores the detached old prop and its metadata")
    root.update=update
    near(world,props.nodeTransform(replacement))
end
local missing=s.props[2]
missing.mesh="missing.nif"; props.restore(s)
check(not s.propScene.nodes[missing.id] and s.propScene.errors[missing.id],"Fixture restores an unavailable existing source")
props.replace(s,missing,{id="recovered",name="Recovered",mesh="items/recovered.nif"})
check(s.propScene.nodes[missing.id] and not s.propScene.errors[missing.id] and missing.objectId=="recovered",
    "Replace recovers an unavailable prop without deleting its definition")
local copy=props.duplicate(s,p)
check(copy.id~=p.id and copy.mesh==p.mesh and copy.translation~=p.translation,"Duplicate is independent with a stable unique ID")
props.reset(s,copy)
check(copy.scale==1 and copy.translation[1]==0 and copy.rotation[1]==1,"Reset local transform")
local saved=props.clone(s.props); p.translation[1]=999
check(saved[1].translation[1]~=999,"History copies do not alias live definitions")
props.delete(s,copy); check(not props.get(s,copy.id),"Delete removes definition and node")
s.props=props.clone(saved); props.restore(s)
check(props.get(s,copy.id) and s.propScene.nodes[copy.id],"Snapshot restore recreates deleted prop")
local size=#s.props
check(not pcall(props.add,s,{id="bad",name="Bad",mesh="missing.nif"}) and #s.props==size,"Failed add leaves existing scene intact")
props.reparent(s,s.props[1],"Missing Bone")
check(s.props[1].attachmentType=="root","Missing bone falls back to root")
local mesh=F.mesh(); mesh.translation=tes3vector3.new(3,4,5); mesh.scale=0.7
check(mesh.effectList and mesh.effectList.data==nil,"Native empty effect lists expose a non-nil head")
local collision=F.node("RootCollisionNode"); collision:attachChild(F.node("Collision","NiTriShape")); mesh:attachChild(collision)
mesh.controller={}; props.sanitize(mesh)
check(not mesh.controller and not collision.parent and mesh.scale==0.7 and mesh.translation.x==3,"Sanitize removes collision/controllers and keeps root transforms")
local artifact=F.node("misc_dwrv_artifact50")
for i=1,7 do artifact:attachChild(F.node("Visible "..i,"NiTriShape")) end
local unnamedCollision=F.node("","RootCollisionNode")
unnamedCollision:attachChild(F.node("","NiTriShape")); artifact:attachChild(unnamedCollision)
check(pcall(props.sanitize,artifact),"Skip the unnamed RootCollisionNode type used by misc_dwrv_artifact50")
check(not unnamedCollision.parent and not artifact.children[8] and #artifact.children==7,
    "Remove only the artifact's collision branch and retain all seven visual shapes")
local collisionBranch=F.node("Physics","RootCollisionNode")
collisionBranch.rotation=rig.engineMatrix({0,0,0,0,0,0,0,0,0})
collisionBranch:attachChild(F.node("Collision Particle","NiParticles"))
local visualMesh=F.mesh(); local inner=F.node("Inner")
inner:attachChild(collisionBranch); visualMesh:attachChild(inner)
check(pcall(props.sanitize,visualMesh) and not collisionBranch.parent,
    "Skip nested collision branches before validating their transforms or contents")
local effectMesh=F.mesh(); effectMesh.effectList={data={}}
check(not pcall(props.sanitize,effectMesh),"Reject a populated dynamic-effect list")
effectMesh=F.mesh(); effectMesh.effectList={next={data={}}}
check(not pcall(props.sanitize,effectMesh),"Inspect actual entries throughout the linked effect list")
effectMesh=F.mesh(); effectMesh.children[1]=nil
local nested=F.mesh(); nested.effectList={data={}}; effectMesh:attachChild(nested)
check(not pcall(props.sanitize,effectMesh),"Reject effects on nested mesh containers")
local nativeEmptyMesh=F.mesh()
nativeEmptyMesh.effectList={next={}}
check(props.sanitize(nativeEmptyMesh)==nativeEmptyMesh,"Empty effect-list links do not reject static geometry")
-- Topology inspected from misc_dwrv_ark_cube00.nif: one ordinary NiNode,
-- two static shapes, no controllers, no skinning and zero effects.
local cube=F.node("misc_dwrv_Ark_cube00")
for i=0,1 do
    local shape=F.node("Tri misc_dwrv_Ark_cube00 "..i,"NiTriShape")
    shape.translation=tes3vector3.new(0,0,-4); cube:attachChild(shape)
end
local loader=tes3.loadMesh
tes3.loadMesh=function() return cube end
local cubeProp=props.new(s,{id="test_cube",name="Dwemer Cube",mesh="m/misc_dwrv_ark_cube00.nif"})
local cubeWrapper=props.construct(cubeProp)
local importedCube=cubeWrapper.children[1].children[1]
check(importedCube~=cube and #importedCube.children==2,"The reported cube hierarchy imports as an independent prop")
check(importedCube.children[1].translation.z==-4 and importedCube.children[2].translation.z==-4,
    "Cube import preserves both original geometry offsets")
tes3.loadMesh=loader
for _,kind in ipairs({"NiParticles","NiLight","NiCamera","NiBSParticleNode","NiSwitchNode"}) do
    local bad=F.mesh(); bad:attachChild(F.node("Unsupported",kind))
    check(not pcall(props.sanitize,bad),"Reject unsupported "..kind)
end
local bad=F.mesh(); bad.children[1].skinInstance={}
check(not pcall(props.sanitize,bad),"Reject skinned inventory meshes")
bad=F.mesh(); bad.rotation=rig.engineMatrix({0,0,0,0,0,0,0,0,0})
check(not pcall(props.sanitize,bad),"Reject singular imported root rotations")
local switch=F.node("Visual Collision Switch","NiCollisionSwitch"); switch.collisionActive=true
switch:attachChild(F.node("Visible","NiTriShape")); props.sanitize(switch)
check(switch.collisionActive==false and switch.children[1],"Collision switches retain visual geometry with collision disabled")
local sourceProperty={controller={}}
function sourceProperty:clone()
    return {controller=self.controller,removeAllControllers=function(self) self.controller=nil end}
end
local propertyMesh=F.mesh(); local sanitizedProperty
function propertyMesh:detachAllProperties() return {sourceProperty} end
function propertyMesh:attachProperty(property) sanitizedProperty=property end
props.sanitize(propertyMesh)
check(sanitizedProperty~=sourceProperty and not sanitizedProperty.controller and sourceProperty.controller,"Property sanitization does not mutate shared source materials/controllers")
for _,path in ipairs({"../bad.nif","C:/bad.nif","/bad.nif","a/../bad.nif","bad.txt"}) do
    check(not pcall(props.meshPath,path),"Reject invalid mesh paths")
end
props.clearLive(s); check(not next(s.propScene.nodes),"Cleanup detaches owned nodes")
print("PASS: "..count.." prop state, item classes, scene parenting, transforms, duplication and sanitization assertions")
