-- Ray/constraint math in world space, independent of the engine scene graph.
local v=require("MannequinPoseDesigner.math3d")
local M={axes={x={1,0,0},y={0,1,0},z={0,0,1}}}
function M.plane(origin,direction,center,normal)
    local denominator=v.dot(direction,normal)
    if math.abs(denominator)<0.02 then return end
    local t=v.dot(v.sub(center,origin),normal)/denominator
    if t<0 then return end
    return v.add(origin,v.scale(direction,t))
end
function M.begin(kind,component,center,rotation,origin,direction)
    local localAxis=M.axes[component]
    if not localAxis then return end
    local axis=v.unit(v.transform(rotation,localAxis))
    local normal=axis
    if kind=="move" then
        -- A camera-facing plane containing the axis, then project onto it.
        normal=v.sub(direction,v.scale(axis,v.dot(direction,axis)))
        if v.length(normal)<0.02 then return end -- Axis points straight at camera.
        normal=v.unit(normal)
    end
    local point=M.plane(origin,direction,center,normal)
    if not point then return end
    local arm=v.sub(point,center)
    if kind=="rotate" and v.length(arm)<1e-5 then return end
    return {kind=kind,component=component,center=v.copy(center),rotation=v.copy(rotation),
        axis=axis,normal=normal,lastPoint=point,lastArm=v.unit(arm),deadZone=v.length(arm)*0.06}
end
function M.step(constraint,origin,direction,fine)
    local point=M.plane(origin,direction,constraint.center,constraint.normal)
    if not point then constraint.lastArm=nil; constraint.lastPoint=nil; return end
    if constraint.kind=="rotate" then
        local arm=v.sub(point,constraint.center)
        if v.length(arm)<constraint.deadZone then constraint.lastArm=nil; constraint.lastPoint=nil; return end
        local lastArm,lastPoint=constraint.lastArm,constraint.lastPoint
        constraint.lastArm=v.unit(arm); constraint.lastPoint=point
        if not lastArm then return end
        -- Rebase if a large mouse event crosses the joint center between samples.
        local segment=v.sub(point,lastPoint)
        local length=v.dot(segment,segment)
        if length>0 then
            local old=v.sub(lastPoint,constraint.center)
            local t=v.clamp(-v.dot(old,segment)/length,0,1)
            if v.length(v.add(old,v.scale(segment,t)))<constraint.deadZone then return end
        end
        local delta=math.atan2(v.dot(constraint.axis,v.cross(lastArm,constraint.lastArm)),
            v.clamp(v.dot(lastArm,constraint.lastArm),-1,1))
        return delta*fine
    end
    if not constraint.lastPoint then constraint.lastPoint=point; return end
    local delta=v.sub(point,constraint.lastPoint)
    constraint.lastPoint=point
    return v.scale(constraint.axis,v.dot(delta,constraint.axis)*fine)
end
return M
