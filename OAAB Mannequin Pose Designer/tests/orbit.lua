package.path="./MWSE/mods/?.lua;"..package.path
local v=require("MannequinPoseDesigner.math3d")
local orbit=require("MannequinPoseDesigner.orbit")
local count=0
local function check(ok,reason) assert(ok,reason); count=count+1 end
local function near(a,b) return math.abs(a-b)<1e-9 end
local function same(a,b) return v.length(v.sub(a,b))<1e-8 end
local function assertView(s,expected,up)
    local position,direction,vertical=orbit.view(s)
    check(same(v.sub(position,s.target),v.scale(expected,s.distance)),"Camera lies on the expected radial direction")
    check(same(direction,v.scale(expected,-1)),"Camera looks at the mannequin pivot")
    check(near(v.length(vertical),1) and near(v.dot(direction,vertical),0),"Camera retains a nonsingular unit up vector")
    if up then check(same(vertical,up),"Canonical screen orientation is deterministic") end
end
for _,heading in ipairs({0,0.3,math.pi/2,-2.6}) do
    local s=orbit.new({20,-40,80},250,1.2,heading,60)
    local front={math.cos(heading),math.sin(heading),0}
    local right={math.sin(heading),-math.cos(heading),0}
    for _,view in ipairs({"front","right","top"}) do
        for _,reverse in ipairs({false,true}) do
            local expected=view=="front" and front or view=="right" and right or {0,0,1}
            if reverse then expected=v.scale(expected,-1) end
            for attempt=1,3 do
                orbit.rotate(s,1.234,2.345)
                orbit.snap(s,view,reverse)
                assertView(s,expected)
                check(s.distance==250,"Every canonical snap preserves distance")
            end
        end
    end
end
for _,pitch in ipairs({0,0.4,math.pi/2,2.0,-math.pi/2,-2.0}) do
    for _,action in ipairs({"left","orbitRight"}) do
        local s=orbit.new({0,0,0},250,math.pi-0.01,0,50)
        s.pitch=pitch
        local initial,forward,up=orbit.view(s)
        for i=1,24 do
            local before,beforeForward,beforeUp=orbit.view(s)
            orbit.apply(s,action)
            local sign=action=="left" and -1 or 1
            local rotation=v.axisAngle({0,0,1},sign*math.pi/12)
            local after,afterForward,afterUp=orbit.view(s)
            check(same(after,v.transform(rotation,before)) and same(afterForward,v.transform(rotation,beforeForward))
                and same(afterUp,v.transform(rotation,beforeUp)),"Each horizontal step follows the same world-Z direction across every angle boundary")
            check(s.distance==250,"Orbit never changes camera distance")
        end
        local after,afterForward,afterUp=orbit.view(s)
        check(same(after,initial) and same(afterForward,forward) and same(afterUp,up),"Twenty-four 15-degree horizontal steps complete exactly one full orbit")
    end
end
for _,action in ipairs({"up","down"}) do
    local s=orbit.new({0,0,0},250,0.7,0,50)
    s.pitch=0
    local initial,forward,up=orbit.view(s)
    local axis={math.sin(s.yaw),-math.cos(s.yaw),0}
    local sign=action=="up" and 1 or -1
    local rotation=v.axisAngle(axis,sign*math.pi/12)
    for i=1,240 do
        local before,beforeForward,beforeUp=orbit.view(s)
        orbit.apply(s,action)
        local after,afterForward,afterUp=orbit.view(s)
        check(same(after,v.transform(rotation,before)) and same(afterForward,v.transform(rotation,beforeForward))
            and same(afterUp,v.transform(rotation,beforeUp)),"Vertical orbit and screen-up pass continuously through both poles over ten revolutions")
        assertView(s,v.unit(after))
    end
    local after,afterForward,afterUp=orbit.view(s)
    check(same(after,initial) and same(afterForward,forward) and same(afterUp,up),"Complete vertical revolutions restore the exact starting view")
end
for _,pitch in ipairs({0,0.43,math.pi/2,2.1,-2.4,-math.pi/2}) do
    local s=orbit.new({20,30,40},250,-2.77,0.5,50)
    s.pitch=pitch
    local before,forward,up=orbit.view(s)
    orbit.opposite(s)
    local after,afterForward,afterUp=orbit.view(s)
    check(same(v.sub(after,s.target),v.scale(v.sub(before,s.target),-1)) and same(afterForward,v.scale(forward,-1)),
        "Opposite view negates every arbitrary radial viewpoint, including inverted and pole views")
    check(same(afterUp,up) and s.distance==250,"Opposite view retains screen-up and camera distance")
    orbit.opposite(s)
    check(same(orbit.view(s),before),"Opposite twice restores the original position")
    for _,action in ipairs({"zoomIn","zoomOut"}) do
        local yaw,angle=s.yaw,s.pitch
        orbit.apply(s,action)
        local position,direction,vertical=orbit.view(s)
        check(s.yaw==yaw and s.pitch==angle and same(direction,forward) and same(vertical,up),"Zoom preserves the complete camera orientation")
    end
    check(near(s.distance,250),"Reciprocal multiplicative zoom steps cancel")
    for i=1,500 do orbit.zoom(s,true) end
    check(s.distance==s.minDistance and s.distance>50,"Zoom stops outside the mannequin's bounding sphere")
    for i=1,500 do orbit.zoom(s,false) end
    check(s.distance==s.maxDistance,"Zoom out has a finite maximum distance")
end
for _,pitch in ipairs({0.43,math.pi/2,2.1,-math.pi/2,-2.4}) do
    local s=orbit.new({10,20,30},250,1.2,0.3,50)
    s.pitch=pitch
    s.panOffset={30,-20,40}
    local focus=v.add(s.target,s.panOffset)
    local before,forward,up=orbit.view(s)
    orbit.rotate(s,0,0)
    local position,direction,vertical=orbit.view(s)
    check(same(position,before) and same(direction,forward) and same(vertical,up),
        "Starting right-drag rotation after pan never changes the camera frame")
    for _,step in ipairs({{math.pi/12,0},{0,math.pi/12}}) do
        before,forward,up=orbit.view(s)
        local axis=step[1]~=0 and {0,0,1} or {math.sin(s.yaw),-math.cos(s.yaw),0}
        local rotation=v.axisAngle(axis,math.pi/12)
        orbit.rotate(s,step[1],step[2])
        position,direction,vertical=orbit.view(s)
        check(same(v.sub(position,focus),v.transform(rotation,v.sub(before,focus)))
            and same(direction,v.transform(rotation,forward)) and same(vertical,v.transform(rotation,up)),
            "Right drag rotates the full camera frame around its panned focus, including through the poles")
        check(s.distance==250 and same(s.panOffset,{30,-20,40}) and same(v.add(position,v.scale(direction,s.distance)),focus),
            "Right drag retains the panned focus and camera distance")
    end
end
for _,action in ipairs({"left","orbitRight","up","down"}) do
    local s=orbit.new({10,20,30},250,1.2,0.3,50)
    s.panOffset={30,-20,40}
    local distance=v.length(v.sub(orbit.view(s),s.target))
    orbit.apply(s,action)
    check(near(s.distance,distance) and same(s.panOffset,{0,0,0}),
        "Directional numpad orbit still returns to the mannequin and preserves actual pivot distance")
end
local s=orbit.new({10,20,30},250,1.2,0.3,50)
s.panOffset={30,-20,40}
local position=orbit.view(s)
local distance=v.length(v.sub(position,s.target))
orbit.snap(s,"front")
check(near(s.distance,distance) and same(s.panOffset,{0,0,0}),"Snapping after pan returns to the mannequin and preserves actual pivot distance")
s.panOffset={20,30,40}
position=orbit.view(s)
orbit.opposite(s)
check(same(v.sub(orbit.view(s),s.target),v.scale(v.sub(position,s.target),-1)),"Opposite view works from a panned arbitrary camera position")
s.panOffset={30,20,10}
local _,forward,up=orbit.view(s)
orbit.apply(s,"zoomIn")
local _,afterForward,afterUp=orbit.view(s)
check(same(forward,afterForward) and same(up,afterUp) and same(s.panOffset,{0,0,0}),"Numpad zoom centers a panned view without changing orientation")
print("PASS: "..count.." canonical views, orbit continuity, opposite view, zoom and pivot assertions")
