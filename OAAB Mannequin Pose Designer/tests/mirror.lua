package.path="./MWSE/mods/?.lua;"..package.path
local v=require("MannequinPoseDesigner.math3d")
local rig=require("MannequinPoseDesigner.rig")
local mirror=require("MannequinPoseDesigner.mirror")
local nif=require("MannequinPoseDesigner.nif")
local count=0
local function check(ok,reason) assert(ok,reason); count=count+1 end
local function same(a,b)
    for i=1,#a do if math.abs(a[i]-b[i])>2e-4 then return false end end
    return true
end
local function transformSame(a,b)
    return same(a.translation,b.translation) and same(a.rotation,b.rotation) and math.abs(a.scale-b.scale)<1e-6
        and a.name==b.name and a.parent==b.parent
end
local bones=dofile("tests/mirror_fixture.lua")
local byName={}
for i,bone in ipairs(bones) do
    byName[bone.name:lower()]=i
    -- An asymmetric pose, including root movement, torso twist, finger edits,
    -- and individual positive scales, exercises more than the Relaxed stance.
    bone.rotation=v.orthonormalize(v.mul(bone.rotation,v.axisAngle({1,2,-3},i*0.031)))
    bone.scale=1+i*0.002
end
bones[1].translation=v.add(bones[1].translation,{17,-8,13})
local original=rig.clone(bones)
local function reflected(vector,normal)
    return v.sub(vector,v.scale(normal,2*v.dot(vector,normal)))
end
local function column(matrix,axis) return {matrix[axis],matrix[axis+3],matrix[axis+6]} end
local function geometry(before,after,destination,source,origin,normal)
    check(same(after[destination].translation,v.add(origin,reflected(v.sub(before[source].translation,origin),normal))),
        "Mirroring reflects actual joint positions in the anatomical plane")
    local flipped=bones[destination].name:lower()=="bip01" and 2 or 3
    for axis=1,3 do
        local expected=reflected(column(before[source].rotation,axis),normal)
        if axis==flipped then expected=v.scale(expected,-1) end
        check(same(column(after[destination].rotation,axis),expected),"Mirroring reflects joint facing without changing handedness")
    end
end
for _,frame in ipairs({
    {translation={0,0,0},rotation=v.identity(),scale=1},
    {translation={150,-35,290},rotation=v.axisAngle({1,2,3},1.1),scale=1.7},
}) do
    local mirrored,touched=mirror.apply(bones,"swap","entire")
    nif.validate(mirrored)
    local before,after=rig.world(bones,frame),rig.world(mirrored,frame)
    local normal=column(frame.rotation,1)
    for destination,bone in ipairs(bones) do
        if touched[destination] then
            local side,part=bone.name:lower():match("^bip01 ([lr]) (.+)$")
            local source=side and byName["bip01 "..(side=="l" and "r" or "l").." "..part] or destination
            geometry(before,after,destination,source,frame.translation,normal)
        else
            check(transformSame(mirrored[destination],bone),"Equipment attachment transforms retain their identity")
        end
    end
    local twice=mirror.apply(mirrored,"swap","entire")
    for i,bone in ipairs(bones) do
        check(transformSame(twice[i],bone),"Mirroring twice restores the entire pose")
        check(transformSame(bone,original[i]),"Mirroring never mutates its source pose")
        check(mirrored[i].translation~=bone.translation and mirrored[i].rotation~=bone.rotation,"Mirror results own their transform arrays")
    end
    for _,scope in ipairs({"arms","legs"}) do
        local pivot=byName[scope=="arms" and "bip01 neck" or "bip01 spine"]
        local origin=before[pivot].translation
        local plane=column(before[pivot].rotation,3)
        for _,action in ipairs({"swap","leftToRight","rightToLeft"}) do
            local result,changed=mirror.apply(bones,action,scope)
            local world=rig.world(result,frame)
            nif.validate(result)
            local affected=0
            for index,bone in ipairs(bones) do
                if changed[index] then
                    affected=affected+1
                    local side,part=bone.name:lower():match("^bip01 ([lr]) (.+)$")
                    local source=byName["bip01 "..(side=="l" and "r" or "l").." "..part]
                    geometry(before,world,index,source,origin,plane)
                    check(result[index].scale==bones[source].scale,"Destination receives source scale")
                    if action~="swap" then
                        check(side==(action=="leftToRight" and "r" or "l"),"Copy changes only its destination side")
                    end
                else
                    check(transformSame(result[index],bone),"Scoped commands preserve other limbs, torso and attachment offsets")
                end
            end
            check(affected==(scope=="arms" and (action=="swap" and 20 or 10) or (action=="swap" and 6 or 3)),
                "Scope includes hidden clavicles/fingers or all three leg joints")
            if action=="swap" then
                local twice=mirror.apply(result,action,scope)
                for i,bone in ipairs(bones) do check(transformSame(twice[i],bone),"Scoped mirroring twice restores the original") end
            else
                local repeated=mirror.apply(result,action,scope)
                for i,bone in ipairs(result) do check(transformSame(repeated[i],bone),"Directional copy is idempotent") end
            end
        end
    end
end
for _,action in ipairs({"leftToRight","rightToLeft"}) do
    local result,touched=mirror.apply(bones,action,"entire")
    for i,bone in ipairs(bones) do
        local side=bone.name:lower():match("^bip01 ([lr]) ")
        check(not touched[i] or side==(action=="leftToRight" and "r" or "l"),"Entire-pose copy changes only destination limbs")
        if not touched[i] then check(transformSame(result[i],bone),"Entire-pose copy preserves its source and central bones") end
    end
end
local incomplete={rig.clone({bones[1]})[1],rig.clone({bones[byName["bip01 l hand"]]})[1]}
incomplete[2].parent=1
local result,touched=mirror.apply(incomplete,"leftToRight","arms")
check(next(touched)==nil and transformSame(result[2],incomplete[2]),"Missing counterparts are skipped safely")
incomplete[2].name="bIP01 r hAND"
local left=rig.clone({bones[byName["bip01 l hand"]]})[1]; left.parent=1
incomplete[3]=left
result,touched=mirror.apply(incomplete,"leftToRight","arms")
check(touched[2] and not touched[3],"Pair matching ignores bone-name case")
check(not pcall(mirror.apply,bones,"bad","entire") and not pcall(mirror.apply,bones,"swap","bad"),"Invalid commands fail before changing the pose")
print("PASS: "..count.." mirror geometry, real skeleton, copy, scope and transform assertions")
