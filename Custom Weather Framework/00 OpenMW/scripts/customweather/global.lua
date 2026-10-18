-- OpenMW owns weather records globally; the player script only handles input/UI.
local core = require('openmw.core')
assert(core.weather and core.weather.records,
    'Weather Adjuster requires OpenMW 0.51 or newer (Lua weather API).')
local storage = require('openmw.storage')
local world = require('openmw.world')
local markup = require('openmw.markup')
local vfs = require('openmw.vfs')
local data = require('scripts.customweather.common')
local weather = require('scripts.customweather.weather')
local regionFiles = require('scripts.customweather.regionfiles')

local saved = storage.globalSection(data.storage)
saved:setLifeTime(storage.LIFE_TIME.Persistent)
-- Weather records survive Lua context resets. Keep the original values for the
-- entire application session so loading another save cannot capture edited values.
local session = storage.globalSection(data.storage .. 'Defaults')
session:setLifeTime(storage.LIFE_TIME.GameSession)
local records = weather.bind(core.weather.records)
local defaults = session:getCopy('preset') or weather.capture(records)
session:set('preset', defaults)
local config, packaged
local player, lastRegion, activePreset, transition, preview
local immediate = true

local function initialize()
    local ok, value = pcall(data.config, saved:getCopy('config') or {}, defaults)
    config = ok and value or data.config({}, defaults)
    if not ok then print('[Weather Adjuster] Invalid stored configuration: ' .. tostring(value)) end
    local paths = {}
    for path in vfs.pathsWithPrefix(regionFiles.directory) do paths[#paths + 1] = path end
    packaged = regionFiles.load(paths, function(path)
        return require((path:sub(1, -5):gsub('/', '.')))
    end, defaults, function(preset) return data.preset(preset, defaults) end,
        function(message) print('[Weather Adjuster] ' .. message) end, config.presets)
end
initialize()

local function persist()
    local value = data.copy(config)
    value.presets.default = nil
    saved:set('config', value)
end

local function regionId()
    local cell = player and player.cell
    if cell and cell.hasSky and cell.region then return cell.region:lower() end
end

local function notify(message)
    if player then player:sendEvent(data.reply, { message = message }) end
end

local function presetFor(name)
    return config.presets[name] or packaged.presets[name] or config.presets.default
end

local function reply(message, resetDraft)
    if not player then return end
    local regions = {}
    for _, region in ipairs(core.regions.records) do
        regions[region.id:lower()] = region.name
    end
    local visible = data.copy(config)
    for name, preset in pairs(packaged.presets) do visible.presets[name] = data.copy(preset) end
    for region, name in pairs(packaged.regions) do
        if visible.regions[region] == nil then visible.regions[region] = name end
    end
    player:sendEvent(data.reply, {
        config = visible, personalConfig = data.copy(config), packaged = data.copy(packaged.sources),
        regions = regions, region = regionId(),
        activePreset = activePreset or 'default', message = message, resetDraft = resetDraft,
    })
end

local function apply(preset)
    weather.apply(records, preset, config.disableSkyTextureChanges)
end

local function resumeRegions()
    preview, transition, activePreset, lastRegion = nil, nil, nil, nil
    immediate = true
end

local function switch(name, instant)
    activePreset = name
    local target = presetFor(name)
    if instant or config.transitionDuration == 0 then
        transition = nil
        apply(target)
    else
        transition = { from = weather.capture(records), target = data.copy(target), elapsed = 0 }
    end
    if config.messageOnRegionChange then
        notify('Weather Adjuster: ' .. (lastRegion or '') .. ' — ' .. name)
    end
end

local function update(dt)
    if not player or not player.cell then return end
    local region = regionId()
    if not region then
        lastRegion = nil
        immediate = true
        return -- Interior cells pause regional interpolation.
    end
    if preview then return end
    local name = config.regions[region] or packaged.regions[region] or 'default'
    if region ~= lastRegion or not activePreset then
        local instant = immediate or not lastRegion
        lastRegion, immediate = region, false
        if name ~= activePreset or instant then switch(name, instant) end
    end
    if transition and dt > 0 and not core.isWorldPaused() then
        transition.elapsed = transition.elapsed + dt
        local t = math.min(1, transition.elapsed / config.transitionDuration)
        apply(data.blend(transition.from, transition.target, t))
        if t == 1 then transition = nil end
    end
end

local function requireName(name)
    assert(data.validName(name) and name ~= 'default', 'Choose a non-default preset name')
    assert(not packaged.presets[name], 'Use Create copy to edit an installed mod preset')
end

local function command(e)
    assert(type(e) == 'table', 'Invalid editor command')
    if e.action == 'request' then
        reply(nil, true)
    elseif e.action == 'preview' then
        local preset = data.preset(e.preset, defaults)
        preview, transition = true, nil
        apply(preset)
    elseif e.action == 'close' or e.action == 'teleported' then
        resumeRegions()
    elseif e.action == 'weather' then
        local region = regionId()
        assert(region, 'Weather preview requires an exterior or a cell with sky')
        assert(type(e.index) == 'number' and data.names[e.index], 'Unknown weather')
        core.weather.changeWeather(region, records[data.names[e.index]])
        -- changeWeather only queues a transition, which freezes in the editor's
        -- paused UI mode. A tiny time advance completes it even while paused.
        -- This also runs the engine's AI fast-forward; see the compatibility notes.
        world.advanceTime(0.000001)
    elseif e.action == 'time' then
        assert(type(e.index) == 'number' and data.timeHours[e.index], 'Unknown time of day')
        -- Set the hour directly so previewing earlier times keeps the same date
        -- and does not run wait/travel AI updates or advance the weather schedule.
        world.mwscript.getGlobalVariables(player).gamehour = data.timeHours[e.index]
    elseif e.action == 'save' then
        requireName(e.name)
        local preset = data.preset(e.preset, defaults)
        config.presets[e.name] = preset
        persist()
        reply('Saved ' .. e.name, true)
    elseif e.action == 'rename' then
        requireName(e.name)
        requireName(e.newName)
        assert(config.presets[e.name], 'Preset does not exist')
        assert(not config.presets[e.newName], 'That preset name already exists')
        config.presets[e.newName], config.presets[e.name] = config.presets[e.name], nil
        for region, name in pairs(config.regions) do
            if name == e.name then config.regions[region] = e.newName end
        end
        persist()
        resumeRegions()
        reply('Renamed preset to ' .. e.newName, true)
    elseif e.action == 'delete' then
        requireName(e.name)
        config.presets[e.name] = nil
        for region, name in pairs(config.regions) do
            if name == e.name then config.regions[region] = nil end
        end
        persist()
        resumeRegions()
        reply('Deleted ' .. e.name, true)
    elseif e.action == 'assign' then
        assert(type(e.region) == 'string' and core.regions.records[e.region:lower()], 'Unknown region')
        assert(config.presets[e.name] or packaged.presets[e.name], 'Unknown preset')
        local name = e.name
        if packaged.presets[name] then
            local stem = name:sub(7, 85) .. ' (copy)'
            name = stem
            local n = 1
            while config.presets[name] or packaged.presets[name] do
                n = n + 1; name = stem .. ' ' .. n
            end
            config.presets[name] = data.copy(packaged.presets[e.name])
        end
        config.regions[e.region:lower()] = name
        persist()
        resumeRegions()
        reply('Assigned ' .. name)
    elseif e.action == 'resetRegion' then
        assert(type(e.region) == 'string' and core.regions.records[e.region:lower()], 'Unknown region')
        config.regions[e.region:lower()] = nil
        persist()
        resumeRegions()
        reply('Restored installed mod colours or engine defaults')
    elseif e.action == 'option' then
        assert(e.key == 'messageOnRegionChange' or e.key == 'disableSkyTextureChanges'
            or e.key == 'transitionDuration', 'Unknown option')
        local candidate = data.copy(config)
        candidate[e.key] = e.value
        config = data.config(candidate, defaults)
        if e.key == 'disableSkyTextureChanges' and e.value then weather.restoreTextures(records, defaults) end
        persist()
        resumeRegions()
        reply()
    elseif e.action == 'import' then
        local raw
        if e.path then
            assert(type(e.path) == 'string', 'Invalid import path')
            raw = markup.loadYaml(e.path) -- JSON is also valid YAML 1.2.
        else
            assert(type(e.text) == 'string' and #e.text <= 2000000, 'Invalid import text (2 MB limit)')
            raw = markup.decodeYaml(e.text)
        end
        -- Validate everything before replacing any saved configuration.
        local candidate = data.config(raw, defaults)
        config = candidate
        persist()
        resumeRegions()
        reply('Imported presets and region assignments. MGE XE scattering is retained but not applied.', true)
    else
        error('Unknown editor command: ' .. tostring(e.action))
    end
end

return {
    engineHandlers = {
        onPlayerAdded = function(object)
            player = object
            resumeRegions()
        end,
        onUpdate = update,
        onLoad = function() initialize(); resumeRegions() end,
    },
    eventHandlers = {
        [data.event] = function(e)
            local ok, message = pcall(command, e)
            if not ok then
                print('[Weather Adjuster] ' .. tostring(message))
                notify('Weather Adjuster: ' .. tostring(message))
            end
        end,
    },
}
