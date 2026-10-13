local rig=require("MannequinPoseDesigner.rig")
local M={}

-- TES3's skeleton parent uses X for left/right, Bip01 uses local Y, and
-- the remaining skeletal bones use local Z. Two reflections preserve proper
-- rotations: destination R = reflection(parent) * source R * reflection(bone).
-- These are anatomical axes, independent of the current pose or viewing yaw.
local function axis(bone)
    if not bone then return 1 end
    return bone.name:lower()=="bip01" and 2 or 3
end
local function reflectedRotation(rotation,parentAxis,boneAxis)
    local result={}
    for row=1,3 do for column=1,3 do
        local index=(row-1)*3+column
        result[index]=rotation[index]*(row==parentAxis and -1 or 1)*(column==boneAxis and -1 or 1)
    end end
    return result
end
local function group(bones,index)
    while index~=0 do
        local bone=bones[index]
        local part=bone.name:lower():match("^bip01 [lr] (.+)$")
        if part=="clavicle" or part=="upperarm" or part=="forearm" or part=="hand" then return "arms" end
        if part=="thigh" or part=="calf" or part=="foot" then return "legs" end
        index=bone.parent
    end
end
local function reflect(bones,source,target)
    local parentAxis=axis(bones[source.parent])
    target.translation={}
    for component=1,3 do
        target.translation[component]=source.translation[component]*(component==parentAxis and -1 or 1)
    end
    target.rotation=reflectedRotation(source.rotation,parentAxis,axis(source))
    target.scale=source.scale
end
local function changed(a,b)
    if a.scale~=b.scale then return true end
    for _,field in ipairs({"translation","rotation"}) do
        for i,value in ipairs(a[field]) do
            if math.abs(value-b[field][i])>1e-10 then return true end
        end
    end
    return false
end

-- Live symmetry follows only the edited side's changed local transforms,
-- including joints adjusted by IK/locks. Unedited limbs keep their own pose.
-- Central bones remain directly editable; Full covers both arm and leg pairs.
function M.follow(bones,previous,selected,scope,edited)
    local touched={}
    if scope=="off" then return touched end
    assert(scope=="entire" or scope=="arms" or scope=="legs","Unknown symmetry mode")
    local side=bones[selected].name:lower():match("^bip01 ([lr]) ")
    local limb=group(bones,selected)
    if not side or not limb or (scope~="entire" and scope~=limb) then return touched end
    local byName={}
    for i,bone in ipairs(bones) do byName[bone.name:lower()]=i end
    for source,bone in ipairs(bones) do
        local sourceSide,part=bone.name:lower():match("^bip01 ([lr]) (.+)$")
        if sourceSide==side and group(bones,source)==limb and (source==selected or (edited and edited[source]) or changed(bone,previous[source])) then
            local destination=byName["bip01 "..(side=="l" and "r" or "l").." "..part]
            if destination then
                reflect(bones,bone,bones[destination])
                touched[destination]=true
            end
        end
    end
    return touched
end

-- Read every source from the original pose, so a swap cannot overwrite its
-- other half. Return changed indices for rebasing affected IK lock anchors.
function M.apply(bones,action,scope)
    assert(action=="swap" or action=="leftToRight" or action=="rightToLeft","Unknown mirror command")
    assert(scope=="entire" or scope=="arms" or scope=="legs","Unknown mirror target")
    local result=rig.clone(bones)
    local byName,touched={},{}
    for i,bone in ipairs(bones) do byName[bone.name:lower()]=i end
    for destination,bone in ipairs(bones) do
        local name=bone.name:lower()
        local side,part=name:match("^bip01 ([lr]) (.+)$")
        local source
        if side and (scope=="entire" or group(bones,destination)==scope) then
            if action=="swap" or (action=="leftToRight" and side=="r") or (action=="rightToLeft" and side=="l") then
                source=byName["bip01 "..(side=="l" and "r" or "l").." "..part]
            end
        elseif not side and scope=="entire" and action=="swap" and (name=="bip01" or name:match("^bip01 ")) then
            source=destination
        end
        if source then
            reflect(bones,bones[source],result[destination])
            touched[destination]=true
        end
    end
    -- Weapon Bone and Shield Bone keep their own local attachment transforms;
    -- their parent hands carry them through the mirrored pose.
    return result,touched
end

return M
