package.path="./MWSE/mods/?.lua;./MWSE/mods/?/init.lua;"..package.path
local v=require("MannequinPoseDesigner.math3d")
local rig=require("MannequinPoseDesigner.rig")
local nif=require("MannequinPoseDesigner.nif")
local count=0
local function check(ok,message) assert(ok,message); count=count+1 end
local function near(a,b,epsilon) return math.abs(a-b)<(epsilon or 1e-5) end
local function vectorNear(a,b) return v.length(v.sub(a,b))<1e-5 end
local function bone(name,parent,t,r,scale)
    return {name=name,parent=parent,translation=t,rotation=r or v.identity(),scale=scale or 1}
end
local bones={
    bone("Bip01",0,{0,0,60},v.axisAngle({0,0,1},0.37)),
    bone("Bip01 L UpperArm",1,{0,0,12}),
    bone("Bip01 L Forearm",2,{20,0,0}),
    bone("Bip01 L Hand",3,{18,0,0}),
    bone("Bip01 L Finger0",4,{2,0,0},v.axisAngle({1,0,0},-0.6)),
    bone("Weapon Bone",1,{1,-2,3},v.axisAngle({0,1,0},1.2)),
}
local frame={translation={140,-35,250},rotation=v.axisAngle({0,0,1},1.1),scale=1.2}
local world=rig.world(bones,frame)
local chains=rig.chains(bones)
check(chains[4]~=nil,"Detect TES3 two-bone chain")
local a=world[2].translation
local target=v.add(a,{14,17,-8})
local pole=v.add(a,{0,0,-30})
local oldTip=v.copy(world[4].rotation)
rig.solve(bones,chains[4],target,pole,frame)
world=rig.world(bones,frame)
check(vectorNear(world[4].translation,target),"IK reaches reachable world target under rotated/scaled parent")
check(near(v.length(v.sub(world[3].translation,a)),24),"Upper length preserved")
check(near(v.length(v.sub(world[4].translation,world[3].translation)),21.6),"Lower length preserved")
for i=1,9 do check(near(oldTip[i],world[4].rotation[i]),"Effector orientation preserved") end
for _,t in ipairs({a,v.add(a,{1000,0,0}),v.add(a,{-1000,0,0}),v.add(a,{0,0,0.00000001})}) do
    rig.solve(bones,chains[4],t,a,frame)
    local w=rig.world(bones,frame)
    check(near(v.length(v.sub(w[3].translation,w[2].translation)),24),"Degenerate target preserves upper length")
    check(near(v.length(v.sub(w[4].translation,w[3].translation)),21.6),"Degenerate target preserves lower length")
end
for i=1,150 do
    rig.solve(bones,chains[4],v.add(a,{math.sin(i)*150,math.cos(i)*150,math.sin(i*0.31)*40}),pole,frame)
end
local function determinant(r)
    return r[1]*(r[5]*r[9]-r[6]*r[8])-r[2]*(r[4]*r[9]-r[6]*r[7])+r[3]*(r[4]*r[8]-r[5]*r[7])
end
for _,index in ipairs({2,3,4}) do
    check(near(determinant(bones[index].rotation),1,0.01),"Repeated IK keeps bone rotation orthogonal")
end
local copied=rig.clone(bones)
copied[1].translation[1]=999
check(bones[1].translation[1]~=999,"Undo snapshots do not alias transforms")
check(vectorNear(v.transform(v.between({1,0,0},{-1,0,0}),{1,0,0}),{-1,0,0}),"Antiparallel rotation")
for _,angle in ipairs({0.0005,math.pi-0.0005}) do
    local target=v.transform(v.axisAngle({0,0,1},angle),{1,0,0})
    check(vectorNear(v.transform(v.between({1,0,0},target),{1,0,0}),target),"Fine and nearly antiparallel corrections reach their direction")
end
local before=rig.clone(bones)
rig.world(bones,{translation={1,2,3},rotation=v.axisAngle({0,0,1},2.3),scale=0.7})
for i,b in ipairs(before) do
    check(vectorNear(b.translation,bones[i].translation) and b.scale==bones[i].scale,"World placement never changes local pose data")
    for j=1,9 do check(b.rotation[j]==bones[i].rotation[j],"World yaw never changes local rotations") end
end
for _,case in ipairs({{}, {bone("Bip01",1,{0,0,0})}, {bone("Bip01",0,{0/0,0,0})}}) do
    check(not pcall(nif.validate,case),"Reject invalid pose data")
end
-- OAAB integration contract, loaded from the actual modified source.
local apiFile=arg[1]
if apiFile then
    local menu,listener,invalid,failed
    local function value(n) return {copy=function() return value(n) end} end
    local function node(name,children)
        local result={name=name,children=children or {},translation=value(0),rotation=value(0),scale=1}
        function result:isInstanceOfType(kind) return kind=="NiNode" end
        function result:update() end
        return result
    end
    local children={}
    for i=1,30 do children[i]=node("Bip01 Test"..i) end
    local function tree() return node("Scene",{node("Bip01",children)}) end
    package.preload["OAAB.Mannequins.discovery"]=function() return {getMannequinProfile=function(r) return r.profile end} end
    tes3={event={simulate="simulate",simulated="simulated"},niType={NiNode="NiNode"},
        makeSafeObjectHandle=function(r) return {valid=function() return not invalid end,getObject=function() return r end} end,
        messageBox=function(m) if type(m)=="table" then menu=m end end,
        loadMesh=function(file) if file=="missing.nif" then error("Missing NIF") end; return tree() end}
    event={register=function() end,trigger=function(_,e) if listener then listener(e) end end}
    mwse={log=function() end}
    local api=assert(loadfile(apiFile))()
    local ref={profile={id="full"},data={},sceneNode=tree(),updateLighting=function() end}
    check(api.showMenu(ref),"Full mannequin menu")
    check(#menu.buttons==5 and menu.buttons[5]=="Cancel","OAAB operates alone")
    menu.callback({button=0})
    check(api.getSelectedFile(ref)=="oaab/k/mann_relax.nif","Built-in file selected")
    check(not api.showMenu({profile={id="stand"}}),"Dress stands excluded")
    listener=function(e) table.insert(e.entries,1,{label="Create pose",callback=function() failed=false end}) end
    api.showMenu(ref)
    check(menu.buttons[1]=="Create pose","Extension action inserted")
    failed=true; menu.callback({button=0}); check(not failed,"Extension callback")
    invalid=true; failed=true; menu.callback({button=0}); check(failed,"Invalid handle blocks stale callback"); invalid=false
    local previous=api.getSelectedFile(ref)
    check(not api.select(ref,"missing.nif"),"Load failure reported")
    check(api.getSelectedFile(ref)==previous,"Failed selection rolls back")
    for i=1,20 do api.registerPose("test"..i,{label="Test "..i,file="test.nif"}) end
    api.showMenu(ref)
    check(#menu.buttons<=10,"Native message box pagination")
    local nextIndex
    for i,label in ipairs(menu.buttons) do if label=="Next" then nextIndex=i end end
    check(nextIndex~=nil,"Next page available")
    menu.callback({button=nextIndex-1})
    check(menu.buttons[#menu.buttons-2]=="Previous","Previous page available")
end
print("PASS: "..count.." math and OAAB integration assertions")
