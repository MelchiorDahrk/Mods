-- Explicit spherical camera state, independent of engine Euler rotations and poses.
local v=require("MannequinPoseDesigner.math3d")
local M={step=math.pi/12,zoomFactor=0.9,repeatDelay=0.3,repeatInterval=0.1}
local tau=2*math.pi
local function wrap(angle) return (angle+math.pi)%tau-math.pi end
local function sincos(angle)
    local s,c=math.sin(angle),math.cos(angle)
    -- Canonical axes and complete revolutions should land exactly on their axis.
    if math.abs(s)<1e-12 then s=0 end
    if math.abs(c)<1e-12 then c=0 end
    return s,c
end
function M.new(target,distance,yaw,frontYaw,radius)
    local minimum=math.max(25,radius+8)
    distance=math.max(distance,minimum*1.5)
    return {target=v.copy(target),distance=distance,yaw=yaw,pitch=0.08,
        frontYaw=frontYaw,minDistance=minimum,maxDistance=math.max(700,distance*6,minimum*10),
        panOffset={0,0,0}}
end
function M.view(s)
    local sy,cy=sincos(s.yaw)
    local sp,cp=sincos(s.pitch)
    local offset={cy*cp,sy*cp,sp}
    -- Transport screen-up through both poles instead of reconstructing it from
    -- world Z. This remains a unit perpendicular vector even at +/-90 degrees.
    local up={-cy*sp,-sy*sp,cp}
    local center=v.add(s.target,s.panOffset)
    return v.add(center,v.scale(offset,s.distance)),v.scale(offset,-1),up
end
function M.recenter(s,preserveDirection)
    if v.length(s.panOffset)==0 then return end
    -- Resume mannequin-centered navigation after panning, retaining the actual
    -- camera position and its distance to the mannequin before changing view.
    local offset=v.sub(M.view(s),s.target)
    s.distance=v.length(offset)
    local horizontal=math.sqrt(offset[1]^2+offset[2]^2)
    local pitch=math.atan2(offset[3],horizontal)
    local yaw=horizontal>1e-10 and math.atan2(offset[2],offset[1]) or s.yaw
    if math.cos(s.pitch)<0 then yaw=yaw+math.pi; pitch=math.pi-pitch end
    if not preserveDirection then s.yaw,s.pitch=wrap(yaw),wrap(pitch) end
    s.panOffset={0,0,0}
end
function M.rotate(s,yaw,pitch)
    -- Mouse orbit retains the current focus (target + panOffset) and radius.
    s.yaw=wrap(s.yaw+yaw)
    s.pitch=wrap(s.pitch+pitch)
end
function M.snap(s,view,reverse)
    M.recenter(s)
    s.yaw=s.frontYaw
    s.pitch=0
    if view=="right" then s.yaw=s.frontYaw-math.pi/2
    elseif view=="top" then s.pitch=reverse and -math.pi/2 or math.pi/2 end
    if reverse and view~="top" then s.yaw=s.yaw+math.pi end
    s.yaw=wrap(s.yaw)
end
function M.opposite(s)
    M.recenter(s)
    s.yaw=wrap(s.yaw+math.pi)
    s.pitch=wrap(-s.pitch)
end
function M.zoom(s,inward)
    s.distance=v.clamp(s.distance*(inward and M.zoomFactor or 1/M.zoomFactor),s.minDistance,s.maxDistance)
end
function M.apply(s,action,reverse)
    -- Directional numpad navigation deliberately returns to the mannequin.
    if action=="left" or action=="orbitRight" or action=="up" or action=="down" then M.recenter(s) end
    if action=="front" or action=="right" or action=="top" then M.snap(s,action,reverse)
    elseif action=="opposite" then M.opposite(s)
    elseif action=="left" then M.rotate(s,-M.step,0)
    elseif action=="orbitRight" then M.rotate(s,M.step,0)
    elseif action=="up" then M.rotate(s,0,M.step)
    elseif action=="down" then M.rotate(s,0,-M.step)
    elseif action=="zoomIn" or action=="zoomOut" then
        M.recenter(s,true)
        M.zoom(s,action=="zoomIn")
    end
end
function M.repeats(action)
    return action=="left" or action=="orbitRight" or action=="up" or action=="down"
        or action=="zoomIn" or action=="zoomOut"
end
return M
