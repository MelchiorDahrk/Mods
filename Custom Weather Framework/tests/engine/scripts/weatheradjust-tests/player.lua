local core = require('openmw.core')
local input = require('openmw.input')
local self = require('openmw.self')
local I = require('openmw.interfaces')
local data = require('scripts.customweather.common')
local port
local started, received, frames = false, false, 0
local day
local function command(action, index)
    core.sendGlobalEvent(data.event, { action = action, index = index })
end
local function checkHour(hour)
    local gameHours = core.getGameTime() / 3600
    assert(math.abs(gameHours % 24 - hour) < 0.0001, 'Game hour did not change to ' .. hour)
    assert(math.floor(gameHours / 24) == day, 'Time selection changed the date')
end
local function checkWeather(scriptId)
    local current = core.weather.getCurrent(self.cell)
    assert(current and current.scriptId == scriptId, 'Weather did not change while paused')
    assert(core.weather.getNext(self.cell) == nil, 'Weather preview left an unfinished transition')
end
local function run(fn)
    local ok, err = pcall(fn)
    if not ok then core.sendGlobalEvent('WeatherAdjusterSmokeResult', { error = tostring(err) }) end
end
return {
    engineHandlers = {
        onFrame = function()
            if not received then return end
            frames = frames + 1
            if frames % 10 ~= 0 then return end
            run(function()
                assert(I.UI.getMode() == I.UI.MODE.Interface, 'Editor did not enter interface mode')
                assert(core.isWorldPaused(), 'Preview test requires a paused editor')
                if frames == 10 then
                    day = math.floor(core.getGameTime() / 86400)
                    command('time', 1)
                elseif frames == 20 then
                    checkHour(7)
                    command('weather', 5)
                elseif frames == 30 then
                    checkHour(7); checkWeather(4)
                    command('time', 2)
                elseif frames == 40 then
                    checkHour(13); checkWeather(4)
                    command('time', 3)
                elseif frames == 50 then
                    checkHour(19)
                    command('weather', 1)
                elseif frames == 60 then
                    checkHour(19); checkWeather(0)
                    command('time', 4)
                elseif frames == 70 then
                    checkHour(1); checkWeather(0)
                    print('[WEATHER TEST] All four times and immediate weather changes passed while paused')
                    port.engineHandlers.onKeyPress { code = input.KEY.Escape }
                    assert(I.UI.getMode() == nil, 'Editor did not release interface mode')
                    core.sendGlobalEvent('WeatherAdjusterSmokeResult', {})
                    received = false
                end
            end)
        end,
    },
    eventHandlers = {
        WeatherAdjusterSmokeOpen = function()
            run(function()
                port = require('scripts.customweather.player')
                started = true
                port.engineHandlers.onKeyPress { code = input.KEY.F4, withShift = true,
                    withCtrl = false, withAlt = false, withSuper = false }
            end)
        end,
        [data.reply] = function(e)
            if not started or not e.config then return end
            run(function() port.eventHandlers[data.reply](e); received = true end)
        end,
    },
}
