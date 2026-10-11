package.path="./MWSE/mods/?.lua;"..package.path
local v=require("MannequinPoseDesigner.math3d")
local rig=require("MannequinPoseDesigner.rig")
local blend=require("MannequinPoseDesigner.blend")
local nif=require("MannequinPoseDesigner.nif")
local count=0
local function check(ok,reason) assert(ok,reason); count=count+1 end
local function same(a,b,epsilon)
    for i,value in ipairs(a) do if math.abs(value-b[i])>(epsilon or 1e-9) then return false end end
    return #a==#b
end
local a=dofile("tests/mirror_fixture.lua")
for _,bone in ipairs(a) do bone.rotation=v.orthonormalize(bone.rotation) end
local b=rig.clone(a)
for i,bone in ipairs(b) do
    bone.translation=v.add(bone.translation,{i,-i*2,i*3})
    bone.scale=0.5+i*0.02
    bone.rotation=v.mul(a[i].rotation,v.axisAngle({1,2,-3},math.pi*0.8))
end
local beforeA,beforeB=rig.clone(a),rig.clone(b)
for _,t in ipairs({0,0.01,0.25,0.5,0.75,0.99,1}) do
    local result=blend.apply(a,b,t)
    nif.validate(result)
    for i,bone in ipairs(result) do
        check(bone.name==a[i].name and bone.parent==a[i].parent,"Blending preserves the live skeleton topology")
        for axis=1,3 do
            check(math.abs(bone.translation[axis]-(a[i].translation[axis]*(1-t)+b[i].translation[axis]*t))<1e-9,
                "Translations use local linear interpolation")
        end
        check(math.abs(bone.scale-(a[i].scale*(1-t)+b[i].scale*t))<1e-9,"Scales use linear interpolation")
        check(same(bone.rotation,v.mul(a[i].rotation,v.axisAngle({1,2,-3},math.pi*0.8*t))),
            "Rotations move at constant angular speed about the relative axis")
        check(same(a[i].rotation,beforeA[i].rotation) and same(b[i].rotation,beforeB[i].rotation)
            and same(a[i].translation,beforeA[i].translation) and same(b[i].translation,beforeB[i].translation),
            "Repeated slider updates never mutate either source pose")
        if t==0 or t==1 then
            local source=t==0 and a[i] or b[i]
            check(same(bone.rotation,source.rotation,0) and same(bone.translation,source.translation,0)
                and bone.scale==source.scale,"Endpoints preserve every transform exactly")
        end
    end
end
local root={{name="Bip01",parent=0,translation={0,0,0},scale=1,rotation=v.identity()}}
local target=rig.clone(root)
for _,axis in ipairs({{1,0,0},{0,1,0},{0,0,1},{1,-3,2}}) do
    for _,angle in ipairs({0,1e-10,1e-4,math.pi,-math.pi,math.pi*1.5}) do
        target[1].rotation=v.axisAngle(axis,angle)
        local midpoint=blend.apply(root,target,0.5)
        nif.validate(midpoint)
        local shortest=angle>math.pi and angle-math.pi*2 or angle
        -- At exactly 180 degrees either equally short direction is valid.
        if math.abs(angle)==math.pi then
            check(same(v.mul(midpoint[1].rotation,midpoint[1].rotation),target[1].rotation),
                "Half-turn interpolation stays finite and reaches its endpoint")
        else
            check(same(midpoint[1].rotation,v.axisAngle(axis,shortest/2)),"Slerp handles equal, close and long-arc rotations")
        end
        check(same(v.quaternionMatrix(v.quaternion(target[1].rotation)),target[1].rotation),
            "Quaternion conversion agrees with row-major NIF rotations for every matrix branch")
    end
end
local q=v.quaternion(v.axisAngle({1,2,3},2))
local negative={-q[1],-q[2],-q[3],-q[4]}
check(same(v.quaternionMatrix(v.slerp(q,negative,0.5)),v.quaternionMatrix(q)),
    "Antipodal quaternion signs describe the same rotation without a full spin")
target[1].rotation=v.axisAngle({0,0,1},-170*math.pi/180)
root[1].rotation=v.axisAngle({0,0,1},170*math.pi/180)
check(same(blend.apply(root,target,0.5)[1].rotation,v.axisAngle({0,0,1},math.pi)),
    "Crossing plus/minus 180 degrees follows the short 20-degree arc")
check(same(blend.apply(root,target,-1)[1].rotation,root[1].rotation,0)
    and same(blend.apply(root,target,2)[1].rotation,target[1].rotation,0),"Out-of-range amounts clamp to endpoints")
check(not pcall(blend.apply,root,target,0/0) and not pcall(blend.apply,root,target,math.huge),"Non-finite blend amounts are refused")
local reference={
    {name="Bip01",parent=0,translation={0,0,0},rotation=v.identity(),scale=1},
    {name="Bip01 L Hand",parent=1,translation={1,2,3},rotation=v.identity(),scale=1},
    {name="Bip01 R Hand",parent=1,translation={4,5,6},rotation=v.identity(),scale=1},
}
local reordered={reference[1],reference[3],reference[2]}
reordered=rig.clone(reordered)
for _,bone in ipairs(reordered) do bone.name=bone.name:lower() end
local aligned=blend.align(reordered,reference)
check(same(aligned[2].translation,reference[2].translation) and aligned[2].name==reference[2].name,
    "Saved bones match by case-insensitive name rather than traversal order")
aligned[2].translation[1]=99
check(reordered[3].translation[1]==1,"Alignment copies rather than aliases source data")
reordered[2].parent=3
check(not pcall(blend.align,reordered,reference),"Different parent frames cannot be blended")
reordered[2].parent=1; reordered[2].name="Bip01 other"
check(not pcall(blend.align,reordered,reference),"Missing bones are refused without substituting a live transform")
reordered[2].name=reordered[3].name
check(not pcall(blend.align,reordered,reference),"Duplicate names are refused")
table.remove(reordered)
check(not pcall(blend.align,reordered,reference),"Different skeleton sizes are refused")
check(not pcall(blend.apply,reference,{reference[1]},0.5),"Unaligned blends cannot silently omit bones")
print("PASS: "..count.." pose blending, shortest-arc quaternion and skeleton matching assertions")
