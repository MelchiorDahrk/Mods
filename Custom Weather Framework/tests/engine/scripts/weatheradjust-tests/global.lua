local core = require('openmw.core')
local storage = require('openmw.storage')
local data = require('scripts.customweather.common')
local player, frame, stage = nil, 0, 0
local function command(action, args)
    args = args or {}; args.action = action
    core.sendGlobalEvent(data.event, args)
end
local function check()
    if not player or not player.cell then return end
    frame = frame + 1
    if frame < 10 then return end
    frame = 0
    if stage == 0 then
        assert(player.cell.region, 'Smoke test needs an exterior starting cell')
        local clear
        for _, w in ipairs(core.weather.records) do if w.scriptId == 0 then clear = w end end
        assert(clear and clear.skyColor.day.r == 0.25 and clear.skyColor.day.b == 0.75,
            'Installed region Lua was not discovered and applied automatically')
        print('[WEATHER TEST] Installed region Lua discovered through VFS and applied automatically')
        command('import', { text = data.json {
            presets = { engineSmoke = { Clear = { skyDayColor = { 0, 1, 0 } } } },
            regions = { [player.cell.region] = 'engineSmoke' },
        } })
        stage = 1
    elseif stage == 1 then
        assert(storage.globalSection(data.storage):getCopy('config').presets.engineSmoke, 'Import failed')
        local clear
        for _, w in ipairs(core.weather.records) do if w.scriptId == 0 then clear = w end end
        assert(clear and clear.skyColor.day.g == 1 and clear.skyColor.day.r == 0,
            'Engine weather colours were not updated')
        print('[WEATHER TEST] Real weather setters, YAML/JSON import and regional application passed')
        command('weather', { index = 1 })
        player:sendEvent('WeatherAdjusterSmokeOpen', {})
        stage = 2
    end
end
return {
    engineHandlers = {
        onPlayerAdded = function(p) player = p end,
        onUpdate = function()
            local ok, err = pcall(check)
            if not ok then print('[WEATHER TEST FAILED] ' .. tostring(err)); core.quit() end
        end,
    },
    eventHandlers = {
        WeatherAdjusterSmokeResult = function(e)
            print(e.error and '[WEATHER TEST FAILED] ' .. e.error or '[WEATHER TEST PASSED] Engine and editor smoke test')
            core.quit()
        end,
    },
}
