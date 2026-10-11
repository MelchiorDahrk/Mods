-- Isolate the live mannequin without turning off the renderer that draws it.
local M={}
local grid=require("MannequinPoseDesigner.focus_grid")
local mgeFeatures={"distantLand","distantStatics","distantWater","grass"}
local waterNodes={"waterPlane","rippleNode"}
local sunNodes={"sceneSunBase","sceneSunVis","sceneSunGlare"}

function M.capture(groundPosition)
    local world=tes3.worldController
    local menu=world.menuController
    local camera=world.worldCamera
    local self={world=world,menu=menu,root=assert(camera.root,"The world scene is unavailable"),
        cameraRoot=camera.cameraRoot,aiDisabled=menu.aiDisabled,worldDisabled=menu.worldDisabled,
        skyDisabled=menu.skyDisabled,simulationTimeScalar=world.simulationTimeScalar,
        floorPosition=groundPosition:copy(),
        visibility={},lights={},mgeFlags={},sunMasks={},mask={node=camera.root,children={}}}
    local audio=world.audioController
    if audio then self.audio={controller=audio,masterVolume=audio.volumeMaster} end
    local menuCamera=world.menuCamera
    if menuCamera then self.menuRoot=menuCamera.root; self.menuCameraRoot=menuCamera.cameraRoot end
    if world.armCamera then self.armCameraRoot=world.armCamera.cameraRoot end
    if world.shadowCamera then self.shadowCameraRoot=world.shadowCamera.cameraRoot end
    self.data=tes3.dataHandler
    local water=self.data and self.data.waterController
    if water then self.water={controller=water,shown=water.waterShown,masks={}} end
    if mge and mge.enabled() then
        self.render=mge.render
        for _,name in ipairs(mgeFeatures) do self.mgeFlags[name]=self.render[name] end
        self.mgeFlags.noMWSunglare=self.render.noMWSunglare
        if mge.shaders then self.sunShader={config=mge.shaders} end
    end
    -- Keep light sources and their ancestor paths so isolation retains lighting.
    local function visit(node)
        if not node then return end -- Native child arrays can contain empty slots.
        if node:isInstanceOfType(tes3.niType.NiLight) then
            self.lights[#self.lights+1]=node
        elseif node:isInstanceOfType(tes3.niType.NiNode) then
            for _,child in pairs(node.children) do visit(child) end
        end
    end
    visit(self.root)
    return self
end

-- MWSE creates fresh Lua wrappers for native nodes. == compares native pointers,
-- but a table keyed by those wrappers cannot find the same node on another read.
local function find(entries,node)
    for _,entry in ipairs(entries) do
        if entry.node==node then return entry end
    end
end
local function setCulled(self,mask,value,external)
    if not mask.snapshot then
        -- The first tree walk visits each node once. Later, reuse the snapshot
        -- even if the engine moved a node to another child slot or parent.
        local saved=(self.masked or external) and find(self.visibility,mask.node)
        if not saved then
            saved={node=mask.node,culled=mask.node.appCulled}
            self.visibility[#self.visibility+1]=saved
        end
        mask.snapshot=saved
    end
    mask.node.appCulled=value
end
local function childMask(mask,index,node)
    local child=mask.children[index]
    if not child or child.node~=node then
        child={node=node,children={}}
        mask.children[index]=child
    end
    return child
end
local function cullSubtree(self,mask)
    setCulled(self,mask,true,true)
    if mask.node:isInstanceOfType(tes3.niType.NiNode) then
        for index,child in pairs(mask.node.children) do
            if child then cullSubtree(self,childMask(mask,index,child)) end
        end
    end
end

local function refreshWeatherSounds(world,attempt)
    local controller=world.weatherController
    if not controller then return end
    local function refresh(sound)
        -- Weather buffers are outside the effects slider's looping-sound list.
        -- Reapply the unchanged sound volume to refresh its buffer with the
        -- current master/effects mix, including master=0 while focused.
        if sound then
            local function apply() sound.volume=sound.volume end
            if attempt then attempt(apply) else apply() end
        end
    end
    for index,weather in pairs(controller.weathers) do
        refresh(weather.ambientLoopSound)
        if index==tes3.weather.rain or index==tes3.weather.thunder then
            refresh(weather.rainLoopSound)
        end
        if index==tes3.weather.thunder then
            for i=1,4 do refresh(weather["thunderSound"..i]) end
        end
    end
end

local function updateFloor(self,scene)
    local floor=self.floor
    if not floor then
        floor=niCollisionSwitch.new()
        self.floor=floor -- Own it before loading or attachment can fail.
        floor.name="OAAB Pose Designer focus floor"
        floor.collisionActive=false
        self.root:attachChild(floor)
    end
    local count=grid.vertexCount(scene.worldBoundRadius)
    if count and count~=self.gridVertexCount and count~=self.failedGridVertexCount then
        local ok,mesh=pcall(grid.load,count)
        if ok then
            floor:attachChild(mesh)
            if self.gridMesh then floor:detachChild(self.gridMesh) end
            self.gridMesh=mesh; self.gridVertexCount=count
            self.failedGridVertexCount=nil
            floor:updateProperties()
        else
            -- A pose/root edit can cross a grid size boundary every frame.
            -- Keep any validated mesh, or an empty floor on initial failure.
            -- The grid is optional: never attach the bad graph or abort an
            -- edited pose merely because its first grid cannot load.
            self.failedGridVertexCount=count
            if mwse then
                if self.gridMesh then
                    mwse.log("[OAAB Pose Designer] Focus grid resize to %d vertices rejected; keeping %d: %s",
                        count,self.gridVertexCount,tostring(mesh))
                else
                    mwse.log("[OAAB Pose Designer] Focus grid load of %d vertices rejected; continuing without grid: %s",
                        count,tostring(mesh))
                end
            end
        end
    end
    -- Keep the grid horizontal at the original grounding plane,
    -- independent of pose/root edits and the world scene parent's transform.
    local inverse,valid=self.root.worldTransform:invert()
    assert(valid,"The focus floor scene transform cannot be inverted")
    floor.translation=inverse*self.floorPosition
    floor.rotation=inverse.rotation
    floor.scale=inverse.scale*grid.spacing*0.5 -- CSSE's gridSnap / 2 scale.
    floor.appCulled=false
    floor:update({controllers=false})
end

local function updateLight(self,scene)
    local entry=self.light
    if not entry then
        entry={source=niPointLight.new(),scene=scene}
        self.light=entry -- Own the light before any setter/attachment can fail.
        local light=entry.source
        light.name="OAAB Pose Designer focus light"
        light.ambient=niColor.new(0.45,0.45,0.45)
        light.diffuse=niColor.new(0.75,0.75,0.75)
        light.dimmer=1
        light.enabled=true
    elseif entry.scene~=scene then
        entry.scene:detachEffect(entry.source)
        entry.source:detachAffectedNode(entry.scene)
        entry.scene:updateEffects()
        entry.scene=scene
    end
    local light=entry.source
    -- This light has no scene parent: its local position is already world-space.
    -- Ambient fill keeps surfaces readable; diffuse light retains their shape.
    local position=tes3.getCameraPosition()
    light.translation=position:copy()
    local floor=self.floor
    light:setRadius(math.ceil(math.max(
        position:distance(scene.worldBoundOrigin)+scene.worldBoundRadius,
        position:distance(floor.worldBoundOrigin)+floor.worldBoundRadius)+128))
    -- Avoid losing brightness as the camera pans or zooms. setRadius also stores
    -- the coverage radius used by Morrowind/MGE in the light's specular color.
    light.constantAttenuation=1
    light.linearAttenuation=0
    light.quadraticAttenuation=0
    light:update({controllers=false})
    -- Native lighting updates may rebuild the mannequin's effect list. Reattach
    -- idempotently and propagate to every body part/outfit before rendering.
    light:attachAffectedNode(scene)
    scene:attachEffect(light)
    scene:updateEffects()
    light:attachAffectedNode(floor)
    floor:attachEffect(light)
    floor:updateEffects()
end

function M.update(self,scene,handles)
    -- Trace only the first activation, so native failures can be located without
    -- logging the scene walk on every focused frame.
    local function trace(stage)
        if not self.activationComplete and mwse then
            mwse.log("[OAAB Pose Designer] Focus activation: %s",stage)
        end
    end
    local paths={node=self.root,children={}}
    local function keep(node)
        if not node then return end
        local chain,current={},node
        while current and current~=self.root do
            chain[#chain+1]=current
            current=current.parent
        end
        if not current then return end
        local route=paths
        for i=#chain,1,-1 do
            local child=find(route.children,chain[i])
            if not child then
                child={node=chain[i],children={}}
                route.children[#route.children+1]=child
            end
            route=child
        end
        -- A camera may share the world root; do not retain the entire world.
        if node~=self.root then route.whole=true end
        return true
    end
    assert(keep(scene),"The mannequin is detached from the world scene")
    trace("create/update grid floor")
    updateFloor(self,scene)
    keep(self.floor)
    keep(handles)
    keep(self.cameraRoot)
    keep(self.armCameraRoot)
    keep(self.shadowCameraRoot)
    keep(self.menuRoot)
    keep(self.menuCameraRoot)
    for _,light in ipairs(self.lights) do keep(light) end
    local function visit(mask,route)
        local node=mask.node
        if node==scene then
            setCulled(self,mask,false) -- Preserve all body parts and equipment below it.
        elseif route and route.whole then
            return -- Handle visibility belongs to the overlay, including modal menus.
        elseif route then
            setCulled(self,mask,false)
            if node:isInstanceOfType(tes3.niType.NiNode) then
                for index,child in pairs(node.children) do
                    if child then -- Native child arrays can contain empty slots.
                        visit(childMask(mask,index,child),find(route.children,child))
                    end
                end
            end
        else
            setCulled(self,mask,true)
        end
    end
    trace("apply scene visibility")
    visit(self.mask,paths)
    self.masked=true
    trace("hide HUD and configure world rendering")
    local hud=tes3ui.findMenu("MenuMulti")
    if hud then
        if not self.hud or self.hud.menu~=hud then
            self.hud={menu=hud,visible=hud.visible}
        end
        -- Hide gameplay UI while leaving help-layer controls and dialogs usable.
        hud.visible=false
    end
    self.menu.aiDisabled=true
    self.menu.worldDisabled=false -- ToggleWorld would also hide the mannequin.
    self.menu.skyDisabled=true
    local weather=self.world.weatherController
    if weather then
        -- The sun disc and glare have separate scene roots. ToggleSky and the
        -- world mask can miss them; hide their geometry on every render too.
        for _,name in ipairs(sunNodes) do
            local node=weather[name]
            if node then
                local mask=self.sunMasks[name]
                if not mask or mask.node~=node then
                    mask={node=node,children={}}
                    self.sunMasks[name]=mask
                end
                cullSubtree(self,mask)
            end
        end
    end
    if self.render then
        for _,name in ipairs(mgeFeatures) do self.render[name]=false end
        self.render.noMWSunglare=true
    end
    if self.sunShader then
        local entry=self.sunShader
        -- Sunshafts draws an additional disc/rays in post-processing, even when
        -- every native sun node is hidden. Suspend that shader during focus.
        -- Look it up by name because MWSE returns fresh handles on each lookup.
        local shader=entry.config.find({name="Sunshafts"})
        if shader then
            if entry.enabled==nil then entry.enabled=shader.enabled end
            shader.enabled=false
        end
    end
    local terrain=self.data and self.data.worldLandscapeRoot
    if terrain then
        if not self.terrain or self.terrain.node~=terrain then
            self.terrain={node=terrain,children={}}
        end
        -- Terrain has its own render root. Cull its geometry as well so a pass
        -- that draws a cell/shape directly cannot bypass the hidden parent.
        cullSubtree(self,self.terrain)
    end
    if self.water then
        -- Disabling MGE water can reveal the native water fallback. Its plane
        -- and ripples may also be rendered outside the world scene tree.
        self.water.controller.waterShown=false
        for _,name in ipairs(waterNodes) do
            local node=self.water.controller[name]
            if node then
                local mask=self.water.masks[name]
                if not mask or mask.node~=node then
                    mask={node=node}
                    self.water.masks[name]=mask
                end
                setCulled(self,mask,true,true)
            end
        end
    end
    local ancestor=scene
    while ancestor do
        assert(not ancestor.appCulled,"Focus hid an ancestor of the mannequin")
        if ancestor==self.root then break end
        ancestor=ancestor.parent
    end
    trace("attach/update focus lighting")
    updateLight(self,scene)
    trace("mute audio and freeze simulation")
    if self.audio then
        -- Morrowind's music channel is independent of master volume.
        self.audio.controller.volumeMaster=0
        refreshWeatherSounds(self.world)
    end
    self.world.simulationTimeScalar=0
    trace("complete")
    self.activationComplete=true
end

function M.restore(self,attempt)
    if not self or self.restored then return end
    self.restored=true
    if self.light then
        local entry=self.light
        attempt(function() entry.source.enabled=false end)
        attempt(function() entry.scene:detachEffect(entry.source) end)
        attempt(function() entry.source:detachAffectedNode(entry.scene) end)
        attempt(function() entry.scene:updateEffects() end)
        if self.floor then
            attempt(function() self.floor:detachEffect(entry.source) end)
            attempt(function() entry.source:detachAffectedNode(self.floor) end)
            attempt(function() self.floor:updateEffects() end)
        end
    end
    if self.floor then
        attempt(function() self.floor.appCulled=true end)
        attempt(function()
            local parent=self.floor.parent
            if parent then parent:detachChild(self.floor) end
        end)
    end
    for _,entry in ipairs(self.visibility) do
        attempt(function() entry.node.appCulled=entry.culled end)
    end
    if self.hud then
        attempt(function()
            local hud=tes3ui.findMenu("MenuMulti")
            -- A load or UI rebuild may have destroyed the saved menu.
            if hud==self.hud.menu then hud.visible=self.hud.visible end
        end)
    end
    if self.render then
        for _,name in ipairs(mgeFeatures) do
            attempt(function() self.render[name]=self.mgeFlags[name] end)
        end
        attempt(function() self.render.noMWSunglare=self.mgeFlags.noMWSunglare end)
    end
    if self.sunShader and self.sunShader.enabled~=nil then
        attempt(function()
            local shader=self.sunShader.config.find({name="Sunshafts"})
            if shader then shader.enabled=self.sunShader.enabled end
        end)
    end
    if self.water then
        attempt(function() self.water.controller.waterShown=self.water.shown end)
    end
    if self.audio then
        attempt(function() self.audio.controller.volumeMaster=self.audio.masterVolume end)
        attempt(function() refreshWeatherSounds(self.world,attempt) end)
    end
    -- Independent restoration also covers errors partway through activation.
    attempt(function() self.menu.aiDisabled=self.aiDisabled end)
    attempt(function() self.menu.worldDisabled=self.worldDisabled end)
    attempt(function() self.menu.skyDisabled=self.skyDisabled end)
    attempt(function() self.world.simulationTimeScalar=self.simulationTimeScalar end)
end

return M
