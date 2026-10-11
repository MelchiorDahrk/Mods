package.path="./MWSE/mods/?.lua;"..package.path
local v=require("MannequinPoseDesigner.math3d")
local realRig=require("MannequinPoseDesigner.rig")
local lighting=dofile("tests/focus_lighting_fixture.lua")
local floorFixture=dofile("tests/focus_floor_fixture.lua")
local count=0
local function check(ok,reason) assert(ok,reason); count=count+1 end
local flags={"controlsDisabled","mouseLookDisabled","attackDisabled","magicDisabled","jumpingDisabled","viewSwitchDisabled","vanityDisabled"}
local originalFlags={}
local playerNode={appCulled=false}
local armsNode={appCulled=false}
local player={firstPersonReference={sceneNode=armsNode}}
for i,name in ipairs(flags) do originalFlags[name]=i%2==0; player[name]=originalFlags[name] end
setmetatable(player,{__index=function(_,key) error("Unknown mobilePlayer property: "..key) end})
local function vec(x,y,z)
    return {x=x,y=y,z=z,copy=function(self) return vec(self.x,self.y,self.z) end}
end
local function rotation(label,forward,up)
    return {label=label,forward=forward and forward:copy(),up=up and up:copy(),
        copy=function(self) return rotation(self.label,self.forward,self.up) end,
        lookAt=function(self,direction,vertical)
            self.forward=direction:copy(); self.up=vertical:copy()
        end}
end
local function transform(x,label,scale)
    return {translation=vec(x,0,0),rotation=rotation(label),scale=scale,
        copy=function(self)
            local result=transform(self.translation.x,self.rotation.label,self.scale)
            result.translation=self.translation:copy()
            return result
        end}
end
local function cameraEvent(x)
    return {cameraTransform=transform(x,"world",1),armCameraTransform=transform(x+1,"arms",0.5)}
end
tes3matrix33={new=function() return rotation("designer") end}
tes3vector3={new=vec}
tes3transform={new=function(matrix,position,scale)
    local result=transform(position.x,matrix.label,scale)
    result.translation=position:copy(); result.rotation=matrix:copy()
    return result
end}
local ref={sceneNode={},cell={},orientation=vec(0,0,0.3),position=vec(0,0,0),updateLighting=function() end}
local valid,writeError,loadError,captureError,menuMode=true,false,false,false,false
local writes,removes,loads,selection={}, {}, {}, "previous.nif"
local savedNames={}
local savedPoseData={}
local failedSaves={}
local blendPoses,blendReads={},{}
local blendReadError=false
local lastReport
local bones={{name="Bip01",parent=0,translation={0,0,0},rotation=v.identity(),scale=1}}
local rigFrame={rotation=v.identity(),translation={0,0,0},scale=1}
local appliedPoses=0
local rig={vector=realRig.vector,engineVector=realRig.engineVector,clone=realRig.clone,world=realRig.world,
    reset=realRig.reset,
    anchor=realRig.anchor,cloneLocks=realRig.cloneLocks,solveLocks=realRig.solveLocks,
    pole=realRig.pole,solve=realRig.solve,
    capture=function() if captureError then error("Capture failed") end return realRig.clone(bones),{{}} end,
    chains=realRig.chains,
    bind=function() return {{}} end,
    frame=function() return rigFrame end,
    apply=function() appliedPoses=appliedPoses+1 end}
local library={cache="cache",write=function(pose,fields,definitions,apply)
    if writeError then error("Disk is full") end
    local file=(fields and "poses" or "cache").."/"..(#writes+1)..".nif"
    savedNames[#savedNames+1]=fields and fields.name or "draft"
    savedPoseData[#savedPoseData+1]=realRig.clone(pose)
    writes[#writes+1]=file
    if apply then
        local ok,err=pcall(apply,file)
        if not ok then failedSaves[#failedSaves+1]=file; error(err) end
    end
    return file
end,removeDraft=function(file) removes[#removes+1]=file end,
readProps=function() return {},false end}
function library.isDefault(file)
    return file and file:lower():gsub("\\","/"):match("^oaab/k/mann_")~=nil or false
end
function library.list() return {{file="a.nif",label="A"},{file="b.nif",label="B"}} end
function library.blendList()
    local files={
        {file="oaab/k/mann_relax.nif",label="Relaxed (Default)"},
        {file="oaab/k/mann_contrapposto.nif",label="Contrapposto (Default)"},
        {file="oaab/k/mann_adlocutio.nif",label="Adlocutio (Default)"},
        {file="oaab/k/mann_adlocutio2.nif",label="Adlocutio II (Default)"},
    }
    for _,pose in ipairs(library.list()) do files[#files+1]=pose end
    return files
end
function library.read(file)
    blendReads[#blendReads+1]=file
    if blendReadError then error("Could not read saved pose") end
    return realRig.clone(assert(blendPoses[file],"Pose is missing"))
end
local namePrompt={}
local saveMenu={}
function saveMenu.open(label,onAction,onClose)
    local prompt={label=label,onAction=onAction,onClose=onClose}
    saveMenu.current=prompt
    return prompt
end
function saveMenu.close(prompt)
    if not prompt or prompt.closed then return end
    prompt.closed=true
    menuMode=false
    prompt.onClose()
end
local mirrorMenu={}
local symmetryMenu={}
local resetMenu={}
local blendMenu={}
local groundMenu={}
function groundMenu.open(onGround,onClose)
    local prompt={onGround=onGround,onClose=onClose}
    groundMenu.current=prompt
    return prompt
end
function groundMenu.close(prompt)
    if not prompt or prompt.closed then return end
    prompt.closed=true
    menuMode=false
    prompt.onClose()
end
function resetMenu.open(boneName,onReset,onClose)
    local prompt={boneName=boneName,onReset=onReset,onClose=onClose}
    resetMenu.current=prompt
    return prompt
end
function resetMenu.close(prompt)
    if not prompt or prompt.closed then return end
    prompt.closed=true
    menuMode=false
    prompt.onClose()
end
function blendMenu.open(files,onPreview,onClose)
    local prompt={files=files,onPreview=onPreview,onClose=onClose}
    blendMenu.current=prompt
    return prompt
end
function blendMenu.close(prompt,accepted)
    if not prompt or prompt.closed then return end
    prompt.closed=true
    menuMode=false
    prompt.onClose(accepted==true)
end
function symmetryMenu.open(initial,onSelect,onClose)
    local prompt={initial=initial,onSelect=onSelect,onClose=onClose}
    symmetryMenu.current=prompt
    return prompt
end
function symmetryMenu.close(prompt)
    if not prompt or prompt.closed then return end
    prompt.closed=true
    menuMode=false
    prompt.onClose()
end
function mirrorMenu.open(initial,onAction,onClose)
    local prompt={initial=initial,onAction=onAction,onClose=onClose}
    mirrorMenu.current=prompt
    return prompt
end
function mirrorMenu.close(prompt)
    if not prompt or prompt.closed then return end
    prompt.closed=true
    menuMode=false
    prompt.onClose()
end
function namePrompt.open(initial,onSave,onClose,options)
    local prompt={initial=initial,onSave=onSave,onClose=onClose,options=options}
    namePrompt.current=prompt
    return prompt
end
function namePrompt.close(prompt)
    if not prompt or prompt.closed then return end
    prompt.closed=true
    prompt.onClose()
end
local overlayDestroyed=0
local pickTargets,lastCursor,lastSelection,lastState,hoverTarget
local function sceneNode(kind,culled)
    return {children={},appCulled=culled or false,
        isInstanceOfType=function(_,wanted) return wanted==(kind or "NiNode") end}
end
local function attach(parent,child)
    parent.children[#parent.children+1]=child
    child.parent=parent
end
local function visible(node)
    while node do
        if node.appCulled then return false end
        node=node.parent
    end
    return true
end
local sceneRoot,cameraRoot,pickRoot=sceneNode(),sceneNode(),sceneNode()
local terrain,water,sky,handlesRoot=sceneNode(),sceneNode(),sceneNode(),sceneNode()
local staticRoot,staticMesh,light=sceneNode(),sceneNode("NiTriShape"),sceneNode("NiLight")
local nativeWater,nativeRipples=sceneNode(),sceneNode()
local waterController={waterShown=true,waterPlane=nativeWater,rippleNode=nativeRipples}
local terrainRoot,terrainShape=sceneNode(),sceneNode("NiTriShape")
attach(terrainRoot,terrainShape)
local function nativeCameraRoot(x,label,scale)
    local result=sceneNode()
    result.translation=vec(x,0,0); result.rotation=rotation(label); result.scale=scale
    result.updates=0
    function result:copyTransforms(source)
        self.translation=source.translation:copy(); self.rotation=source.rotation:copy(); self.scale=source.scale
    end
    function result:update(args)
        check(args.controllers==false,"Camera updates never advance animation controllers")
        self.updates=self.updates+1
    end
    return result
end
cameraRoot=nativeCameraRoot(10,"world",1)
local armCameraRoot,shadowCameraRoot=nativeCameraRoot(11,"arms",0.5),nativeCameraRoot(12,"shadow",1)
attach(sceneRoot,cameraRoot); attach(sceneRoot,pickRoot); attach(sceneRoot,terrain)
attach(sceneRoot,water); attach(sceneRoot,sky); attach(sceneRoot,handlesRoot)
attach(sceneRoot,staticRoot); attach(staticRoot,staticMesh); attach(staticRoot,light)
local overlay={create=function() return {menu={visible=true},markersMenu={visible=true},markers={}} end,
    update=function(_,s)
        if pickTargets then s.screen=pickTargets end
        s.hovered=hoverTarget
        lastCursor={s.cursor[1],s.cursor[2]}; lastSelection=s.selected
        lastState=s
    end,
    setVisible=function(ui,value,guide) ui.menu.visible=value or guide==true; ui.markersMenu.visible=value end,
    destroy=function() overlayDestroyed=overlayDestroyed+1 end}
local createOverlay=overlay.create
overlay.create=function()
    local ui=createOverlay()
    ui.native={root=handlesRoot}
    return ui
end
local highlightUpdates,highlightClears,lastHighlight=0,0,nil
local highlight={create=function() return {parts={}} end,
    update=function(_,index) highlightUpdates=highlightUpdates+1; lastHighlight=index end,
    clear=function() highlightClears=highlightClears+1 end}
package.loaded["MannequinPoseDesigner.rig"]=rig
package.loaded["MannequinPoseDesigner.library"]=library
package.loaded["MannequinPoseDesigner.overlay"]=overlay
package.loaded["MannequinPoseDesigner.metadata_prompt"]=namePrompt
package.loaded["MannequinPoseDesigner.save_menu"]=saveMenu
package.loaded["MannequinPoseDesigner.mirror_menu"]=mirrorMenu
package.loaded["MannequinPoseDesigner.symmetry_menu"]=symmetryMenu
package.loaded["MannequinPoseDesigner.reset_menu"]=resetMenu
package.loaded["MannequinPoseDesigner.blend_menu"]=blendMenu
package.loaded["MannequinPoseDesigner.ground_menu"]=groundMenu
package.loaded["MannequinPoseDesigner.highlight"]=highlight
local callbacks={}
event={register=function(name,fn) callbacks[name]=fn end,
    unregister=function(name,fn) if callbacks[name]==fn then callbacks[name]=nil end end}
local frameTimers={}
timer={frame={delayOneFrame=function(fn) frameTimers[#frameTimers+1]=fn end}}
local function nextFrame()
    local pending=frameTimers
    frameTimers={}
    for _,fn in ipairs(pending) do fn() end
end
local hud={visible=true}
local tooltipsSuppressed=false
local worldTooltipVisible=true
tes3ui={menuMode=function() return menuMode end,getViewportSize=function() return 800,600 end,
    suppressTooltip=function(value)
        tooltipsSuppressed=value
        if value then worldTooltipVisible=false end
    end,
    findMenu=function(name) assert(name=="MenuMulti"); return hud end}
local view={worldRight=vec(1,0,0),worldUp=vec(0,0,1),worldDirection=vec(0,1,0)}
local projectionHidden=false
function view:worldPointToScreenPoint(position)
    if projectionHidden then return end
    local p=realRig.vector(position)
    return {x=v.dot(p,realRig.vector(self.worldRight))*0.25,y=v.dot(p,realRig.vector(self.worldUp))*0.25}
end
local menuController={aiDisabled=false,worldDisabled=false,skyDisabled=false}
local audioController={volumeMaster=0.8,volumeEffects=0.6,volumeMusic=0.4,volumeVoice=0.7,volumeFootsteps=0.9}
local rainVolume=0.8
local rainBufferVolume=0.8*0.6*rainVolume
local rainSound=setmetatable({}, {
    __index=function(_,name) if name=="volume" then return rainVolume end end,
    __newindex=function(_,name,value)
        assert(name=="volume" and value==rainVolume,"Preserve the rain sound definition")
        rainBufferVolume=audioController.volumeMaster*audioController.volumeEffects*value
    end})
local weatherController={weathers={[4]={rainLoopSound=rainSound}}}
local worldController={menuController=menuController,simulationTimeScalar=0.75,
    audioController=audioController,weatherController=weatherController,
    worldCamera={root=sceneRoot,cameraRoot=cameraRoot},armCamera={cameraRoot=armCameraRoot},
    shadowCamera={cameraRoot=shadowCameraRoot}}
local originalMge={distantLand=true,distantStatics=true,distantWater=true,grass=false}
mge={enabled=function() return true end,render={}}
for name,value in pairs(originalMge) do mge.render[name]=value end
tes3={keybind={escape=34,activate=5,rest=20},keyTransition={downThisFrame=0,upThisFrame=1,changedThisFrame=2,isDown=3},niType={NiNode="NiNode",NiLight="NiLight"},weather={rain=4,thunder=5},worldController=worldController,dataHandler={waterController=waterController,worldLandscapeRoot=terrainRoot},mobilePlayer=player,player={cell=ref.cell,sceneNode=playerNode},animationGroup={idle=0},scanCode={escape=1,enter=28,numpadEnter=156,tab=15,r=19,x=45,z=44,y=21,l=38,g=34,f=33,m=50,s=31,b=48,t=20,h=35,v=47,backspace=14,numpad1=79,numpad2=80,numpad3=81,numpad4=75,numpad6=77,numpad7=71,numpad8=72,numpad9=73,add=78,subtract=74,one=2,three=4,seven=8,nine=10,addRow=13,subtractRow=12,keyLeft=203,keyRight=205,keyUp=200,keyDown=208},
    makeSafeObjectHandle=function() return {valid=function() return valid end,getObject=function() return ref end} end,
    getCameraPosition=function() return lighting.vector(cameraRoot.translation.x,cameraRoot.translation.y,cameraRoot.translation.z) end,
    getCamera=function() return view end,
    messageBox=function(format,...) lastReport=string.format(format,...) end,
    skipAnimationFrame=function() end,
    loadAnimation=function(p) loads[#loads+1]=p.file or "default"; if loadError then error("Load failed") end; ref.sceneNode={} end,
    playAnimation=function() end}
floorFixture.install(sceneRoot,lighting)
mwse={log=function() end}
local suspended=false
local api={canPose=function()
        -- Rebuilt scenes are attached before starting the next session.
        for _,child in pairs(pickRoot.children) do child.parent=nil end
        pickRoot.children={}
        if ref.sceneNode then
            lighting.node(ref.sceneNode)
            ref.sceneNode.children=ref.sceneNode.children or {}
            ref.sceneNode.appCulled=false
            ref.sceneNode.isInstanceOfType=function(_,wanted) return wanted=="NiNode" end
            attach(pickRoot,ref.sceneNode)
        end
        return true
    end,getSelectedFile=function() return selection end,
    setSelectedFile=function(_,file) selection=file end,
    suspend=function(_,value) suspended=value end,
    select=function(_,file)
        if loadError then return false end
        selection=file; loads[#loads+1]=file; ref.sceneNode={}
        return true
    end}
local session=require("MannequinPoseDesigner.session")
session.register()
local function controlsRestored()
    for _,floor in ipairs(floorFixture.floors) do
        check(floor.parent==nil and floor.appCulled,"All session exit paths remove the focus floor")
    end
    for _,light in ipairs(lighting.lights) do
        check(not light.enabled and #light.affectedNodes==0,"All session exit paths remove the temporary focus light")
    end
    -- The engine resumes cameraControl after focus releases the clock.
    if not session.isActive() then callbacks.cameraControl(cameraEvent(99)) end
    check(not tooltipsSuppressed,"Cleanup releases world tooltips after every session exit")
    check(not playerNode.appCulled and not armsNode.appCulled,"Completed cleanup restores both player models")
    check(not menuController.aiDisabled and not menuController.worldDisabled and worldController.simulationTimeScalar==0.75,
        "Cleanup restores AI, world rendering and the original simulation speed")
    check(not menuController.skyDisabled and visible(terrain) and visible(water) and visible(staticMesh),
        "Cleanup restores sky and surrounding scene visibility")
    check(waterController.waterShown and visible(nativeWater) and visible(nativeRipples),
        "Cleanup restores native water rendering and independent water nodes")
    check(not terrainRoot.appCulled and not terrainShape.appCulled,"Cleanup restores the separate landscape pass")
    check(hud.visible,"Cleanup restores the gameplay HUD after every session exit")
    check(audioController.volumeMaster==0.8 and audioController.volumeEffects==0.6 and audioController.volumeMusic==0.4
        and audioController.volumeVoice==0.7 and audioController.volumeFootsteps==0.9,
        "Cleanup restores master volume and preserves the other channels after every session exit")
    check(rainBufferVolume==0.8*0.6*rainVolume,"Cleanup restores the native rain buffer after every session exit")
    for name,value in pairs(originalMge) do check(mge.render[name]==value,"Restore MGE feature "..name) end
    for _,name in ipairs(flags) do check(player[name]==originalFlags[name],"Restore original flag "..name) end
    callbacks.keyUp({keyCode=tes3.scanCode.escape})
    nextFrame()
end
check(session.start(ref,api),"Start designer")
check(tooltipsSuppressed and not worldTooltipVisible,"Entry immediately hides an existing reticle tooltip")
check(not session.start(ref,api) and tooltipsSuppressed,"A refused second entry keeps the active editor's tooltip suppression")
tooltipsSuppressed=false; worldTooltipVisible=true
callbacks.render({})
check(tooltipsSuppressed and not worldTooltipVisible,"Rendering hides reticle tooltips again if suppression is reset")
check(session.isActive() and writes[1]=="cache/1.nif","Session starts with a real draft NIF")
check(suspended,"Existing pose playback is suspended during editing")
check(#loads==0,"Entering editor must preserve the mannequin's current animation")
callbacks.simulated({})
check(session.isActive() and #removes==0,"First simulation frame keeps the editor open with the same scene node")
check(highlightUpdates>=1,"Current bone is highlighted during editing")
for _,name in ipairs(flags) do check(player[name],"Disable "..name) end
local e={}; check(callbacks.save(e)==false and e.block,"Block save during transient edit")
e={}; check(callbacks.keybindTested(e)==false and e.block,"Suppress game keybinds")
local helpWrites=#writes
local helpBones,helpLocks=lastState.bones,lastState.locks
check(not lastState.expandedControls,"The editor starts with only the compact guide")
local controlsMenu=lastState.overlay.menu
check(callbacks.keyDown({keyCode=tes3.scanCode.h})==false and lastState.expandedControls,
    "The existing H shortcut expands categorized controls in place")
callbacks.enterFrame({menuMode=false})
check(lastState.overlay.menu==controlsMenu and controlsMenu.visible and lastState.overlay.markersMenu.visible
    and player.controlsDisabled and not menuMode,"Expanded controls reuse the original sidebar while keeping posing active")
callbacks.keyDown({keyCode=tes3.scanCode.r})
check(lastState.mode=="Rotate","Rotation mode remains available with help open")
callbacks.keyDown({keyCode=tes3.scanCode.g})
check(lastState.mode=="IK","Movement mode remains available with help open")
local helpDistance=lastState.orbit.distance
callbacks.mouseWheel({delta=1})
check(lastState.orbit.distance<helpDistance,"Wheel still zooms with controls expanded")
helpDistance=lastState.orbit.distance
callbacks.mouseAxis({deltaX=100,deltaY=0})
callbacks.mouseWheel({delta=-1})
check(lastState.orbit.distance>helpDistance and lastState.expandedControls and session.isActive(),
    "Wheel over the expanded sidebar zooms without closing pose mode or scrolling controls")
for _,button in ipairs({1,2}) do
    callbacks.mouseButtonDown({button=button})
    check(lastState.drag and lastState.drag.button==button,
        "The expanded sidebar keeps the default camera drag input")
    callbacks.mouseButtonUp({button=button})
end
callbacks.mouseAxis({deltaX=-100,deltaY=0})
callbacks.keyDown({keyCode=tes3.scanCode.m})
local helpMirror=lastState.mirrorPrompt
check(helpMirror and lastState.expandedControls,"Other dialogs preserve expanded controls")
menuMode=true; callbacks.enterFrame({menuMode=true})
check(not controlsMenu.visible,"Modal dialogs temporarily hide the existing controls")
mirrorMenu.close(helpMirror); menuMode=false; callbacks.enterFrame({menuMode=false})
check(controlsMenu.visible and lastState.expandedControls and lastState.overlay.menu==controlsMenu and player.controlsDisabled,
    "Closing a dialog restores expanded controls in the same sidebar")
check(callbacks.keyDown({keyCode=tes3.scanCode.h})==false and not lastState.expandedControls and session.isActive(),
    "H again collapses controls without ending the editing session")
callbacks.keyDown({keyCode=tes3.scanCode.h})
check(callbacks.keyDown({keyCode=tes3.scanCode.escape})==false and not lastState.expandedControls and session.isActive(),
    "Escape collapses controls before it cancels editing")
check(callbacks.keyDown({keyCode=tes3.scanCode.escape})==false and session.isActive(),"Repeating the help-close Escape cannot cancel editing")
callbacks.keyUp({keyCode=tes3.scanCode.escape}); nextFrame()
check(lastState.bones==helpBones and lastState.locks==helpLocks and #writes==helpWrites and #lastState.undo==0,
    "Opening and closing help preserves bones, locks, history and checkpoints")
callbacks.enterFrame({menuMode=false})
check(lastState.overlay.menu.visible and player.controlsDisabled,"Closing help restores the compact guide and editor input ownership")
ref.orientation.z=1.8
session.finish(false)
check(highlightClears==1,"Cancel clears the mesh highlight")
check(not session.isActive() and ref.orientation.z==0.3,"Cancel restores orientation")
check(selection=="previous.nif" and #loads==0,"Cancel leaves the original animation untouched")
check(not suspended,"Cancelling resumes normal pose playback")
check(#removes==1,"Draft removed after cancellation")
controlsRestored()
worldTooltipVisible=true
callbacks.render({})
check(not tooltipsSuppressed and worldTooltipVisible,"Rendering after exit leaves gameplay tooltips available")

local function focusKey()
    callbacks.keyDown({keyCode=tes3.scanCode.f})
    callbacks.keyUp({keyCode=tes3.scanCode.f})
end
local function focusEnabled()
    local light=lastState.focus.light
    local floor=lastState.focus.floor
    local position=lastState.groundFrame.translation
    check(floor.parent==sceneRoot and visible(floor)
        and floor.worldBoundOrigin:distance(lighting.vector(unpack(position)))<1e-8,
        "Focus displays the grid at the session's original grounding plane")
    check(light.scene==ref.sceneNode and ref.sceneNode.renderEffects[1]==light.source and light.source.enabled,
        "Focused editing keeps the mannequin and outfit lit")
    check(tooltipsSuppressed,"World tooltips stay hidden throughout focused editing")
    check(not hud.visible,"Focus hides the gameplay HUD")
    check(audioController.volumeMaster==0,"All non-music mixes stay muted throughout focused editing")
    check(audioController.volumeMusic==0.4,"Focus leaves the music volume unchanged")
    check(rainBufferVolume==0,"Native rain stays muted throughout focused editing")
    check(lastState.focus and menuController.aiDisabled and not menuController.worldDisabled and worldController.simulationTimeScalar==0,
        "Focus mode disables AI and freezes time while leaving the mannequin renderer enabled")
    check(visible(ref.sceneNode) and visible(handlesRoot) and visible(cameraRoot) and visible(light),
        "Focus preserves the mannequin, pearls, camera, and lighting")
    check(not visible(terrain) and not visible(water) and not visible(staticMesh) and menuController.skyDisabled,
        "Focus hides terrain, water, static geometry and sky")
    check(not waterController.waterShown and not visible(nativeWater) and not visible(nativeRipples),
        "Focus also suppresses native water rendered outside the world root")
    for name in pairs(originalMge) do check(not mge.render[name],"Hide MGE feature "..name) end
end
check(session.start(ref,api) and not lastState.focus,"Each session starts with focus mode off")
callbacks.keyDown({keyCode=tes3.scanCode.f})
focusEnabled()
callbacks.keyDown({keyCode=tes3.scanCode.f})
focusEnabled() -- Auto-repeat must not flicker focus on/off.
terrain.appCulled=false -- Model the engine updating scene flags before rendering.
waterController.waterShown=true; nativeWater.appCulled=false
hud.visible=true
callbacks.render({})
check(not visible(terrain) and visible(ref.sceneNode),"The render event reapplies isolation after scene updates")
check(not waterController.waterShown and not visible(nativeWater),"The render event suppresses regenerated native water")
check(not hud.visible,"The render event hides a reactivated gameplay HUD")
-- No cameraControl or simulation events occur here: frozen camera movement must
-- reach the native scene transforms through real frame/render callbacks.
local function cameraPosition() return realRig.vector(cameraRoot.translation) end
local function positionChanged(before) return v.length(v.sub(cameraPosition(),before))>1e-6 end
local beforeCamera=cameraPosition()
callbacks.mouseButtonDown({button=2})
callbacks.mouseAxis({deltaX=12,deltaY=-5})
callbacks.mouseButtonUp({button=2})
callbacks.enterFrame({menuMode=false})
check(positionChanged(beforeCamera) and worldController.simulationTimeScalar==0,
    "Middle-mouse pan changes the rendered camera while time remains frozen")
check(armCameraRoot.translation.x==cameraRoot.translation.x and armCameraRoot.scale==0.5,
    "Frozen camera updates preserve the independent first-person camera scale")
beforeCamera=cameraPosition()
callbacks.mouseWheel({delta=1})
callbacks.render({})
check(positionChanged(beforeCamera),"Wheel zoom changes the rendered camera without a cameraControl event")
beforeCamera=cameraPosition()
callbacks.mouseButtonDown({button=2})
callbacks.mouseAxis({deltaX=0,deltaY=10,isShiftDown=true})
callbacks.mouseButtonUp({button=2})
callbacks.render({})
check(positionChanged(beforeCamera),"Shift-middle drag moves the frozen camera in depth")
beforeCamera=cameraPosition()
callbacks.mouseButtonDown({button=1})
callbacks.mouseAxis({deltaX=8,deltaY=7})
callbacks.mouseButtonUp({button=1})
callbacks.render({})
check(positionChanged(beforeCamera) and shadowCameraRoot.translation.z==cameraRoot.translation.z,
    "Tilt changes the frozen rendered view and keeps the shadow camera in sync")
check(lastState.originalCamera.camera.translation.x==10 and lastState.originalCamera.arms.translation.x==11,
    "Repeated frozen camera updates retain the original gameplay transforms")
beforeCamera=cameraPosition(); menuMode=true
callbacks.mouseWheel({delta=-1}); callbacks.render({})
check(not positionChanged(beforeCamera),"Modal menus stop frozen camera input and direct camera writes")
menuMode=false
terrainRoot.appCulled=false; terrainShape.appCulled=false
callbacks.render({})
check(terrainRoot.appCulled and terrainShape.appCulled,"The render event hides regenerated terrain geometry")
local beforeApply=appliedPoses
callbacks.enterFrame({menuMode=false})
check(session.isActive() and appliedPoses>beforeApply,"Frozen editing updates the pose without a simulation event")
callbacks.mouseButtonDown({button=0})
callbacks.mouseAxis({deltaX=10,deltaY=0})
callbacks.mouseButtonUp({button=0})
check(lastState.bones[1].translation[1]>0,"Bone dragging works while time is frozen")
callbacks.keyDown({keyCode=tes3.scanCode.enter})
hud.visible=true
callbacks.render({})
check(namePrompt.current and not namePrompt.current.closed and not hud.visible,
    "The name dialog remains open while focus continues hiding the gameplay HUD")
callbacks.keyDown({keyCode=tes3.scanCode.f})
check(lastState.focus,"Typing F in the name dialog does not toggle focus")
check(callbacks.keyUp({keyCode=tes3.scanCode.f})==nil,"Modal F release passes through and clears the repeat guard")
namePrompt.close(namePrompt.current)
focusEnabled()
focusKey()
check(not lastState.focus and session.isActive(),"F toggles focus off without ending the edit")
check(tooltipsSuppressed,"Leaving focus keeps world tooltips hidden until the designer closes")
check(hud.visible,"F restores the gameplay HUD immediately when focus is turned off")
check(audioController.volumeMaster==0.8,"F immediately restores master volume while editing continues")
check(rainBufferVolume==0.8*0.6*rainVolume,"F immediately restores the native rain buffer while editing continues")
check(not menuController.aiDisabled and not menuController.worldDisabled and worldController.simulationTimeScalar==0.75,
    "Toggling off restores the captured settings")
focusKey()
writeError=true
session.finish(true,false,{id="Focus_Retry",name="Focus Retry"})
check(session.isActive(),"A failed save keeps focus editing active")
focusEnabled()
writeError=false
session.finish(true,false,{id="Focus_Retry",name="Focus Retry"})
check(not session.isActive(),"Saving successfully ends focus editing")
controlsRestored()

-- Preserve independently disabled console settings and an already frozen clock.
for _,settings in ipairs({{true,false,2.5},{false,true,0},{true,true,0.25}}) do
    menuController.aiDisabled,menuController.worldDisabled,worldController.simulationTimeScalar=unpack(settings)
    check(session.start(ref,api),"Start with existing focus-related settings")
    focusKey()
    focusEnabled()
    focusKey()
    check(menuController.aiDisabled==settings[1] and menuController.worldDisabled==settings[2]
        and worldController.simulationTimeScalar==settings[3],"Focus-off preserves existing AI/world/time settings")
    -- A new activation captures the latest settings, not a stale first snapshot.
    menuController.aiDisabled,menuController.worldDisabled,worldController.simulationTimeScalar=false,false,0.75
    focusKey()
    session.finish(false)
    controlsRestored()
end

for _,boundary in ipairs({"escape","load","cellChanged","scene","reference","playerCell"}) do
    check(session.start(ref,api),"Start focused session before "..boundary)
    focusKey()
    if boundary=="escape" then
        menuMode=true
        callbacks.keyDown({keyCode=tes3.scanCode.escape})
        menuMode=false
    elseif boundary=="load" or boundary=="cellChanged" then
        callbacks[boundary]({})
    else
        if boundary=="scene" then ref.sceneNode={}
        elseif boundary=="reference" then valid=false
        else tes3.player.cell={} end
        callbacks.enterFrame({menuMode=false})
    end
    check(not session.isActive(),"Frozen lifecycle checks close the session on "..boundary)
    valid=true
    tes3.player.cell=ref.cell
    controlsRestored()
end

check(session.start(ref,api),"Start before a partial focus activation failure")
local savedController=tes3.worldController
tes3.worldController=setmetatable({menuController=menuController,worldCamera=worldController.worldCamera,
    audioController=audioController,weatherController=weatherController},{
    __index=function(_,name) if name=="simulationTimeScalar" then return 0.75 end end,
    __newindex=function() error("Simulation clock unavailable") end})
focusKey()
check(not session.isActive() and not menuController.aiDisabled and not menuController.worldDisabled,
    "A failed time freeze restores AI and scene/MGE settings already changed")
tes3.worldController=savedController
controlsRestored()

check(session.start(ref,api),"Start camera-exit regression")
local editedCamera=cameraEvent(10)
callbacks.cameraControl(editedCamera)
check(playerNode.appCulled and armsNode.appCulled,"Both player models are hidden at the designer camera")
menuMode=true
callbacks.keyDown({keyCode=tes3.scanCode.escape})
check(not session.isActive(),"Escape exits while the game is paused")
callbacks.enterFrame({menuMode=true})
check(playerNode.appCulled and armsNode.appCulled,"Paused exit keeps both models hidden until their cameras can return")
menuMode=false
local restoredCamera=cameraEvent(99)
callbacks.cameraControl(restoredCamera)
check(restoredCamera.cameraTransform.translation.x==10 and restoredCamera.armCameraTransform.translation.x==11,
    "The first camera update after exit restores both original camera positions")
check(restoredCamera.cameraTransform.rotation.label=="world" and restoredCamera.armCameraTransform.rotation.label=="arms"
    and restoredCamera.armCameraTransform.scale==0.5,"Camera restoration preserves the independent arm transform")
check(not playerNode.appCulled and not armsNode.appCulled,"Models become visible with the restored cameras")
local nextCamera=cameraEvent(100)
callbacks.cameraControl(nextCamera)
check(nextCamera.cameraTransform.translation.x==100,"Camera restoration runs once")
controlsRestored()

playerNode.appCulled=true
check(session.start(ref,api),"Start with an already hidden player model")
callbacks.cameraControl(cameraEvent(20))
session.finish(true,false,{id="Camera_Pose",name="Camera Pose"})
check(playerNode.appCulled and armsNode.appCulled,"Saving also defers visibility until camera restoration")
callbacks.cameraControl(cameraEvent(99))
check(playerNode.appCulled and not armsNode.appCulled,"Exit preserves each model's original culling flag")
playerNode.appCulled=false
controlsRestored()

check(session.start(ref,api),"Start before a rapid restart")
callbacks.cameraControl(cameraEvent(30))
session.finish(false)
check(session.start(ref,api),"Restart before the pending camera update")
callbacks.cameraControl(cameraEvent(99))
check(playerNode.appCulled and armsNode.appCulled,"A rapid restart keeps both player models hidden")
session.finish(false)
restoredCamera=cameraEvent(100)
callbacks.cameraControl(restoredCamera)
check(restoredCamera.cameraTransform.translation.x==30 and not playerNode.appCulled and not armsNode.appCulled,
    "Rapid restart retains the original gameplay camera and visibility")
controlsRestored()

for _,boundary in ipairs({"load","cellChanged"}) do
    check(session.start(ref,api),"Start before a pending exit and "..boundary)
    callbacks.cameraControl(cameraEvent(40))
    session.finish(false)
    callbacks[boundary]({})
    check(not playerNode.appCulled and not armsNode.appCulled,"Discarding a pending camera on "..boundary.." releases visibility")
    nextCamera=cameraEvent(100)
    callbacks.cameraControl(nextCamera)
    check(nextCamera.cameraTransform.translation.x==100,"No stale camera is applied after "..boundary)
    controlsRestored()
end

check(session.start(ref,api),"Start before a camera-restoration failure")
callbacks.cameraControl(cameraEvent(50))
session.finish(false)
callbacks.cameraControl(setmetatable({},{__newindex=function() error("Camera unavailable") end}))
check(not playerNode.appCulled and not armsNode.appCulled,"Camera-restoration errors release both hidden models")
controlsRestored()

check(session.start(ref,api),"Start before an external menu pauses the game")
menuMode=true
callbacks.keyDown({keyCode=tes3.scanCode.escape})
check(not session.isActive(),"Escape cancels even after menu mode begins")
menuMode=false
controlsRestored()

-- Native keybind tests run after keyDown, even if keyDown claimed the event.
-- Model the same Escape press after cleanup has released the active session.
local function escapeTest(transition)
    local e={keybind=tes3.keybind.escape,transition=transition or tes3.keyTransition.downThisFrame,result=true}
    callbacks.keybindTested(e)
    return not e.block and e.result
end
for _,focused in ipairs({false,true}) do
    check(session.start(ref,api),"Start Escape consumption regression")
    callbacks.cameraControl(cameraEvent(60))
    local scene=ref.sceneNode
    local originalLight={name="native cell lighting"}
    scene:attachEffect(originalLight); scene:updateEffects()
    if focused then focusKey(); callbacks.render({}) end
    check(not escapeTest(),"The native Escape test is blocked before editor cleanup")
    check(callbacks.keyDown({keyCode=tes3.scanCode.escape})==false and not session.isActive(),
        "Escape immediately cancels the designer with focus on or off")
    if escapeTest() then menuMode=true end
    check(not menuMode,"The same Escape press cannot open the pause menu after cleanup")
    check(#scene.effectList==1 and scene.effectList[1]==originalLight
        and #scene.renderEffects==1 and scene.renderEffects[1]==originalLight,
        "Escape removes focus fill and preserves the original rendered lighting")
    for _,transition in pairs(tes3.keyTransition) do
        check(not escapeTest(transition),"The consumed Escape stays blocked for every native transition test")
    end
    check(callbacks.keyDown({keyCode=tes3.scanCode.escape})==false and not escapeTest(),
        "Holding or repeating Escape cannot open the pause menu after exit")
    local unrelated={keybind=tes3.keybind.activate,result=true}
    check(callbacks.keybindTested(unrelated)==nil and not unrelated.block and unrelated.result,
        "Gameplay keybinds resume immediately while the exit Escape is held")
    local gameplayCamera=cameraEvent(99)
    callbacks.cameraControl(gameplayCamera)
    check(gameplayCamera.cameraTransform.translation.x==60 and gameplayCamera.armCameraTransform.translation.x==61,
        "Escape returns both cameras to their original gameplay transforms")
    check(callbacks.keyUp({keyCode=tes3.scanCode.escape})==false
        and not escapeTest(tes3.keyTransition.upThisFrame),"The release frame also consumes native Escape tests")
    nextFrame()
    check(callbacks.keyDown({keyCode=tes3.scanCode.escape})==nil and escapeTest(),
        "A fresh Escape press after release opens the ordinary game menu")
    controlsRestored()
end

check(session.start(ref,api),"Start before a queued Escape release and rapid restart")
callbacks.keyDown({keyCode=tes3.scanCode.escape})
callbacks.keyUp({keyCode=tes3.scanCode.escape})
check(session.start(ref,api),"Restart before the old Escape release timer runs")
callbacks.keyDown({keyCode=tes3.scanCode.escape})
nextFrame()
check(not escapeTest(),"A stale release timer cannot clear the new session's consumed Escape")
controlsRestored()

for _,boundary in ipairs({"load","cellChanged"}) do
    check(session.start(ref,api),"Start Escape consumption before "..boundary)
    callbacks.keyDown({keyCode=tes3.scanCode.escape})
    callbacks.keyUp({keyCode=tes3.scanCode.escape})
    callbacks[boundary]({})
    nextFrame()
    check(escapeTest(),"Lifecycle changes release the consumed Escape on "..boundary)
    controlsRestored()
end

captureError=true
check(not session.start(ref,api) and not session.isActive(),"Start failure cleans up")
controlsRestored(); captureError=false

check(session.start(ref,api),"Restart")
local beforePrompt=#writes
callbacks.keyDown({keyCode=tes3.scanCode.enter})
check(namePrompt.current and #writes==beforePrompt,"Enter prompts for a name before writing")
tooltipsSuppressed=false; worldTooltipVisible=true
callbacks.render({})
check(tooltipsSuppressed and not worldTooltipVisible,"The name dialog keeps world tooltips suppressed without focus")
check(player.controlsDisabled==originalFlags.controlsDisabled,"Text dialog releases the player's control lock")
check(callbacks.keyDown({keyCode=tes3.scanCode.z})==nil,"Modal dialog keys pass through to text input")
check(callbacks.keyDown({keyCode=tes3.scanCode.t})==nil,"T remains available to the name field")
e={keybind=tes3.keybind.rest,result=true}
check(callbacks.keybindTested(e)==false and e.block,"Typing T cannot invoke Rest while naming a pose")
e={allowRest=true,scripted=false}
check(callbacks.uiShowRestMenu(e)==false and e.block,"Rest/Wait cannot take over the name dialog")
check(callbacks.keyDown({keyCode=tes3.scanCode.escape})==nil and escapeTest() and session.isActive(),
    "Escape belongs to the name dialog without consuming the editor-exit keybind")
namePrompt.close(namePrompt.current)
check(session.isActive(),"Canceling the name prompt keeps editing")
check(player.controlsDisabled,"Closing the dialog restores the editor's control lock")
callbacks.keyDown({keyCode=tes3.scanCode.enter})
local pending=namePrompt.current
namePrompt.close(pending)
pending.onSave({id="Guard_Stance",name="Guard Stance"})
check(not session.isActive() and savedNames[#savedNames]=="Guard Stance","Named save passes the name to the library")
controlsRestored()

check(session.start(ref,api),"Restart after named save")
writeError=true
session.finish(true,false,{id="Second_Pose",name="Second Pose"})
check(session.isActive() and selection:match("^poses/"),"Failed save keeps session and old selection")
check(tooltipsSuppressed,"A failed save keeps world tooltips hidden while editing continues")
writeError=false
session.finish(true,false,{id="Second_Pose",name="Second Pose"})
check(not session.isActive() and selection:match("^poses/"),"Successful save selects actual NIF")
check(highlightClears>=2,"Saving removes the tint before animation replacement")
controlsRestored()

check(session.start(ref,api),"Restart before pose application failure")
loadError=true
session.finish(true,false,{id="Retry_Pose",name="Retry Pose"})
check(session.isActive() and #failedSaves==1,"Failed pose application removes the new bundle")
loadError=false
session.finish(true,false,{id="Retry_Pose",name="Retry Pose"})
check(not session.isActive(),"Pose can be saved again under the same name")
controlsRestored()

check(session.start(ref,api),"Restart after saving")
ref.sceneNode={}
callbacks.simulated({})
check(not session.isActive(),"Scene rebuild aborts before stale bone access")
controlsRestored()

check(session.start(ref,api),"Start before load")
ref.orientation.z=2
callbacks.load({})
check(not session.isActive() and ref.orientation.z==0.3,"Load releases session and world rotation")
controlsRestored()

check(session.start(ref,api),"Start before disappearing reference")
valid=false
callbacks.simulated({})
check(not session.isActive(),"Invalid safe handle releases session")
controlsRestored(); valid=true

check(session.start(ref,api),"Start before failed drag checkpoint")
callbacks.mouseButtonDown({button=0})
callbacks.mouseAxis({deltaX=10,deltaY=0})
callbacks.mouseButtonUp({button=0})
writeError=true
callbacks.keyDown({keyCode=tes3.scanCode.z,isControlDown=true})
check(not session.isActive(),"Checkpoint failure releases session")
controlsRestored(); writeError=false

bones[2]={name="Bip01 L Hand",parent=1,translation={10,0,0},rotation=v.identity(),scale=1}
pickTargets={{x=0,y=0},{x=160,y=90}}
check(session.start(ref,api),"Start pointer-selection regression")
local hoverHistory,hoverWrites=#lastState.undo,#writes
hoverTarget=2
callbacks.mouseAxis({deltaX=162,deltaY=-91})
callbacks.enterFrame({})
check(lastCursor[1]==162 and lastCursor[2]==91,"Mouse movement reaches the overlay in the screen coordinates used for picking")
check(lastState.hovered==2 and lastState.selected==1 and lastHighlight==2,
    "The body tint follows this frame's hovered bone without changing selection")
check(#lastState.undo==hoverHistory and #writes==hoverWrites,"Hover creates no pose history or checkpoint")
hoverTarget=nil; callbacks.enterFrame({})
check(lastHighlight==1,"Leaving hover restores the selected body's tint")
hoverTarget=2; callbacks.enterFrame({})
callbacks.mouseButtonDown({button=1}); callbacks.enterFrame({})
check(not lastState.hovered and lastHighlight==1,"Camera drags restore selection tint")
callbacks.mouseButtonUp({button=1}); callbacks.enterFrame({})
check(lastHighlight==2,"Hover preview resumes after a camera drag")
callbacks.keyDown({keyCode=tes3.scanCode.v}); callbacks.enterFrame({})
check(not lastState.hovered and lastHighlight==1,"Hiding handles restores selection tint")
callbacks.keyDown({keyCode=tes3.scanCode.v}); callbacks.enterFrame({})
menuMode=true; callbacks.enterFrame({menuMode=true})
check(not lastState.hovered and lastHighlight==1,"A modal restores the selected body's tint even while the overlay is hidden")
menuMode=false; callbacks.enterFrame({})
callbacks.mouseButtonDown({button=0}); callbacks.mouseButtonUp({button=0})
callbacks.enterFrame({})
check(lastSelection==2,"Clicking by the moved pointer selects the nearby hand instead of the original root bone")
hoverTarget=nil
callbacks.mouseAxis({deltaX=1000,deltaY=-1000}); callbacks.enterFrame({})
check(lastCursor[1]==400 and lastCursor[2]==300,"The editing pointer stays inside the viewport")
session.finish(false)
controlsRestored()
local function same(a,b)
    for i=1,#a do if math.abs(a[i]-b[i])>1e-4 then return false end end
    return true
end
local function press(scan,ctrl,shift)
    callbacks.keyDown({keyCode=tes3.scanCode[scan],isControlDown=ctrl,isShiftDown=shift})
    callbacks.enterFrame({})
    check(session.isActive(),"Editor input leaves the session active: "..tostring(lastReport))
end
local function release(scan)
    local result=callbacks.keyUp({keyCode=tes3.scanCode[scan]})
    callbacks.enterFrame({})
    check(session.isActive(),"Key release leaves the session active")
    return result
end
local function select(index)
    while lastState.selected~=index do press("tab") end
end
local function drag(dx,dy,alt,ctrl)
    callbacks.mouseButtonDown({button=0,isAltDown=alt})
    callbacks.mouseAxis({deltaX=dx,deltaY=dy,isControlDown=ctrl})
    callbacks.mouseButtonUp({button=0})
    callbacks.enterFrame({})
    check(session.isActive(),"Editor drag completes without errors")
end
local function moveCursor(x,y,ctrl)
    callbacks.mouseAxis({deltaX=x-lastState.cursor[1],deltaY=lastState.cursor[2]-y,isControlDown=ctrl})
    check(session.isActive(),"Angular mouse input leaves the session active: "..tostring(lastReport))
end
local function beginRotation(alt)
    local world=realRig.world(lastState.bones,rigFrame)
    local joint=view:worldPointToScreenPoint(realRig.engineVector(world[lastState.selected].translation))
    moveCursor(joint.x+60,joint.y)
    callbacks.mouseButtonDown({button=0,isAltDown=alt})
    check(lastState.drag and lastState.drag.startRotation,"Rotation captures its starting state")
    return lastState.drag
end
local function orbit(angle,ctrl,radius)
    local state=lastState.drag
    moveCursor(state.jointX+(radius or 60)*math.cos(angle),state.jointY-(radius or 60)*math.sin(angle),ctrl)
end
local function rotate(angle,ctrl,alt)
    local state=beginRotation(alt)
    orbit(angle,ctrl)
    callbacks.mouseButtonUp({button=0}); callbacks.enterFrame({})
    return state
end

-- Stock poses put Pelvis within a millionth of a unit of Bip01. Even a
-- subpixel difference must not replace the amber ROOT handle when dragging it.
bones={
    {name="Bip01",parent=0,translation={0,0,50},rotation=v.identity(),scale=1},
    {name="Bip01 Pelvis",parent=1,translation={0.000001,0,0},rotation=v.identity(),scale=1},
    {name="Bip01 Spine",parent=2,translation={0,0,12},rotation=v.identity(),scale=1},
}
rigFrame={rotation=v.axisAngle({0,0,1},0.7),translation={100,-50,20},scale=1.6}
for _,focused in ipairs({false,true}) do
    pickTargets={{x=0,y=0},{x=0.000001,y=0},{x=80,y=80}}
    check(session.start(ref,api),"Start overlapping root/pelvis drag regression")
    if focused then press("f") end
    moveCursor(6,0); press("g")
    local before=realRig.clone(lastState.bones)
    local beforeWorld=realRig.world(before,rigFrame)
    local history,written=#lastState.undo,#writes
    callbacks.mouseButtonDown({button=0})
    check(lastState.selected==1 and lastState.drag.mode=="IK",
        "A slightly nearer overlapping pelvis cannot steal the selected root drag")
    local expected=v.scale(realRig.vector(view.worldRight),10*lastState.orbit.distance*0.0015)
    callbacks.mouseAxis({deltaX=10,deltaY=0})
    callbacks.mouseButtonUp({button=0}); callbacks.enterFrame({})
    local afterWorld=realRig.world(lastState.bones,rigFrame)
    for i=1,#bones do
        check(same(v.sub(afterWorld[i].translation,beforeWorld[i].translation),expected),
            "Root dragging translates every joint through the scaled/rotated parent frame")
        check(same(lastState.bones[i].rotation,before[i].rotation),"Root translation preserves rotations")
    end
    check(#lastState.undo==history+1 and #writes==written+1,"Root drag creates one undo step and checkpoint")
    local moved=v.copy(lastState.bones[1].translation)
    press("z",true)
    check(same(lastState.bones[1].translation,before[1].translation),"Undo restores the root translation")
    press("y",true)
    check(same(lastState.bones[1].translation,moved),"Redo restores the root movement")

    -- Ctrl-Z while the mouse is still held must own the partial root move.
    -- Reproduce the native grid rejection during the same focused gesture.
    moveCursor(6,0)
    local dragStart=v.copy(lastState.bones[1].translation)
    local savedRadius=ref.sceneNode.worldBoundRadius
    local focusState=lastState.focus
    local validGrid=focusState and focusState.gridMesh
    local undoSteps,writeCount=#lastState.undo,#writes
    callbacks.mouseButtonDown({button=0})
    callbacks.mouseAxis({deltaX=12,deltaY=-4})
    local partial=v.copy(lastState.bones[1].translation)
    check(lastState.drag.dirty and not same(partial,dragStart),"Root drag changes the pose before undo")
    if focused then
        floorFixture.rejectVertexCount=736
        ref.sceneNode.worldBoundRadius=180
        callbacks.render({})
        check(session.isActive() and lastState.focus==focusState and focusState.gridMesh==validGrid,
            "A rejected grid reload during root movement preserves the active focus session")
    end
    press("z",true)
    check(not lastState.drag and lastState.axis==nil and same(lastState.bones[1].translation,dragStart)
        and #lastState.undo==undoSteps and #lastState.redo==1 and #writes==writeCount+1,
        "Undo during a root drag ends the gesture, restores its start and checkpoints once")
    callbacks.mouseAxis({deltaX=15,deltaY=3})
    callbacks.mouseButtonUp({button=0}); callbacks.enterFrame({})
    check(same(lastState.bones[1].translation,dragStart) and #writes==writeCount+1,
        "Held-mouse movement and the later release cannot reapply or checkpoint an undone drag")
    press("y",true)
    check(same(lastState.bones[1].translation,partial) and #lastState.undo==undoSteps+1
        and #lastState.redo==0 and #writes==writeCount+2,"Redo restores the exact partial root move")
    if focused then
        check(lastState.focus==focusState and visible(validGrid) and audioController.volumeMaster==0,
            "Undo and redo keep the fallback grid, isolation and muted audio active")
        floorFixture.rejectVertexCount=nil
        ref.sceneNode.worldBoundRadius=savedRadius
    end

    -- A press with no movement must retain the preceding redo snapshot.
    press("z",true)
    moveCursor(6,0)
    callbacks.mouseButtonDown({button=0})
    press("y",true)
    callbacks.mouseButtonUp({button=0})
    check(not lastState.drag and same(lastState.bones[1].translation,partial) and #lastState.redo==0,
        "Redo during an unchanged bone gesture restores the preceding edit")

    select(2); moveCursor(-6,0)
    callbacks.mouseButtonDown({button=0})
    check(lastState.selected==2 and lastState.drag.mode=="Rotate",
        "Tab-selected pelvis remains editable even when the root is slightly nearer")
    callbacks.mouseButtonUp({button=0})
    moveCursor(80,80)
    callbacks.mouseButtonDown({button=0})
    check(lastState.selected==3,"Distinct handles still select the nearest bone")
    callbacks.mouseButtonUp({button=0})
    session.finish(false); controlsRestored()
end

-- Angular rotation preserves local/camera semantics through rotated parents
-- and a scaled/yawed reference. Each drag freezes its axis and projected pivot.
pickTargets=nil
bones={
    {name="Bip01",parent=0,translation={0,0,50},rotation=v.axisAngle({1,0,0},0.4),scale=1},
    {name="Bip01 Spine",parent=1,translation={0,0,12},rotation=v.axisAngle({0,1,0},-0.7),scale=1},
    {name="Bip01 Head",parent=2,translation={0,0,18},rotation=v.axisAngle({0,0,1},0.3),scale=1},
}
rigFrame={rotation=v.axisAngle({0,0,1},1.1),translation={100,-200,40},scale=1.6}
check(session.start(ref,api),"Start camera rotation integration")
check(lastState.axis==nil,"New sessions have no axis constraint")
local function viewDrag(angle,ctrl)
    local index=lastState.selected
    local before=realRig.world(lastState.bones,rigFrame)[index]
    local expected=v.mul(v.axisAngle(realRig.vector(view.worldDirection),angle*(ctrl and 0.15 or 1)),before.rotation)
    rotate(angle,ctrl)
    local after=realRig.world(lastState.bones,rigFrame)[index]
    check(same(after.rotation,expected),"Unconstrained rotation follows the current camera axis in world space")
    check(same(after.translation,before.translation),"Rotation keeps the selected bone's pivot fixed")
end
select(3)
viewDrag(0.4) -- G falls back to rotation for ordinary bones.
select(1); press("r"); viewDrag(-0.3)
select(3)
view.worldDirection=vec(0.6,-0.3,math.sqrt(0.55))
viewDrag(-0.7)
viewDrag(0.8,true)
for _,axis in ipairs({"x","y","z"}) do
    press(axis)
    check(lastState.axis==axis and lastState.mode=="Rotate","Holding an axis enables its local constraint")
    local unit=axis=="x" and {1,0,0} or axis=="y" and {0,1,0} or {0,0,1}
    local state=beginRotation()
    local expected=v.mul(lastState.bones[3].rotation,v.axisAngle(unit,0.35*state.direction))
    check(same(state.axis,unit),"Local axis remains in starting bone coordinates")
    orbit(0.35); callbacks.mouseButtonUp({button=0})
    check(same(lastState.bones[3].rotation,expected),"Held "..axis.." constrains rotation to the bone's local axis")
    release(axis)
    check(lastState.axis==nil,"Releasing "..axis.." restores camera rotation")
    viewDrag(0.2)
end
press("x"); release("x"); viewDrag(0.15)
press("x"); press("y"); press("x")
check(lastState.axis=="y" and #lastState.heldAxes==2,"Repeated key-down cannot replace the latest held axis")
release("y")
check(lastState.axis=="x","Releasing the latest axis restores the previous held key")
release("x")
press("x"); press("z"); release("x")
check(lastState.axis=="z","Releasing an older key leaves the latest constraint active")
release("z")

local before=realRig.clone(lastState.bones)
local undoCount=#lastState.undo
local state=beginRotation()
local frozenAxis=v.copy(state.axis)
local jointX,jointY=state.jointX,state.jointY
check(math.abs(state.lastAngle)<1e-8 and state.totalAngle==0,"A drag starting directly right of its joint starts at zero")
orbit(0.4)
press("y")
orbit(0.8,true)
local expected=v.mul(state.startRotation,v.axisAngle(frozenAxis,0.46))
check(same(lastState.bones[3].rotation,expected) and math.abs(state.totalAngle-0.46)<1e-8,
    "Ctrl scales only new angular increments without a jump when enabled")
check(state.axisName==nil and same(state.axis,frozenAxis),"Pressing an axis cannot change the active camera drag")
release("y")
local originalDirection=view.worldDirection
view.worldDirection=vec(-1,0,0) -- A changed camera must not redefine the axis.
lastState.screen={[3]={x=jointX+50,y=jointY+40}}
lastState.bones[3].rotation=v.identity() -- Detect feedback from previous frames.
orbit(0.6)
expected=v.mul(state.startRotation,v.axisAngle(frozenAxis,0.26))
check(same(lastState.bones[3].rotation,expected),"Reversal and Ctrl release rebuild from the drag-start matrix")
check(same(state.axis,frozenAxis) and state.jointX==jointX and state.jointY==jointY,
    "Camera changes and refreshed projections cannot move the drag axis or pivot")
view.worldDirection=originalDirection; lastState.screen=nil
callbacks.mouseButtonUp({button=0})
check(#lastState.undo==undoCount+1,"A complete angular drag retains one undo snapshot")
local after=v.copy(lastState.bones[3].rotation)
press("z",true)
check(lastState.axis==nil and same(lastState.bones[3].rotation,before[3].rotation),"Ctrl+Z undoes the entire drag without constraining Z")
press("y",true)
check(lastState.axis==nil and same(lastState.bones[3].rotation,after),"Ctrl+Y redoes the entire drag without constraining Y")
press("x"); press("z",true); press("y",true)
check(lastState.axis=="x","Undo/redo preserves a separately held axis")
release("x")

-- Full circles in both directions, wrap boundaries, many turns, and reversal.
for _,direction in ipairs({1,-1}) do
    state=beginRotation()
    local startWorld=realRig.world(lastState.bones,rigFrame)[3].rotation
    for quarter=1,9 do
        orbit(direction*quarter*math.pi/2)
        check(math.abs(state.totalAngle-direction*quarter*math.pi/2)<1e-8,
            "Clockwise/counterclockwise travel accumulates through 360, 450, and 720 degrees")
        local expectedWorld=v.mul(v.axisAngle(realRig.vector(view.worldDirection),state.totalAngle),startWorld)
        check(same(realRig.world(lastState.bones,rigFrame)[3].rotation,expectedWorld),
            "Each quadrant preserves the same world-space rotation direction")
    end
    orbit(direction*8*math.pi/2)
    check(math.abs(state.totalAngle-direction*4*math.pi)<1e-8,"Reversing after multiple turns removes exactly the reversed arc")
    check(same(lastState.bones[3].rotation,state.startRotation),"Two full revolutions return to the starting matrix")
    callbacks.mouseButtonUp({button=0})
end
state=beginRotation()
for turn=1,100 do
    for quarter=1,4 do orbit((turn*4-4+quarter)*math.pi/2) end
end
check(math.abs(state.totalAngle-200*math.pi)<1e-7 and same(lastState.bones[3].rotation,state.startRotation),
    "A hundred complete revolutions retain the original orthonormal transform")
callbacks.mouseButtonUp({button=0})
state=beginRotation()
orbit(math.pi/2); orbit(math.pi-0.01); orbit(math.pi+0.01)
check(math.abs(state.totalAngle-(math.pi+0.01))<1e-8,"Crossing +180/-180 adds a small increment instead of a full-turn jump")
orbit(math.pi-0.01)
check(math.abs(state.totalAngle-(math.pi-0.01))<1e-8,"Reversing across the wrap boundary remains continuous")
callbacks.mouseButtonUp({button=0})

-- Local facing correction stays fixed even as axes/ancestors change.
press("x"); state=beginRotation()
local sign=state.direction
local axisWorld=v.transform(realRig.world(lastState.bones,rigFrame)[3].rotation,{1,0,0})
check(sign==(v.dot(axisWorld,realRig.vector(view.worldDirection))<0 and -1 or 1),
    "Local clockwise direction accounts for a rotated parent's axis facing")
release("x"); press("z")
orbit(0.5)
check(state.axisName=="x" and same(state.axis,{1,0,0})
    and same(lastState.bones[3].rotation,v.mul(state.startRotation,v.axisAngle({1,0,0},0.5*sign))),
    "Releasing/pressing keys during a local drag keeps the starting Local X axis")
callbacks.mouseButtonUp({button=0})
state=beginRotation(); check(state.axisName=="z","The next drag adopts the currently held local axis")
callbacks.mouseButtonUp({button=0}); release("z")

-- Clicking a joint center has no angle. Establish one after leaving its radius.
local joint=view:worldPointToScreenPoint(realRig.engineVector(realRig.world(lastState.bones,rigFrame)[3].translation))
moveCursor(joint.x,joint.y)
callbacks.mouseButtonDown({button=0}); state=lastState.drag
check(state.lastAngle==nil,"The joint center does not invent an atan2 direction")
orbit(0); check(state.totalAngle==0 and not state.dirty,"Leaving the center establishes a baseline without a rotation jump")
orbit(math.pi/2); check(math.abs(state.totalAngle-math.pi/2)<1e-8,"Rotation resumes once the pointer has a usable radius")
moveCursor(state.jointX,state.jointY)
orbit(math.pi); check(math.abs(state.totalAngle-math.pi/2)<1e-8,"Crossing the sampled center resets only the mouse angle")
orbit(0); check(math.abs(state.totalAngle-math.pi/2)<1e-8,"A single event through the center cannot apply an artificial half-turn")
orbit(math.pi/2); check(math.abs(state.totalAngle-math.pi)<1e-8,"Ordinary angular travel resumes after a center crossing")
callbacks.mouseButtonUp({button=0})
projectionHidden=true; undoCount=#lastState.undo
callbacks.mouseButtonDown({button=0})
check(not lastState.drag and #lastState.undo==undoCount,"An off-screen joint cannot start an undefined angular drag")
projectionHidden=false

press("z"); press("enter")
check(callbacks.keyUp({keyCode=tes3.scanCode.z})==nil and lastState.axis==nil,
    "Releasing an axis in the name dialog clears it and passes the event to the text field")
namePrompt.close(namePrompt.current)
press("y"); menuMode=true
check(callbacks.keyUp({keyCode=tes3.scanCode.y})==nil and lastState.axis==nil,
    "Axis release while paused cannot leave a sticky constraint")
menuMode=false
press("x"); session.finish(false); controlsRestored()
check(session.start(ref,api) and lastState.axis==nil and #lastState.heldAxes==0,"Held axis state does not survive an editor restart")
session.finish(false); controlsRestored()
rigFrame={rotation=v.identity(),translation={0,0,0},scale=1}
view.worldDirection=vec(0,1,0)

-- Drive the real IK math through editor input with both a hand and foot locked.
bones={
    {name="Bip01",parent=0,translation={0,0,50},rotation=v.identity(),scale=1},
    {name="Bip01 L UpperArm",parent=1,translation={0,0,12},rotation=v.identity(),scale=1},
    {name="Bip01 L Forearm",parent=2,translation={20,0,0},rotation=v.axisAngle({0,0,1},0.8),scale=1},
    {name="Bip01 L Hand",parent=3,translation={18,0,0},rotation=v.axisAngle({0,1,0},0.2),scale=1},
    {name="Bip01 L Thigh",parent=1,translation={-8,0,0},rotation=v.identity(),scale=1},
    {name="Bip01 L Calf",parent=5,translation={0,0,-25},rotation=v.axisAngle({1,0,0},-0.8),scale=1},
    {name="Bip01 L Foot",parent=6,translation={0,0,-22},rotation=v.identity(),scale=1},
}
check(session.start(ref,api),"Start IK lock integration")
press("l")
check(next(lastState.locks)==nil and #lastState.undo==0,"L ignores bones without IK")
select(4); press("l")
select(7); press("l")
check(lastState.locks[4] and lastState.locks[7],"L locks a selected hand and foot independently")
press("z",true)
check(lastState.locks[4] and not lastState.locks[7],"Undo restores the previous lock state")
press("y",true)
check(lastState.locks[4] and lastState.locks[7],"Redo restores the lock and its anchor")
local planted=realRig.world(lastState.bones)
select(1); press("g"); drag(3,0)
local moved=realRig.world(lastState.bones)
check(same(moved[4].translation,planted[4].translation) and same(moved[7].translation,planted[7].translation),
    "Root translation compensates both locked limbs")
local movedRoot=v.copy(lastState.bones[1].translation)
press("z",true)
check(same(lastState.bones[1].translation,bones[1].translation) and lastState.locks[4] and lastState.locks[7],
    "Undo restores the pose together with both locks")
press("y",true)
check(same(lastState.bones[1].translation,movedRoot),"Redo restores the constrained pose")
press("backspace")
moved=realRig.world(lastState.bones)
check(same(lastState.bones[1].translation,bones[1].translation) and same(moved[4].translation,planted[4].translation)
    and same(moved[7].translation,planted[7].translation),"Resetting the root also compensates locked limbs")
select(4); drag(4,0)
local hand=realRig.world(lastState.bones)[4]
check(not same(hand.translation,planted[4].translation) and same(lastState.locks[4].target,hand.translation),
    "Direct IK movement repositions a locked hand and its anchor")
drag(0,5,true)
check(same(realRig.world(lastState.bones)[4].translation,hand.translation),"Alt pole adjustment preserves the locked target")
press("r"); press("x"); rotate(0.12,false,true)
release("x")
local turned=realRig.world(lastState.bones)[4]
check(not same(turned.rotation,hand.rotation) and same(turned.rotation,lastState.locks[4].rotation),
    "Direct hand rotation updates its locked facing, including with Alt held")
rotate(0.05)
local cameraTurned=realRig.world(lastState.bones)[4]
check(same(cameraTurned.rotation,v.mul(v.axisAngle({0,1,0},0.05),turned.rotation))
    and same(cameraTurned.rotation,lastState.locks[4].rotation),
    "Default camera rotation updates a locked hand's facing without the lock undoing the edit")
turned=cameraTurned
select(1); press("g"); drag(2,0)
check(same(realRig.world(lastState.bones)[4].rotation,turned.rotation),"Later parent movement preserves the newly edited hand facing")
select(2); press("r"); press("z")
local turn=rotate(0.12)
local upper=v.mul(turn.startRotation,v.axisAngle({0,0,1},turn.totalAngle*turn.direction))
release("z")
check(same(lastState.bones[2].rotation,upper),"A hand lock does not cancel an explicit upper-arm rotation")
check(same(lastState.locks[4].target,realRig.world(lastState.bones)[4].translation),"Forced hand displacement rebases the lock")
select(3)
press("z")
turn=rotate(0.1)
local lower=v.mul(turn.startRotation,v.axisAngle({0,0,1},turn.totalAngle*turn.direction))
release("z")
check(same(lastState.bones[3].rotation,lower),"A hand lock does not cancel an explicit forearm rotation")
select(4); press("l")
check(not lastState.locks[4] and lastState.locks[7],"Unlocking the hand leaves the foot locked")
press("z",true)
check(lastState.locks[4] and lastState.locks[7],"Undo can restore an unlocked hand's last anchor")
press("backspace")
check(same(lastState.bones[4].rotation,bones[4].rotation),"Resetting a locked tip honors the selected transform reset")
session.finish(false)
controlsRestored()
check(session.start(ref,api) and next(lastState.locks)==nil,"Locks are transient and cleared for a new editing session")
session.finish(false)
controlsRestored()
dofile("tests/gizmo_session_fixture.lua")({
    check=check,rig=realRig,callbacks=callbacks,session=session,ref=ref,api=api,
    state=function() return lastState end,frame=function() return rigFrame end,cameraEvent=cameraEvent,
    writes=function() return #writes end,
})
dofile("tests/navigation_fixture.lua")({
    check=check,rig=realRig,callbacks=callbacks,session=session,ref=ref,api=api,
    state=function() return lastState end,frame=function() return rigFrame end,
    writes=function() return #writes end,
    savedPose=function(expected)
        local actual=savedPoseData[#savedPoseData]
        if not actual or #actual~=#expected then return false end
        for i,bone in ipairs(expected) do
            if not same(bone.translation,actual[i].translation) or not same(bone.rotation,actual[i].rotation)
                or bone.scale~=actual[i].scale then return false end
        end
        return true
    end,
    cameraRoot=cameraRoot,cameraEvent=cameraEvent,controlsRestored=controlsRestored,
    menus={
        {key="enter",field="namePrompt",close=namePrompt.close},
        {key="m",field="mirrorPrompt",close=mirrorMenu.close},
        {key="s",field="symmetryPrompt",close=symmetryMenu.close},
        {key="backspace",shift=true,field="resetPrompt",close=resetMenu.close},
        {key="b",field="blendPrompt",close=blendMenu.close},
        {key="t",field="groundPrompt",close=groundMenu.close},
    },
})
for _,focused in ipairs({false,true}) do
    check(session.start(ref,api),"Start before editing with full help open")
    if focused then focusKey() end
    local state=lastState
    callbacks.keyDown({keyCode=tes3.scanCode.h})
    callbacks.enterFrame({menuMode=false})
    local menu=state.overlay.menu
    local originalRoot=v.copy(state.bones[1].translation)
    local beforeWrites=#writes
    callbacks.mouseButtonDown({button=0})
    callbacks.mouseAxis({deltaX=10,deltaY=0})
    callbacks.mouseButtonUp({button=0})
    check(not same(state.bones[1].translation,originalRoot) and #writes==beforeWrites+1 and #state.undo==1
        and state.expandedControls and state.overlay.menu==menu,"A deliberate pose drag works and checkpoints normally with controls expanded")
    callbacks.keyDown({keyCode=tes3.scanCode.z,isControlDown=true})
    check(same(state.bones[1].translation,originalRoot),"Undo remains available with help open")
    callbacks.keyDown({keyCode=tes3.scanCode.y,isControlDown=true})
    check(not same(state.bones[1].translation,originalRoot),"Redo remains available with help open")
    local yaw=state.orbit.yaw
    callbacks.keyDown({keyCode=tes3.scanCode.numpad6})
    callbacks.keyUp({keyCode=tes3.scanCode.numpad6})
    check(state.orbit.yaw~=yaw and state.expandedControls,"Numpad navigation remains available with controls expanded")
    yaw=state.orbit.yaw
    callbacks.mouseButtonDown({button=1})
    callbacks.mouseAxis({deltaX=10,deltaY=0})
    callbacks.mouseButtonUp({button=1})
    check(state.orbit.yaw~=yaw,"Mouse orbit remains available with help open")
    callbacks.keyDown({keyCode=tes3.scanCode.enter})
    check(state.namePrompt and state.expandedControls,"Saving can open the name dialog with controls expanded")
    menuMode=true; callbacks.enterFrame({menuMode=true})
    check(not menu.visible,"The existing controls hide behind the name dialog")
    namePrompt.close(state.namePrompt); menuMode=false; callbacks.enterFrame({menuMode=false})
    check(menu.visible and state.expandedControls and state.overlay.menu==menu and player.controlsDisabled,
        "Cancelling naming restores the expanded default controls")
    session.finish(false); controlsRestored()
end
-- Mirror commands use the real bundled skeleton and the same history/lock
-- machinery as drags. Exercise all targets and directions through M's modal.
local mirror=require("MannequinPoseDesigner.mirror")
local function samePose(a,b)
    for i,bone in ipairs(a) do
        if not same(bone.translation,b[i].translation) or not same(bone.rotation,b[i].rotation)
            or bone.scale~=b[i].scale or bone.parent~=b[i].parent or bone.name~=b[i].name then return false end
    end
    return #a==#b
end
local function command(action,scope)
    local prompt=mirrorMenu.current
    mirrorMenu.close(prompt)
    prompt.onAction(action,scope)
    callbacks.enterFrame({})
end
local templateBones=dofile("tests/mirror_fixture.lua")
local tips={}
for i,bone in ipairs(templateBones) do
    if bone.name:match(" Hand$") or bone.name:match(" Foot$") then tips[#tips+1]=i end
    bone.rotation=v.orthonormalize(v.mul(bone.rotation,v.axisAngle({1,-2,3},i*0.02)))
end
rigFrame={rotation=v.axisAngle({0,0,1},1.3),translation={400,-90,170},scale=1.6}
for _,scope in ipairs({"entire","arms","legs"}) do
    for _,action in ipairs({"swap","leftToRight","rightToLeft"}) do
        bones=realRig.clone(templateBones)
        check(session.start(ref,api),"Start mirror command integration")
        for _,tip in ipairs(tips) do select(tip); press("l") end
        if action=="swap" then press("f") end
        local before=realRig.clone(lastState.bones)
        local locks=realRig.cloneLocks(lastState.locks)
        local expected,touched=mirror.apply(before,action,scope)
        local undoCount,writeCount=#lastState.undo,#writes
        local focusState=lastState.focus
        press("m")
        local prompt=mirrorMenu.current
        check(lastState.mirrorPrompt==prompt and prompt.initial=="entire","M opens the default target")
        check(player.controlsDisabled==originalFlags.controlsDisabled,"Mirror menu releases the player-control lock")
        check(not lastState.overlay.menu.visible,"The editor overlay hides while menu activation is pending")
        check(lastState.focus==focusState,"Opening the mirror menu retains focus mode")
        callbacks.mouseButtonDown({button=0}); callbacks.mouseAxis({deltaX=20,deltaY=10})
        callbacks.mouseButtonUp({button=0})
        check(not lastState.drag and samePose(lastState.bones,before),"Pending modal blocks bone drags")
        check(callbacks.keyDown({keyCode=tes3.scanCode.m})==nil and mirrorMenu.current==prompt,
            "Repeated M passes through without opening another menu")
        check(callbacks.keyDown({keyCode=tes3.scanCode.enter})==nil and not lastState.namePrompt,
            "Enter in the mirror menu cannot open the save dialog")
        menuMode=true
        callbacks.simulated({})
        check(samePose(lastState.bones,before),"Native menu mode cannot apply an unintended edit")
        command(action,scope)
        check(session.isActive() and not lastState.mirrorPrompt and player.controlsDisabled,"Command resumes editing and restores its control lock")
        check(samePose(lastState.bones,expected),"Menu command applies the requested mirror result")
        check(#lastState.undo==undoCount+1 and #writes==writeCount+1,"Each command has one history entry and one NIF checkpoint")
        check(lastState.selected==tips[#tips] and lastState.focus==focusState,"Commands preserve bone selection and focus")
        for _,tip in ipairs(tips) do
            local index,affected=tip,false
            while index~=0 do
                if touched[index] then affected=true; break end
                index=before[index].parent
            end
            local expectedLock=affected and realRig.anchor(expected,tip) or locks[tip]
            check(lastState.locks[tip] and same(lastState.locks[tip].target,expectedLock.target)
                and same(lastState.locks[tip].rotation,expectedLock.rotation),
                "Affected locks follow the command; other locks retain their anchors")
        end
        press("z",true)
        check(samePose(lastState.bones,before),"Undo restores the entire pre-command pose")
        for _,tip in ipairs(tips) do
            check(same(lastState.locks[tip].target,locks[tip].target) and same(lastState.locks[tip].rotation,locks[tip].rotation),
                "Undo restores pre-command lock anchors")
        end
        press("y",true)
        check(samePose(lastState.bones,expected),"Redo restores the command")
        press("m")
        check(mirrorMenu.current.initial==scope,"The next mirror menu remembers its target")
        check(callbacks.keyDown({keyCode=tes3.scanCode.escape})==nil and session.isActive(),
            "Escape in the mirror menu belongs to that menu")
        check(escapeTest(),"The mirror menu retains native Escape handling")
        mirrorMenu.close(mirrorMenu.current)
        callbacks.enterFrame({})
        check(samePose(lastState.bones,expected),"Canceling the mirror menu keeps the edited pose")
        press("m"); local stale=mirrorMenu.current
        local written=#writes
        session.finish(false)
        check(stale.closed,"Editor exit closes a pending mirror menu")
        stale.onAction(action,scope)
        check(#writes==written and not session.isActive(),"Late menu callbacks cannot edit a finished session")
        controlsRestored()
    end
end
-- Live symmetry uses ordinary edit snapshots: one drag owns both sides, while
-- switching modes changes neither the pose nor the history/checkpoint count.
local symmetric=mirror.apply(dofile("tests/mirror_fixture.lua"),"leftToRight","entire")
local byName={}
for i,bone in ipairs(symmetric) do byName[bone.name:lower()]=i end
local function chooseSymmetry(mode)
    press("s")
    local prompt=symmetryMenu.current
    symmetryMenu.close(prompt)
    prompt.onSelect(mode)
    callbacks.enterFrame({})
    check(lastState.symmetry==mode and not lastState.symmetryPrompt and player.controlsDisabled,
        "Selecting symmetry resumes editing with the requested mode")
end
-- Reproduce focus entry after symmetric foot IK, with the first grid rejected.
do
bones=realRig.clone(symmetric)
check(session.start(ref,api),"Start focus entry after symmetric foot IK")
chooseSymmetry("entire")
local leftFoot,rightFoot=byName["bip01 l foot"],byName["bip01 r foot"]
select(rightFoot); press("l")
select(leftFoot); press("l"); press("g")
local beforeFeet=realRig.clone(lastState.bones)
drag(3,2)
check(not samePose(lastState.bones,beforeFeet),"The regression moves feet with symmetric IK before focus")
local editedFeet=realRig.clone(lastState.bones)
local footLocks=realRig.cloneLocks(lastState.locks)
local footUndo,footWrites,footReport=#lastState.undo,#writes,lastReport
floorFixture.rejectVertexCount=require("MannequinPoseDesigner.focus_grid").vertexCount(ref.sceneNode.worldBoundRadius)
local footLoads=floorFixture.loads
press("f")
check(lastState.focus and not lastState.focus.gridMesh and lastState.focus.activationComplete
    and samePose(lastState.bones,editedFeet) and lastState.symmetry=="entire"
    and #lastState.undo==footUndo and #writes==footWrites and lastReport==footReport,
    "A rejected first grid preserves symmetry, edited feet, history and checkpoints without an error popup")
for _,tip in ipairs({leftFoot,rightFoot}) do
    check(same(lastState.locks[tip].target,footLocks[tip].target)
        and same(lastState.locks[tip].rotation,footLocks[tip].rotation),
        "Focus entry preserves each edited foot's IK anchor")
end
for _=1,5 do callbacks.render({}); callbacks.enterFrame({}) end
check(session.isActive() and floorFixture.loads==footLoads+1 and samePose(lastState.bones,editedFeet),
    "Rendering gridless focus keeps the edit active without retrying the rejected size")
release("f"); press("f")
check(not lastState.focus and samePose(lastState.bones,editedFeet),"Leaving gridless focus preserves the edited pose")
floorFixture.rejectVertexCount=nil
release("f"); press("f")
check(lastState.focus.gridMesh and samePose(lastState.bones,editedFeet),
    "A later focus activation can retry the grid without resetting foot IK")
session.finish(false); controlsRestored()
end

for _,scope in ipairs({"entire","arms","legs"}) do
    bones=realRig.clone(symmetric)
    check(session.start(ref,api) and lastState.symmetry=="off","Each session starts with symmetry Off")
    if scope=="entire" then press("f") end
    local focusState=lastState.focus
    local before=realRig.clone(lastState.bones)
    local undoCount,writeCount=#lastState.undo,#writes
    press("s")
    local prompt=symmetryMenu.current
    check(lastState.symmetryPrompt==prompt and prompt.initial=="off" and not lastState.overlay.menu.visible,
        "S opens the mode selector and hides the editor before native menu activation")
    check(player.controlsDisabled==originalFlags.controlsDisabled and lastState.focus==focusState,
        "Symmetry selection releases the player-control lock and retains focus")
    callbacks.mouseButtonDown({button=0}); callbacks.mouseAxis({deltaX=20,deltaY=10}); callbacks.mouseButtonUp({button=0})
    check(not lastState.drag and samePose(lastState.bones,before),"Pending symmetry selection blocks bone drags")
    check(callbacks.keyDown({keyCode=tes3.scanCode.m})==nil and not lastState.mirrorPrompt,
        "The symmetry menu prevents opening the mirror menu")
    check(callbacks.keyDown({keyCode=tes3.scanCode.enter})==nil and not lastState.namePrompt,
        "Enter belongs to the symmetry menu instead of opening the name dialog")
    check(callbacks.keyDown({keyCode=tes3.scanCode.s})==nil and symmetryMenu.current==prompt,
        "Repeated S cannot open a duplicate mode selector")
    check(callbacks.keyDown({keyCode=tes3.scanCode.escape})==nil and session.isActive(),
        "Escape belongs to the symmetry selector instead of ending the session")
    check(escapeTest(),"The symmetry selector retains native Escape handling")
    menuMode=true
    symmetryMenu.close(prompt); prompt.onSelect(scope); callbacks.enterFrame({})
    check(lastState.symmetry==scope and samePose(lastState.bones,before)
        and #lastState.undo==undoCount and #writes==writeCount,
        "Enabling symmetry leaves the existing pose, history and NIF checkpoints unchanged")
    for _,side in ipairs({"l","r"}) do
        for _,part in ipairs({"upperarm","forearm","hand","thigh","calf","foot"}) do
            local selected=byName["bip01 "..side.." "..part]
            local destination=byName["bip01 "..(side=="l" and "r" or "l").." "..part]
            local enabled=scope=="entire" or scope==((part=="thigh" or part=="calf" or part=="foot") and "legs" or "arms")
            select(selected); press("r"); press("x")
            local before=realRig.clone(lastState.bones)
            local undoCount,writeCount=#lastState.undo,#writes
            rotate(0.2,true); release("x")
            local after=realRig.clone(lastState.bones)
            local expected=mirror.apply(after,side=="l" and "leftToRight" or "rightToLeft","entire")
            check(same(after[destination].rotation,enabled and expected[destination].rotation or before[destination].rotation),
                "Rotations follow either source side only when that limb is in the active scope")
            check(not same(after[selected].rotation,before[selected].rotation),"Symmetry retains the user's source-side edit")
            for i,bone in ipairs(before) do
                if i~=selected and (not enabled or i~=destination) then
                    check(same(bone.rotation,after[i].rotation) and same(bone.translation,after[i].translation),
                        "Direct symmetry rotation leaves all unrelated bones unchanged")
                end
            end
            check(#lastState.undo==undoCount+1 and #writes==writeCount+1,"A mirrored drag stays one history and checkpoint step")
            press("z",true); check(samePose(lastState.bones,before) and lastState.symmetry==scope,"Undo restores both sides and keeps the mode")
            press("y",true); check(samePose(lastState.bones,after),"Redo restores the paired edit")
            press("backspace")
            expected=mirror.apply(lastState.bones,side=="l" and "leftToRight" or "rightToLeft","entire")
            check(same(lastState.bones[selected].rotation,symmetric[selected].rotation)
                and same(lastState.bones[destination].rotation,enabled and expected[destination].rotation or after[destination].rotation),
                "Backspace resets the source and reflects the reset only within the active scope")
        end
    end
    for _,side in ipairs({"l","r"}) do
        for _,part in ipairs({"hand","foot"}) do
            local selected=byName["bip01 "..side.." "..part]
            local opposite=byName["bip01 "..(side=="l" and "r" or "l").." "..part]
            local enabled=scope=="entire" or scope==(part=="hand" and "arms" or "legs")
            select(selected); press("g")
            for _,poleMode in ipairs({false,true}) do
                local before=realRig.clone(lastState.bones)
                drag(6,-4,poleMode)
                local expected=mirror.apply(lastState.bones,side=="l" and "leftToRight" or "rightToLeft","entire")
                local chain=lastState.chains[opposite]
                for _,index in ipairs({chain.upper,chain.lower,chain.tip}) do
                    check(same(lastState.bones[index].rotation,enabled and expected[index].rotation or before[index].rotation),
                        "IK targets and elbow/knee poles follow only the scoped opposite chain")
                end
            end
        end
    end
    chooseSymmetry("off")
    select(byName["bip01 l hand"]); press("r")
    local right=v.copy(lastState.bones[byName["bip01 r hand"]].rotation)
    rotate(0.15)
    check(same(lastState.bones[byName["bip01 r hand"]].rotation,right),"Off resumes independent posing")
    chooseSymmetry(scope)
    press("s"); prompt=symmetryMenu.current
    check(prompt.initial==scope,"Reopening S displays the active symmetry mode")
    symmetryMenu.close(prompt); callbacks.enterFrame({})
    check(lastState.symmetry==scope and lastState.focus==focusState,"Cancel keeps the symmetry mode and focus")
    press("s"); local stale=symmetryMenu.current
    local state=lastState
    session.finish(false); stale.onSelect("off")
    check(stale.closed and state.symmetry==scope and not session.isActive(),"Cleanup closes S and rejects late mode callbacks")
    controlsRestored()
end
bones=realRig.clone(symmetric)
check(session.start(ref,api),"Start live symmetry with all four limbs locked")
chooseSymmetry("entire")
for _,tip in ipairs(tips) do select(tip); press("l") end
for _,case in ipairs({{"l","hand"},{"r","foot"}}) do
    local side,part=case[1],case[2]
    local selected=byName["bip01 "..side.." "..part]
    local opposite=byName["bip01 "..(side=="l" and "r" or "l").." "..part]
    local before=realRig.clone(lastState.bones)
    local locks=realRig.cloneLocks(lastState.locks)
    select(selected); press("g"); drag(4,-2)
    local after=realRig.clone(lastState.bones)
    local expected=mirror.apply(after,side=="l" and "leftToRight" or "rightToLeft","entire")
    check(same(after[opposite].rotation,expected[opposite].rotation),"The destination lock cannot cancel mirrored IK")
    local anchor=realRig.anchor(after,opposite)
    check(same(lastState.locks[opposite].target,anchor.target) and same(lastState.locks[opposite].rotation,anchor.rotation),
        "The locked counterpart adopts the mirrored position and facing")
    press("z",true)
    check(samePose(lastState.bones,before) and same(lastState.locks[opposite].target,locks[opposite].target),
        "Undo restores paired IK together with the original destination lock")
    press("y",true)
    check(samePose(lastState.bones,after) and same(lastState.locks[opposite].target,anchor.target),
        "Redo restores paired IK and the rebased lock")
    local chain=lastState.chains[selected]
    for _,index in ipairs({chain.upper,chain.lower}) do
        select(index); press("r"); press("z"); rotate(0.12); release("z")
        local expected=mirror.apply(lastState.bones,side=="l" and "leftToRight" or "rightToLeft","entire")
        for _,oppositeIndex in ipairs({lastState.chains[opposite].upper,lastState.chains[opposite].lower,opposite}) do
            check(same(lastState.bones[oppositeIndex].rotation,expected[oppositeIndex].rotation),
                "Direct locked-joint rotation mirrors the source's compensating joints too")
        end
    end
end
local anchors=realRig.cloneLocks(lastState.locks)
select(1); press("g"); drag(1,0)
for _,tip in ipairs(tips) do
    local world=realRig.world(lastState.bones)
    check(same(world[tip].translation,anchors[tip].target) and same(world[tip].rotation,anchors[tip].rotation),
        "Later root movement holds the new anchors on all four locked limbs")
end
select(byName["bip01 r hand"]); press("l")
select(byName["bip01 l hand"]); press("g"); drag(3,0)
check(not lastState.locks[byName["bip01 r hand"]] and lastState.locks[byName["bip01 l hand"]],
    "Symmetry preserves independent lock flags on each side")
session.finish(false); controlsRestored()
check(session.start(ref,api),"Start before scene rebuild with S open")
press("s"); local staleSymmetry=symmetryMenu.current
ref.sceneNode={}; callbacks.simulated({})
check(not session.isActive() and staleSymmetry.closed,"Scene rebuild closes the symmetry selector safely")
controlsRestored()
check(session.start(ref,api),"Start before a symmetry checkpoint failure")
chooseSymmetry("entire"); select(byName["bip01 l hand"])
writeError=true
callbacks.mouseButtonDown({button=0}); callbacks.mouseAxis({deltaX=5,deltaY=0}); callbacks.mouseButtonUp({button=0})
check(not session.isActive(),"A failed symmetry checkpoint cancels and cleans up the session")
writeError=false; controlsRestored()
check(session.start(ref,api),"Start before a mirror checkpoint failure")
press("m"); writeError=true
command("swap","entire")
check(not session.isActive(),"Mirror checkpoint errors cancel safely")
writeError=false; controlsRestored()
check(session.start(ref,api),"Start before scene rebuild with an open mirror menu")
press("m"); local stale=mirrorMenu.current
ref.sceneNode={}; callbacks.simulated({})
check(not session.isActive() and stale.closed,"Scene rebuild closes the modal before stale bone access")
controlsRestored()
-- Blending previews local NIF data while the native menu owns input; only
-- acceptance commits history/checkpoints. Use the actual skeleton/IK anchors.
local blend=require("MannequinPoseDesigner.blend")
blendPoses["a.nif"]=realRig.clone(templateBones)
blendPoses["b.nif"]=realRig.clone(templateBones)
local defaultFile="oaab/k/mann_relax.nif"
blendPoses[defaultFile]=realRig.clone(templateBones)
for i,bone in ipairs(blendPoses["b.nif"]) do
    bone.translation=v.add(bone.translation,{i*0.3,-i*0.2,i*0.1})
    bone.rotation=v.mul(bone.rotation,v.axisAngle({2,-1,3},i*0.05))
    bone.scale=0.8+i*0.01
end
for _,focused in ipairs({false,true}) do
    local sourceA=focused and "a.nif" or defaultFile
    local sourceB=focused and defaultFile or "b.nif"
    bones=realRig.clone(templateBones)
    check(session.start(ref,api),"Start saved-pose blending integration")
    chooseSymmetry("entire")
    for _,tip in ipairs(tips) do select(tip); press("l") end
    if focused then press("f") end
    local before=realRig.clone(lastState.bones)
    local locks=realRig.cloneLocks(lastState.locks)
    local focusState=lastState.focus
    local undoCount,writeCount,loadCount,readCount=#lastState.undo,#writes,#loads,#blendReads
    press("b"); local prompt=blendMenu.current
    check(lastState.blendPrompt==prompt and #prompt.files==6
        and prompt.files[1].label=="Relaxed (Default)" and prompt.files[6].file=="b.nif"
        and player.controlsDisabled==originalFlags.controlsDisabled,
        "B supplies default and custom poses and releases controls for native UI input")
    callbacks.enterFrame({})
    check(lastState.overlay.menu.visible and not lastState.overlay.markersMenu.visible and lastState.focus==focusState,
        "Blend UI keeps its context guide visible, hides editing handles and preserves focus")
    check(callbacks.keyDown({keyCode=tes3.scanCode.b})==nil and blendMenu.current==prompt,
        "Repeated B cannot open another blend dialog")
    for _,key in ipairs({tes3.scanCode.enter,tes3.scanCode.escape,tes3.scanCode.l,tes3.scanCode.z}) do
        check(callbacks.keyDown({keyCode=key,isControlDown=true})==nil and session.isActive(),
            "Editor save, exit, lock and undo shortcuts belong to the blend menu")
    end
    check(escapeTest(),"The blend menu retains native Escape handling")
    menuMode=true
    for _,t in ipairs({0,0.25,1,0.5}) do
        check(prompt.onPreview(sourceA,sourceB,t)==true,"Either blend endpoint can select a default pose")
        local expected=blend.apply(blendPoses[sourceA],blendPoses[sourceB],t)
        check(samePose(lastState.bones,expected),"Preview uses saved local transforms independent of view and symmetry")
        local applies=appliedPoses
        callbacks.enterFrame({menuMode=true}); callbacks.simulated({})
        check(appliedPoses>applies and samePose(lastState.bones,expected),"The live pose stays applied across paused preview frames")
        local view=cameraEvent(50); callbacks.cameraControl(view)
        check(view.cameraTransform.rotation.label=="designer","The camera retains its editor framing during live preview")
        for _,tip in ipairs(tips) do
            local anchor=realRig.anchor(expected,tip)
            check(same(lastState.locks[tip].target,anchor.target) and same(lastState.locks[tip].rotation,anchor.rotation),
                "All enabled locks adopt the blended pose without altering the interpolation")
        end
    end
    check(#blendReads==readCount+2,"Each source NIF is loaded once per dialog, not on each slider event")
    check(#lastState.undo==undoCount and #writes==writeCount and #loads==loadCount and selection==api.getSelectedFile(ref),
        "Preview neither enters pose history nor writes or selects a persistent pose")
    local previewed=realRig.clone(lastState.bones)
    blendPoses["broken.nif"]={}
    local ok,err=prompt.onPreview(sourceA,"broken.nif",0.5)
    check(ok==false and err:find("skeleton",1,true) and samePose(lastState.bones,previewed) and session.isActive(),
        "Incompatible pose data reports an error and preserves the last valid preview")
    blendReadError=true
    ok,err=prompt.onPreview("unreadable.nif","b.nif",0.5)
    blendReadError=false
    check(ok==false and err:find("Could not read saved pose",1,true) and samePose(lastState.bones,previewed),
        "File errors remain recoverable inside the dialog")
    blendMenu.close(prompt)
    callbacks.enterFrame({})
    check(not lastState.blendPrompt and player.controlsDisabled and samePose(lastState.bones,before),
        "Cancel restores the pre-dialog pose and resumes editing")
    for _,tip in ipairs(tips) do
        check(same(lastState.locks[tip].target,locks[tip].target) and same(lastState.locks[tip].rotation,locks[tip].rotation),
            "Cancel restores the original lock anchors")
    end
    check(#lastState.undo==undoCount and #writes==writeCount and lastState.focus==focusState,"Cancel leaves history, drafts and focus unchanged")
    press("b"); prompt=blendMenu.current
    check(prompt.onPreview(sourceA,sourceB,0.5),"Reopening allows a new default/custom blend")
    blendMenu.close(prompt,true); callbacks.enterFrame({})
    check(samePose(lastState.bones,previewed) and #lastState.undo==undoCount+1 and #writes==writeCount+1,
        "Use blend commits one undo snapshot and one checkpoint")
    press("z",true)
    check(samePose(lastState.bones,before),"Undo restores the pose before opening the blend dialog")
    for _,tip in ipairs(tips) do check(same(lastState.locks[tip].target,locks[tip].target),"Undo restores pre-blend anchors") end
    local redoCount=#lastState.redo
    press("b"); prompt=blendMenu.current
    prompt.onPreview("a.nif","b.nif",1); blendMenu.close(prompt)
    check(#lastState.redo==redoCount and samePose(lastState.bones,before),"Cancel preserves an existing redo stack")
    press("y",true)
    check(samePose(lastState.bones,previewed),"Redo restores the accepted blend as one step")
    session.finish(true,false,{id="Blended",name="Blended"})
    check(not session.isActive() and savedNames[#savedNames]=="Blended","The accepted blend saves through the ordinary NIF exporter")
    controlsRestored()
end
for _,exit in ipairs({"load","cellChanged","referenceDeactivated","rebuild","finish"}) do
    bones=realRig.clone(templateBones)
    check(session.start(ref,api),"Start before blend preview cleanup")
    press("b"); local prompt=blendMenu.current
    prompt.onPreview("a.nif","b.nif",0.5)
    if exit=="rebuild" then ref.sceneNode={}; callbacks.enterFrame({})
    elseif exit=="finish" then session.finish(false)
    else callbacks[exit]({reference=ref}) end
    check(not session.isActive() and prompt.closed,"Each session exit closes the blend dialog safely")
    local written=#writes
    prompt.onPreview("a.nif","b.nif",1)
    prompt.onClose(true)
    check(#writes==written and not session.isActive(),"Late preview and acceptance cannot change a finished session")
    controlsRestored()
end
check(session.start(ref,api),"Start before blend checkpoint failure")
press("b"); local blendPrompt=blendMenu.current
blendPrompt.onPreview("a.nif","b.nif",0.5)
writeError=true; blendMenu.close(blendPrompt,true)
check(not session.isActive(),"A failed blend checkpoint cancels safely and restores the session")
writeError=false; controlsRestored()
bones={{name="Bip01",parent=0,translation={0,0,50},rotation=v.identity(),scale=1}}
check(session.start(ref,api),"Start with no paired limbs")
local undoCount,writeCount=#lastState.undo,#writes
press("m"); command("leftToRight","arms")
check(session.isActive() and #lastState.undo==undoCount and #writes==writeCount,"Unavailable limb copies leave history and checkpoints unchanged")
session.finish(false); controlsRestored()
-- Reset commands share one history/checkpoint path for menu and keyboard use.
do
    local baseline=dofile("tests/mirror_fixture.lua")
    local indices={}
    for i,bone in ipairs(baseline) do indices[bone.name:lower()]=i end
    local calf=indices["bip01 l calf"]
    local foot=indices["bip01 l foot"]
    local function resetCommand(scope)
        local prompt=resetMenu.current
        resetMenu.close(prompt)
        prompt.onReset(scope)
        callbacks.enterFrame({})
    end
    for _,route in ipairs({"shortcut","menu"}) do
        for _,scope in ipairs({"bone","limb","entire"}) do
            bones=realRig.clone(baseline)
            check(session.start(ref,api),"Start scoped reset integration")
            select(calf)
            if scope=="entire" then chooseSymmetry("entire"); press("f") end
            -- Pose every local transform, including hidden controls. Make locks
            -- follow this setup so each reset must restore the intended anchors.
            for i,bone in ipairs(lastState.bones) do
                bone.rotation=v.mul(bone.rotation,v.axisAngle({1,2,3},i*0.01))
                bone.translation=v.add(bone.translation,{i,-i,2*i})
                bone.scale=1+i*0.005
            end
            if scope~="bone" then
                for tip in pairs(lastState.chains) do lastState.locks[tip]=realRig.anchor(lastState.bones,tip) end
            end
            local before=realRig.clone(lastState.bones)
            local anchors=realRig.cloneLocks(lastState.locks)
            local expected=realRig.reset(before,baseline,calf,scope)
            local undoCount,writeCount=#lastState.undo,#writes
            local focusState=lastState.focus
            if route=="menu" then
                press("backspace",false,true)
                check(lastState.resetPrompt==resetMenu.current and resetMenu.current.boneName==baseline[calf].name,
                    "Shift+Backspace opens reset choices for the selected bone")
                resetCommand(scope)
            else
                press("backspace",scope~="bone",scope=="entire")
            end
            check(samePose(lastState.bones,expected),"Menu and shortcut resets restore exactly the chosen scope")
            check(samePose(lastState.initial,baseline),"Reset retains the original session baseline")
            check(#lastState.undo==undoCount+1 and #writes==writeCount+1 and #lastState.redo==0,
                "Each reset adds one undo snapshot and one checkpoint")
            check(lastState.focus==focusState and not lastState.resetPrompt and player.controlsDisabled,
                "Reset resumes editing with its focus state and control lock")
            for tip in pairs(anchors) do
                local expectedAnchor=realRig.anchor(expected,tip)
                check(lastState.locks[tip] and same(lastState.locks[tip].target,expectedAnchor.target)
                    and same(lastState.locks[tip].rotation,expectedAnchor.rotation),
                    "Branch and pose resets keep enabled locks at their resulting positions and facing")
            end
            if scope=="entire" then
                check(lastState.symmetry=="entire","Entire reset restores the asymmetric baseline without changing symmetry mode")
            end
            press("z",true)
            check(samePose(lastState.bones,before),"Undo restores the complete pose before reset")
            for tip,anchor in pairs(anchors) do
                check(same(lastState.locks[tip].target,anchor.target) and same(lastState.locks[tip].rotation,anchor.rotation),
                    "Undo restores pre-reset lock anchors")
            end
            press("y",true)
            check(samePose(lastState.bones,expected),"Redo restores the reset as one step")
            session.finish(false); controlsRestored()
        end
    end
    -- A reset selector owns input even before native menu mode activates.
    bones=realRig.clone(baseline)
    check(session.start(ref,api),"Start reset modal integration")
    select(calf); press("r"); rotate(0.2); press("f")
    local before=realRig.clone(lastState.bones)
    local undoCount,writeCount=#lastState.undo,#writes
    local focusState=lastState.focus
    press("backspace",false,true)
    local prompt=resetMenu.current
    check(not lastState.overlay.menu.visible and player.controlsDisabled==originalFlags.controlsDisabled,
        "Pending reset menu hides handles and releases player controls for native input")
    callbacks.mouseButtonDown({button=0}); callbacks.mouseAxis({deltaX=20,deltaY=10}); callbacks.mouseButtonUp({button=0})
    check(not lastState.drag and samePose(lastState.bones,before),"Reset modal blocks bone drags")
    for _,scan in ipairs({"backspace","enter","m","s","b","f","escape"}) do
        check(callbacks.keyDown({keyCode=tes3.scanCode[scan],isControlDown=true,isShiftDown=true})==nil,
            "Editor shortcuts yield keyboard input to the reset menu")
    end
    check(session.isActive() and lastState.resetPrompt==prompt and escapeTest(),"Reset menu retains native Escape handling")
    resetMenu.close(prompt); callbacks.enterFrame({})
    check(samePose(lastState.bones,before) and #lastState.undo==undoCount and #writes==writeCount
        and lastState.focus==focusState and lastState.overlay.menu.visible and player.controlsDisabled,
        "Cancel resumes editing without pose, history, checkpoint or focus changes")
    callbacks.mouseButtonDown({button=0})
    check(lastState.drag~=nil,"Start drag before reset shortcut checks")
    callbacks.keyDown({keyCode=tes3.scanCode.backspace,isControlDown=true})
    callbacks.keyDown({keyCode=tes3.scanCode.backspace,isShiftDown=true})
    check(not lastState.resetPrompt and samePose(lastState.bones,before),"Reset shortcuts cannot interrupt an active drag")
    callbacks.mouseButtonUp({button=0}); callbacks.enterFrame({})
    session.finish(false); controlsRestored()
    -- Live symmetry includes the full reset branch and updates opposite locks.
    for _,mode in ipairs({"entire","arms","legs"}) do
        bones=realRig.clone(baseline)
        check(session.start(ref,api),"Start limb reset with live symmetry")
        chooseSymmetry(mode); select(calf)
        local rightFoot=indices["bip01 r foot"]
        lastState.bones[rightFoot].rotation=v.mul(lastState.bones[rightFoot].rotation,v.axisAngle({0,1,0},0.4))
        lastState.bones[foot].rotation=v.mul(lastState.bones[foot].rotation,v.axisAngle({1,0,0},0.3))
        for tip in pairs(lastState.chains) do lastState.locks[tip]=realRig.anchor(lastState.bones,tip) end
        local before=realRig.clone(lastState.bones)
        local expected,touched=realRig.reset(before,baseline,calf,"limb")
        mirror.follow(expected,before,calf,mode,touched)
        press("backspace",true)
        check(samePose(lastState.bones,expected),"Limb reset mirrors its descendants only within the active symmetry scope")
        for tip in pairs(lastState.chains) do
            local anchor=realRig.anchor(expected,tip)
            check(same(lastState.locks[tip].target,anchor.target) and same(lastState.locks[tip].rotation,anchor.rotation),
                "Reset symmetry rebases affected opposite lock anchors")
        end
        session.finish(false); controlsRestored()
    end
    for _,exit in ipairs({"load","cellChanged","referenceDeactivated","rebuild","finish"}) do
        bones=realRig.clone(baseline)
        check(session.start(ref,api),"Start before reset menu cleanup")
        press("backspace",false,true)
        local stale=resetMenu.current
        if exit=="rebuild" then ref.sceneNode={}; callbacks.enterFrame({})
        elseif exit=="finish" then session.finish(false)
        else callbacks[exit]({reference=ref}) end
        check(not session.isActive() and stale.closed,"Every session exit closes the reset selector: "..exit)
        local written=#writes
        stale.onReset("entire")
        check(#writes==written and not session.isActive(),"Late reset callbacks cannot change a finished session")
        controlsRestored()
    end
    check(session.start(ref,api),"Start before reset checkpoint failure")
    press("backspace",false,true)
    writeError=true; resetCommand("entire")
    check(not session.isActive(),"Reset checkpoint failure restores and cleans up the session")
    writeError=false; controlsRestored()
end
for _,focused in ipairs({false,true}) do
    for _,exit in ipairs({"load","cellChanged","referenceDeactivated","rebuild","finish"}) do
        check(session.start(ref,api),"Start before full-help lifecycle checks")
        if focused then focusKey() end
        local focusState=lastState.focus
        callbacks.keyDown({keyCode=tes3.scanCode.h})
        local beforeDestroyed=overlayDestroyed
        callbacks.enterFrame({menuMode=false})
        check(lastState.expandedControls and lastState.focus==focusState
            and lastState.overlay.menu.visible and lastState.overlay.markersMenu.visible,
            "Expanded default controls preserve focus and keep handles visible")
        if exit=="rebuild" then ref.sceneNode={}; callbacks.enterFrame({menuMode=false})
        elseif exit=="finish" then session.finish(false)
        else callbacks[exit]({reference=ref}) end
        check(not session.isActive() and overlayDestroyed==beforeDestroyed+1,"Every session exit removes the existing expanded controls: "..exit)
        local written=#writes
        callbacks.enterFrame({menuMode=false})
        check(not session.isActive() and #writes==written,"Later frames cannot restart or write to a finished session")
        controlsRestored()
    end
end
dofile("tests/ground_session_fixture.lua")({
    check=check,rig=realRig,callbacks=callbacks,session=session,ref=ref,api=api,menu=groundMenu,player=player,
    relaxed=templateBones,press=press,same=same,samePose=samePose,controlsRestored=controlsRestored,
    state=function() return lastState end,frame=function() return rigFrame end,
    setBones=function(value) bones=realRig.clone(value) end,
    setRelaxed=function(value) blendPoses["oaab/k/mann_relax.nif"]=realRig.clone(value) end,
    setReadError=function(value) blendReadError=value end,
    setWriteError=function(value) writeError=value end,
    writes=function() return #writes end,reads=function() return #blendReads end,
    saved=function() return savedPoseData[#savedPoseData] end,
})
local custom="pose/k/Edit.nif"
local customLabel="Edit"
local replacements,refreshes=0,0
function library.find(file)
    if file==custom then return {file=custom,label=customLabel} end
end
function library.label(file) return file==custom and customLabel or "Copy" end
function library.poseId() return "Edit" end
function library.updateMetadata(file,fields) assert(file==custom and fields.id=="Edit"); customLabel=fields.name; return file end
function library.replace(pose,file,apply)
    assert(file==custom)
    replacements=replacements+1
    if writeError then error("Disk full") end
    apply(file)
    return file
end
function api.refreshFile(file,except) assert(file==custom and except==ref); refreshes=refreshes+1 end
local function saveAction(action)
    local prompt=saveMenu.current
    saveMenu.close(prompt)
    prompt.onAction(action)
end
local function submitName(name,id)
    local prompt=namePrompt.current
    namePrompt.close(prompt)
    prompt.onSave({name=name,id=id or "Edit",description="",category=""})
end
for _,baseline in ipairs({"oaab/k/mann_relax.nif","oaab/k/mann_contrapposto.nif",
    "oaab/k/mann_adlocutio.nif","OAAB\\K\\MANN_ADLOCUTIO2.NIF",false}) do
    selection=baseline or nil
    if baseline then
        check(not session.start(ref,api,baseline) and not session.isActive(),"Baseline poses refuse explicit Edit Pose entry")
        check(lastReport:find("Baseline OAAB poses cannot be edited",1,true),"Refused baseline editing explains how to create a custom copy")
    end
    check(session.start(ref,api),"Baseline poses remain available as starting points for new custom poses")
    local beforeWrites,beforeReplacements=#writes,replacements
    press("s",true)
    check(lastReport:find("Baseline OAAB poses cannot be overwritten",1,true) and lastReport:find("Press Enter",1,true),
        "Ctrl+S on baseline poses explains the protection and Save As action")
    check(not lastState.namePrompt and not lastState.savePrompt and #writes==beforeWrites and replacements==beforeReplacements
        and selection==(baseline or nil),"Ctrl+S on baselines writes nothing, preserves selection and keeps editing active")
    local previousReport=lastReport
    press("s",true,true)
    check(not lastState.namePrompt and not lastState.savePrompt and #writes==beforeWrites and lastReport==previousReport
        and lastState.symmetry=="off","Removed Ctrl+Shift+S performs no save, Save As or symmetry action")
    press("enter")
    check(lastState.namePrompt and namePrompt.current.options.button=="Save As","Enter opens Save As from a baseline starting point")
    session.finish(false); controlsRestored()
end
selection=custom
check(session.start(ref,api),"Create can still start from a custom pose without taking overwrite ownership")
local beforeNewWrites=#writes
press("s",true)
check(lastReport:find("No saved pose is being edited",1,true) and not lastState.namePrompt and #writes==beforeNewWrites,
    "Ctrl+S does not silently save or overwrite a new pose started from a custom source")
press("enter")
check(lastState.namePrompt and not lastState.editFile,"Create uses Save As even when the mannequin already has a custom pose")
session.finish(false); controlsRestored()
selection=custom
check(session.start(ref,api,custom),"A mannequin can intentionally edit its selected custom pose")
check(lastState.editFile==custom and lastState.editLabel=="Edit","Edit retains the saved identity and its display name")
local editWrites=#writes
press("enter")
check(lastState.savePrompt and not lastState.namePrompt and #writes==editWrites,"Enter offers saved-pose actions before writing")
check(callbacks.keyDown({keyCode=tes3.scanCode.escape})==nil and session.isActive(),"Escape belongs to the save menu")
saveMenu.close(saveMenu.current)
check(player.controlsDisabled and session.isActive(),"Closing the save menu resumes editing")
press("enter"); saveAction("rename")
check(namePrompt.current.options.immutableId and namePrompt.current.options.button=="Save Metadata",
    "Rename preselects this saved identity and accepts its own name")
submitName("Renamed")
check(session.isActive() and selection==custom and lastState.editLabel=="Renamed" and #writes==editWrites,
    "Rename preserves selection, unsaved edits and editor ownership")
press("enter"); saveAction("as")
check(namePrompt.current.initial.name=="Renamed" and namePrompt.current.initial.id==""
    and not namePrompt.current.options.allowOverwrite and namePrompt.current.options.button=="Save As",
    "Save As requests a fresh ID without offering overwrite")
submitName("Separate")
check(not session.isActive() and selection~=custom and savedNames[#savedNames]=="Separate" and replacements==0,
    "Save As exports current edits under another identity")
controlsRestored()
selection=custom
check(session.start(ref,api,custom),"Restart Edit Pose for replacement failures")
local failures=#failedSaves
writeError=true
press("s",true)
check(session.isActive() and selection==custom and #failedSaves==failures,
    "Save Changes write failure never deletes the saved pose or ends editing")
writeError=false; loadError=true
press("s",true)
check(session.isActive() and selection==custom and #failedSaves==failures,
    "Replacement application failure restores ownership without new-file cleanup")
loadError=false
callbacks.keyDown({keyCode=tes3.scanCode.s,isControlDown=true})
check(not session.isActive() and selection==custom and refreshes==1,
    "Ctrl+S saves the same identity and refreshes other users after successful commit")
controlsRestored()
selection=custom
check(session.start(ref,api,custom),"Restart for Enter Save As")
local beforeRemovedShortcutWrites,beforeRemovedShortcutReplacements=#writes,replacements
press("s",true,true)
check(not lastState.namePrompt and not lastState.savePrompt and #writes==beforeRemovedShortcutWrites
    and replacements==beforeRemovedShortcutReplacements and lastState.symmetry=="off",
    "Ctrl+Shift+S has no action even when editing a custom pose")
press("enter"); saveAction("as")
check(lastState.namePrompt and not namePrompt.current.options.allowOverwrite,"Enter's Save As action requires a new ID")
namePrompt.close(namePrompt.current)
callbacks.keyDown({keyCode=tes3.scanCode.s,isControlDown=true})
check(not session.isActive() and selection==custom and refreshes==2,"Save Changes preserves the selected immutable identity")
controlsRestored()
for _,exit in ipairs({"load","cellChanged","referenceDeactivated","rebuild","finish"}) do
    selection=custom
    check(session.start(ref,api,custom),"Start for saved-pose dialog lifecycle")
    press("enter")
    local stale=saveMenu.current
    if exit=="rebuild" then ref.sceneNode={}; callbacks.enterFrame({})
    elseif exit=="finish" then session.finish(false)
    else callbacks[exit]({reference=ref}) end
    check(not session.isActive() and stale.closed,"Session exit closes the save action dialog: "..exit)
    local previous=replacements
    stale.onAction("changes")
    check(previous==replacements,"Late save-menu callbacks cannot replace a file")
    controlsRestored()
end
selection="changed.nif"
check(not session.start(ref,api,custom) and not session.isActive(),"A changed selection cannot silently edit the earlier pose")
print("PASS: "..count.." session/lifecycle assertions")
