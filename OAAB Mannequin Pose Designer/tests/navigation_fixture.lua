-- Run the actual registered input and camera callbacks in the session fixture.
return function(t)
    local v=require("MannequinPoseDesigner.math3d")
    local rig=t.rig
    local check=t.check
    local callbacks=t.callbacks
    local controller=tes3.worldController
    local oldInput,oldMenuInput=controller.inputController,controller.menuController.inputController
    local held,modifiers={},{}
    controller.inputController={
        isKeyDown=function(_,code) return held[code]==true end,
        isControlDown=function() return modifiers.ctrl==true end,
        isAltDown=function() return modifiers.alt==true end,
        isShiftDown=function() return modifiers.shift==true end,
        isSuperDown=function() return modifiers.super==true end,
    }
    local menuInput={}
    controller.menuController.inputController=menuInput
    local function same(a,b) return v.length(v.sub(a,b))<1e-8 end
    local function press(key,ctrl,element)
        local code=tes3.scanCode[key]
        held[code]=true
        local result=callbacks.keyDown({keyCode=code,isControlDown=ctrl,element=element})
        held[code]=nil
        callbacks.keyUp({keyCode=code,element=element})
        check(t.session.isActive(),"Camera shortcut keeps the editor active")
        return result
    end
    local function frame(delta)
        callbacks.enterFrame({delta=delta or 0,menuMode=tes3ui.menuMode()})
    end
    for _,focused in ipairs({false,true}) do
        check(t.session.start(t.ref,t.api),"Start numpad camera integration")
        local state=t.state()
        if focused then callbacks.keyDown({keyCode=tes3.scanCode.f}); callbacks.keyUp({keyCode=tes3.scanCode.f}) end
        for tip in pairs(state.chains) do state.locks[tip]=rig.anchor(state.bones,tip) end
        local originalLocks=rig.cloneLocks(state.locks)
        local function draw()
            if focused then callbacks.render({}); return t.cameraRoot end
            local event=t.cameraEvent(99)
            callbacks.cameraControl(event)
            return event.cameraTransform
        end
        local initialPose=rig.clone(state.bones)
        local originalOrientation=rig.vector(t.ref.orientation)
        local originalPosition=rig.vector(t.ref.position)
        local world=rig.world(state.bones,t.frame())
        local written=t.writes()
        local history=#state.undo
        local function direction() return rig.vector(draw().rotation.forward) end
        local function position() return rig.vector(draw().translation) end
        local function offset() return v.sub(position(),state.orbit.target) end
        local heading=state.orbit.frontYaw
        local front={math.cos(heading),math.sin(heading),0}
        local right={math.sin(heading),-math.cos(heading),0}
        for _,entry in ipairs({{"numpad1",front},{"numpad3",right},{"numpad7",{0,0,1}}}) do
            for _,reverse in ipairs({false,true}) do
                for attempt=1,3 do
                    state.orbit.yaw=attempt*0.47
                    state.orbit.pitch=attempt*1.23
                    local distance=state.orbit.distance
                    check(press(entry[1],reverse)==false,"Physical numpad view key is claimed")
                    local radial=reverse and v.scale(entry[2],-1) or entry[2]
                    check(same(offset(),v.scale(radial,distance)) and same(direction(),v.scale(radial,-1)),
                        "Every numpad/Ctrl snap produces the exact canonical camera view")
                    check(state.orbit.distance==distance,"Snap preserves camera distance")
                end
            end
        end
        for _,key in ipairs({"numpad4","numpad6","numpad8","numpad2"}) do
            press("numpad1")
            local before=position()
            local beforeUp=rig.vector(draw().rotation.up)
            local distance=state.orbit.distance
            for step=1,24 do
                local previousDirection=direction()
                press(key)
                local forward=direction()
                check(math.abs(v.dot(previousDirection,forward)-math.cos(math.pi/12))<1e-9,
                    "Each physical directional numpad press changes the viewing angle by 15 degrees")
                check(state.orbit.distance==distance and math.abs(v.length(offset())-distance)<1e-8,
                    "Rendered orbit maintains distance from the mannequin")
            end
            check(same(position(),before) and same(rig.vector(draw().rotation.up),beforeUp),
                "Twenty-four physical numpad presses restore the original camera, including through the vertical poles")
        end
        state.orbit.yaw=-2.93; state.orbit.pitch=0.43
        local arbitrary=offset()
        press("numpad9")
        check(same(offset(),v.scale(arbitrary,-1)),"Numpad 9 negates an arbitrary viewpoint")
        press("numpad9")
        check(same(offset(),arbitrary),"Two opposite-view presses restore the arbitrary viewpoint")
        local forward,up=direction(),rig.vector(draw().rotation.up)
        local distance=state.orbit.distance
        press("add")
        check(state.orbit.distance<distance and same(direction(),forward) and same(rig.vector(draw().rotation.up),up),
            "Numpad + zooms in without changing camera orientation")
        press("subtract")
        check(math.abs(state.orbit.distance-distance)<1e-8 and same(direction(),forward),"Numpad - reverses the multiplicative zoom step")
        -- Engine repeats cannot double the real-time repeat schedule.
        press("numpad1")
        held[tes3.scanCode.numpad4]=true
        callbacks.keyDown({keyCode=tes3.scanCode.numpad4})
        local first=position()
        callbacks.keyDown({keyCode=tes3.scanCode.numpad4})
        check(same(position(),first),"Duplicate key-down events do not accelerate held-key repeat")
        frame(0.1); frame(0.1)
        check(same(position(),first),"Held orbit waits for its initial repeat delay")
        frame(0.1)
        check(not same(position(),first),"Held orbit repeats on real frames even while focus freezes simulation")
        local repeated=position()
        callbacks.keyUp({keyCode=tes3.scanCode.numpad4}); held[tes3.scanCode.numpad4]=nil
        frame(0.1)
        check(same(position(),repeated),"Releasing a held orbit stops repeat immediately")
        held[tes3.scanCode.numpad6]=true
        callbacks.keyDown({keyCode=tes3.scanCode.numpad6})
        held[tes3.scanCode.numpad6]=nil -- Lost key-up: raw keyboard state repairs it.
        local lostRelease=position()
        for i=1,4 do frame(0.1) end
        check(same(position(),lostRelease),"A missed key-up never latches orbit")
        held[tes3.scanCode.numpad9]=true
        callbacks.keyDown({keyCode=tes3.scanCode.numpad9})
        local opposite=position()
        for i=1,8 do frame(0.1); callbacks.keyDown({keyCode=tes3.scanCode.numpad9}) end
        check(same(position(),opposite),"Holding opposite-view performs only one inversion")
        held[tes3.scanCode.numpad9]=nil; callbacks.keyUp({keyCode=tes3.scanCode.numpad9})
        -- Native focus can still point at an input inside a hidden retained menu.
        local hiddenMenu={visible=false}
        local staleFocus={type="textInput",visible=true,parent={visible=true,parent=hiddenMenu}}
        menuInput.textInputFocus=staleFocus
        state.orbit.yaw=state.orbit.frontYaw+0.43
        check(press("numpad1",false,staleFocus)==false and same(direction(),v.scale(front,-1)),
            "A hidden ancestor makes stale native text focus inactive for numpad shortcuts")
        for _,inactive in ipairs({{type="textInput",visible=false},
            {type="slider",visible=true,disabled=true},
            {type="textInput",visible=true,parent={visible=true,disabled=true}}}) do
            menuInput.textInputFocus=inactive
            state.orbit.yaw=state.orbit.frontYaw+0.43
            check(press("numpad1",false,inactive)==false and same(direction(),v.scale(front,-1)),
                "Hidden or disabled focus owners do not capture numpad input")
        end
        menuInput.textInputFocus=staleFocus
        held[tes3.scanCode.numpad4]=true
        callbacks.keyDown({keyCode=tes3.scanCode.numpad4,element=staleFocus})
        local beforeRepeat=position()
        frame(0.1); frame(0.1); frame(0.1)
        check(not same(position(),beforeRepeat),"Held orbit continues while native focus points into a hidden menu")
        held[tes3.scanCode.numpad4]=nil
        callbacks.keyUp({keyCode=tes3.scanCode.numpad4,element=staleFocus})
        hiddenMenu.visible=true
        local beforeVisibleFocus=position()
        check(press("numpad6",false,staleFocus)==nil and same(position(),beforeVisibleFocus),
            "Showing a retained menu restores its keyboard ownership")
        hiddenMenu.visible=false
        menuInput.textInputFocus={type="textInput",visible=true,parent={visible=true}}
        check(press("numpad6",false,staleFocus)==nil and same(position(),beforeVisibleFocus),
            "A hidden event element cannot bypass a separate visible native focus owner")
        menuInput.textInputFocus=nil
        for _,key in ipairs({"numpad1","numpad3","numpad7","numpad9","numpad4","numpad6","numpad8","numpad2","add","subtract"}) do
            local before=position()
            check(press(key,false,{type="textInput"})==nil and same(position(),before),"Focused text and numeric fields own numpad input")
            check(press(key,false,{type="slider"})==nil and same(position(),before),"Other focused UI controls own numpad input")
            menuInput.textInputFocus={}
            check(press(key)==nil and same(position(),before),"Native text-input focus blocks shortcuts even without event.element")
            menuInput.textInputFocus=nil
        end
        held[tes3.scanCode.numpad8]=true
        callbacks.keyDown({keyCode=tes3.scanCode.numpad8})
        local beforeFocus=position()
        menuInput.textInputFocus={}; frame(0.1); menuInput.textInputFocus=nil
        for i=1,5 do frame(0.1) end
        check(same(position(),beforeFocus),"Acquiring text input cancels a held orbit until a fresh press")
        held[tes3.scanCode.numpad8]=nil; callbacks.keyUp({keyCode=tes3.scanCode.numpad8})
        for _,modifier in ipairs({"ctrl","shift","alt","super"}) do
            for _,key in ipairs({"numpad4","numpad8","numpad9","add","subtract"}) do
                local before=position()
                local code=tes3.scanCode[key]
                local event={keyCode=code,isControlDown=modifier=="ctrl",isShiftDown=modifier=="shift",
                    isAltDown=modifier=="alt",isSuperDown=modifier=="super"}
                check(callbacks.keyDown(event)==nil and same(position(),before),"Unassigned modified numpad chords do not activate navigation")
                callbacks.keyUp({keyCode=code})
            end
        end
        for _,key in ipairs({"one","three","seven","nine","addRow","subtractRow","keyLeft","keyRight","keyUp","keyDown"}) do
            local before=position()
            press(key)
            check(same(position(),before),"Number-row and navigation-cluster keys do not activate numpad shortcuts")
        end
        -- Right drag uses the same continuous camera state and leaves the actor fixed.
        for _,depth in ipairs({false,true}) do
            callbacks.mouseButtonDown({button=2})
            callbacks.mouseAxis({deltaX=35,deltaY=-20,isShiftDown=depth})
            callbacks.mouseButtonUp({button=2})
            local pan=v.copy(state.orbit.panOffset)
            local focus=v.add(state.orbit.target,pan)
            local before=position()
            local forward,up=direction(),rig.vector(draw().rotation.up)
            local distance=state.orbit.distance
            check(v.length(pan)>0,"Middle drag pans the camera before the rotation regression")
            for _,fine in ipairs({false,true}) do
                callbacks.mouseButtonDown({button=1})
                callbacks.mouseAxis({deltaX=0,deltaY=0,isControlDown=fine})
                check(same(position(),before) and same(direction(),forward) and same(rig.vector(draw().rotation.up),up),
                    "Starting a right drag after screen/depth pan keeps the rendered camera frame")
                callbacks.mouseAxis({deltaX=50,deltaY=45,isControlDown=fine})
                check(not same(position(),before) and same(state.orbit.panOffset,pan) and state.orbit.distance==distance
                    and same(v.add(position(),v.scale(direction(),distance)),focus),
                    "Normal/fine right drag rotates around the current panned focus at the same distance")
                callbacks.mouseAxis({deltaX=-50,deltaY=-45,isControlDown=fine})
                callbacks.mouseButtonUp({button=1})
                check(same(position(),before) and same(direction(),forward) and same(rig.vector(draw().rotation.up),up),
                    "Reversing right drag restores the panned camera frame")
            end
        end
        callbacks.mouseButtonDown({button=1})
        callbacks.mouseAxis({deltaX=50,deltaY=1000})
        callbacks.mouseButtonUp({button=1})
        check(same(rig.vector(t.ref.orientation),originalOrientation),"Right drag never rotates the mannequin reference")
        callbacks.mouseButtonDown({button=0})
        local dragHistory=#state.undo
        local beforeDrag=position()
        press("numpad4")
        check(same(position(),beforeDrag) and #state.undo==dragHistory,"Numpad orbit cannot disturb an active bone drag")
        callbacks.mouseButtonUp({button=0})
        check(dragHistory==history+1 and #state.undo==history,
            "A bone press reserves history while held and releases it without movement")
        for _,menu in ipairs(t.menus) do
            callbacks.keyDown({keyCode=tes3.scanCode[menu.key],isShiftDown=menu.shift})
            local prompt=state[menu.field]
            check(prompt~=nil,"Open modal for camera input test: "..menu.field)
            local beforeYaw,beforePitch,beforeDistance=state.orbit.yaw,state.orbit.pitch,state.orbit.distance
            for _,key in ipairs({"numpad1","numpad3","numpad7","numpad9","numpad4","numpad6","numpad8","numpad2","add","subtract"}) do
                check(press(key)==nil,"Modal owns every numpad shortcut")
                frame(0.1)
            end
            check(state.orbit.yaw==beforeYaw and state.orbit.pitch==beforePitch and state.orbit.distance==beforeDistance,
                "Modal input never changes orbit state")
            menu.close(prompt)
        end
        check(same(rig.vector(t.ref.orientation),originalOrientation) and same(rig.vector(t.ref.position),originalPosition),
            "All camera controls leave mannequin reference transforms unchanged")
        for tip,anchor in pairs(originalLocks) do
            local after=state.locks[tip]
            check(after~=nil and same(after.target,anchor.target),"Camera navigation leaves IK lock positions fixed")
            for j=1,9 do check(after.rotation[j]==anchor.rotation[j],"Camera navigation leaves IK lock facing fixed") end
        end
        local afterWorld=rig.world(state.bones,t.frame())
        for i,bone in ipairs(state.bones) do
            check(same(bone.translation,initialPose[i].translation) and bone.scale==initialPose[i].scale,
                "Camera navigation leaves every bone position and scale unchanged")
            for j=1,9 do check(bone.rotation[j]==initialPose[i].rotation[j],"Camera navigation leaves every bone rotation unchanged") end
            check(same(afterWorld[i].translation,world[i].translation),"World bone positions remain fixed during camera navigation")
        end
        check(#state.undo==history and #state.redo==0 and t.writes()==written,
            "Camera controls never create pose history or saved/draft pose writes")
        local saved=rig.clone(state.bones)
        t.session.finish(true,false,{id="Camera_test",name="Camera test"})
        check(t.savedPose(saved),"Saving after camera navigation exports the untouched pose")
        t.controlsRestored()
        local yaw=state.orbit.yaw
        check(callbacks.keyDown({keyCode=tes3.scanCode.numpad4})==nil,"Numpad shortcuts pass through after the designer exits")
        frame(0.1)
        check(state.orbit.yaw==yaw,"No held orbit survives cleanup")
    end
    controller.inputController=oldInput
    controller.menuController.inputController=oldMenuInput
end
