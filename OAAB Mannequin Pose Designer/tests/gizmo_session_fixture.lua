-- Exercise the real input handlers and constraint math in the session fixture.
local v=require("MannequinPoseDesigner.math3d")
local constraintMath=require("MannequinPoseDesigner.gizmo_math")
local gizmos=require("MannequinPoseDesigner.gizmos")
return function(t)
    local check,callbacks,session,rig=t.check,t.callbacks,t.session,t.rig
    local originalPick,originalBegin,originalRay=gizmos.pick,gizmos.begin,gizmos.ray
    local component="x"
    local center,direction,arm
    gizmos.pick=function() return component end
    gizmos.ray=function(cursor)
        return v.add(v.sub(center,v.scale(direction,100)),{cursor[1],0,cursor[2]}),direction
    end
    gizmos.begin=function(_,s,transform)
        center=v.copy(transform.translation)
        local origin,ray=gizmos.ray(s.cursor)
        return constraintMath.begin(s.mode=="Rotate" and "rotate" or "move",component,center,transform.rotation,origin,ray)
    end
    local function start()
        check(session.start(t.ref,t.api),"Start a gizmo input integration session")
        local s=t.state(); s.selected=1; s.mode="IK"; s.cursor={0,0}; s.symmetry="off"
        s.bones[1].rotation=v.identity()
        return s
    end
    local function release()
        callbacks.mouseButtonUp({button=0}); callbacks.enterFrame({})
    end
    local s=start()
    -- Test X in an arbitrary rig parent frame. Ray basis follows that world X.
    local transform=rig.world(s.bones,t.frame())[1]
    direction=v.unit(v.transform(transform.rotation,{0,1,1}))
    component="x"
    local undo=#s.undo; local before=v.copy(s.bones[1].translation)
    callbacks.mouseButtonDown({button=0})
    check(s.drag and s.drag.constraint and s.selected==1,"A gizmo click keeps the selected joint and captures its constraint")
    local constraint=s.drag.constraint
    local axis=v.copy(constraint.axis)
    -- Supply a translated ray origin to isolate movement from the fixture projection.
    local offset={0,0,0}
    gizmos.ray=function() return v.add(v.sub(center,v.scale(direction,100)),offset),direction end
    offset=v.scale(axis,10)
    callbacks.mouseAxis({deltaX=10,deltaY=0})
    local expected=v.add(before,v.scale(v.transform(v.transpose(t.frame().rotation),offset),1/t.frame().scale))
    check(v.length(v.sub(s.bones[1].translation,expected))<1e-7,"Root arrow converts constrained world movement into its parent frame")
    local focus=v.copy(s.orbit.target)
    callbacks.cameraControl(t.cameraEvent(77))
    check(v.length(v.sub(s.orbit.target,focus))<1e-7,"Constrained root movement holds the camera focus to avoid feedback")
    offset=v.scale(axis,20)
    callbacks.mouseAxis({deltaX=10,deltaY=0,isControlDown=true,isShiftDown=true})
    expected=v.add(expected,v.scale(v.transform(v.transpose(t.frame().rotation),v.scale(axis,1.5)),1/t.frame().scale))
    check(v.length(v.sub(s.bones[1].translation,expected))<1e-7,"Fine mode scales ray increments and Shift does not replace an explicit axis")
    local writes=t.writes()
    callbacks.keyDown({keyCode=tes3.scanCode.z,isControlDown=true}); callbacks.enterFrame({})
    check(not s.drag and v.length(v.sub(s.bones[1].translation,before))<1e-7,
        "Undo while dragging an arrow ends and restores constrained root movement")
    offset=v.scale(axis,30)
    callbacks.mouseAxis({deltaX=10,deltaY=0}); release()
    check(v.length(v.sub(s.bones[1].translation,before))<1e-7 and t.writes()==writes+1,
        "An undone arrow gesture cannot move or checkpoint again on release")
    callbacks.keyDown({keyCode=tes3.scanCode.y,isControlDown=true}); callbacks.enterFrame({})
    check(#s.undo==undo+1 and v.length(v.sub(s.bones[1].translation,expected))<1e-7,"Redo restores constrained root movement as one history step")
    session.finish(false)

    s=start(); s.mode="Rotate"; component="z"
    transform=rig.world(s.bones,t.frame())[1]
    local axisZ=v.transform(transform.rotation,{0,0,1})
    arm=v.transform(transform.rotation,{1,0,0}); direction=axisZ
    gizmos.ray=function() return v.add(v.sub(center,v.scale(direction,100)),arm),direction end
    s.axis="x" -- The clicked ring overrides a held shortcut for this drag only.
    callbacks.mouseButtonDown({button=0})
    check(s.drag and s.drag.constraint and s.drag.axisName=="z","Clicked rotation ring chooses its local axis")
    for i=1,48 do
        arm=v.transform(v.axisAngle(axisZ,math.pi/12),arm)
        callbacks.mouseAxis({deltaX=1,deltaY=0})
    end
    check(math.abs(s.drag.totalAngle-4*math.pi)<1e-7,"The session retains signed complete ring turns")
    arm=v.transform(v.axisAngle(axisZ,math.pi/2),arm)
    callbacks.mouseAxis({deltaX=1,deltaY=0})
    local expectedRotation=v.axisAngle({0,0,1},math.pi/2)
    for i,n in ipairs(s.bones[1].rotation) do check(math.abs(n-expectedRotation[i])<1e-7,"Ring rotation uses the local axis in a rotated parent") end
    callbacks.keyDown({keyCode=tes3.scanCode.z,isControlDown=true})
    check(not s.drag,"Undo ends an active ring rotation")
    for i,n in ipairs(s.bones[1].rotation) do check(math.abs(n-v.identity()[i])<1e-7,"Undo restores the ring's starting rotation") end
    callbacks.keyDown({keyCode=tes3.scanCode.y,isControlDown=true})
    for i,n in ipairs(s.bones[1].rotation) do check(math.abs(n-expectedRotation[i])<1e-7,"Redo restores the ring's partial rotation") end
    release(); check(s.axis=="x","Mouse release preserves the held-axis shortcut for later pearl drags")
    local history=#s.undo
    callbacks.mouseButtonDown({button=0}); release()
    check(#s.undo==history,"Clicking a gizmo without moving does not consume undo history")
    session.finish(false)
    gizmos.pick,gizmos.begin,gizmos.ray=originalPick,originalBegin,originalRay
end
