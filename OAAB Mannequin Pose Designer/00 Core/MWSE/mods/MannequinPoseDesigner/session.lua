local log=require("MannequinPoseDesigner.logger")
local config=require("MannequinPoseDesigner.config")
local v=require("MannequinPoseDesigner.math3d")
local rig=require("MannequinPoseDesigner.rig")
local library=require("MannequinPoseDesigner.library")
local overlay=require("MannequinPoseDesigner.overlay")
local bonePicking=require("MannequinPoseDesigner.bone_picking")
local controls=require("MannequinPoseDesigner.controls")
local gizmos=require("MannequinPoseDesigner.gizmos")
local gizmoMath=require("MannequinPoseDesigner.gizmo_math")
local namePrompt=require("MannequinPoseDesigner.metadata_prompt")
local saveMenu=require("MannequinPoseDesigner.save_menu")
local mirror=require("MannequinPoseDesigner.mirror")
local mirrorMenu=require("MannequinPoseDesigner.mirror_menu")
local symmetryMenu=require("MannequinPoseDesigner.symmetry_menu")
local resetMenu=require("MannequinPoseDesigner.reset_menu")
local blend=require("MannequinPoseDesigner.blend")
local blendMenu=require("MannequinPoseDesigner.blend_menu")
local ground=require("MannequinPoseDesigner.ground")
local groundMenu=require("MannequinPoseDesigner.ground_menu")
local highlight=require("MannequinPoseDesigner.highlight")
local focus=require("MannequinPoseDesigner.focus")
local orbit=require("MannequinPoseDesigner.orbit")
local props=require("MannequinPoseDesigner.props")
local propsMenu=require("MannequinPoseDesigner.props_menu")
local M={}
local active
local restoreCamera
local consumedEscape
local flags={"controlsDisabled","mouseLookDisabled","attackDisabled","magicDisabled","jumpingDisabled","viewSwitchDisabled","vanityDisabled"}
local disabledBones={
    ["weapon bone"]=true,
    ["shield bone"]=true,
    ["bip01 neck"]=true,
    ["bip01 l clavicle"]=true,
    ["bip01 r clavicle"]=true,
}
local function reference(s)
    if not s.handle:valid() then return end
    local ref=s.handle:getObject()
    if not ref.deleted and not ref.disabled and ref.sceneNode then return ref end
end
local function report(err)
    log("[OAAB Pose Designer] %s",tostring(err))
    tes3.messageBox("Pose Designer: %s",tostring(err))
end
local function restore(fn)
    local ok,err=pcall(fn)
    if not ok then log("[OAAB Pose Designer] Cleanup: %s",tostring(err)) end
end
local function restoreFocus(s)
    local state=s.focus
    if not state then return end
    s.focus=nil
    -- The module restores each setting independently after partial activation.
    focus.restore(state,restore)
end
local function toggleFocus(s)
    log("[OAAB Pose Designer] Focus toggle requested: current=%s, pose=%s, props=%d",
        s.focus and "on" or "off",tostring(s.originalFile),#s.props)
    if s.focus then
        restoreFocus(s)
        log("[OAAB Pose Designer] Focus off: restoration complete")
        return
    end
    -- Take ownership before any write so a failed toggle can still be cleaned up.
    log("[OAAB Pose Designer] Focus activation: capture scene and settings")
    s.focus=focus.capture(rig.engineVector(s.groundFrame.translation))
    log("[OAAB Pose Designer] Focus activation: apply isolation")
    focus.update(s.focus,s.scene,s.overlay.native.root)
    log("[OAAB Pose Designer] Focus on: mannequin=%s, landscape=%s, saved scene flags=%d, native water=%s, MGE=%s, master volume=%s, music volume=%s",
        tostring(s.scene),tostring(s.focus.terrain and s.focus.terrain.node),#s.focus.visibility,
        tostring(s.focus.water~=nil),tostring(s.focus.render~=nil),
        tostring(s.focus.audio and s.focus.audio.controller.volumeMaster),
        tostring(s.focus.audio and s.focus.audio.controller.volumeMusic))
    log("[OAAB Pose Designer] Focus Sunshafts original state=%s; native sunglare suppressed=%s",
        tostring(s.focus.sunShader and s.focus.sunShader.enabled),tostring(s.focus.render and s.focus.render.noMWSunglare))
end
local function restoreVisibility(visibility)
    for _,entry in ipairs(visibility or {}) do
        restore(function() entry.node.appCulled=entry.culled end)
    end
end
local function discardCameraRestore()
    local pending=restoreCamera
    restoreCamera=nil
    if pending then restoreVisibility(pending.visibility) end
end
local function bind(s,ref)
    s.scene=ref.sceneNode
    s.nodes=rig.bind(s.scene,s.bones)
end
local function clearHighlight(s,live)
    if s.highlight and live then highlight.clear(s.highlight) end
    s.highlight=nil
end
local function checkpoint(s)
    assert(reference(s),"The mannequin is no longer available")
    local file=library.write(s.bones,nil,s.props)
    s.drafts[#s.drafts+1]=file
end
local function snapshot(s)
    return {bones=rig.clone(s.bones),locks=rig.cloneLocks(s.locks),props=props.clone(s.props),
        selected=s.selected,selectedProp=s.selectedProp}
end
local function remember(s,previous)
    s.undo[#s.undo+1]=previous or snapshot(s)
    if #s.undo>100 then table.remove(s.undo,1) end
    s.redo={}
end
local function rebaseLocks(s,touched)
    for tip in pairs(s.locks) do
        local index=tip
        while index~=0 do
            if touched[index] then s.locks[tip]=rig.anchor(s.bones,tip); break end
            index=s.bones[index].parent
        end
    end
end
local function followSymmetry(s,previous,edited)
    if previous then rebaseLocks(s,mirror.follow(s.bones,previous,s.selected,s.symmetry,edited)) end
end
function M.isActive() return active~=nil end
function M.finish(save, unloading, name,replaceFile)
    local s=active
    if not s then return end
    local ref=s.handle:valid() and s.handle:getObject() or nil
    if ref and ref.deleted then ref=nil end
    local file
    if save then
        if not ref or not ref.sceneNode then return M.finish(false) end
        s.pendingName=name
        -- Keep editing on I/O/load failures, with the old persistent pose intact.
        local ok,err=pcall(function()
            local function apply(path)
                file=path
                clearHighlight(s,ref.sceneNode==s.scene)
                props.clearLive(s)
                s.attemptedLoad=true
                assert(s.api.select(ref,path),"Pose NIF could not be applied")
                bind(s,ref)
            end
            if replaceFile then
                local pose=assert(library.find(replaceFile),"The saved pose is no longer available")
                file=library.replace(s.bones,pose.file,apply,s.props)
            else
                assert(name,"Enter a pose name and ID before saving")
                file=library.write(s.bones,name,s.props,apply,s.originalFile,s.libraryRecords)
            end
            log("[OAAB Pose Designer] Saved pose applied: %s",file)
        end)
        if not ok then
            if s.attemptedLoad then
                -- Restore OAAB's maintained pose before returning control to
                -- the live edit buffer (replacement bundles have rolled back).
                restore(function()
                    if s.originalFile then assert(s.api.select(ref,s.originalFile))
                    else s.api.setSelectedFile(ref,nil) end
                end)
            end
            if ref.sceneNode~=s.scene then
                s.attemptedLoad=true
                clearHighlight(s,false)
            end
            local rebound=pcall(bind,s,ref)
            if rebound then
                local restored,problem=pcall(function()
                    rig.apply(s.bones,s.nodes,s.scene)
                    if #s.props>0 then
                        props.unhideEmbedded(s); props.hideEmbedded(s); props.restore(s)
                    end
                    if not s.highlight then s.highlight=highlight.create(s.scene,s.bones,s.nodes) end
                    highlight.update(s.highlight,s.selected,s.selectedProp~=nil)
                end)
                if not restored then log("[OAAB Pose Designer] Highlight recovery: %s",tostring(problem)) end
            end
            report(err)
            if not rebound then M.finish(false) end
            return false,err
        end
        s.api.setSelectedFile(ref,file)
        if replaceFile then
            restore(function() s.api.refreshFile(file,ref) end)
        end
    end
    active=nil -- Release input/camera even if restoration below fails.
    restore(function() tes3ui.suppressTooltip(false) end)
    restoreFocus(s)
    if not unloading and s.originalCamera then
        -- Menus may pause camera updates. Keep both player models hidden until
        -- the gameplay and arm cameras have returned to their original frames.
        restoreCamera={camera=s.originalCamera.camera,arms=s.originalCamera.arms,
            visibility=s.visibility,player=s.player,playerCell=s.playerCell}
    else
        restoreVisibility(s.visibility)
    end
    s.visibility=nil
    restore(function() namePrompt.close(s.namePrompt) end)
    restore(function() saveMenu.close(s.savePrompt) end)
    restore(function() mirrorMenu.close(s.mirrorPrompt) end)
    restore(function() symmetryMenu.close(s.symmetryPrompt) end)
    restore(function() resetMenu.close(s.resetPrompt) end)
    restore(function() blendMenu.close(s.blendPrompt) end)
    restore(function() groundMenu.close(s.groundPrompt) end)
    restore(function()
        if s.propPrompt then s.propPrompt.close() end
    end)
    restore(function() props.clearLive(s); props.unhideEmbedded(s) end)
    restore(function() clearHighlight(s,not unloading and ref and ref.sceneNode==s.scene) end)
    restore(function() overlay.destroy(s.overlay) end)
    restore(function()
        if tes3.mobilePlayer==s.player then
            for _,name in ipairs(flags) do s.player[name]=s.flags[name] end
        end
    end)
    if ref then
        restore(function() ref.orientation=s.orientation:copy() end)
        if ref.sceneNode and not unloading then
            if not save then
                if s.attemptedLoad then
                    restore(function()
                        if s.originalFile then assert(s.api.select(ref,s.originalFile))
                        else
                            s.api.setSelectedFile(ref,nil)
                            rig.apply(s.initial,s.nodes,s.scene)
                        end
                    end)
                elseif ref.sceneNode==s.scene then
                    restore(function() rig.apply(s.initial,s.nodes,s.scene) end)
                end
            end
            restore(function() ref:updateLighting() end)
        end
    end
    for _,draft in ipairs(s.drafts) do restore(function() library.removeDraft(draft) end) end
    if ref then restore(function() s.api.suspend(ref,false) end) end
    if save then
        tes3.messageBox("Pose saved.",file)
    end
    return true
end
function M.start(ref,api,editFile,records)
    if active or not api.canPose(ref) or not ref.sceneNode or not tes3.mobilePlayer then
        log("[OAAB Pose Designer] Start refused: active=%s, scene=%s, player=%s",tostring(active~=nil),tostring(ref.sceneNode~=nil),tostring(tes3.mobilePlayer~=nil))
        return false
    end
    local s={handle=tes3.makeSafeObjectHandle(ref),api=api,scene=ref.sceneNode,originalFile=api.getSelectedFile(ref),orientation=ref.orientation:copy(),player=tes3.mobilePlayer,playerCell=tes3.player.cell,flags={},drafts={},undo={},redo={},locks={},props={},heldAxes={},cameraHeld={},cursor={0,0},selected=1,mode="IK",symmetry="off",handles=true}
    s.libraryRecords=records
    if editFile then
        if library.isDefault(editFile) then
            tes3.messageBox("Baseline OAAB poses cannot be edited. Choose Create pose to save a custom copy.")
            return false
        end
        local found,pose=pcall(library.find,editFile)
        if not found then report(pose); return false end
        if not pose or not s.originalFile or pose.file:lower():gsub("\\","/")~=s.originalFile:lower():gsub("\\","/") then
            log("[OAAB Pose Designer] Edit refused: selected custom pose changed or disappeared")
            return false
        end
        s.editFile=pose.file
        s.editLabel=pose.label
    end
    -- Establish ownership before any operation which can fail, so cleanup always
    -- restores the player's original control flags and the prior animation.
    for _,name in ipairs(flags) do s.flags[name]=s.player[name] end
    active=s
    s.visibility={}
    if restoreCamera then
        if restoreCamera.player==s.player and restoreCamera.playerCell==s.playerCell then
            -- A rapid restart inherits the original camera and visibility, not
            -- the still-hidden player and the previous designer camera.
            s.originalCamera={camera=restoreCamera.camera,arms=restoreCamera.arms}
            s.visibility=restoreCamera.visibility
            restoreCamera=nil
        else
            discardCameraRestore()
        end
    end
    local ok,err=pcall(function()
        log("[OAAB Pose Designer] Editor entry: selected=%s, edit=%s",
            tostring(s.originalFile),tostring(s.editFile))
        tes3ui.suppressTooltip(true)
        api.suspend(ref,true)
        log("[OAAB Pose Designer] Editor entry: capture live skeleton")
        s.bones,s.nodes=rig.capture(ref.sceneNode)
        log("[OAAB Pose Designer] Editor entry: captured %d bone(s)",#s.bones)
        s.selectable={}
        s.selectableIndex={}
        for i,bone in ipairs(s.bones) do
            local name=bone.name:lower()
            if not disabledBones[name] and not name:find("finger",1,true) then
                s.selectable[#s.selectable+1]=i
                s.selectableIndex[i]=#s.selectable
            end
        end
        s.initial=rig.clone(s.bones)
        s.chains=rig.chains(s.bones)
        if s.originalFile then
            local metadata
            s.props,metadata=library.readProps(s.originalFile)
            if not metadata and props.hasEmbedded(s.scene) then
                s.preserveEmbedded=true
                tes3.messageBox("This pose has no editable prop metadata. Its embedded props will be preserved while you edit the skeleton.")
            end
        end
        if #s.props>0 then
            log("[OAAB Pose Designer] Editor entry: restore %d prop(s)",#s.props)
            props.hideEmbedded(s); props.restore(s)
            log("[OAAB Pose Designer] Editor entry: props restored, errors=%s",tostring(next(s.propScene.errors)~=nil))
            if next(s.propScene.errors) then tes3.messageBox("Some prop meshes could not be restored. Definitions are retained. Select their nodes to delete them or restore their source meshes. For details in mwse.log, enable Debug mode in the mod's MCM and reopen the editor.") end
        end
        s.highlight=highlight.create(s.scene,s.bones,s.nodes)
        log("[OAAB Pose Designer] Initial bone highlight maps to %d shape(s)",
            #(s.highlight.parts[s.selected] or {}))
        highlight.update(s.highlight,s.selected)
        local frame=rig.frame(s.nodes)
        s.groundFrame={translation=v.copy(frame.translation),rotation=v.copy(frame.rotation),scale=frame.scale}
        local world=rig.world(s.bones,frame)
        local lo,hi=math.huge,-math.huge
        for _,b in ipairs(world) do lo=math.min(lo,b.translation[3]); hi=math.max(hi,b.translation[3]) end
        local center={world[1].translation[1],world[1].translation[2],(lo+hi)/2}
        local eye=rig.vector(tes3.getCameraPosition())
        local offset=v.sub(eye,center)
        local front=v.transform(frame.rotation,{0,1,0}) -- TES3 mannequin: +Y front, +X right.
        local radius=0
        for _,b in ipairs(world) do radius=math.max(radius,v.length(v.sub(b.translation,center))) end
        if s.scene.worldBoundOrigin and s.scene.worldBoundRadius then
            radius=math.max(radius,v.length(v.sub(rig.vector(s.scene.worldBoundOrigin),center))+s.scene.worldBoundRadius)
        end
        s.orbit=orbit.new(center,math.max(100,(hi-lo)*1.7),math.atan2(offset[2],offset[1]),math.atan2(front[2],front[1]),radius)
        s.orbitCenter=v.copy(center)
        s.orbitRoot=v.copy(world[1].translation)
        for _,name in ipairs(flags) do s.player[name]=true end
        for _,playerRef in ipairs({tes3.player,s.player.firstPersonReference}) do
            local node=playerRef.sceneNode
            if node then
                local known=false
                for _,entry in ipairs(s.visibility) do
                    if entry.node==node then known=true; break end
                end
                if not known then s.visibility[#s.visibility+1]={node=node,culled=node.appCulled} end
                node.appCulled=true
            end
        end
        log("[OAAB Pose Designer] Editor entry: write draft checkpoint")
        checkpoint(s) -- A real NIF exists from the beginning of the session.
        log("[OAAB Pose Designer] Editor entry: create controls and handles")
        s.overlay=overlay.create(s.bones,s.selectable)
        if config.focusModeByDefault then toggleFocus(s) end
        log("[OAAB Pose Designer] Editor entry: initial overlay layout")
        overlay.update(s.overlay,s,world)
        highlight.update(s.highlight,s.hovered or s.selected)
    end)
    if not ok then M.finish(false); report(err); return false end
    log("[OAAB Pose Designer] Editor active with %d bones",#s.bones)
    return true
end
local function ready()
    return active and not active.namePrompt and not active.savePrompt and not active.mirrorPrompt and not active.symmetryPrompt and not active.resetPrompt and not active.blendPrompt and not active.groundPrompt and not active.propPrompt and not tes3ui.menuMode()
end
local function keyboardOwner(element)
    if not element then return false end
    -- MWSE's element/textInputFocus is a retained pointer, not proof that the
    -- field still accepts input. Hidden menus can keep their visible children
    -- and focus pointer after closing, so check the entire ancestor chain.
    local current=element
    while current do
        if current.visible==false or current.disabled then return false end
        current=current.parent
    end
    return true
end
local function keyboardCaptured(element)
    local input=tes3.worldController.menuController.inputController
    return keyboardOwner(element) or (input and keyboardOwner(input.textInputFocus))
end
local function viewing()
    return ready() or (active and active.blendPrompt~=nil)
end
local function current(s)
    local ref=reference(s)
    if not ref or ref.sceneNode~=s.scene or tes3.mobilePlayer~=s.player or tes3.player.cell~=s.playerCell then
        log("[OAAB Pose Designer] Editor closed: reference=%s, sceneChanged=%s, playerChanged=%s, cellChanged=%s",tostring(ref~=nil),tostring(ref and ref.sceneNode~=s.scene),tostring(tes3.mobilePlayer~=s.player),tostring(tes3.player.cell~=s.playerCell))
        M.finish(false)
        return
    end
    return ref
end
local function guarded(fn)
    return function(e)
        if not active then return end
        local ok,result,detail=pcall(fn,e or {})
        if not ok then M.finish(false); report(result) else return result,detail end
    end
end
local function openName(s,action)
    local initial=s.pendingName or {}
    local options={title="Save As",button="Save As"}
    if s.editFile then
        local pose=assert(library.find(s.editFile),"The saved pose is no longer available")
        initial={id=pose.id or library.poseId(s.editFile),name=pose.name or pose.label,
            description=pose.description or "",category=pose.category or ""}
        if action=="rename" then
            options={immutableId=true,title="Edit Metadata",button="Save Metadata"}
        else
            initial.id=""
        end
    end
    options.records=s.libraryRecords
    s.player.controlsDisabled=s.flags.controlsDisabled
    s.namePrompt=namePrompt.open(initial,function(fields)
        if active~=s or not current(s) then return false,"The editing session has ended" end
        if action=="rename" then
            library.updateMetadata(s.editFile,fields)
            s.editLabel=library.label(s.editFile)
            return true
        else return M.finish(true,false,fields) end
    end,function()
        s.namePrompt=nil
        if active==s then s.player.controlsDisabled=true end
    end,options)
    if not s.namePrompt then s.player.controlsDisabled=true end
end
local function openSave(s)
    if not s.editFile then openName(s,"as"); return end
    s.player.controlsDisabled=s.flags.controlsDisabled
    s.savePrompt=saveMenu.open(library.label(s.editFile),function(action)
        if active~=s or not current(s) then return end
        if action=="changes" then M.finish(true,false,nil,s.editFile)
        else openName(s,action) end
    end,function()
        s.savePrompt=nil
        if active==s then s.player.controlsDisabled=true end
    end)
    if not s.savePrompt then s.player.controlsDisabled=true end
end
local function openMirror(s)
    s.player.controlsDisabled=s.flags.controlsDisabled
    s.mirrorPrompt=mirrorMenu.open(s.mirrorScope or "entire",function(action,scope)
        guarded(function()
            if active~=s or not current(s) then return end
            s.mirrorScope=scope
            local bones,touched=mirror.apply(s.bones,action,scope)
            if not next(touched) then
                tes3.messageBox("No matching left/right bones in this target.")
                return
            end
            remember(s)
            s.bones=bones
            -- Keep each side's lock enabled, but move anchors with the explicit
            -- command. Solving against old anchors would undo the mirrored pose.
            rebaseLocks(s,touched)
            rig.apply(s.bones,s.nodes,s.scene)
            checkpoint(s)
        end)()
    end,function()
        s.mirrorPrompt=nil
        if active==s then s.player.controlsDisabled=true end
    end)
    if not s.mirrorPrompt then s.player.controlsDisabled=true end
end
local function openSymmetry(s)
    s.player.controlsDisabled=s.flags.controlsDisabled
    s.symmetryPrompt=symmetryMenu.open(s.symmetry,function(mode)
        guarded(function()
            if active~=s or not current(s) then return end
            s.symmetry=mode
        end)()
    end,function()
        s.symmetryPrompt=nil
        if active==s then s.player.controlsDisabled=true end
    end)
    if not s.symmetryPrompt then s.player.controlsDisabled=true end
end
local function resetPose(s,scope)
    remember(s)
    local previous=scope~="entire" and s.symmetry~="off" and rig.clone(s.bones)
    local touched
    s.bones,touched=rig.reset(s.bones,s.initial,s.selected,scope)
    if scope=="bone" then
        if s.locks[s.selected] then s.locks[s.selected]=rig.anchor(s.bones,s.selected) end
        rig.solveLocks(s.bones,s.chains,s.locks,rig.frame(s.nodes),s.selected)
    else
        -- Explicit branch/pose resets move their locks to the restored pose.
        -- Old anchors must not pull any of the reset bones back out of place.
        rebaseLocks(s,touched)
    end
    followSymmetry(s,previous,touched)
    rig.apply(s.bones,s.nodes,s.scene)
    checkpoint(s)
end
local function openReset(s)
    s.player.controlsDisabled=s.flags.controlsDisabled
    s.resetPrompt=resetMenu.open(s.bones[s.selected].name,function(scope)
        guarded(function()
            if active~=s or not current(s) then return end
            resetPose(s,scope)
        end)()
    end,function()
        s.resetPrompt=nil
        if active==s then s.player.controlsDisabled=true end
    end)
    if not s.resetPrompt then s.player.controlsDisabled=true end
end
local function openBlend(s)
    local ok,files=pcall(library.blendList)
    if not ok then report(files); return end
    local before=snapshot(s)
    local cache={}
    local touched={}
    for i=1,#s.bones do touched[i]=true end
    s.player.controlsDisabled=s.flags.controlsDisabled
    s.blendPrompt=blendMenu.open(files,function(a,b,t)
        return guarded(function()
            if active~=s or not s.blendPrompt or not current(s) then return end
            -- Prepare both poses before changing the mannequin. A bad/missing
            -- file leaves the dialog usable so another pair can be selected.
            local loaded,result=pcall(function()
                for _,file in ipairs({a,b}) do
                    if not cache[file] then cache[file]=blend.align(library.read(file),before.bones) end
                end
                return blend.apply(cache[a],cache[b],t)
            end)
            if not loaded then return false,tostring(result) end
            s.bones=result
            rebaseLocks(s,touched)
            rig.apply(s.bones,s.nodes,s.scene)
            return true
        end)()
    end,function(accepted)
        s.blendPrompt=nil
        if active~=s then return end
        s.player.controlsDisabled=true
        guarded(function()
            if not current(s) then return end
            if accepted then
                remember(s,before)
                checkpoint(s)
            else
                s.bones,s.locks=before.bones,before.locks
                rig.apply(s.bones,s.nodes,s.scene)
            end
        end)()
    end)
    if not s.blendPrompt then s.player.controlsDisabled=true end
end
local function openGround(s)
    s.player.controlsDisabled=s.flags.controlsDisabled
    s.groundPrompt=groundMenu.open(function(scope)
        guarded(function()
            if active~=s or not current(s) then return end
            -- Load and solve before committing anything. An unreachable target
            -- or unreadable reference leaves the pose/history available to edit.
            local ok,bones,touched=pcall(function()
                if not s.groundReference then
                    s.groundReference=ground.reference(library.read("oaab/k/mann_relax.nif"),s.groundFrame)
                end
                return ground.apply(s.bones,s.groundReference,scope,rig.frame(s.nodes))
            end)
            if not ok then report(bones); return end
            remember(s)
            s.bones=bones
            -- Explicit grounding takes priority over old locks and symmetry.
            -- Root movement carries every anchor with the resulting pose.
            rebaseLocks(s,touched)
            rig.apply(s.bones,s.nodes,s.scene)
            checkpoint(s)
        end)()
    end,function()
        s.groundPrompt=nil
        if active==s then s.player.controlsDisabled=true end
    end)
    if not s.groundPrompt then s.player.controlsDisabled=true end
end
local function propCommand(s,action,value,targetId)
    if active~=s or not current(s) then return end
    if s.preserveEmbedded then
        tes3.messageBox("This pose has no editable prop metadata. Restore its original NIF to modify props. Skeleton edits preserve the embedded props.")
        return
    end
    if action=="add" or action=="replace" then
        local replacing=action=="replace"
        local selected=replacing and props.get(s)
        if replacing and not selected then return end
        local id=selected and selected.id
        s.player.controlsDisabled=s.flags.controlsDisabled
        local ok,prompt=pcall(propsMenu.inventory,function(item) propCommand(s,replacing and "replaceItem" or "item",item,id) end,function()
            s.propPrompt=nil; if active==s then s.player.controlsDisabled=true end
        end,replacing and "Replace Prop" or "Add Prop")
        if ok then s.propPrompt=not prompt.closed and prompt or nil
        else s.player.controlsDisabled=true; report(prompt) end
        return
    end
    local p=props.get(s,targetId)
    if action~="item" and not p then return end
    local before=snapshot(s)
    local ok,err=pcall(function()
        if action=="item" then props.add(s,value)
        elseif action=="replaceItem" then props.replace(s,p,value)
        elseif action=="duplicate" then props.duplicate(s,p)
        elseif action=="delete" then props.delete(s,p); if not s.selectedProp then s.mode="IK" end
        elseif action=="reset" then props.reset(s,p,value)
        elseif action=="attach" then props.reparent(s,p,value)
        elseif action=="free" then props.reparent(s,p,nil) end
    end)
    if not ok then report(err); return end
    remember(s,before)
    local saved,problem=pcall(checkpoint,s)
    if not saved then report(problem) end -- Keep editing if draft I/O fails.
end
local function updateSelection(s)
    if not ready() or not s.handles or s.drag then s.hovered=nil; s.hoveredProp=nil end
    if s.highlight then highlight.update(s.highlight,s.selectedProp and s.selected or (s.hovered or s.selected),s.selectedProp~=nil) end
    props.select(s)
end
local function update()
    local s=active
    if not current(s) then return end
    overlay.setVisible(s.overlay,ready(),s.blendPrompt~=nil)
    if not ready() then s.drag=nil end
    if not viewing() then updateSelection(s); return end
    for _,entry in ipairs(s.visibility or {}) do entry.node.appCulled=true end
    rig.apply(s.bones,s.nodes,s.scene)
    updateSelection(s)
end
local function syncOrbitTarget(s)
    -- Keep the camera fixed while ray-constrained root movement is in progress.
    -- Otherwise following the root feeds the prior movement into the next ray.
    if s.drag and s.drag.constraint and not s.drag.propId and s.drag.mode=="IK"
        and s.bones[s.selected].parent==0 then return end
    local frame=rig.frame(s.nodes)
    local root=v.add(frame.translation,v.scale(v.transform(frame.rotation,s.bones[1].translation),frame.scale))
    -- Follow deliberate root posing without making limb edits move the pivot.
    s.orbit.target=v.add(s.orbitCenter,v.sub(root,s.orbitRoot))
end
local function camera(e)
    if restoreCamera then
        e.cameraTransform=restoreCamera.camera
        e.armCameraTransform=restoreCamera.arms
        discardCameraRestore()
    end
    if not viewing() then return end
    local s=active
    if not s.originalCamera then
        s.originalCamera={camera=e.cameraTransform:copy(),arms=e.armCameraTransform:copy()}
    end
    syncOrbitTarget(s)
    local position,direction,up=orbit.view(s.orbit)
    local rotation=tes3matrix33.new()
    rotation:lookAt(rig.engineVector(direction),rig.engineVector(up))
    -- These are camera transforms, never the player's position/orientation.
    e.cameraTransform.translation=rig.engineVector(position)
    e.cameraTransform.rotation=rotation
    e.armCameraTransform.translation=rig.engineVector(position)
    e.armCameraTransform.rotation=rotation:copy()
end
local function frozenCamera()
    -- cameraControl belongs to the player's simulation update, which may stop
    -- at zero delta time. Apply the same local root transforms on real frames.
    local world=tes3.worldController
    local root=assert(world.worldCamera.cameraRoot,"The world camera is unavailable")
    local arms=assert(world.armCamera.cameraRoot,"The first-person camera is unavailable")
    local e={cameraTransform=tes3transform.new(root.rotation,root.translation,root.scale),
        armCameraTransform=tes3transform.new(arms.rotation,arms.translation,arms.scale)}
    camera(e)
    root:copyTransforms(e.cameraTransform)
    arms:copyTransforms(e.armCameraTransform)
    root:update({controllers=false})
    arms:update({controllers=false})
    local shadow=world.shadowCamera and world.shadowCamera.cameraRoot
    if shadow then
        shadow:copyTransforms(e.cameraTransform)
        shadow:update({controllers=false})
    end
end
local axes={x={1,0,0},y={0,1,0},z={0,0,1}}
local rotationDeadZone=4
local function rotationAngle(drag,cursor)
    local x,y=cursor[1]-drag.jointX,cursor[2]-drag.jointY
    if x*x+y*y<rotationDeadZone^2 then return end
    -- MWSE screen coordinates point up. Negate Y so clockwise is positive.
    return math.atan2(-y,x)
end
local function mouseDown(e)
    if not ready() then return end
    local s=active
    if not current(s) then return end
    if e.button==0 then
        if s.drag then return end
        local gizmoHit=not e.isAltDown and gizmos.pick(s.overlay.gizmo,s.cursor)
        local picked,propId,attachmentBone
        if not gizmoHit then picked,propId=bonePicking.target(s,e.isShiftDown) end
        if picked then
            if e.isShiftDown and s.selectedProp then
                -- Decide on release: a click chooses the attachment bone;
                -- a drag still performs the prop's existing Shift depth move.
                attachmentBone=picked
            else
                s.selected=picked; s.selectedProp=nil
                if s.mode=="Move" or s.mode=="Scale" then s.mode="IK" end
            end
        elseif propId then
            if s.selectedProp~=propId then s.selectedProp=propId; s.mode="Move" end
        end
        local frame=rig.frame(s.nodes)
        local world=rig.world(s.bones,frame)
        local prop=props.get(s)
        local chain=not prop and s.chains[s.selected]
        local bone=prop or s.bones[s.selected]
        local transform=world[s.selected]
        if prop then
            local node=s.propScene.nodes[prop.id]
            if not node then tes3.messageBox("This prop's mesh is unavailable. Delete it or restore its source mesh."); return end
            transform=props.nodeTransform(node)
        end
        local drag={button=0,mode=prop and s.mode or (s.mode=="IK" and (chain or bone.parent==0) and "IK" or "Rotate"),
            target=v.copy(transform.translation),pole=chain and rig.pole(s.bones,chain,frame),dirty=false,poleMode=e.isAltDown,
            propId=prop and prop.id,axisName=s.axis,attachmentBone=attachmentBone}
        if gizmoHit then
            drag.constraint=gizmos.begin(s.overlay.gizmo,s,transform)
            if not drag.constraint then return end -- Edge-on constraints have no stable drag plane.
            drag.axisName=drag.constraint.component
        end
        if drag.mode=="Rotate" then
            local cameraNode=tes3.getCamera()
            local joint=cameraNode:worldPointToScreenPoint(rig.engineVector(transform.translation))
            if not joint then return end -- A hidden pivot has no usable drag plane.
            local forward=rig.vector(cameraNode.worldDirection)
            drag.axisName=drag.constraint and drag.constraint.component or s.axis
            -- Matrices act on column vectors: world = parent * bone. A
            -- post-multiplied delta needs an axis in the starting bone frame.
            drag.axis=v.copy(axes[drag.axisName] or v.transform(v.transpose(transform.rotation),forward))
            drag.startRotation=v.copy(bone.rotation)
            drag.jointX,drag.jointY=joint.x,joint.y
            drag.lastAngle=rotationAngle(drag,s.cursor)
            drag.totalAngle=0
            -- Positive rotation around the camera's forward axis is clockwise.
            -- Keep local axes pointing away from the viewer for the same feel;
            -- the sign, like the axis and pivot, stays fixed for the whole drag.
            drag.direction=drag.constraint and 1 or (v.dot(v.transform(transform.rotation,drag.axis),forward)<0 and -1 or 1)
        end
        drag.before=snapshot(s)
        drag.undoBefore=v.copy(s.undo); drag.redoBefore=s.redo
        remember(s,drag.before)
        s.drag=drag
    elseif e.button==1 or e.button==2 then
        s.drag={button=e.button}
    end
end
local function endDrag(s)
    local drag=s.drag
    if not drag then return end
    if drag.button==0 and not drag.dirty then
        s.undo,s.redo=drag.undoBefore,drag.redoBefore
        if drag.attachmentBone then s.selected=drag.attachmentBone end
    end
    s.drag=nil
    return drag.dirty
end
local function mouseUp(e)
    if not active then return end
    local s=active
    if s.drag and s.drag.button==e.button and endDrag(s) then checkpoint(s) end
end
local function history(s,redo)
    -- End the gesture before replacing its transforms. Further mouse movement
    -- and the eventual release must not resume or checkpoint the old drag.
    local dirty=endDrag(s)
    local source,destination=s.undo,s.redo
    if redo then source,destination=destination,source end
    if #source>0 then
        destination[#destination+1]=snapshot(s)
        local previous=table.remove(source)
        s.bones,s.locks=previous.bones,previous.locks
        s.props=previous.props
        s.selected=previous.selected; s.selectedProp=previous.selectedProp
        if s.propScene or #s.props>0 then props.restore(s) end
        if not s.selectedProp and (s.mode=="Move" or s.mode=="Scale") then s.mode="IK" end
        if s.selectedProp and s.mode=="IK" then s.mode="Move" end
        rig.apply(s.bones,s.nodes,s.scene)
        checkpoint(s)
    elseif dirty then checkpoint(s) end
end
local function rotateDrag(s,drag,dx,dy,fine)
    local oldX,oldY=s.cursor[1]-drag.jointX,s.cursor[2]-drag.jointY
    local w,h=tes3ui.getViewportSize()
    -- Fine adjustment scales angular increments, never the visible pointer.
    s.cursor[1]=v.clamp(s.cursor[1]+dx,-w/2,w/2)
    s.cursor[2]=v.clamp(s.cursor[2]-dy,-h/2,h/2)
    local angle=rotationAngle(drag,s.cursor)
    local last=drag.lastAngle
    drag.lastAngle=angle
    if not angle or not last then return false end
    -- Passing through the pivot has no defined angular direction. Rebase the
    -- sample even if one mouse event jumps across the entire center dead zone.
    local stepX,stepY=s.cursor[1]-drag.jointX-oldX,s.cursor[2]-drag.jointY-oldY
    local length=stepX*stepX+stepY*stepY
    if length>0 then
        local t=v.clamp(-(oldX*stepX+oldY*stepY)/length,0,1)
        if (oldX+t*stepX)^2+(oldY+t*stepY)^2<rotationDeadZone^2 then return false end
    end
    local delta=angle-last
    if delta>math.pi then delta=delta-2*math.pi
    elseif delta< -math.pi then delta=delta+2*math.pi end
    if delta==0 then return false end
    drag.totalAngle=drag.totalAngle+delta*fine
    local target=drag.propId and props.get(s,drag.propId) or s.bones[s.selected]
    target.rotation=v.orthonormalize(v.mul(drag.startRotation,
        v.axisAngle(drag.axis,drag.totalAngle*drag.direction)))
    return true
end
local function mouseAxis(e)
    if not ready() then return end
    local s=active
    local ref=current(s)
    if not ref then return end
    local dx,dy=e.deltaX,e.deltaY
    local drag=s.drag
    if not drag then
        local w,h=tes3ui.getViewportSize()
        s.cursor[1]=v.clamp(s.cursor[1]+dx,-w/2,w/2)
        s.cursor[2]=v.clamp(s.cursor[2]-dy,-h/2,h/2)
        return
    end
    local fine=e.isControlDown and 0.15 or 1
    local previous=not drag.propId and s.symmetry~="off" and drag.button==0 and rig.clone(s.bones)
    local gizmoMovement
    if drag.constraint then
        local w,h=tes3ui.getViewportSize()
        s.cursor[1]=v.clamp(s.cursor[1]+dx,-w/2,w/2)
        s.cursor[2]=v.clamp(s.cursor[2]-dy,-h/2,h/2)
        local origin,direction=gizmos.ray(s.cursor)
        if not origin then return end
        local delta=gizmoMath.step(drag.constraint,origin,direction,fine)
        if not delta then return end
        if drag.mode=="Rotate" then
            if math.abs(delta)<1e-10 then return end
            drag.totalAngle=drag.totalAngle+delta
            local target=drag.propId and props.get(s,drag.propId) or s.bones[s.selected]
            target.rotation=v.orthonormalize(v.mul(drag.startRotation,v.axisAngle(drag.axis,drag.totalAngle)))
        else
            if v.length(delta)<1e-10 then return end
            gizmoMovement=delta
        end
    elseif drag.mode=="Rotate" and not rotateDrag(s,drag,dx,dy,fine) then return end
    dx,dy=dx*fine,dy*fine
    if drag.button==1 then
        syncOrbitTarget(s)
        orbit.rotate(s.orbit,-dx*0.009,dy*0.005)
        return
    end
    local cameraNode=tes3.getCamera()
    local right,up,forward=rig.vector(cameraNode.worldRight),rig.vector(cameraNode.worldUp),rig.vector(cameraNode.worldDirection)
    local movement=gizmoMovement or v.scale(v.add(v.scale(right,dx),v.scale(e.isShiftDown and forward or up,-dy)),s.orbit.distance*0.0015)
    if drag.button==2 then s.orbit.panOffset=v.sub(s.orbit.panOffset,movement); return end
    if drag.propId then
        local p=props.get(s,drag.propId)
        local node=s.propScene.nodes[p.id]
        if drag.mode=="Move" then
            local parent=props.nodeTransform(node.parent)
            local localMove=v.scale(v.transform(v.transpose(parent.rotation),movement),1/parent.scale)
            if not drag.constraint and axes[drag.axisName] then
                local axis=axes[drag.axisName]; localMove=v.scale(axis,v.dot(localMove,axis))
            end
            p.translation=v.add(p.translation,localMove)
        elseif drag.mode=="Scale" then p.scale=v.clamp(p.scale*math.exp((dx-dy)*0.01),0.001,1000) end
        drag.dirty=true; props.apply(p,node); s.scene:update()
        return
    end
    local bone=s.bones[s.selected]
    local frame=rig.frame(s.nodes)
    local chain=s.chains[s.selected]
    if drag.mode=="IK" and chain then
        if drag.poleMode then drag.pole=v.add(drag.pole,movement) else drag.target=v.add(drag.target,movement) end
        rig.solve(s.bones,chain,drag.target,drag.pole,frame)
    elseif drag.mode=="IK" and bone.parent==0 then
        bone.translation=v.add(bone.translation,v.scale(v.transform(v.transpose(frame.rotation),movement),1/frame.scale))
    end
    -- Direct edits to a locked hand/foot move its anchor or change its facing.
    -- Other edits must compensate without replacing the edited local rotation.
    if s.locks[s.selected] and (drag.mode~="IK" or not drag.poleMode) then
        s.locks[s.selected]=rig.anchor(s.bones,s.selected)
    end
    rig.solveLocks(s.bones,s.chains,s.locks,frame,s.selected)
    -- Mirrored edits take priority over the destination's old lock anchor.
    -- Rebase that anchor after source-side lock compensation to retain the edit.
    followSymmetry(s,previous)
    drag.dirty=true
    rig.apply(s.bones,s.nodes,s.scene)
end
local function keyUp(e)
    local s=active
    if not s then return end
    if controls.cameraAction(e.keyCode) then
        s.cameraHeld[e.keyCode]=nil
        if ready() and not keyboardCaptured(e.element) then return false end
        return
    end
    if controls.matches("focus",e.keyCode) then
        s.focusKeyDown=nil
        if ready() then return false end
        return
    end
    local axis=controls.axis(e.keyCode)
    if not axis then return end
    for i,held in ipairs(s.heldAxes) do
        if held==axis then
            table.remove(s.heldAxes,i)
            s.axis=s.heldAxes[#s.heldAxes]
            if ready() then return false end
            return -- Let modal text fields receive key releases.
        end
    end
end
local function key(e)
    local s=active
    if not s then return end
    if s.savePrompt or s.mirrorPrompt or s.symmetryPrompt or s.resetPrompt or s.blendPrompt or s.groundPrompt or s.propPrompt then return end -- These menus own keyboard input.
    if s.namePrompt then return end -- The modal text field owns keyboard input.
    local k=e.keyCode
    if s.expandedControls and (controls.matches("help",k) or controls.matches("cancel",k)) then
        if controls.matches("cancel",k) then consumedEscape={} end
        s.expandedControls=false
        return false
    end
    if controls.matches("cancel",k) then
        if s.drag and s.drag.propId then
            local before=s.drag.before
            s.undo,s.redo=s.drag.undoBefore,s.drag.redoBefore
            if before then s.props=before.props; props.restore(s) end
            s.drag=nil; consumedEscape={}; return false
        end
        log("[OAAB Pose Designer] Escape received; menuMode=%s",tostring(tes3ui.menuMode()))
        -- keyDown only claims Lua callbacks. The game's native Escape test runs
        -- later, after finish has released active and the normal keybind lock.
        consumedEscape={}
        M.finish(false)
        return false
    end
    if not ready() then return end
    local cameraAction=controls.cameraAction(k)
    if cameraAction then
        if keyboardCaptured(e.element) then
            s.cameraHeld={}
            local input=tes3.worldController.menuController.inputController
            local owner=keyboardOwner(e.element) and e.element or (input and input.textInputFocus)
            log("[OAAB Pose Designer] Numpad input captured: scan=%s, element=%s, type=%s",
                tostring(k),tostring(owner and owner.id),tostring(owner and owner.type))
            return
        end
        -- Leave bone drags' frozen camera plane alone until their mouse release.
        if s.drag then s.cameraHeld={}; return false end
        if e.isAltDown or e.isShiftDown or e.isSuperDown or (e.isControlDown and
            cameraAction~="front" and cameraAction~="right" and cameraAction~="top") then return end
        if not current(s) then return end
        if not s.cameraHeld[k] then
            syncOrbitTarget(s)
            orbit.apply(s.orbit,cameraAction,e.isControlDown)
            s.cameraHeld[k]={action=cameraAction,remaining=orbit.repeatDelay}
            log("[OAAB Pose Designer] Numpad camera: scan=%s, action=%s, ctrl=%s, yaw=%.6f, pitch=%.6f, distance=%.3f",
                tostring(k),cameraAction,tostring(e.isControlDown==true),s.orbit.yaw,s.orbit.pitch,s.orbit.distance)
        end
        return false
    end
    if controls.matches("save",k) then
        -- The editor's player-control lock also suppresses keyboard delivery to
        -- MWSE text inputs on some setups. The modal menu owns input meanwhile.
        openSave(s)
        return false
    end
    if e.isControlDown and controls.matches("saveChanges",k) then
        if s.drag or e.isShiftDown or e.isAltDown or e.isSuperDown then return false end
        if s.editFile then M.finish(true,false,nil,s.editFile)
        elseif not s.originalFile or library.isDefault(s.originalFile) then
            tes3.messageBox("Baseline OAAB poses cannot be overwritten. Press Enter to Save As a custom pose.")
        else
            tes3.messageBox("No saved pose is being edited. Press Enter to Save As, or choose Edit Pose to save changes.")
        end
        return false
    end
    local axis=controls.axis(k)
    if axis and not (e.isControlDown and (controls.matches("undo",k) or controls.matches("redo",k))) then
        -- Held keys choose the next drag's axis. The current drag keeps its
        -- starting axis/mode; repeated key-down events cannot latch an axis.
        for _,held in ipairs(s.heldAxes) do if held==axis then return false end end
        s.heldAxes[#s.heldAxes+1]=axis
        s.axis=axis
        if not s.selectedProp then s.mode="Rotate" end
        return false
    end
    if e.isControlDown and (controls.matches("undo",k) or controls.matches("redo",k)) then
        history(s,controls.matches("redo",k))
        return false
    end
    if s.drag then return false end
    if controls.matches("props",k) then
        if e.isControlDown and not (e.isAltDown or e.isShiftDown or e.isSuperDown) then
            propCommand(s,"attach",s.bones[s.selected].name)
        elseif e.isAltDown and not (e.isControlDown or e.isShiftDown or e.isSuperDown) then
            local p=props.get(s)
            if p and p.attachmentType=="bone" then propCommand(s,"free") end
        elseif e.isShiftDown and not (e.isControlDown or e.isAltDown or e.isSuperDown) then propCommand(s,"replace")
        elseif not (e.isControlDown or e.isAltDown or e.isShiftDown or e.isSuperDown) then propCommand(s,"add") end
    elseif s.selectedProp and e.isControlDown and controls.matches("propDuplicate",k)
        and not (e.isAltDown or e.isShiftDown or e.isSuperDown) then propCommand(s,"duplicate")
    elseif s.selectedProp and e.isAltDown and not (e.isControlDown or e.isShiftDown or e.isSuperDown)
        and (controls.matches("propResetScale",k) or controls.matches("propResetRotation",k) or controls.matches("propResetTranslation",k)) then
        propCommand(s,"reset",controls.matches("propResetScale",k) and "scale" or controls.matches("propResetRotation",k) and "rotation" or "translation")
    elseif s.selectedProp and controls.matches("propDelete",k)
        and not (e.isControlDown or e.isAltDown or e.isShiftDown or e.isSuperDown) then propCommand(s,"delete")
    elseif controls.matches("mirror",k) then
        openMirror(s)
    elseif controls.matches("symmetry",k) then
        if s.selectedProp then s.mode="Scale" else openSymmetry(s) end
    elseif controls.matches("blend",k) then
        openBlend(s)
    elseif controls.matches("ground",k) then
        openGround(s)
    elseif controls.matches("focus",k) then
        if not s.focusKeyDown then
            s.focusKeyDown=true
            toggleFocus(s)
        end
    elseif controls.matches("cycle",k) then
        if e.isControlDown then
            if #s.props>0 then
                local _,position=props.get(s)
                position=position or (e.isShiftDown and 1 or 0)
                s.selectedProp=s.props[(position-1+(e.isShiftDown and -1 or 1))%#s.props+1].id
                if s.mode=="IK" then s.mode="Move" end
            end
        else
            local position=s.selectableIndex[s.selected] or 1
            s.selected=s.selectable[(position-1+(e.isShiftDown and -1 or 1))%#s.selectable+1]
        end
    elseif controls.matches("help",k) then s.expandedControls=true
    elseif controls.matches("handles",k) then s.handles=not s.handles
    elseif not s.selectedProp and controls.matches("lock",k) and s.chains[s.selected] then
        remember(s)
        s.locks[s.selected]=not s.locks[s.selected] and rig.anchor(s.bones,s.selected) or nil
    elseif controls.matches("rotate",k) then s.mode="Rotate"
    elseif controls.matches("move",k) then s.mode=s.selectedProp and "Move" or "IK"
    elseif controls.matches("resetBone",k) then
        if s.selectedProp then propCommand(s,"reset")
        elseif e.isControlDown then resetPose(s,e.isShiftDown and "entire" or "limb")
        elseif e.isShiftDown then openReset(s)
        else resetPose(s,"bone") end
    end
    return false
end
local function repeatCamera(s,e)
    if not next(s.cameraHeld) then return end
    local input=tes3.worldController.inputController
    if e.menuMode or not ready() or keyboardCaptured() or s.drag or (input and
        (input:isControlDown() or input:isAltDown() or input:isShiftDown() or input:isSuperDown())) then
        s.cameraHeld={}
        return
    end
    if not current(s) then return end
    syncOrbitTarget(s)
    -- Real frame time keeps repeat usable during focus's frozen simulation.
    -- Cap stalls so resuming a suspended game never jumps through many views.
    local delta=v.clamp(e.delta or 0,0,0.1)
    for code,held in pairs(s.cameraHeld) do
        if input and not input:isKeyDown(code) then s.cameraHeld[code]=nil
        elseif orbit.repeats(held.action) then
            held.remaining=held.remaining-delta
            if held.remaining<=1e-10 then
                orbit.apply(s.orbit,held.action)
                held.remaining=held.remaining+orbit.repeatInterval
            end
        end
    end
end
function M.register()
    event.register("render",guarded(function()
        -- Keep reticle labels hidden even during focus and modal name dialogs.
        tes3ui.suppressTooltip(true)
        local s=active
        if s.focus and current(s) then
            if viewing() then
                frozenCamera()
            end
            if viewing() then
                -- Project markers with the camera that will draw this frame.
                overlay.update(s.overlay,s,rig.world(s.bones,rig.frame(s.nodes)))
                updateSelection(s)
            end
            focus.update(s.focus,s.scene,s.overlay.native.root)
        end
    end),{priority=-1000})
    event.register("enterFrame",guarded(function(e)
        local s=active
        repeatCamera(s,e)
        if active~=s then return end
        -- Keep pose updates and lifecycle checks running even at zero simulation time.
        if s.focus or s.namePrompt or s.savePrompt or s.blendPrompt or s.resetPrompt or s.groundPrompt or s.propPrompt or s.expandedControls then
            update()
            if active~=s then return end
            if s.focus and viewing() then frozenCamera() end
        end
        if s.overlay then
            overlay.setVisible(s.overlay,ready(),s.blendPrompt~=nil)
            if viewing() then
                overlay.update(s.overlay,s,rig.world(s.bones,rig.frame(s.nodes)))
            end
            updateSelection(s)
        end
        if e.menuMode and s.drag then
            s.needsCheckpoint=s.needsCheckpoint or s.drag.dirty
            s.drag=nil
        elseif not e.menuMode and s.needsCheckpoint and current(s) then
            s.needsCheckpoint=nil
            checkpoint(s)
        end
    end))
    event.register("simulate",guarded(function()
        if viewing() then
            local ref=current(active)
            if ref then tes3.skipAnimationFrame({reference=ref}) end
        end
    end),{priority=1000})
    event.register("simulated",guarded(update),{priority=-100})
    event.register("cameraControl",function(e)
        if not active and not restoreCamera then return end
        local ok,err=pcall(camera,e)
        if not ok then discardCameraRestore(); M.finish(false); report(err) end
    end,{priority=-100})
    event.register("mouseButtonDown",guarded(mouseDown),{priority=1000})
    event.register("mouseButtonUp",guarded(mouseUp),{priority=1000})
    event.register("mouseAxis",guarded(mouseAxis),{priority=1000})
    event.register("mouseWheel",guarded(function(e)
        if not ready() or active.drag or e.delta==0 then return end
        local s=active
        orbit.zoom(s.orbit,e.delta>0)
    end),{priority=1000})
    local onKeyDown,onKeyUp=guarded(key),guarded(keyUp)
    event.register("keyDown",function(e)
        if controls.matches("cancel",e.keyCode) and consumedEscape then
            if not consumedEscape.released then return false end
            consumedEscape=nil -- A new press after release belongs to gameplay.
        end
        return onKeyDown(e)
    end,{priority=1000})
    event.register("keyUp",function(e)
        if controls.matches("cancel",e.keyCode) and consumedEscape then
            local pending=consumedEscape
            pending.released=true
            -- Native release tests also run after keyUp. Keep consuming this
            -- press through the frame, independently of the finished session.
            timer.frame.delayOneFrame(function()
                if consumedEscape==pending then consumedEscape=nil end
            end)
            return false
        end
        return onKeyUp(e)
    end,{priority=1000})
    event.register("keybindTested",function(e)
        if consumedEscape and e.keybind==tes3.keybind.escape then e.block=true; return false end
        -- A modifier releases player controls before its menu activates on the
        -- next frame. Native Rest tests can still see the opening T press then.
        if active and e.keybind==tes3.keybind.rest then e.block=true; return false end
        if ready() then e.block=true; return false end
    end,{priority=1000})
    event.register("uiShowRestMenu",function(e)
        -- Suppress the native Rest/Wait UI throughout editing, including menu
        -- transitions and requests that bypass the normal keybind test.
        if active then e.block=true; return false end
    end,{priority=1000})
    event.register("activate",function(e)
        if active and e.activator==tes3.player then e.block=true; return false end
    end,{priority=1000})
    event.register("save",function(e)
        if active then
            e.block=true
            tes3.messageBox("Finish or cancel the pose before saving your game.")
            return false
        end
    end,{priority=1000})
    event.register("load",function() consumedEscape=nil; M.finish(false,true); discardCameraRestore() end,{priority=1000})
    event.register("cellChanged",function() consumedEscape=nil; M.finish(false); discardCameraRestore() end,{priority=1000})
    event.register("referenceDeactivated",function(e)
        if active and active.handle:valid() and active.handle:getObject()==e.reference then M.finish(false,true) end
    end,{priority=1000})
end
return M
