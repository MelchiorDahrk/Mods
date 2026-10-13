local v=require("MannequinPoseDesigner.math3d")
local rig=require("MannequinPoseDesigner.rig")
local M={}

-- The Relaxed ankle positions include the sole-to-joint offsets. Using them
-- instead of z=0 plants the soles on the mannequin's original ground plane.
function M.reference(relaxed,frame)
    local world=rig.world(relaxed,frame)
    local feet={plane=frame and frame.translation[3] or 0}
    for i,bone in ipairs(relaxed) do
        local side=bone.name:lower():match("^bip01 ([lr]) foot$")
        if side then feet[side]=world[i] end
    end
    assert(feet.l and feet.r,"The Relaxed pose is missing a foot")
    return feet
end

local function flat(rotation,relaxed)
    -- Foot-local axes are not world axes (TES3 feet have X pointing down).
    -- Remove the Relaxed basis before separating world-Z heading from tilt.
    local delta=v.mul(rotation,v.transpose(relaxed))
    local yaw
    if delta[1]^2+delta[4]^2>1e-10 then
        yaw=math.atan2(delta[4],delta[1])
    else
        yaw=math.atan2(-delta[2],delta[5])
    end
    return v.orthonormalize(v.mul(v.axisAngle({0,0,1},yaw),relaxed))
end

function M.apply(bones,reference,scope,frame)
    assert(scope=="left" or scope=="right" or scope=="both","Unknown grounding target")
    local result=rig.clone(bones)
    local chains=rig.chains(result)
    local world=rig.world(result,frame)
    local feet={}
    local lowest=math.huge
    local root
    for i,bone in ipairs(result) do
        if bone.name:lower()=="bip01" and bone.parent==0 then root=i end
        local side=bone.name:lower():match("^bip01 ([lr]) foot$")
        if side and (scope=="both" or scope=="left" and side=="l" or scope=="right" and side=="r") then
            local relaxed=assert(reference[side],"The Relaxed pose is missing this foot")
            local chain=assert(chains[i],"This foot is missing its thigh/calf IK rig")
            local height=reference.plane+(relaxed.translation[3]-reference.plane)*world[i].scale/relaxed.scale
            lowest=math.min(lowest,world[i].translation[3]-height)
            feet[#feet+1]={tip=i,chain=chain,height=height,rotation=flat(world[i].rotation,relaxed.rotation)}
        end
    end
    assert(root and #feet==(scope=="both" and 2 or 1),"The mannequin is missing a grounding bone")
    frame=frame or {rotation=v.identity(),translation={0,0,0},scale=1}
    assert(frame.scale>1e-6,"The mannequin has an invalid scale")
    local movement=v.scale(v.transform(v.transpose(frame.rotation),{0,0,-lowest}),1/frame.scale)
    result[root].translation=v.add(result[root].translation,movement)
    local touched={[root]=true}
    local tolerance=1e-4*frame.scale
    for _,foot in ipairs(feet) do
        world=rig.world(result,frame)
        local target=v.copy(world[foot.tip].translation)
        target[3]=foot.height
        if math.abs(world[foot.tip].translation[3]-target[3])>tolerance then
            -- Only the higher foot needs IK; its horizontal placement and the
            -- lower leg's pose stay intact. The solver preserves segment lengths.
            rig.solve(result,foot.chain,target,rig.pole(result,foot.chain,frame),frame)
            touched[foot.chain.upper]=true; touched[foot.chain.lower]=true
            world=rig.world(result,frame)
            assert(v.length(v.sub(world[foot.tip].translation,target))<=tolerance,
                "Both feet cannot reach the ground at these positions. Move the raised foot closer and try again.")
        end
        result[foot.tip].rotation=v.orthonormalize(v.mul(v.transpose(world[result[foot.tip].parent].rotation),foot.rotation))
        touched[foot.tip]=true
    end
    return result,touched
end
return M
