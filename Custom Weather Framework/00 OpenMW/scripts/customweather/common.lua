-- Weather Adjuster: data shared by the OpenMW runtime and editor.
-- Presets retain Weather Adjuster 3.0's MWSE colour names and 0..1 RGB values.
local M = {}
M.names = { 'Clear', 'Cloudy', 'Foggy', 'Overcast', 'Rain', 'Thunderstorm', 'Ashstorm', 'Blight', 'Snow', 'Blizzard' }
M.times = { 'Sunrise', 'Day', 'Sunset', 'Night' }
M.timeHours = { 7, 13, 19, 1 }
M.groups = { 'sky', 'fog', 'ambient', 'sun' }
M.fields = {}
for _, group in ipairs(M.groups) do
    for _, time in ipairs(M.times) do
        M.fields[#M.fields + 1] = group .. time .. 'Color'
    end
end
M.fields[#M.fields + 1] = 'sundiscSunsetColor'
M.event = 'HrnWeatherAdjusterCommand'
M.reply = 'HrnWeatherAdjusterState'
M.storage = 'HrnWeatherAdjuster'
M.importPath = 'MWSE/config/Weather Adjuster.json'

function M.copy(value)
    if type(value) ~= 'table' then return value end
    local result = {}
    for k, v in pairs(value) do result[k] = M.copy(v) end
    return result
end

function M.finite(value)
    return type(value) == 'number' and value == value and math.abs(value) < math.huge
end

function M.validName(name)
    return type(name) == 'string' and #name > 0 and #name <= 120 and name:match('%S')
        and not name:find('%c')
end

function M.rgb(value, label)
    assert(type(value) == 'table' and #value == 3, label .. ' must be an RGB array')
    for i = 1, 3 do
        assert(M.finite(value[i]) and value[i] >= 0 and value[i] <= 1,
            label .. ' components must be numbers between 0 and 1')
    end
    return { value[1], value[2], value[3] }
end

function M.preset(source, defaults)
    assert(type(source) == 'table', 'Preset must be an object')
    local result = M.copy(defaults)
    for _, name in ipairs(M.names) do
        local weather = source[name]
        if weather ~= nil then
            assert(type(weather) == 'table', name .. ' must be an object')
            for _, field in ipairs(M.fields) do
                if weather[field] ~= nil then
                    result[name][field] = M.rgb(weather[field], name .. '.' .. field)
                end
            end
            if weather.cloudTexture ~= nil then
                assert(type(weather.cloudTexture) == 'string' and not weather.cloudTexture:find('%c'),
                    name .. '.cloudTexture must be a texture path')
                -- MWSE paths can omit the textures/ prefix and use backslashes.
                local path = weather.cloudTexture:gsub('\\', '/'):gsub('^/+', '')
                if not path:lower():match('^textures/') then path = 'textures/' .. path end
                result[name].cloudTexture = path
            end
        end
    end
    -- Retain MGE XE data for sharing, although OpenMW does not apply it.
    for _, field in ipairs { 'outscatter', 'inscatter', 'skylightScatter' } do
        if source[field] ~= nil then result[field] = M.rgb(source[field], field) end
    end
    if source.skylightScatterMix ~= nil then
        assert(M.finite(source.skylightScatterMix), 'Invalid skylightScatterMix')
        result.skylightScatterMix = source.skylightScatterMix
    end
    return result
end

function M.config(source, defaults)
    assert(type(source) == 'table', 'Configuration must be an object')
    assert(source.presets == nil or type(source.presets) == 'table', 'presets must be an object')
    assert(source.regions == nil or type(source.regions) == 'table', 'regions must be an object')
    local result = {
        presets = { default = M.copy(defaults) }, regions = {},
        messageOnRegionChange = false, disableSkyTextureChanges = false,
        transitionDuration = 20,
    }
    for name, preset in pairs(source.presets or {}) do
        assert(M.validName(name), 'Invalid preset name')
        -- Always use the engine's starting weather as the immutable default.
        if name ~= 'default' then result.presets[name] = M.preset(preset, defaults) end
    end
    for region, name in pairs(source.regions or {}) do
        assert(M.validName(region) and type(name) == 'string', 'Invalid region assignment')
        assert(result.presets[name], 'Region references missing preset: ' .. name)
        result.regions[region:lower()] = name
    end
    for _, key in ipairs { 'messageOnRegionChange', 'disableSkyTextureChanges' } do
        if source[key] ~= nil then
            assert(type(source[key]) == 'boolean', key .. ' must be true or false')
            result[key] = source[key]
        end
    end
    if source.transitionDuration ~= nil then
        assert(M.finite(source.transitionDuration) and source.transitionDuration >= 0
            and source.transitionDuration <= 300, 'Transition duration must be between 0 and 300 seconds')
        result.transitionDuration = source.transitionDuration
    end
    return result
end

function M.blend(from, target, t)
    t = math.max(0, math.min(1, t))
    local result = M.copy(target)
    if t == 1 then return result end
    for _, name in ipairs(M.names) do
        for _, field in ipairs(M.fields) do
            local a, b = from[name][field], target[name][field]
            result[name][field] = {
                a[1] + (b[1] - a[1]) * t,
                a[2] + (b[2] - a[2]) * t,
                a[3] + (b[3] - a[3]) * t,
            }
        end
        -- Textures are discrete. Switch only once the colour transition finishes.
        if t < 1 then result[name].cloudTexture = from[name].cloudTexture end
    end
    return result
end

function M.sortedKeys(values)
    local keys = {}
    for key in pairs(values) do keys[#keys + 1] = key end
    table.sort(keys)
    return keys
end

-- Export to a text box/console: sandboxed OpenMW scripts cannot write arbitrary files.
function M.json(value)
    local kind = type(value)
    if kind == 'string' then
        return '"' .. value:gsub('[%z\1-\31\\"]', function(c)
            return string.format('\\u%04x', string.byte(c))
        end) .. '"'
    elseif kind == 'number' then
        assert(M.finite(value), 'Cannot export a non-finite number')
        return string.format('%.17g', value)
    elseif kind == 'boolean' then
        return tostring(value)
    end
    assert(kind == 'table', 'Cannot export ' .. kind)
    local parts = {}
    if #value > 0 then
        for i, v in ipairs(value) do parts[i] = M.json(v) end
        return '[' .. table.concat(parts, ',') .. ']'
    end
    for _, key in ipairs(M.sortedKeys(value)) do
        parts[#parts + 1] = M.json(key) .. ':' .. M.json(value[key])
    end
    return '{' .. table.concat(parts, ',') .. '}'
end

return M
