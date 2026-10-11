package.path="./MWSE/mods/?.lua;"..package.path
local v=require("MannequinPoseDesigner.math3d")
local rig=require("MannequinPoseDesigner.rig")
local ground=require("MannequinPoseDesigner.ground")
local count=0
local function check(ok,reason) assert(ok,reason); count=count+1 end
local function same(a,b) return v.length(v.sub(a,b))<1e-4 end
local function matrix(a,b)
    for i=1,9 do if math.abs(a[i]-b[i])>1e-4 then return false end end
    return true
end
local relaxed=dofile("tests/mirror_fixture.lua")
local indices={}
for i,bone in ipairs(relaxed) do indices[bone.name:lower()]=i end
local left,right=indices["bip01 l foot"],indices["bip01 r foot"]
local chains=rig.chains(relaxed)
local function facing(bones,tip,rotation,frame)
    local world=rig.world(bones,frame)
    bones[tip].rotation=v.mul(v.transpose(world[bones[tip].parent].rotation),rotation)
end
for _,scale in ipairs({0.5,1,2}) do
    local frame={translation={170,-230,80},rotation=v.axisAngle({0,0,1},1.2),scale=scale}
    local reference=ground.reference(relaxed,frame)
    for _,raised in ipairs({left,right}) do
        for _,scope in ipairs({"left","right","both"}) do
            for _,offset in ipairs({-15,12}) do
                local bones=rig.clone(relaxed)
                local world=rig.world(bones,frame)
                local target=v.add(world[raised].translation,{0,0,9*scale})
                rig.solve(bones,chains[raised],target,rig.pole(bones,chains[raised],frame),frame)
                bones[1].translation[3]=bones[1].translation[3]+offset
                local yaws={[left]=0.7,[right]=-1.1}
                for _,tip in ipairs({left,right}) do
                    local side=tip==left and "l" or "r"
                    local delta=v.mul(v.axisAngle({0,0,1},yaws[tip]),
                        v.mul(v.axisAngle({0,1,0},0.4),v.axisAngle({1,0,0},-0.3)))
                    facing(bones,tip,v.mul(delta,reference[side].rotation),frame)
                end
                local before=rig.clone(bones)
                local original=rig.world(bones,frame)
                local result=ground.apply(bones,reference,scope,frame)
                world=rig.world(result,frame)
                check(same(world[1].translation,{original[1].translation[1],original[1].translation[2],world[1].translation[3]}),
                    "Grounding moves the root only vertically in world space")
                check(matrix(result[1].rotation,bones[1].rotation),"Root orientation remains unchanged")
                for _,tip in ipairs({left,right}) do
                    local side=tip==left and "l" or "r"
                    local selected=scope=="both" or scope=="left" and tip==left or scope=="right" and tip==right
                    if selected then
                        check(math.abs(world[tip].translation[3]-reference[side].translation[3])<1e-4,
                            "Selected soles reach their original ground height, accounting for ankle offsets")
                        check(matrix(world[tip].rotation,v.mul(v.axisAngle({0,0,1},yaws[tip]),reference[side].rotation)),
                            "Selected foot matches Relaxed tilt while preserving its world Z heading")
                    else
                        check(matrix(result[tip].rotation,bones[tip].rotation),"Unselected foot retains its local rotation")
                    end
                    check(math.abs(world[tip].translation[1]-original[tip].translation[1])<1e-4
                        and math.abs(world[tip].translation[2]-original[tip].translation[2])<1e-4,
                        "Grounding preserves both feet's horizontal positions")
                end
                for i,bone in ipairs(result) do
                    check((i==1 or same(bone.translation,bones[i].translation)) and bone.scale==bones[i].scale,
                        "No bone or limb segment is stretched or translated except the root")
                    local movedLeg=scope=="both" and (i==chains[raised].upper or i==chains[raised].lower)
                    if i~=left and i~=right and not movedLeg then
                        check(matrix(bone.rotation,bones[i].rotation),"Grounding preserves unrelated and lower planted leg rotations")
                    end
                    check(same(bones[i].translation,before[i].translation) and matrix(bones[i].rotation,before[i].rotation),
                        "Preparing grounding never mutates the input pose")
                end
                local repeated=ground.apply(result,reference,scope,frame)
                local again=rig.world(repeated,frame)
                for _,tip in ipairs({left,right}) do
                    check(same(again[tip].translation,world[tip].translation) and matrix(again[tip].rotation,world[tip].rotation),
                        "Repeated grounding is stable")
                end
            end
        end
    end
end
local reference=ground.reference(relaxed)
local bones=rig.clone(relaxed)
-- Identical support heights require no IK, despite different Relaxed ankle z.
local both=ground.apply(bones,reference,"both")
for _,tip in ipairs({left,right}) do
    check(matrix(both[chains[tip].upper].rotation,bones[chains[tip].upper].rotation)
        and matrix(both[chains[tip].lower].rotation,bones[chains[tip].lower].rotation),
        "Feet already on the plane do not receive an IK correction")
end
-- A turned/tilted parent requires inverse-frame conversion for vertical movement.
local tilted={translation={80,40,-60},rotation=v.axisAngle({1,2,3},0.7),scale=1.4}
local before=rig.world(bones,tilted)
local result=ground.apply(bones,reference,"left",tilted)
local after=rig.world(result,tilted)
check(math.abs(after[1].translation[1]-before[1].translation[1])<1e-4
    and math.abs(after[1].translation[2]-before[1].translation[2])<1e-4,
    "Even a tilted parent frame produces a vertical world root shift")
check(math.abs(after[left].translation[3]-reference.l.translation[3]*tilted.scale)<1e-4,
    "The saved original ground reference stays fixed through parent-frame changes")
for _,index in ipairs({1,left}) do
    local scaled=rig.clone(relaxed)
    scaled[index].scale=1.7
    local grounded=ground.apply(scaled,reference,"left")
    local foot=rig.world(grounded)[left]
    local sole=foot.translation[3]-reference.l.translation[3]*foot.scale/reference.l.scale
    check(math.abs(sole-reference.plane)<1e-4,"Scaled root and foot bones still plant the sole on the original plane")
    check(grounded[index].scale==scaled[index].scale,"Grounding preserves custom pose bone scales")
end
-- Near-vertical foot poses still produce a finite flat orientation.
facing(bones,left,v.mul(v.mul(v.axisAngle({0,0,1},1.3),v.axisAngle({0,1,0},math.pi/2)),reference.l.rotation))
result=ground.apply(bones,reference,"left")
check(matrix(rig.world(result)[left].rotation,v.mul(v.axisAngle({0,0,1},1.3),reference.l.rotation)),
    "A singular pitch falls back to the other horizontal axis without losing Z heading")
-- Reject unreachable vertical targets without changing the source pose.
bones=rig.clone(relaxed)
local root=rig.world(bones)[chains[right].upper].translation
rig.solve(bones,chains[right],v.add(root,{65,0,0}),rig.pole(bones,chains[right]))
local saved=rig.clone(bones)
local ok,err=pcall(ground.apply,bones,reference,"both")
check(not ok and err:find("cannot reach the ground",1,true),"Impossible both-foot targets report a useful error instead of stretching")
for i,bone in ipairs(bones) do check(same(bone.translation,saved[i].translation) and matrix(bone.rotation,saved[i].rotation),
    "An unreachable target leaves the source pose intact") end
check(not pcall(ground.apply,bones,reference,"unknown"),"Unknown targets are rejected")
check(not pcall(ground.reference,{relaxed[1]}),"An incomplete Relaxed reference is rejected")
print("PASS: "..count.." Ground Feet height, heading, IK, frame, scale and reach assertions")
