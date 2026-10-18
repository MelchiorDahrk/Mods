package.path = '00 OpenMW/?.lua;' .. package.path
local data = require('scripts.customweather.common')
local count = 0
local function test(name, fn)
    local ok, err = pcall(fn)
    assert(ok, name .. ': ' .. tostring(err))
    count = count + 1
    print('PASS ' .. name)
end
local function equal(actual, expected)
    assert(actual == expected, tostring(actual) .. ' ~= ' .. tostring(expected))
end
local function near(actual, expected) assert(math.abs(actual - expected) < 1e-8) end

local engineRecords = {}
local function color(r, g, b) return { r = r, g = g, b = b } end
for i, name in ipairs(data.names) do
    local record = { scriptId = i - 1, name = name, cloudTexture = 'textures/' .. name .. '.dds',
        sunDiscSunsetColor = color(0.4, 0.5, 0.6) }
    for _, group in ipairs(data.groups) do
        record[group .. 'Color'] = {}
        for _, time in ipairs(data.times) do record[group .. 'Color'][time:lower()] = color(0.2, 0.3, 0.4) end
    end
    engineRecords[i] = record
end
package.loaded['openmw.util'] = { color = { rgb = color } }
local adapter = require('scripts.customweather.weather')
local bound = adapter.bind(engineRecords)
local defaults = adapter.capture(bound)

test('all 17 colours round trip through engine interpolators', function()
    local changed = data.copy(defaults)
    for _, name in ipairs(data.names) do
        for _, field in ipairs(data.fields) do changed[name][field] = { 0.7, 0.6, 0.5 } end
    end
    adapter.apply(bound, changed, false, defaults)
    local captured = adapter.capture(bound)
    equal(#data.fields, 17)
    for _, name in ipairs(data.names) do
        for _, field in ipairs(data.fields) do equal(captured[name][field][1], 0.7) end
    end
    adapter.apply(bound, defaults, false, defaults)
end)

test('sparse MWSE presets inherit defaults and normalize texture paths', function()
    local config = data.config({ presets = { custom = { Clear = {
        skyDayColor = { 0, 1, 0.5 }, cloudTexture = 'Tx_Custom.tga',
    } } }, regions = { ['West Gash Region'] = 'custom' } }, defaults)
    equal(config.presets.custom.Clear.cloudTexture, 'textures/Tx_Custom.tga')
    equal(config.presets.custom.Blizzard.skyDayColor[1], 0.2)
    equal(config.regions['west gash region'], 'custom')
    equal(defaults.Clear.skyDayColor[1], 0.2)
end)

test('invalid colours, references and options are rejected', function()
    for _, bad in ipairs {
        { presets = { custom = { Clear = { skyDayColor = { 1, 0 / 0, 0 } } } } },
        { presets = { custom = { Clear = { skyDayColor = { 256, 0, 0 } } } } },
        { presets = { custom = { Clear = { skyDayColor = 'bad' } } } },
        { regions = { ashlands = 'missing' } }, { transitionDuration = -1 },
        { transitionDuration = math.huge }, { disableSkyTextureChanges = 'false' },
    } do assert(not pcall(data.config, bad, defaults)) end
end)

test('default preset cannot be overridden by imported configuration', function()
    local config = data.config({ presets = { default = { Clear = { skyDayColor = { 1, 0, 0 } } } } }, defaults)
    equal(config.presets.default.Clear.skyDayColor[1], 0.2)
end)

test('MGE scattering survives conversion for sharing', function()
    local p = data.preset({ outscatter = { 0.1, 0.2, 0.3 }, skylightScatterMix = 0 }, defaults)
    equal(p.outscatter[3], 0.3)
    equal(p.skylightScatterMix, 0)
end)

test('interpolation clamps overshoot and defers cloud texture changes', function()
    local target = data.copy(defaults)
    target.Clear.skyDayColor = { 1, 0, 0 }
    target.Clear.cloudTexture = 'textures/new.dds'
    local mid = data.blend(defaults, target, 0.5)
    near(mid.Clear.skyDayColor[1], 0.6)
    equal(mid.Clear.cloudTexture, defaults.Clear.cloudTexture)
    local final = data.blend(defaults, target, 2)
    equal(final.Clear.skyDayColor[1], 1)
    equal(final.Clear.cloudTexture, 'textures/new.dds')
end)

test('texture compatibility leaves other mods in control after restoring defaults', function()
    local target = data.copy(defaults)
    target.Clear.cloudTexture = 'textures/new.dds'
    adapter.apply(bound, target, false, defaults)
    equal(bound.Clear.cloudTexture, 'textures/new.dds')
    adapter.restoreTextures(bound, defaults)
    equal(bound.Clear.cloudTexture, defaults.Clear.cloudTexture)
    bound.Clear.cloudTexture = 'textures/other-mod.dds'
    adapter.apply(bound, target, true, defaults)
    equal(bound.Clear.cloudTexture, 'textures/other-mod.dds')
    adapter.restoreTextures(bound, defaults)
end)

test('JSON escapes quotes, control characters and backslashes', function()
    equal(data.json('a"\\\n'), '"a\\u0022\\u005c\\u000a"')
    equal(data.json({ x = { 0, 0.5, 1 }, enabled = false }), '{"enabled":false,"x":[0,0.5,1]}')
end)

-- Integration harness: exercise real global script event/lifecycle handlers.
local sections, replies, importValue, changes = {}, {}, nil, {}
local function section(name)
    if not sections[name] then
        local values = {}
        sections[name] = {
            getCopy = function(_, key) return data.copy(values[key]) end,
            get = function(_, key) return values[key] end,
            set = function(_, key, value) values[key] = data.copy(value) end,
            setLifeTime = function() end,
        }
    end
    return sections[name]
end
local regionA, regionB = 'west gash region', 'bitter coast region'
local regionRecords = { { id = regionA, name = 'West Gash' }, { id = regionB, name = 'Bitter Coast' } }
regionRecords[regionA], regionRecords[regionB] = regionRecords[1], regionRecords[2]
local core = {
    weather = { records = engineRecords, changeWeather = function(region, record) changes[#changes + 1] = {region, record} end },
    regions = { records = regionRecords }, isWorldPaused = function() return false end,
}
local globals, advances = { gamehour = 10, day = 16, month = 7, year = 427 }, {}
local player
local installedPaths = {}
package.loaded['openmw.vfs'] = { pathsWithPrefix = function(prefix)
    equal(prefix, 'scripts/weatheradjust/regions/')
    local i = 0
    return function() i = i + 1; return installedPaths[i] end
end }
package.loaded['openmw.world'] = {
    mwscript = { getGlobalVariables = function(p) equal(p, player); return globals end },
    advanceTime = function(hours) advances[#advances + 1] = hours end,
}
package.loaded['openmw.core'] = core
package.loaded['openmw.storage'] = { globalSection = section, LIFE_TIME = { Persistent = 0, GameSession = 1 } }
package.loaded['openmw.markup'] = { decodeYaml = function() return importValue end, loadYaml = function() return importValue end }
player = { cell = { hasSky = true, region = regionA }, sendEvent = function(_, _, e) replies[#replies + 1] = e end }
local function newRuntime()
    package.loaded['scripts.customweather.global'] = nil
    local runtime = require('scripts.customweather.global')
    runtime.engineHandlers.onPlayerAdded(player)
    return runtime
end
local runtime = newRuntime()
local function update(dt) runtime.engineHandlers.onUpdate(dt or 0) end
local function command(action, args)
    args = args or {}; args.action = action
    runtime.eventHandlers[data.event](args)
end
local function state() command('request'); return replies[#replies] end

test('regional transitions restart from visible colours on a second crossing', function()
    command('save', { name = 'red', preset = { Clear = { skyDayColor = { 1, 0, 0 } } } })
    command('save', { name = 'blue', preset = { Clear = { skyDayColor = { 0, 0, 1 } } } })
    command('assign', { region = regionA, name = 'red' })
    command('assign', { region = regionB, name = 'blue' })
    update()
    equal(bound.Clear.skyColor.day.r, 1)
    player.cell.region = regionB
    update(10)
    near(bound.Clear.skyColor.day.r, 0.5)
    near(bound.Clear.skyColor.day.b, 0.5)
    player.cell.region = regionA
    update(10)
    near(bound.Clear.skyColor.day.r, 0.75)
    near(bound.Clear.skyColor.day.b, 0.25)
    update(100)
    equal(bound.Clear.skyColor.day.r, 1)
end)

test('interiors pause interpolation and returning outside applies immediately', function()
    player.cell.region = regionB; update(5)
    local value = bound.Clear.skyColor.day.r
    player.cell = { hasSky = false }
    update(100)
    equal(bound.Clear.skyColor.day.r, value)
    player.cell = { hasSky = true, region = regionB }; update()
    equal(bound.Clear.skyColor.day.b, 1)
end)

test('save loading reapplies regions and never captures modified defaults', function()
    runtime = newRuntime(); update()
    equal(bound.Clear.skyColor.day.b, 1)
    local current = state()
    equal(current.config.presets.default.Clear.skyDayColor[1], 0.2)
    runtime.engineHandlers.onLoad(); runtime.engineHandlers.onPlayerAdded(player); update()
    equal(bound.Clear.skyColor.day.b, 1)
end)

test('preview is temporary and close restores regional weather', function()
    command('preview', { preset = defaults }); update(30)
    equal(bound.Clear.skyColor.day.r, 0.2)
    command('close'); update()
    equal(bound.Clear.skyColor.day.b, 1)
end)

test('rename and delete maintain region references', function()
    command('rename', { name = 'blue', newName = 'renamed' })
    equal(state().config.regions[regionB], 'renamed')
    command('delete', { name = 'renamed' }); update()
    equal(state().config.regions[regionB], nil)
    equal(bound.Clear.skyColor.day.r, 0.2)
end)

test('invalid imports leave persistent configuration intact', function()
    importValue = { regions = { [regionA] = 'nonexistent' } }
    command('import', { text = '{}' })
    assert(state().config.presets.red)
    importValue = { presets = { imported = { Clear = { skyDayColor = { 0, 1, 0 } } } }, regions = { [regionA] = 'imported' } }
    command('import', { path = data.importPath })
    equal(state().config.regions[regionA], 'imported')
end)

test('weather preview uses the engine record for the current region', function()
    for index = 1, #data.names do
        command('weather', { index = index })
        equal(changes[index][1], regionB)
        equal(changes[index][2], engineRecords[index])
        assert(advances[index] > 0 and advances[index] < 1 / 3600,
            'Preview must finish the paused transition without a significant time skip')
    end
end)

test('time selections change the game hour in either direction without changing the date', function()
    local expectedHours = { 7, 13, 19, 1 }
    local advanceCount = #advances
    for index, hour in ipairs(expectedHours) do
        command('time', { index = index })
        equal(globals.gamehour, hour)
        equal(globals.day, 16); equal(globals.month, 7); equal(globals.year, 427)
    end
    equal(#advances, advanceCount)
end)

test('invalid preview selections leave the game unchanged', function()
    local changeCount, advanceCount, hour = #changes, #advances, globals.gamehour
    for _, index in ipairs { 0, -1, 11, 1.5, '1', math.huge } do
        command('weather', { index = index })
        command('time', { index = index })
    end
    equal(#changes, changeCount); equal(#advances, advanceCount); equal(globals.gamehour, hour)
    local cell = player.cell
    player.cell = { hasSky = false }
    command('weather', { index = 1 })
    equal(#changes, changeCount); equal(#advances, advanceCount)
    player.cell = cell
end)

test('zero-duration transitions apply without dividing by zero', function()
    command('option', { key = 'transitionDuration', value = 0 })
    player.cell.region = regionA; update(1)
    equal(bound.Clear.skyColor.day.g, 1)
    player.cell.region = regionB; update(1)
    equal(bound.Clear.skyColor.day.g, 0.3)
end)

test('installed region Lua applies automatically without persisting mod data', function()
    local path = 'scripts/weatheradjust/regions/test_coast.lua'
    installedPaths = { path }
    package.preload['scripts.weatheradjust.regions.test_coast'] = function()
        return { version = 1, region = 'Bitter Coast Region',
            preset = { Clear = { skyDayColor = { 0.6, 0.7, 0.8 }, cloudTexture = 'tx_mod.dds' } } }
    end
    runtime = newRuntime(); update()
    equal(bound.Clear.skyColor.day.r, 0.6)
    equal(bound.Clear.cloudTexture, 'textures/tx_mod.dds')
    local current = state()
    local name = current.config.regions[regionB]
    equal(current.packaged[name], path)
    equal(current.personalConfig.regions[regionB], nil)
    command('option', { key = 'messageOnRegionChange', value = true })
    local savedConfig = section(data.storage):getCopy('config')
    equal(savedConfig.presets[name], nil)
    equal(savedConfig.regions[regionB], nil)
end)

test('personal overrides win and reset restores the installed mod', function()
    command('assign', { region = regionB, name = 'default' }); update()
    equal(bound.Clear.skyColor.day.r, 0.2)
    equal(state().personalConfig.regions[regionB], 'default')
    command('resetRegion', { region = regionB }); update()
    equal(bound.Clear.skyColor.day.r, 0.6)
    command('assign', { region = regionB, name = 'imported' }); update()
    equal(bound.Clear.skyColor.day.g, 1)
    command('resetRegion', { region = regionB }); update()
    equal(bound.Clear.skyColor.day.g, 0.7)
end)

test('installed presets are immutable and assignment elsewhere creates a personal copy', function()
    local name = state().config.regions[regionB]
    command('save', { name = name, preset = defaults })
    command('rename', { name = name, newName = 'changed mod' })
    command('delete', { name = name })
    equal(state().config.presets[name].Clear.skyDayColor[1], 0.6)
    command('assign', { region = regionA, name = name })
    local personal = state().personalConfig
    local copyName = personal.regions[regionA]
    assert(copyName ~= name)
    equal(personal.presets[copyName].Clear.skyDayColor[1], 0.6)
end)

test('uninstalling a region file restores defaults and keeps personal copies', function()
    installedPaths = {}
    runtime = newRuntime(); update()
    equal(bound.Clear.skyColor.day.r, 0.2)
    equal(state().config.regions[regionB], nil)
    player.cell.region = regionA; update()
    equal(bound.Clear.skyColor.day.r, 0.6)
    assert(state().personalConfig.presets.imported)
end)

test('installed Thousand Isles interop applies to its record ID and appears in editor state', function()
    local id = 'az_region_thousand isles'
    local record = { id = id, name = 'Lyithdonea, Thousand Isles' }
    regionRecords[#regionRecords + 1], regionRecords[id] = record, record
    local path = 'scripts/weatheradjust/regions/md_azurian_isles_thousand_isles.lua'
    installedPaths = { path }
    package.preload['scripts.weatheradjust.regions.md_azurian_isles_thousand_isles'] = function()
        return dofile('interops/MD_Azurian Isles/' .. path)
    end
    player.cell = { hasSky = true, region = id }
    runtime = newRuntime(); update()
    near(bound.Clear.skyColor.day.r, 130 / 255)
    near(bound.Clear.skyColor.day.g, 156 / 255)
    local current = state()
    equal(current.region, id)
    equal(current.regions[id], 'Lyithdonea, Thousand Isles')
    equal(current.packaged[current.config.regions[id]], path)
    equal(current.personalConfig.regions[id], nil)
    command('assign', { region = id, name = 'default' }); update()
    equal(bound.Clear.skyColor.day.r, 0.2)
    command('resetRegion', { region = id }); update()
    near(bound.Clear.skyColor.day.r, 130 / 255)
end)

print(string.format('%d tests passed.', count))
