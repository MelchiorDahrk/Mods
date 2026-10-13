local v=require("MannequinPoseDesigner.math3d")
local rig=require("MannequinPoseDesigner.rig")
local M={}

-- NIF child order can differ from the live actor. Match names and parent names,
-- then retain the live order so its node bindings and IK chains stay valid.
function M.align(source,reference)
    assert(#source==#reference,"Pose skeleton does not match this mannequin")
    local byName={}
    for _,bone in ipairs(source) do
        local name=bone.name:lower()
        assert(not byName[name],"Duplicate pose bone: "..bone.name)
        byName[name]=bone
    end
    local out=rig.clone(reference)
    for i,bone in ipairs(reference) do
        local saved=assert(byName[bone.name:lower()],"Pose is missing bone: "..bone.name)
        local parent=saved.parent==0 and "" or source[saved.parent].name:lower()
        local expected=bone.parent==0 and "" or reference[bone.parent].name:lower()
        assert(parent==expected,"Pose parent does not match: "..bone.name)
        out[i].translation=v.copy(saved.translation)
        out[i].rotation=v.copy(saved.rotation)
        out[i].scale=saved.scale
    end
    return out
end

function M.apply(a,b,t)
    assert(type(t)=="number" and t==t and math.abs(t)<math.huge,"Invalid blend amount")
    t=v.clamp(t,0,1)
    local out=rig.clone(a)
    for i,bone in ipairs(out) do
        local target=assert(b[i],"Pose skeletons do not match")
        assert(bone.name:lower()==target.name:lower() and bone.parent==target.parent,
            "Pose bones must be aligned before blending")
        if t==1 then
            bone.translation=v.copy(target.translation)
            bone.rotation=v.copy(target.rotation)
            bone.scale=target.scale
        elseif t~=0 then
            for axis=1,3 do
                bone.translation[axis]=a[i].translation[axis]*(1-t)+target.translation[axis]*t
            end
            bone.scale=a[i].scale*(1-t)+target.scale*t
            bone.rotation=v.quaternionMatrix(v.slerp(v.quaternion(a[i].rotation),v.quaternion(target.rotation),t))
        end
    end
    assert(#a==#b,"Pose skeletons do not match")
    return out
end
return M
