return function(t)
    local v=require("MannequinPoseDesigner.math3d")
    local ground=require("MannequinPoseDesigner.ground")
    local rig=t.rig
    local check=t.check
    local callbacks=t.callbacks
    local menu=t.menu
    local left,right
    for i,bone in ipairs(t.relaxed) do
        if bone.name=="Bip01 L Foot" then left=i end
        if bone.name=="Bip01 R Foot" then right=i end
    end
    t.setRelaxed(t.relaxed)
    local function restTest(transition)
        local e={keybind=tes3.keybind.rest,transition=transition or tes3.keyTransition.downThisFrame,result=true}
        callbacks.keybindTested(e)
        return not e.block and e.result
    end
    local function command(scope)
        local prompt=menu.current
        menu.close(prompt)
        prompt.onGround(scope)
        callbacks.enterFrame({})
    end
    for _,focused in ipairs({false,true}) do
        for _,scope in ipairs({"left","right","both"}) do
            local bones=rig.clone(t.relaxed)
            local chains=rig.chains(bones)
            local target=v.add(rig.world(bones)[right].translation,{0,0,8})
            rig.solve(bones,chains[right],target,rig.pole(bones,chains[right]))
            bones[1].translation[3]=bones[1].translation[3]+10
            bones[left].rotation=v.mul(bones[left].rotation,v.axisAngle({0,1,0},0.3))
            t.setBones(bones)
            check(t.session.start(t.ref,t.api),"Start Ground Feet integration")
            local state=t.state()
            state.symmetry="entire"; state.expandedControls=true
            for tip in pairs(state.chains) do state.locks[tip]=rig.anchor(state.bones,tip) end
            if focused then t.press("f") end
            local focusState=state.focus
            local before=rig.clone(state.bones)
            local locks=rig.cloneLocks(state.locks)
            local written,reads=t.writes(),t.reads()
            check(not restTest(),"Rest is blocked before the Ground Feet shortcut")
            t.press("t")
            local prompt=menu.current
            for _,transition in pairs(tes3.keyTransition) do
                check(not restTest(transition),"The opening T press cannot reach native Rest tests during delayed dialog activation")
            end
            for _,scripted in ipairs({false,true}) do
                local e={allowRest=true,scripted=scripted}
                check(callbacks.uiShowRestMenu(e)==false and e.block,
                    "Native or scripted Rest/Wait requests cannot take over the Ground Feet dialog")
            end
            check(state.groundPrompt==prompt and not state.overlay.menu.visible and not state.overlay.markersMenu.visible,
                "Ground Feet opens a modal and hides pose controls/handles before activation")
            callbacks.mouseButtonDown({button=0})
            check(not state.drag,"The pending Ground Feet menu blocks bone drags")
            for _,key in ipairs({"t","enter","escape","b","m","s","z","l","backspace"}) do
                check(callbacks.keyDown({keyCode=tes3.scanCode[key],isControlDown=true})==nil,
                    "The Ground Feet menu owns editor keyboard input")
            end
            check(state.groundPrompt==prompt and #state.undo==0 and t.writes()==written,
                "Opening or typing in the dialog preserves pose history and checkpoints")
            command(scope)
            local expected=ground.apply(before,ground.reference(t.relaxed,state.groundFrame),scope,t.frame())
            check(t.samePose(state.bones,expected) and #state.undo==1 and #state.redo==0 and t.writes()==written+1,
                "Each grounding choice applies once with one undo step and checkpoint")
            check(state.focus==focusState and state.expandedControls and state.symmetry=="entire"
                and not state.groundPrompt and state.overlay.menu.visible and t.player.controlsDisabled,
                "Grounding resumes controls and preserves focus, help expansion and symmetry setting")
            for tip in pairs(locks) do
                local anchor=rig.anchor(state.bones,tip)
                check(state.locks[tip] and t.same(state.locks[tip].target,anchor.target)
                    and t.same(state.locks[tip].rotation,anchor.rotation),
                    "All enabled locks follow explicit root/foot grounding without undoing it")
            end
            local grounded=rig.clone(state.bones)
            t.press("z",true)
            check(t.samePose(state.bones,before),"Undo restores all pre-grounding bones")
            for tip,lock in pairs(locks) do
                check(t.same(state.locks[tip].target,lock.target) and t.same(state.locks[tip].rotation,lock.rotation),
                    "Undo restores pre-grounding lock positions and facing")
            end
            written=t.writes()
            t.press("t"); menu.close(menu.current); callbacks.enterFrame({})
            check(t.samePose(state.bones,before) and #state.redo==1 and t.writes()==written,
                "Cancel changes neither the pose nor its existing redo history")
            t.press("y",true)
            check(t.samePose(state.bones,grounded),"Redo restores grounding in one step")
            t.press("t"); command(scope)
            check(t.reads()==reads+1,"The Relaxed ground reference is loaded once per session")
            if focused and scope=="both" then
                t.session.finish(true,false,{id="Grounded",name="Grounded"})
                check(not t.session.isActive() and t.samePose(t.saved(),grounded),
                    "Saving a grounded pose exports its resulting local bone transforms")
            else
                t.session.finish(false)
            end
            t.controlsRestored()
            check(restTest(),"Normal Rest input resumes after the editor exits")
            local e={allowRest=true,scripted=false}
            check(callbacks.uiShowRestMenu(e)==nil and not e.block,
                "Normal Rest/Wait menus resume after the editor exits")
        end
    end
    t.setBones(t.relaxed)
    check(t.session.start(t.ref,t.api),"Start before Ground Feet reference failure")
    local state=t.state()
    for tip in pairs(state.chains) do state.locks[tip]=rig.anchor(state.bones,tip) end
    local locks=rig.cloneLocks(state.locks)
    local before=rig.clone(state.bones)
    local written=t.writes()
    t.setReadError(true); t.press("t"); command("both"); t.setReadError(false)
    check(t.session.isActive() and t.samePose(state.bones,before) and #state.undo==0 and t.writes()==written,
        "An unreadable Relaxed pose reports an error while keeping the session and history usable")
    local chain=state.chains[right]
    local pivot=rig.world(state.bones)[chain.upper].translation
    rig.solve(state.bones,chain,v.add(pivot,{65,0,0}),rig.pole(state.bones,chain))
    before=rig.clone(state.bones)
    t.press("t"); command("both")
    check(t.session.isActive() and t.samePose(state.bones,before) and #state.undo==0 and t.writes()==written,
        "An unreachable both-foot target keeps the session, pose, locks and history intact")
    for tip,lock in pairs(locks) do
        check(t.same(state.locks[tip].target,lock.target) and t.same(state.locks[tip].rotation,lock.rotation),
            "Failed grounding preserves existing lock positions and facing")
    end
    t.session.finish(false); t.controlsRestored()
    for _,exit in ipairs({"load","cellChanged","referenceDeactivated","rebuild","finish"}) do
        t.setBones(t.relaxed)
        check(t.session.start(t.ref,t.api),"Start before Ground Feet cleanup")
        t.press("t"); local stale=menu.current
        if exit=="rebuild" then t.ref.sceneNode={}; callbacks.enterFrame({})
        elseif exit=="finish" then t.session.finish(false)
        else callbacks[exit]({reference=t.ref}) end
        check(not t.session.isActive() and stale.closed,"Every exit closes the Ground Feet menu safely: "..exit)
        written=t.writes(); stale.onGround("both")
        check(not t.session.isActive() and t.writes()==written,"A late grounding callback cannot modify a finished session")
        t.controlsRestored()
    end
    check(t.session.start(t.ref,t.api),"Start before Ground Feet checkpoint failure")
    t.press("t"); t.setWriteError(true); command("both"); t.setWriteError(false)
    check(not t.session.isActive(),"A grounding checkpoint failure restores and cleans up the session")
    t.controlsRestored()
end
