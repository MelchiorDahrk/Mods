package.path="./MWSE/mods/?.lua;"..package.path
local v=require("MannequinPoseDesigner.math3d")
local rig=require("MannequinPoseDesigner.rig")
local mirror=require("MannequinPoseDesigner.mirror")
local count=0
local function check(ok,reason) assert(ok,reason); count=count+1 end
local function same(a,b)
    for i,value in ipairs(a) do if math.abs(value-b[i])>1e-8 then return false end end
    return true
end
local function sameTransform(a,b)
    return same(a.translation,b.translation) and same(a.rotation,b.rotation) and a.scale==b.scale
end
local initial=dofile("tests/mirror_fixture.lua")
local posed=rig.clone(initial)
local byName={}
for i,bone in ipairs(posed) do
    byName[bone.name:lower()]=i
    bone.translation=v.add(bone.translation,{i,-i,2*i})
    bone.rotation=v.mul(bone.rotation,v.axisAngle({1,2,3},i*0.02))
    bone.scale=1+i*0.01
end
local before=rig.clone(posed)
for selected=1,#posed do
    for _,scope in ipairs({"bone","limb","entire"}) do
        local result,touched=rig.reset(posed,initial,selected,scope)
        for i,bone in ipairs(result) do
            local descendant=false
            local ancestor=i
            while ancestor~=0 do
                if ancestor==selected then descendant=true; break end
                ancestor=posed[ancestor].parent
            end
            local expected=scope=="entire" or i==selected or (scope=="limb" and descendant)
            check(sameTransform(bone,expected and initial[i] or posed[i]),
                "Each reset restores exactly its target's local translation, rotation and scale")
            check((touched[i]==true)==expected,"Reset reports the entire target branch for lock rebasing")
            check(bone.name==posed[i].name and bone.parent==posed[i].parent,"Reset preserves the captured hierarchy")
            check(bone.translation~=initial[i].translation and bone.rotation~=initial[i].rotation
                and bone.translation~=posed[i].translation and bone.rotation~=posed[i].rotation,
                "Reset owns its arrays without aliasing the session baseline or prior pose")
        end
    end
end
for i,bone in ipairs(initial) do
    check(sameTransform(posed[i],before[i]) and not sameTransform(bone,posed[i]),"Reset never mutates its inputs")
end
local calf=byName["bip01 l calf"]
local foot=byName["bip01 l foot"]
local thigh=byName["bip01 l thigh"]
local result=rig.reset(posed,initial,calf,"limb")
check(sameTransform(result[calf],initial[calf]) and sameTransform(result[foot],initial[foot])
    and sameTransform(result[thigh],posed[thigh]),"Knee limb reset restores calf and foot while keeping the thigh posed")
local forearm=byName["bip01 l forearm"]
local _,touched=rig.reset(posed,initial,forearm,"limb")
check(touched[byName["bip01 l finger01"]] and not touched[byName["bip01 l upperarm"]],
    "Forearm limb reset includes hidden finger descendants and excludes its upper arm")
-- Explicit limb resets mirror even descendants whose source is already at its
-- baseline; an independently posed counterpart still needs to follow the reset.
result,touched=rig.reset(initial,initial,calf,"limb")
local rightFoot=byName["bip01 r foot"]
result[rightFoot].rotation=v.mul(result[rightFoot].rotation,v.axisAngle({0,1,0},0.4))
local previous=rig.clone(result)
local reflected=mirror.apply(result,"leftToRight","legs")
local mirrored=mirror.follow(result,previous,calf,"legs",touched)
check(mirrored[rightFoot] and sameTransform(result[rightFoot],reflected[rightFoot]),
    "Live symmetry follows all explicitly reset descendants, including unchanged sources")
print("PASS: "..count.." reset scope, hierarchy, baseline isolation and symmetry assertions")
