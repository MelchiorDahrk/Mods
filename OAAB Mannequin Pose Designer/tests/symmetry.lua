package.path="./MWSE/mods/?.lua;"..package.path
local v=require("MannequinPoseDesigner.math3d")
local rig=require("MannequinPoseDesigner.rig")
local mirror=require("MannequinPoseDesigner.mirror")
local nif=require("MannequinPoseDesigner.nif")
local count=0
local function check(ok,reason) assert(ok,reason); count=count+1 end
local function same(a,b)
    for i,value in ipairs(a) do if math.abs(value-b[i])>1e-8 then return false end end
    return true
end
local function sameTransform(a,b)
    return same(a.rotation,b.rotation) and same(a.translation,b.translation) and a.scale==b.scale
end
local bones=dofile("tests/mirror_fixture.lua")
local byName={}
for i,bone in ipairs(bones) do
    byName[bone.name:lower()]=i
    bone.rotation=v.orthonormalize(v.mul(bone.rotation,v.axisAngle({1,2,3},i*0.017)))
end
for _,side in ipairs({"l","r"}) do
    for _,part in ipairs({"upperarm","forearm","hand","thigh","calf","foot","finger01","clavicle"}) do
        local selected=byName["bip01 "..side.." "..part]
        local other=byName["bip01 "..(side=="l" and "r" or "l").." "..part]
        local limb=(part=="thigh" or part=="calf" or part=="foot") and "legs" or "arms"
        for _,scope in ipairs({"off","entire","arms","legs"}) do
            local edited=rig.clone(bones)
            edited[selected].rotation=v.mul(edited[selected].rotation,v.axisAngle({0,1,0},0.3))
            edited[selected].translation=v.add(edited[selected].translation,{2,-3,4})
            edited[selected].scale=1.2
            local before=rig.clone(edited)
            local touched=mirror.follow(edited,bones,selected,scope)
            local enabled=scope=="entire" or scope==limb
            check((touched[other]==true)==enabled,"Only the chosen symmetry scope follows the selected bone")
            local expected=mirror.apply(before,side=="l" and "leftToRight" or "rightToLeft",limb)
            for i,bone in ipairs(before) do
                check(sameTransform(edited[i],enabled and i==other and expected[i] or bone),
                    "Live symmetry preserves source, unedited opposite joints, other limbs, torso and attachment offsets")
            end
            check(not enabled or edited[other].rotation~=edited[selected].rotation,
                "Source and counterpart own separate transform arrays")
            nif.validate(edited)
        end
    end
end
-- Follow every local joint changed by an IK solve, while leaving fingers alone.
local frame={translation={250,-70,190},rotation=v.axisAngle({1,-2,3},0.9),scale=1.8}
for _,side in ipairs({"l","r"}) do
    for _,part in ipairs({"hand","foot"}) do
        local selected=byName["bip01 "..side.." "..part]
        local edited=rig.clone(bones)
        local chain=rig.chains(edited)[selected]
        local world=rig.world(edited,frame)
        rig.solve(edited,chain,v.add(world[selected].translation,{5,-9,7}),rig.pole(edited,chain,frame),frame)
        local before=rig.clone(edited)
        local expected=mirror.apply(before,side=="l" and "leftToRight" or "rightToLeft","entire")
        local touched=mirror.follow(edited,bones,selected,"entire")
        for _,source in ipairs({chain.upper,chain.lower,chain.tip}) do
            local sourcePart=bones[source].name:lower():match("^bip01 [lr] (.+)$")
            local destination=byName["bip01 "..(side=="l" and "r" or "l").." "..sourcePart]
            check(touched[destination] and sameTransform(edited[destination],expected[destination]),
                "IK follows the solved upper joint, lower joint and effector in a rotated, scaled viewing frame")
        end
        for i,bone in ipairs(before) do
            if not touched[i] then check(sameTransform(edited[i],bone),"IK symmetry affects only its opposite chain") end
        end
    end
end
for _,name in ipairs({"bip01","bip01 pelvis","bip01 spine","bip01 head","weapon bone","shield bone"}) do
    local selected=byName[name]
    local edited=rig.clone(bones)
    edited[selected].rotation=v.mul(edited[selected].rotation,v.axisAngle({1,0,0},0.4))
    check(next(mirror.follow(edited,bones,selected,"entire"))==nil,
        "Central bones and unpaired equipment controls stay directly editable")
end
local incomplete={rig.clone({bones[1]})[1],rig.clone({bones[byName["bip01 l hand"]]})[1]}
incomplete[2].parent=1
check(next(mirror.follow(incomplete,rig.clone(incomplete),2,"entire"))==nil,"Missing counterpart is skipped safely")
local edited=rig.clone(bones)
local left,right=byName["bip01 l hand"],byName["bip01 r hand"]
edited[right].name="bIP01 R hAND"
check(mirror.follow(edited,bones,left,"arms")[right],"Live pair matching ignores case")
check(not pcall(mirror.follow,bones,bones,left,"invalid"),"Invalid symmetry mode fails before mutation")
print("PASS: "..count.." live symmetry, scope isolation, real-skeleton IK and transform assertions")
