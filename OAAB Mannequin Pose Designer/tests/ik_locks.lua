package.path="./MWSE/mods/?.lua;"..package.path
local v=require("MannequinPoseDesigner.math3d")
local rig=require("MannequinPoseDesigner.rig")
local count=0
local function check(ok,reason) assert(ok,reason); count=count+1 end
local function near(a,b) return math.abs(a-b)<1e-4 end
local function vectorNear(a,b) return v.length(v.sub(a,b))<1e-4 end
local function matrixNear(a,b)
    for i=1,9 do if not near(a[i],b[i]) then return false end end
    return true
end
local function bone(name,parent,t,r)
    return {name=name,parent=parent,translation=t,rotation=r or v.identity(),scale=1}
end
local function fixture()
    return {
        bone("Bip01",0,{0,0,55}),
        bone("Bip01 Pelvis",1,{0,0,0}),
        bone("Bip01 Spine",2,{0,0,20}),
        bone("Bip01 L Clavicle",3,{-2,0,10}),
        bone("Bip01 L UpperArm",4,{-8,0,0}),
        bone("Bip01 L Forearm",5,{-16,0,0},v.axisAngle({0,0,1},0.8)),
        bone("Bip01 L Hand",6,{-14,0,0},v.axisAngle({0,1,0},0.3)),
        bone("Bip01 R Clavicle",3,{2,0,10}),
        bone("Bip01 R UpperArm",8,{8,0,0}),
        bone("Bip01 R Forearm",9,{16,0,0},v.axisAngle({0,0,1},-0.8)),
        bone("Bip01 R Hand",10,{14,0,0}),
        bone("Bip01 L Thigh",2,{-6,0,0},v.axisAngle({1,0,0},0.45)),
        bone("Bip01 L Calf",12,{0,0,-23},v.axisAngle({1,0,0},-0.9)),
        bone("Bip01 L Foot",13,{0,0,-20},v.axisAngle({1,0,0},0.45)),
        bone("Bip01 R Thigh",2,{6,0,0},v.axisAngle({1,0,0},0.45)),
        bone("Bip01 R Calf",15,{0,0,-23},v.axisAngle({1,0,0},-0.9)),
        bone("Bip01 R Foot",16,{0,0,-20},v.axisAngle({1,0,0},0.45)),
    }
end
local function lockAll(bones,chains)
    local locks={}
    for tip in pairs(chains) do locks[tip]=rig.anchor(bones,tip) end
    return locks
end
local function checkLengths(bones,chains,frame)
    local world=rig.world(bones,frame)
    for _,chain in pairs(chains) do
        for _,index in ipairs({chain.lower,chain.tip}) do
            local parent=bones[index].parent
            check(near(v.length(v.sub(world[index].translation,world[parent].translation)),
                v.length(bones[index].translation)*world[parent].scale),"Locks preserve limb segment lengths")
        end
    end
end
for _,scale in ipairs({0.5,1,2}) do
    local frame={translation={140,-250,40},rotation=v.axisAngle({0,0,1},1.1),scale=scale}
    local bones=fixture()
    local chains=rig.chains(bones)
    local locks=lockAll(bones,chains)
    local original=rig.world(bones,frame)
    local function held(edited)
        local world=rig.world(bones,frame)
        for tip in pairs(chains) do
            check(vectorNear(world[tip].translation,original[tip].translation),
                "All locked hands/feet stay planted through reachable edits: scale="..scale..", edited="..tostring(edited)..", tip="..tip..", error="..v.length(v.sub(world[tip].translation,original[tip].translation)))
            check(matrixNear(world[tip].rotation,original[tip].rotation),"Locked hands/feet retain their facing")
        end
        checkLengths(bones,chains,frame)
    end
    bones[1].translation=v.add(bones[1].translation,{0.7,0.2,0.1})
    rig.solveLocks(bones,chains,locks,frame,1); held()
    for _,index in ipairs({1,2,3,4,8}) do
        bones[index].rotation=v.mul(bones[index].rotation,v.axisAngle({0,0,1},0.035))
        local edited=v.copy(bones[index].rotation)
        rig.solveLocks(bones,chains,locks,frame,index); held(index)
        check(matrixNear(bones[index].rotation,edited),"Root/pelvis/spine/clavicle edits are retained")
    end
    -- Viewing yaw/placement/scale carry anchors with the mannequin.
    local before=rig.clone(bones)
    local otherFrame={translation={-400,180,90},rotation=v.axisAngle({0,0,1},-0.8),scale=scale*1.3}
    rig.solveLocks(bones,chains,locks,otherFrame)
    for i,b in ipairs(bones) do
        check(matrixNear(b.rotation,before[i].rotation) and vectorNear(b.translation,before[i].translation),
            "Changing the view frame does not deform a locked pose")
    end
end
-- Explicit rotations inside a locked chain constrain the remaining freedom.
for _,tip in ipairs({7,11,14,17}) do
    for _,part in ipairs({"upper","lower"}) do
        local bones=fixture()
        local chains=rig.chains(bones)
        local chain=chains[tip]
        local locks={[tip]=rig.anchor(bones,tip)}
        local anchor=v.copy(locks[tip].target)
        local facing=v.copy(locks[tip].rotation)
        local edited=chain[part]
        bones[edited].rotation=v.mul(bones[edited].rotation,v.axisAngle({0,0,1},0.55))
        local rotation=v.copy(bones[edited].rotation)
        local world=rig.world(bones)
        local pivot=world[part=="upper" and chain.lower or chain.upper].translation
        local current=v.sub(world[tip].translation,pivot)
        local nearest=v.add(pivot,v.scale(v.unit(v.sub(anchor,pivot)),v.length(current)))
        rig.solveLocks(bones,chains,locks,nil,edited)
        world=rig.world(bones)
        check(matrixNear(bones[edited].rotation,rotation),"Lock never undoes an explicit upper/lower limb rotation")
        check(vectorNear(world[tip].translation,nearest),"With a fixed limb rotation the tip moves only as far as forced")
        check(vectorNear(locks[tip].target,nearest),"Forced position becomes the new lock anchor")
        check(matrixNear(world[tip].rotation,facing),"Forced movement preserves the effector's facing")
        checkLengths(bones,chains)
    end
end
local bones=fixture()
local chains=rig.chains(bones)
local locks={[7]=rig.anchor(bones,7)}
local oldAnchor=v.copy(locks[7].target)
bones[1].translation=v.add(bones[1].translation,{100,0,0})
rig.solveLocks(bones,chains,locks,nil,1)
local forced=rig.world(bones)[7].translation
check(not vectorNear(forced,oldAnchor) and vectorNear(forced,locks[7].target),"Unreachable root movement clamps and rebases a locked hand")
check(near(v.length(v.sub(forced,rig.world(bones)[5].translation)),30),"Forced movement stops at maximum reach")
bones[1].translation=v.add(bones[1].translation,{-1,0,0})
rig.solveLocks(bones,chains,locks,nil,1)
check(vectorNear(rig.world(bones)[7].translation,forced),"Subsequent reachable edits hold the forced position without springing back")
local snapshots=rig.cloneLocks(locks)
snapshots[7].target[1]=999
snapshots[7].rotation[1]=999
check(locks[7].target[1]~=999 and locks[7].rotation[1]~=999,"Undo lock snapshots do not alias position or orientation")
-- A folded target must remain finite and obey the minimum reach.
bones=fixture(); locks={[7]=rig.anchor(bones,7)}
bones[1].translation=v.add(bones[1].translation,v.sub(locks[7].target,rig.world(bones)[5].translation))
rig.solveLocks(bones,chains,locks,nil,1)
local world=rig.world(bones)
check(near(v.length(v.sub(world[7].translation,world[5].translation)),2),"Fully folded lock respects minimum reach without singularities")
checkLengths(bones,chains)
-- Unlocking restores ordinary FK inheritance.
locks[7]=nil
local hand=v.copy(world[7].translation)
bones[3].rotation=v.mul(bones[3].rotation,v.axisAngle({1,0,0},0.2))
rig.solveLocks(bones,chains,locks,nil,3)
check(not vectorNear(rig.world(bones)[7].translation,hand),"Unlocked hand follows its parent's rotation")
print("PASS: "..count.." IK lock, reach, explicit rotation, scaling, frame and snapshot assertions")
