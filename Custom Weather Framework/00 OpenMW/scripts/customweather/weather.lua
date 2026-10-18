local util = require('openmw.util')
local data = require('scripts.customweather.common')
local M = {}

function M.bind(records)
    local result = {}
    for _, weather in ipairs(records) do
        local name = data.names[weather.scriptId + 1]
        if name then result[name] = weather end
    end
    for _, name in ipairs(data.names) do
        assert(result[name], 'Weather Adjuster requires OpenMW 0.51+ weather records: missing ' .. name)
    end
    return result
end

local function array(color) return { color.r, color.g, color.b } end
local function color(rgb) return util.color.rgb(rgb[1], rgb[2], rgb[3]) end

function M.capture(records)
    local preset = {}
    for _, name in ipairs(data.names) do
        local weather, values = records[name], {}
        for _, group in ipairs(data.groups) do
            for _, time in ipairs(data.times) do
                values[group .. time .. 'Color'] = array(weather[group .. 'Color'][time:lower()])
            end
        end
        values.sundiscSunsetColor = array(weather.sunDiscSunsetColor)
        values.cloudTexture = weather.cloudTexture
        preset[name] = values
    end
    return preset
end

function M.apply(records, preset, disableTextures)
    for _, name in ipairs(data.names) do
        local weather, values = records[name], preset[name]
        for _, group in ipairs(data.groups) do
            for _, time in ipairs(data.times) do
                -- The interpolator itself is read-only; its time slots are writable.
                weather[group .. 'Color'][time:lower()] = color(values[group .. time .. 'Color'])
            end
        end
        weather.sunDiscSunsetColor = color(values.sundiscSunsetColor)
        if not disableTextures then weather.cloudTexture = values.cloudTexture end
    end
end

function M.restoreTextures(records, defaults)
    for _, name in ipairs(data.names) do records[name].cloudTexture = defaults[name].cloudTexture end
end

return M
