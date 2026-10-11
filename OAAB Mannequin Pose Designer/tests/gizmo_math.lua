package.path="./MWSE/mods/?.lua;"..package.path
local v=require("MannequinPoseDesigner.math3d")
local g=require("MannequinPoseDesigner.gizmo_math")
local count=0
local function check(ok,reason) assert(ok,reason); count=count+1 end
local function same(a,b) return a and v.length(v.sub(a,b))<1e-7 end
local center={17,-9,31}
for _,rotation in ipairs({v.identity(),v.axisAngle({1,2,3},1.2)}) do
    for name,axis in pairs(g.axes) do
        axis=v.transform(rotation,axis)
        local direction=v.unit(v.transform(rotation,{1,2,3}))
        local origin=v.sub(center,v.scale(direction,100))
        local drag=g.begin("move",name,center,rotation,origin,direction)
        check(drag~=nil,"Start axis movement in a rotated world frame")
        local displaced=v.add(origin,v.scale(axis,4))
        check(same(g.step(drag,displaced,direction,1),v.scale(axis,4)),"Arrow moves along the displayed local axis")
        check(same(g.step(drag,v.add(displaced,v.scale(axis,10)),direction,.15),v.scale(axis,1.5)),"Fine mode scales incremental movement")
        check(not g.begin("move",name,center,rotation,origin,axis),"A camera-aligned arrow has no stable plane")
    end
    for name,localAxis in pairs(g.axes) do
        local axis=v.transform(rotation,localAxis)
        local arm=v.transform(rotation,g.axes[({x="y",y="z",z="x"})[name]])
        local origin=v.add(v.sub(center,v.scale(axis,100)),arm)
        local drag=g.begin("rotate",name,center,rotation,origin,axis)
        local angle=0
        for i=1,96 do
            arm=v.transform(v.axisAngle(axis,math.pi/12),arm)
            local step=g.step(drag,v.add(v.sub(center,v.scale(axis,100)),arm),axis,1)
            check(math.abs(step-math.pi/12)<1e-7,"Ray rotation follows the ring with signed increments")
            angle=angle+step
        end
        check(math.abs(angle-8*math.pi)<1e-7,"Rings accumulate complete turns without wrapping the pose")
        arm=v.transform(v.axisAngle(axis,-math.pi/3),arm)
        check(math.abs(g.step(drag,v.add(v.sub(center,v.scale(axis,100)),arm),axis,.15)+math.pi/20)<1e-7,
            "Clockwise/reverse motion and fine mode retain the physical axis sign")
    end
end
check(not g.plane({0,0,1},{0,0,1},{0,0,0},{0,0,1}),"Reject an intersection behind the camera")
check(not g.begin("rotate","z",{0,0,0},v.identity(),{0,0,10},{0,0,-1}),"Rotation at the axis center is undefined")
local drag=g.begin("rotate","z",{0,0,0},v.identity(),{1,0,10},{0,0,-1})
check(not g.step(drag,{-1,0,10},{0,0,-1},1),"An event jumping across the center rebases without a half-turn")
check(math.abs(g.step(drag,{0,-1,10},{0,0,-1},1)-math.pi/2)<1e-7,"Rotation resumes after crossing the pivot")
check(not g.step(drag,{0,0,10},{0,0,-1},1),"Entering the joint dead zone suspends angular edits")
check(not g.step(drag,{1,0,10},{0,0,-1},1),"Leaving the dead zone establishes a new arm")
check(not g.plane({0,0,10},v.unit({1,0,-.001}),{0,0,0},{0,0,1}),"Nearly grazing rays cannot cause pose jumps")
print("PASS: "..count.." gizmo axis/plane/ring, rotated-frame, fine and degenerate-ray assertions")
