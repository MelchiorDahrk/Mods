package.path="./MWSE/mods/?.lua;"..package.path
local focus=require("MannequinPoseDesigner.focus")
local lighting=dofile("tests/focus_lighting_fixture.lua")
local floorFixture=dofile("tests/focus_floor_fixture.lua")
local floorPosition=lighting.vector(25,-40,12)
local count=0
local function check(ok,reason) assert(ok,reason); count=count+1 end
local nodes={}
local function node(kind,culled)
    local result={kind=kind or "NiNode",appCulled=culled or false,children={}}
    function result:isInstanceOfType(wanted) return self.kind==wanted end
    nodes[#nodes+1]=result
    return result
end
local function attach(parent,child,index)
    parent.children[index or #parent.children+1]=child
    child.parent=parent
end
local function visible(value)
    while value do
        if value.appCulled then return false end
        value=value.parent
    end
    return true
end
local root,pick,cell,scene=node(),node(),node(),node()
lighting.node(scene)
local cameraPosition=lighting.vector(0,-200,70)
attach(root,pick,3); attach(pick,cell,5); attach(cell,scene,9)
local body,outfit,hiddenPart=node("NiTriShape"),node("NiTriShape"),node("NiTriShape",true)
attach(scene,body); attach(scene,outfit); attach(scene,hiddenPart)
local otherActor,otherBody=node(),node("NiTriShape")
attach(cell,otherActor,12); attach(otherActor,otherBody)
local landscape,water,sky=node(),node(),node()
attach(root,landscape,6); attach(root,water,8); attach(root,sky,13)
local statics,lamp,bulb,lampMesh=node(),node(),node("NiLight"),node("NiTriShape")
attach(root,statics,16); attach(statics,lamp); attach(lamp,bulb); attach(lamp,lampMesh)
local hiddenStatic=node("NiTriShape",true); attach(statics,hiddenStatic)
local camera,handles,pearl=node(),node(),node("NiTriShape")
attach(root,camera,19); attach(root,handles,22); attach(handles,pearl)
local uiRoot,uiText=node(),node("NiTriShape")
attach(root,uiRoot,24); attach(uiRoot,uiText)
-- Native water can use a separate render pass, outside worldCamera.root.
local nativeWater,nativeRipples=node(),node()
local waterController={waterShown=true,waterPlane=nativeWater,rippleNode=nativeRipples}
-- Loaded terrain also has its own render root, outside the object scene.
local terrainRoot,terrainCell,terrainShape,hiddenTerrain=node(),node(),node("NiTriShape"),node("NiTriShape",true)
attach(terrainRoot,terrainCell,4); attach(terrainCell,terrainShape,7); attach(terrainCell,hiddenTerrain,11)
-- The sun disc and glare are also rendered outside the world scene/ToggleSky.
local sunBase,sunVis,sunDisc=node(),node(),node("NiTriShape")
local sunGlare,glareShape=node("NiNode",true),node("NiTriShape")
attach(sunBase,sunVis,3); attach(sunVis,sunDisc,7); attach(sunGlare,glareShape,5)
local originals={}
for _,value in ipairs(nodes) do originals[value]=value.appCulled end
local audioValues={volumeEffects=0.65,volumeMaster=0.8,volumeMusic=0.4,volumeVoice=0.7,volumeFootsteps=0.9,
    isMusicPlaying=true,isMusicPaused=false,currentMusicFilePath="Music/Explore/test.mp3"}
local playingEffectsVolume=0.8*0.65
local audioController=setmetatable({}, {
    __index=audioValues,
    __newindex=function(_,name,value)
        audioValues[name]=value
        -- This updates tracked effect loops, but not native weather buffers.
        if name=="volumeEffects" or name=="volumeMaster" then
            playingEffectsVolume=audioValues.volumeMaster*audioValues.volumeEffects
        end
    end})
local nativeSounds={}
local function weatherSound(volume)
    local source={volume=volume,bufferVolume=audioValues.volumeMaster*audioValues.volumeEffects*volume}
    nativeSounds[#nativeSounds+1]=source
    return setmetatable({}, {
        __index=source,
        __newindex=function(_,name,value)
            assert(name=="volume","Only refresh the weather sound's volume")
            assert(value==source.volume,"Refreshing buffers must preserve sound definitions")
            source.bufferVolume=audioValues.volumeMaster*audioValues.volumeEffects*value
        end})
end
local wind,rain,thunder=weatherSound(0.6),weatherSound(0.8),weatherSound(0.5)
local function weather(values,rainy,storm)
    local allowed={ambientLoopSound=true}
    if rainy then allowed.rainLoopSound=true end
    if storm then for i=1,4 do allowed["thunderSound"..i]=true end end
    return setmetatable(values,{__index=function(_,name)
        assert(allowed[name],"Unsupported weather property: "..name)
    end})
end
local weatherController={sceneSunBase=sunBase,sceneSunVis=sunVis,sceneSunGlare=sunGlare,weathers={
    [0]=weather({}),[1]=weather({ambientLoopSound=wind}),
    [4]=weather({ambientLoopSound=wind,rainLoopSound=rain},true),
    [5]=weather({ambientLoopSound=wind,rainLoopSound=rain,thunderSound1=thunder},true,true),
}}
local menu={aiDisabled=true,worldDisabled=true,skyDisabled=false}
local hud={visible=true}
tes3ui={findMenu=function(name)
    assert(name=="MenuMulti","Only the gameplay HUD should be hidden")
    return hud
end}
tes3={niType={NiNode="NiNode",NiLight="NiLight"},weather={rain=4,thunder=5},
    getCameraPosition=function() return cameraPosition end,
    worldController={menuController=menu,audioController=audioController,weatherController=weatherController,
    worldCamera={root=root,cameraRoot=camera},menuCamera={root=uiRoot,cameraRoot=uiRoot},simulationTimeScalar=1.25},
    dataHandler={waterController=waterController,worldLandscapeRoot=terrainRoot}}
floorFixture.install(root,lighting)
local originalFeatures={distantLand=true,distantStatics=false,distantWater=true,grass=true,shaders=true,noMWSunglare=false}
local sunshafts={enabled=true,alive=true}
local shaders={Sunshafts=sunshafts,["Bloom Soft"]={enabled=true},["SSAO HQ"]={enabled=false}}
local function shaderHandle(source)
    if not source then return end
    -- A fresh handle on every lookup; handles from a replaced chain are invalid.
    return setmetatable({}, {
        __index=function(_,name)
            assert(source.alive,"A stale shader handle was read")
            assert(name=="enabled","Only change the shader enabled state")
            return source.enabled
        end,
        __newindex=function(_,name,value)
            assert(source.alive,"A stale shader handle was written")
            assert(name=="enabled" and type(value)=="boolean","Only change the shader enabled state")
            source.enabled=value
        end})
end
mge={enabled=function() return true end,render={},shaders={find=function(params)
    assert(params.name=="Sunshafts","Only look up the sun post-processing shader")
    return shaderHandle(shaders[params.name])
end}}
local function renderedSun()
    -- Sunshafts generates a disc independently of all native culling flags.
    return visible(sunDisc) or (mge.render.shaders and shaders.Sunshafts and shaders.Sunshafts.enabled)
end
for name,value in pairs(originalFeatures) do mge.render[name]=value end
local function restore(state)
    focus.restore(state,function(fn) local ok,err=pcall(fn); assert(ok,err) end)
end
local function restored()
    for _,floor in ipairs(floorFixture.floors) do
        check(floor.parent==nil and floor.appCulled and #floor.effectList==0,
            "Focus exit removes and unlights every temporary floor")
    end
    check(#scene.effectList==0 and #scene.renderEffects==0,"Focus exit removes the temporary lighting from the mannequin")
    for _,light in ipairs(lighting.lights) do
        check(not light.enabled and #light.affectedNodes==0,"Temporary lights cannot keep affecting a scene after cleanup")
    end
    for value,culled in pairs(originals) do check(value.appCulled==culled,"Restore every original culling flag") end
    for name,value in pairs(originalFeatures) do check(mge.render[name]==value,"Restore each original MGE feature") end
    check(sunshafts.enabled and shaders["Bloom Soft"].enabled and not shaders["SSAO HQ"].enabled,
        "Restore Sunshafts without changing unrelated shader states")
    check(menu.aiDisabled and menu.worldDisabled and not menu.skyDisabled
        and tes3.worldController.simulationTimeScalar==1.25,"Restore original console flags and time")
    check(waterController.waterShown,"Restore native water rendering")
    check(hud.visible,"Restore gameplay HUD visibility")
    check(audioController.volumeMaster==0.8 and playingEffectsVolume==0.8*0.65,"Restore the original master volume and playing loops")
    check(audioController.volumeEffects==0.65 and audioController.volumeMusic==0.4
        and audioController.volumeVoice==0.7 and audioController.volumeFootsteps==0.9,"Preserve other audio sliders")
    for _,sound in ipairs(nativeSounds) do
        check(sound.bufferVolume==0.8*0.65*sound.volume,"Restore native weather buffers with the original master mix")
    end
end
audioController.volumeEffects=0
check(rain.bufferVolume>0,"Fixture reproduces rain remaining audible after setting Effects volume to zero")
audioController.volumeEffects=0.65
local state=focus.capture(floorPosition)
focus.update(state,scene,handles)
check(not renderedSun() and not sunshafts.enabled and mge.render.noMWSunglare,
    "Hide the procedural Sunshafts disc/rays and native sunglare, not just the native scene nodes")
local focusLight=state.light.source
local floor=state.floor
check(floor.parent==root and visible(floor) and visible(floor.children[1]) and not floor.collisionActive,
    "Focus retains the generated grid in the scene without introducing collision")
check(floor.worldBoundOrigin:distance(floorPosition)==0 and floor.worldTransform.scale==8,
    "The grid is centered at the original grounding plane using CSSE's half-spacing scale")
check(state.gridVertexCount==416,"The grid's radius is doubled with radial samples and unchanged 16-unit spacing")
check(floor.renderEffects[1]==focusLight,"The focus floor remains lit when world lighting is hidden")
local floorMesh=floor.children[1]
check(floorMesh.renderProperties.alphaProperty==floorMesh.alphaProperty
    and floorMesh.alphaProperty.propertyFlags==8429 and floorMesh.alphaProperty.alphaTestRef==0
    and floorMesh.materialProperty.alpha==0.5 and floorMesh.vertexColors[1].a==0 and floorMesh.vertexColors[2].a==0.1
    and floorMesh.vertexColors[3].a==0.2 and floorMesh.vertexColors[4].a==0,
    "Scene attachment preserves alpha blending, radial opacity and transparent edges")
check(floorFixture.fragmentAlpha(floorMesh,0,0.8,1)==0
    and floorFixture.fragmentAlpha(floorMesh,0.2,0.8,1)==0.1
    and floorMesh.renderProperties.vertexColorProperty.source==1
    and floorMesh.renderProperties.vertexColorProperty.lighting==0,
    "The grid uses translucent emissive vertex colors despite opaque world-root defaults")
check(floorFixture.fragmentAlpha(floorMesh,1,0.8,0.5)==0
    and floorMesh.renderProperties.zBufferProperty.propertyFlags==1,
    "Mannequin depth rejects grid lines behind it and the transparent grid does not write depth")
check(root.vertexColorProperty.source==0 and root.zBufferProperty.propertyFlags==0,
    "Floor render properties do not change the world, mannequin or handle defaults")
check(#scene.effectList==1 and scene.renderEffects[1]==focusLight and focusLight.affectedNodes[1]==scene,
    "Focus supplies lighting to the mannequin's full subtree without relying on the hidden sky")
check(focusLight.parent==nil and #focusLight.affectedNodes==2 and focusLight.affectedNodes[2]==floor,
    "The temporary light affects the mannequin and floor without lighting the world or pearl handles")
local normalLight=node("NiLight")
scene:attachEffect(normalLight)
scene:updateEffects()
check(focusLight.ambient.r>=0.4 and focusLight.diffuse.r>0 and focusLight.dimmer==1,
    "Even surfaces facing away from the camera receive neutral fill while diffuse light preserves shading")
check(focusLight.constantAttenuation==1 and focusLight.linearAttenuation==0 and focusLight.quadraticAttenuation==0,
    "Studio brightness does not fall with camera distance")
local lightCount=#lighting.lights
local floorLoads=floorFixture.loads
cameraPosition=lighting.vector(150,-650,220)
scene:detachEffect(focusLight); focusLight:detachAffectedNode(scene); scene:updateEffects()
focus.update(state,scene,handles)
check(state.floor==floor and floorFixture.loads==floorLoads and visible(floor),
    "Rendering repeatedly reuses a single floor and keeps it visible")
local originalRadius=scene.worldBoundRadius
scene.worldBoundRadius=180
focus.update(state,scene,handles)
check(state.floor==floor and state.gridVertexCount==736 and floorFixture.loads==floorLoads+1
    and #floor.children==1 and not floorMesh.parent,
    "Changing the mannequin bounds regenerates the line grid and releases the old geometry")
scene.worldBoundRadius=181
focus.update(state,scene,handles)
check(floorFixture.loads==floorLoads+1,"Bounds changes within one grid step reuse the existing geometry")
scene.worldBoundRadius=1e9
focus.update(state,scene,handles)
check(state.gridVertexCount==736 and floorFixture.loads==floorLoads+1,
    "An oversized bound retains the previous grid without exceeding the native vertex limit")
scene.worldBoundRadius=originalRadius
focus.update(state,scene,handles)
local validGrid=state.gridMesh
local reloads=floorFixture.loads
floorFixture.rejectVertexCount=736
scene.worldBoundRadius=180
focus.update(state,scene,handles)
check(state.gridMesh==validGrid and state.gridVertexCount==416 and state.failedGridVertexCount==736
    and #floor.children==1 and validGrid.parent==floor and visible(validGrid),
    "A rejected native resize retains only the last validated grid in the scene")
for _=1,5 do focus.update(state,scene,handles) end
check(floorFixture.loads==reloads+1 and tes3.worldController.simulationTimeScalar==0 and not hud.visible,
    "A rejected grid size is not reloaded every render and focus stays active")
scene.worldBoundRadius=200
focus.update(state,scene,handles)
check(state.gridVertexCount==864 and state.failedGridVertexCount==nil and not validGrid.parent,
    "A later valid grid size replaces the fallback normally")
floorFixture.rejectVertexCount=nil
scene.worldBoundRadius=originalRadius
focus.update(state,scene,handles)
check(#lighting.lights==lightCount and #scene.effectList==2 and scene.renderEffects[2]==focusLight,
    "A native lighting rebuild is repaired without duplicate lights or losing existing effects")
check(focusLight.worldPosition:distance(cameraPosition)==0 and focusLight.radius>cameraPosition:distance(scene.worldBoundOrigin)+scene.worldBoundRadius,
    "The light follows the rendered camera and covers the whole mannequin after pan, tilt and zoom")
scene:detachEffect(normalLight); scene:updateEffects()
check(visible(body) and visible(outfit) and not visible(hiddenPart),"The full mannequin and outfit retain their individual visibility")
check(visible(pearl) and visible(camera),"Pearls and camera survive isolation")
check(visible(uiText),"A shared UI scene remains visible")
check(not hud.visible,"Focus hides the gameplay HUD while retaining the shared UI scene")
check(not visible(terrainShape) and terrainShape.appCulled and not visible(hiddenTerrain),
    "The independent landscape root and directly rendered terrain geometry are hidden")
check(not waterController.waterShown and not visible(nativeWater) and not visible(nativeRipples),
    "The native fallback water plane and ripples are hidden even outside the world root")
check(not visible(otherBody) and not visible(landscape) and not visible(water) and not visible(sky),
    "Nearby actors, terrain, water and sky are hidden")
check(sunBase.appCulled and sunVis.appCulled and sunDisc.appCulled and sunGlare.appCulled and glareShape.appCulled,
    "The separate sun disc and glare roots and directly rendered geometry are hidden")
check(visible(bulb) and not visible(lampMesh),"Lighting survives while the lamp's visible geometry is hidden")
check(not mge.render.distantLand and not mge.render.distantStatics and not mge.render.distantWater
    and not mge.render.grass and mge.render.shaders,"MGE background passes are disabled while the shader chain remains enabled")
check(shaders["Bloom Soft"].enabled and not shaders["SSAO HQ"].enabled,
    "Focus preserves enabled and disabled shaders unrelated to the sun")
check(not menu.worldDisabled and menu.skyDisabled and tes3.worldController.simulationTimeScalar==0,
    "Isolation overrides a prior ToggleWorld state to render the mannequin")
check(audioController.volumeMaster==0 and playingEffectsVolume==0,
    "Focus mutes master volume and tracked looping sounds immediately")
check(audioController.volumeMaster*audioController.volumeVoice==0
    and audioController.volumeMaster*audioController.volumeFootsteps==0,
    "Voice and footstep mixes are also silent")
check(audioController.volumeMusic==0.4 and audioController.isMusicPlaying and not audioController.isMusicPaused
    and audioController.currentMusicFilePath=="Music/Explore/test.mp3","Music keeps its volume, playback and track")
check(audioController.volumeEffects==0.65 and audioController.volumeVoice==0.7 and audioController.volumeFootsteps==0.9,
    "Muting master preserves the individual sound channel sliders")
check(rain.bufferVolume==0 and wind.bufferVolume==0 and thunder.bufferVolume==0,
    "Focus also silences native rain, wind and thunder buffers")
handles.appCulled=true
focus.update(state,scene,handles)
check(not visible(pearl) and visible(outfit),"The overlay can still hide handles for modal menus")
handles.appCulled=false
local added=node("NiTriShape"); attach(cell,added,31)
focus.update(state,scene,handles)
check(not visible(added),"New background children on retained scene paths are also hidden")
landscape.appCulled=false; pick.appCulled=true
waterController.waterShown=true; nativeWater.appCulled=false; nativeRipples.appCulled=false
terrainRoot.appCulled=false; terrainShape.appCulled=false
sunBase.appCulled=false; sunVis.appCulled=false; sunDisc.appCulled=false
sunGlare.appCulled=false; glareShape.appCulled=false
sunshafts.enabled=true; mge.render.noMWSunglare=false
hud.visible=true
audioController.volumeMaster=0.2
nativeSounds[2].bufferVolume=0.8 -- Native weather updates can bypass the effects mix.
focus.update(state,scene,handles)
check(not visible(landscape) and visible(body),"Render-time masking repairs engine changes to background and ancestor flags")
check(not waterController.waterShown and not visible(nativeWater) and not visible(nativeRipples),
    "Render-time masking also repairs native water flags")
check(terrainRoot.appCulled and terrainShape.appCulled,"Terrain render flags are repaired after engine updates")
check(sunBase.appCulled and sunVis.appCulled and sunDisc.appCulled and sunGlare.appCulled and glareShape.appCulled,
    "Render-time masking repairs sun visibility reset by the weather engine")
check(not renderedSun() and mge.render.noMWSunglare,"Render-time masking also repairs re-enabled Sunshafts and native glare")
check(not hud.visible,"Render-time masking hides a HUD made visible again by the engine")
check(audioController.volumeMaster==0 and playingEffectsVolume==0,"Focus reapplies muting after master volume changes")
check(rain.bufferVolume==0,"Render-time muting repairs a rain buffer reset by the weather engine")
local savedCount=#state.visibility
root.children[6]=nil; attach(root,landscape,36)
cell.children[9]=nil; attach(cell,scene,29)
focus.update(state,scene,handles)
check(visible(outfit) and not visible(landscape) and #state.visibility==savedCount,
    "Moving nodes to other child slots preserves native identity and original snapshots")
root.children[36]=nil; attach(root,landscape,6)
cell.children[29]=nil; attach(cell,scene,9)
restore(state)
restored()
check(not added.appCulled,"Newly observed background nodes recover their original visibility")
restore(state)
restored()

-- Preserve a fixed grounding grid under a transformed world scene parent.
local parentTransform=root.worldTransform
parentTransform.translation=lighting.vector(100,200,-30)
parentTransform.rotation=require("MannequinPoseDesigner.math3d").axisAngle({0,0,1},math.pi/2)
parentTransform.scale=2
state=focus.capture(floorPosition); focus.update(state,scene,handles)
local fixedFloor=state.floor
check(fixedFloor.worldBoundOrigin:distance(floorPosition)<1e-8 and fixedFloor.worldTransform.scale==8,
    "A translated, rotated and scaled world parent preserves the grid's world position and spacing")
local identity={1,0,0,0,1,0,0,0,1}
for i,value in ipairs(identity) do
    check(math.abs(fixedFloor.worldTransform.rotation[i]-value)<1e-8,"Parent rotation cannot tilt or turn the world-aligned grid")
end
floorPosition.x=floorPosition.x+100 -- The capture must own the original position.
local originalOrigin=scene.worldBoundOrigin
scene.worldBoundOrigin=lighting.vector(2000,-1000,900)
focus.update(state,scene,handles)
check(fixedFloor.worldBoundOrigin.x==25 and fixedFloor.worldBoundOrigin.z==12,
    "Pose/root movement and later position changes cannot move the original grounding grid")
check(state.light.source.radius>cameraPosition:distance(fixedFloor.worldBoundOrigin)+fixedFloor.worldBoundRadius,
    "The light still covers the floor when the mannequin moves away")
scene.worldBoundOrigin=originalOrigin; floorPosition.x=25
restore(state)
parentTransform.translation=lighting.vector(0,0,0); parentTransform.rotation=identity; parentTransform.scale=1
restored()

-- A rejected first grid must not prevent safe isolation and lighting.
local gridCount=require("MannequinPoseDesigner.focus_grid").vertexCount(scene.worldBoundRadius)
floorFixture.rejectVertexCount=gridCount
local rejectedLoads=floorFixture.loads
state=focus.capture(floorPosition); focus.update(state,scene,handles)
check(state.activationComplete and not state.gridMesh and #state.floor.children==0
    and state.failedGridVertexCount==gridCount and not hud.visible
    and tes3.worldController.simulationTimeScalar==0 and visible(scene),
    "A rejected initial native grid still activates focus with an empty safe floor")
check(state.light.source.enabled and #state.light.source.affectedNodes==2,
    "Focus lighting covers the mannequin even without grid geometry")
for _=1,5 do focus.update(state,scene,handles) end
check(floorFixture.loads==rejectedLoads+1,"An unavailable initial grid is not reloaded each frame")
floorFixture.rejectVertexCount=nil
local gridRadius=scene.worldBoundRadius
scene.worldBoundRadius=180; focus.update(state,scene,handles)
check(state.gridMesh and state.gridVertexCount==736 and not state.failedGridVertexCount
    and #state.floor.children==1 and state.gridMesh.parent==state.floor,
    "A later valid size restores the grid after an initial rejection")
scene.worldBoundRadius=gridRadius
restore(state); restored()

-- A missing mesh also leaves focus usable; partial attachment still cleans up.
local loadFloor=tes3.loadMesh
tes3.loadMesh=function() return nil end
state=focus.capture(floorPosition)
focus.update(state,scene,handles)
check(state.activationComplete and not state.gridMesh,"A missing grid does not abort activation")
restore(state); tes3.loadMesh=loadFloor; restored()
local attachFloor=root.attachChild
root.attachChild=function(self,child) attachFloor(self,child); error("Floor attachment interrupted") end
state=focus.capture(floorPosition)
check(not pcall(focus.update,state,scene,handles) and state.floor.parent==root,
    "The fixture interrupts activation after the floor joins the world")
restore(state); root.attachChild=attachFloor; restored()

-- Existing scene effects survive the light's complete activation/cleanup cycle.
scene:attachEffect(normalLight); scene:updateEffects()
state=focus.capture(floorPosition); focus.update(state,scene,handles); restore(state)
check(#scene.effectList==1 and scene.renderEffects[1]==normalLight,
    "Turning focus off preserves the mannequin's original lighting effects")
scene:detachEffect(normalLight); scene:updateEffects()
restored()

-- Failure after attaching the light must release both native attachment lists.
local attachEffect=scene.attachEffect
local failLightAttachment=true
scene.attachEffect=function(self,light)
    attachEffect(self,light)
    if failLightAttachment then failLightAttachment=false; error("Light attachment interrupted") end
end
state=focus.capture(floorPosition)
local lightOK=pcall(focus.update,state,scene,handles)
check(not lightOK and #scene.effectList==1,"Fixture fails after the temporary light is partly attached")
restore(state)
scene.attachEffect=attachEffect
restored()

-- Preserve a silent channel, and capture the latest volume on each activation.
for _,volume in ipairs({0,0.35,1}) do
    audioController.volumeMaster=volume
    state=focus.capture(floorPosition); focus.update(state,scene,handles); restore(state)
    check(audioController.volumeMaster==volume and playingEffectsVolume==volume*0.65,
        "Restore an already muted or adjusted master channel")
    check(rain.bufferVolume==volume*0.65*rain.volume,"Rain buffers follow the restored master mix")
end
audioController.volumeMaster=0.8
state=focus.capture(floorPosition); focus.update(state,scene,handles); restore(state)
local savedWeather=tes3.worldController.weatherController
tes3.worldController.weatherController=nil
state=focus.capture(floorPosition); focus.update(state,scene,handles); restore(state)
tes3.worldController.weatherController=savedWeather
restored()

state=focus.capture(floorPosition); focus.update(state,scene,handles)
local replacementRain=weatherSound(0.4)
weatherController.weathers[4].rainLoopSound=replacementRain
focus.update(state,scene,handles)
check(replacementRain.bufferVolume==0,"A replacement rain buffer is muted on the next frame")
restore(state)
weatherController.weathers[4].rainLoopSound=rain
restored()

tes3.worldController.audioController=nil
state=focus.capture(floorPosition); focus.update(state,scene,handles); restore(state)
check(audioController.volumeMaster==0.8,"Focus also works without an audio controller")
tes3.worldController.audioController=audioController
restored()

-- Preserve hidden HUDs, observe late/rebuilt menus, and never write dead UI objects.
hud.visible=false
state=focus.capture(floorPosition); focus.update(state,scene,handles); restore(state)
check(not hud.visible,"An originally hidden HUD stays hidden on focus exit")
hud.visible=true
local installedHud=hud
hud=nil
state=focus.capture(floorPosition); focus.update(state,scene,handles)
check(state.hud==nil,"Focus works while the HUD is absent")
hud=installedHud
focus.update(state,scene,handles)
check(not hud.visible,"A HUD appearing during focus is hidden on the next frame")
restore(state)
restored()
hud.visible=false
state=focus.capture(floorPosition); focus.update(state,scene,handles)
local replacedHud=hud
hud={visible=true}
setmetatable(replacedHud,{__newindex=function() error("Destroyed HUD accessed") end})
replacedHud.visible=nil
focus.update(state,scene,handles)
check(not hud.visible,"A rebuilt HUD is hidden without reusing its predecessor's visibility")
restore(state)
restored()
state=focus.capture(floorPosition); focus.update(state,scene,handles)
local destroyedHud=hud
hud=nil
destroyedHud.visible=nil
setmetatable(destroyedHud,{__newindex=function() error("Destroyed HUD accessed") end})
restore(state)
check(state.restored,"Cleanup tolerates a HUD destroyed before focus exit")
hud={visible=true}
restored()

-- No MGE interface: scene isolation still works, and inactive MGE properties are never read.
local installedMge=mge
mge={enabled=function() return false end}
state=focus.capture(floorPosition); focus.update(state,scene,handles)
check(visible(outfit) and not visible(landscape),"Focus works when MGE is disabled")
restore(state)
mge=nil
state=focus.capture(floorPosition); focus.update(state,scene,handles)
check(visible(outfit) and not visible(landscape),"Focus works without an MGE global")
restore(state)
mge=installedMge
restored()

-- Preserve disabled/missing shaders and suppress ones loaded during focus.
sunshafts.enabled=false; mge.render.noMWSunglare=true
state=focus.capture(floorPosition); focus.update(state,scene,handles); restore(state)
check(not sunshafts.enabled and mge.render.noMWSunglare,
    "Originally disabled Sunshafts and suppressed native glare retain their settings")
sunshafts.enabled=true; mge.render.noMWSunglare=false
restored()
shaders.Sunshafts=nil
state=focus.capture(floorPosition); focus.update(state,scene,handles)
check(state.sunShader.enabled==nil,"Focus works without loading a missing Sunshafts shader")
shaders.Sunshafts=sunshafts
focus.update(state,scene,handles)
check(not sunshafts.enabled,"Sunshafts loaded during focus is suppressed on the next render")
restore(state)
restored()
state=focus.capture(floorPosition); focus.update(state,scene,handles)
local oldSunshafts=sunshafts
oldSunshafts.alive=false
sunshafts={enabled=true,alive=true}; shaders.Sunshafts=sunshafts
focus.update(state,scene,handles)
check(not sunshafts.enabled,"A rebuilt shader chain is suppressed using its current handle")
restore(state)
restored()
local installedShaders=mge.shaders
mge.shaders=nil
state=focus.capture(floorPosition); focus.update(state,scene,handles); restore(state)
mge.shaders=installedShaders
restored()
-- A failure after the shader state changes must still restore its original state.
local failShader=true
shaders.Sunshafts=setmetatable({}, {
    __index=function(_,name) return sunshafts[name] end,
    __newindex=function(_,name,value)
        sunshafts[name]=value
        if failShader then failShader=false; error("Shader suspension interrupted") end
    end})
state=focus.capture(floorPosition)
local shaderOK=pcall(focus.update,state,scene,handles)
check(not shaderOK and not sunshafts.enabled,"Fixture fails after Sunshafts has partly been suspended")
restore(state)
shaders.Sunshafts=sunshafts
restored()

local installedHandler=tes3.dataHandler
tes3.dataHandler=nil
state=focus.capture(floorPosition); focus.update(state,scene,handles)
check(visible(outfit) and not visible(landscape),"Scene isolation works without the native water interface")
restore(state)
tes3.dataHandler=installedHandler
restored()

waterController.waterShown=false; nativeWater.appCulled=true
state=focus.capture(floorPosition); focus.update(state,scene,handles); restore(state)
check(not waterController.waterShown and nativeWater.appCulled,
    "Originally disabled native water and its original culling state are restored")
waterController.waterShown=true; nativeWater.appCulled=false
restored()

-- Interiors start with terrain hidden; preserve the root and each child flag.
terrainRoot.appCulled=true
state=focus.capture(floorPosition); focus.update(state,scene,handles); restore(state)
check(terrainRoot.appCulled and not terrainShape.appCulled and hiddenTerrain.appCulled,
    "Originally hidden terrain retains the root and individual geometry flags")
terrainRoot.appCulled=false
restored()

-- A terrain root can also belong to the world scene; its root is not snapshotted twice.
attach(root,terrainRoot,28)
state=focus.capture(floorPosition); focus.update(state,scene,handles)
local terrainSnapshots=0
for _,entry in ipairs(state.visibility) do
    if entry.node==terrainRoot then terrainSnapshots=terrainSnapshots+1 end
end
check(terrainSnapshots==1 and terrainShape.appCulled,"Shared terrain render roots retain one original snapshot")
local replacementRoot,replacementShape=node(),node("NiTriShape")
attach(replacementRoot,replacementShape,2)
tes3.dataHandler.worldLandscapeRoot=replacementRoot
focus.update(state,scene,handles)
check(replacementRoot.appCulled and replacementShape.appCulled,"New terrain render roots are hidden on the next frame")
restore(state)
check(not replacementRoot.appCulled and not replacementShape.appCulled,"Replacement terrain restores its original flags")
tes3.dataHandler.worldLandscapeRoot=terrainRoot
root.children[28]=nil; terrainRoot.parent=nil
restored()

-- Shared/replaced sun nodes reuse original snapshots, including hidden glare.
attach(root,sunBase,28)
state=focus.capture(floorPosition); focus.update(state,scene,handles)
local sunSnapshots=0
for _,entry in ipairs(state.visibility) do if entry.node==sunBase then sunSnapshots=sunSnapshots+1 end end
check(sunSnapshots==1 and sunDisc.appCulled,"A sun root inside the world scene is snapshotted once")
local replacementSun,replacementDisc=node(),node("NiTriShape")
attach(replacementSun,replacementDisc,2)
weatherController.sceneSunVis=replacementSun
focus.update(state,scene,handles)
check(replacementSun.appCulled and replacementDisc.appCulled,"Replacement sun nodes are hidden on the next render")
restore(state)
check(not replacementSun.appCulled and not replacementDisc.appCulled,"Replacement sun nodes restore their original visibility")
weatherController.sceneSunVis=sunVis
root.children[28]=nil; sunBase.parent=nil
restored()

-- Sun nodes can be absent in interiors, then appear while focus is active.
weatherController.sceneSunBase=nil; weatherController.sceneSunVis=nil; weatherController.sceneSunGlare=nil
state=focus.capture(floorPosition); focus.update(state,scene,handles)
weatherController.sceneSunBase=sunBase; weatherController.sceneSunVis=sunVis; weatherController.sceneSunGlare=sunGlare
focus.update(state,scene,handles)
check(sunDisc.appCulled and glareShape.appCulled,"Sun nodes appearing after activation are hidden")
restore(state)
restored()

-- The native plane may also be part of the masked scene. Snapshot it only once.
waterController.waterPlane=water
state=focus.capture(floorPosition); focus.update(state,scene,handles)
local waterSnapshots=0
for _,entry in ipairs(state.visibility) do if entry.node==water then waterSnapshots=waterSnapshots+1 end end
check(waterSnapshots==1,"A native plane inside the world root has one original culling snapshot")
waterController.waterPlane=nativeWater
focus.update(state,scene,handles)
check(not visible(nativeWater),"A replacement native water plane is masked")
restore(state)
restored()

local cameraRootBefore=tes3.worldController.worldCamera.cameraRoot
local menuRootBefore=tes3.worldController.menuCamera.root
tes3.worldController.worldCamera.cameraRoot=root
tes3.worldController.menuCamera.root=root
state=focus.capture(floorPosition); focus.update(state,scene,handles)
check(visible(outfit) and not visible(landscape),"A camera sharing the world root does not retain the entire world")
restore(state)
tes3.worldController.worldCamera.cameraRoot=cameraRootBefore
tes3.worldController.menuCamera.root=menuRootBefore
restored()

-- A setter failure after earlier writes must not strand the scene or MGE features.
local failing=true
weatherController.weathers[4].rainLoopSound=setmetatable({}, {
    __index=function(_,name) return rain[name] end,
    __newindex=function(_,name,value)
        if failing then failing=false; error("Rain buffer unavailable") end
        rain[name]=value
    end})
state=focus.capture(floorPosition)
local ok=pcall(focus.update,state,scene,handles)
check(not ok,"A partial native weather muting failure is detected")
restore(state)
weatherController.weathers[4].rainLoopSound=rain
restored()

failing=true
tes3.worldController.audioController=setmetatable({}, {
    __index=function(_,name) return audioController[name] end,
    __newindex=function(_,name,value)
        if failing and name=="volumeMaster" and value==0 then failing=false; error("Master audio unavailable") end
        audioController[name]=value
    end})
state=focus.capture(floorPosition)
ok=pcall(focus.update,state,scene,handles)
check(not ok,"A partial master muting failure is detected")
restore(state)
tes3.worldController.audioController=audioController
restored()

local features=mge.render
failing=true
mge.render=setmetatable({}, {
    __index=function(_,name) return features[name] end,
    __newindex=function(_,name,value)
        if failing and name=="distantWater" then failing=false; error("MGE water unavailable") end
        features[name]=value
    end})
state=focus.capture(floorPosition)
ok=pcall(focus.update,state,scene,handles)
check(not ok,"A partial MGE activation failure is detected")
restore(state)
mge.render=features
restored()

failing=true
tes3.dataHandler={worldLandscapeRoot=terrainRoot,waterController=setmetatable({}, {
    __index=function(_,name) return waterController[name] end,
    __newindex=function(_,name,value)
        if failing and name=="waterShown" then failing=false; error("Native water unavailable") end
        waterController[name]=value
    end})}
state=focus.capture(floorPosition)
ok=pcall(focus.update,state,scene,handles)
check(not ok,"A partial native water activation failure is detected")
restore(state)
tes3.dataHandler=installedHandler
restored()

state=focus.capture(floorPosition)
local detached=node()
ok=pcall(focus.update,state,detached,handles)
check(not ok and visible(outfit),"A detached mannequin is rejected before masking the scene")
restore(state)
restored()

-- MWSE normally returns fresh smart-pointer userdata on each parent/child read.
-- Their == comparison tests the native pointer, but table keys use wrapper identity.
local sources=setmetatable({}, {__mode="k"})
local proxyMeta={}
local function wrap(source)
    if not source then return end
    local proxy=setmetatable({},proxyMeta)
    sources[proxy]=source
    return proxy
end
proxyMeta.__eq=function(a,b) return sources[a]==sources[b] end
proxyMeta.__index=function(proxy,key)
    local source=sources[proxy]
    if key=="parent" then return wrap(source.parent) end
    if key=="children" then
        local children={}
        for index,child in pairs(source.children) do children[index]=wrap(child) end
        return children
    end
    if key=="isInstanceOfType" then return function(_,kind) return source:isInstanceOfType(kind) end end
    if key=="attachChild" or key=="detachChild" then
        return function(_,child) return source[key](source,sources[child] or child) end
    end
    return source[key]
end
proxyMeta.__newindex=function(proxy,key,value) sources[proxy][key]=value end
local originalCamera=tes3.worldController.worldCamera
local originalMenuCamera=tes3.worldController.menuCamera
local newFloor,loadFloor=niCollisionSwitch.new,tes3.loadMesh
niCollisionSwitch.new=function() return wrap(newFloor()) end
tes3.loadMesh=function(...) return wrap(loadFloor(...)) end
tes3.worldController.weatherController=setmetatable({}, {__index=function(_,name)
    if name=="sceneSunBase" or name=="sceneSunVis" or name=="sceneSunGlare" then return wrap(weatherController[name]) end
    return weatherController[name]
end})
tes3.worldController.worldCamera={root=wrap(root),cameraRoot=wrap(camera)}
tes3.worldController.menuCamera={root=wrap(uiRoot),cameraRoot=wrap(uiRoot)}
tes3.dataHandler={worldLandscapeRoot=wrap(terrainRoot),waterController=setmetatable({}, {
    __index=function(_,name)
        if name=="waterPlane" or name=="rippleNode" then return wrap(waterController[name]) end
        return waterController[name]
    end,
    __newindex=function(_,name,value) waterController[name]=value end})}
local wrappedScene,wrappedHandles=wrap(scene),wrap(handles)
check(wrap(root)==wrap(root) and not rawequal(wrap(root),wrap(root)),"Fixture models equal native pointers with different Lua wrappers")
state=focus.capture(floorPosition)
focus.update(state,wrappedScene,wrappedHandles)
check(visible(state.floor) and state.floor.parent==wrap(root),
    "Fresh native wrappers retain the floor attached beneath the world root")
check(visible(outfit) and visible(pearl) and visible(camera),"Fresh native wrappers cannot hide the mannequin, handles or camera")
check(not visible(landscape) and not visible(otherBody),"Fresh native wrappers still isolate the surrounding world")
check(visible(uiText) and not visible(nativeWater) and not visible(nativeRipples),
    "Fresh native wrappers preserve shared UI and hide independent water nodes")
check(not visible(terrainShape) and terrainShape.appCulled,"Fresh native wrappers also hide the independent terrain pass")
check(sunDisc.appCulled and glareShape.appCulled,"Fresh native wrappers also hide the independent sun passes")
local snapshots=#state.visibility
for _=1,5 do focus.update(state,wrap(scene),wrap(handles)) end
check(#state.visibility==snapshots,"Refreshing native wrappers does not duplicate restoration snapshots")
restore(state)
niCollisionSwitch.new=newFloor; tes3.loadMesh=loadFloor
tes3.worldController.worldCamera=originalCamera
tes3.worldController.menuCamera=originalMenuCamera
tes3.worldController.weatherController=weatherController
tes3.dataHandler=installedHandler
restored()
print("PASS: "..count.." focus scene, master audio/music preservation, mannequin/outfit visibility, MGE rendering and restoration assertions")
