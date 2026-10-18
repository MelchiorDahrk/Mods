-- Portable region definitions. Keep this pure Lua module identical in both packages.
local M = { directory = 'scripts/weatheradjust/regions/' }
local names = { 'Clear', 'Cloudy', 'Foggy', 'Overcast', 'Rain', 'Thunderstorm', 'Ashstorm', 'Blight', 'Snow', 'Blizzard' }
local fields = { 'sundiscSunsetColor' }
for _, group in ipairs { 'sky', 'fog', 'ambient', 'sun' } do
    for _, time in ipairs { 'Sunrise', 'Day', 'Sunset', 'Night' } do
        fields[#fields + 1] = group .. time .. 'Color'
    end
end

local function copy(value)
    if type(value) ~= 'table' then return value end
    local result = {}
    for k, v in pairs(value) do result[k] = copy(v) end
    return result
end

local function finite(value)
    return type(value) == 'number' and value == value and math.abs(value) < math.huge
end

local function validName(value)
    return type(value) == 'string' and #value > 0 and #value <= 120
        and value:match('%S') and not value:find('%c')
end

local function rgb(value, label)
    assert(type(value) == 'table' and #value == 3, label .. ' must be an RGB array')
    for i = 1, 3 do
        assert(finite(value[i]) and value[i] >= 0 and value[i] <= 1,
            label .. ' components must be between 0 and 1')
    end
    return { value[1], value[2], value[3] }
end

-- Sparse files inherit engine defaults. Export only recognised weather settings.
function M.preset(source, defaults)
    assert(type(source) == 'table', 'preset must be a table')
    local result = copy(defaults or {})
    for _, name in ipairs(names) do
        local weather = source[name]
        if weather ~= nil then
            assert(type(weather) == 'table', name .. ' must be a table')
            local dest = result[name] or {}
            result[name] = dest
            for _, field in ipairs(fields) do
                if weather[field] ~= nil then dest[field] = rgb(weather[field], name .. '.' .. field) end
            end
            if weather.cloudTexture ~= nil then
                assert(type(weather.cloudTexture) == 'string' and #weather.cloudTexture > 0
                    and not weather.cloudTexture:find('%c'), 'Invalid cloud texture')
                dest.cloudTexture = weather.cloudTexture
            end
        end
    end
    for _, field in ipairs { 'outscatter', 'inscatter', 'skylightScatter' } do
        if source[field] ~= nil then result[field] = rgb(source[field], field) end
    end
    if source.skylightScatterMix ~= nil then
        assert(finite(source.skylightScatterMix), 'Invalid skylightScatterMix')
        result.skylightScatterMix = source.skylightScatterMix
    end
    return result
end

-- Explicit decimal escapes work in Lua 5.1 and do not depend on locale or %q.
local function quote(value)
    return '"' .. value:gsub('[%z\1-\31\127\\"]', function(c)
        return string.format('\\%03d', string.byte(c))
    end) .. '"'
end

local function literal(value, depth)
    if type(value) == 'string' then return quote(value) end
    if type(value) == 'number' then
        assert(finite(value), 'Cannot export a non-finite number')
        return (string.format('%.17g', value):gsub(',', '.'))
    end
    assert(type(value) == 'table', 'Unsupported export value')
    local parts, indent = {}, string.rep('    ', depth)
    if #value > 0 then
        for i, v in ipairs(value) do parts[i] = literal(v, depth + 1) end
        return '{ ' .. table.concat(parts, ', ') .. ' }'
    end
    local keys = {}
    for key in pairs(value) do keys[#keys + 1] = key end
    table.sort(keys)
    for _, key in ipairs(keys) do
        parts[#parts + 1] = indent .. '    [' .. quote(key) .. '] = ' .. literal(value[key], depth + 1) .. ',\n'
    end
    return '{\n' .. table.concat(parts) .. indent .. '}'
end

function M.export(region, preset)
    assert(validName(region), 'Choose a region to export')
    return '-- Weather Adjuster region colours (MWSE and OpenMW).\n'
        .. '-- OpenMW: install under ' .. M.directory .. '.\n'
        .. '-- MWSE: use as your mod main.lua, or require this file from your mod.\n'
        .. 'local definition = ' .. literal({ version = 1, region = region:lower(), preset = M.preset(preset) }, 0) .. '\n\n'
        .. "local interop = type(include) == 'function' and include('customweather.interop')\n"
        .. 'if interop then interop.registerRegion(definition) end\n'
        .. 'return definition\n'
end

function M.filename(region)
    assert(validName(region), 'Choose a region to export')
    local stem = region:lower():gsub('[^a-z0-9]+', '_'):gsub('^_+', ''):gsub('_+$', ''):sub(1, 70)
    if stem == '' then stem = 'region' end
    return stem .. '.lua'
end

-- Scan only immediate .lua children. Flat, portable names can be required by both engines.
function M.fileStem(path, directory)
    directory = directory or M.directory
    local leaf = path:sub(1, #directory):lower() == directory:lower() and path:sub(#directory + 1)
    if leaf and leaf:lower():match('^[a-z0-9_%-]+%.lua$') then return leaf:sub(1, -5) end
end

function M.definition(raw, defaults)
    assert(type(raw) == 'table' and raw.version == 1, 'Expected a version 1 region definition')
    assert(validName(raw.region), 'Invalid region ID')
    return { region = raw.region:lower(), preset = M.preset(raw.preset, defaults) }
end

function M.load(paths, loadFile, defaults, normalize, warn, userPresets)
    local sorted, result = {}, { presets = {}, regions = {}, sources = {} }
    for _, path in ipairs(paths) do
        local label = M.fileStem(path)
        if label then sorted[#sorted + 1] = { path = path, label = label } end
    end
    table.sort(sorted, function(a, b) return a.path:lower() < b.path:lower() end)
    for _, entry in ipairs(sorted) do
        local path = entry.path
        local ok, value = pcall(function()
            local value = M.definition(loadFile(path), defaults)
            if normalize then value.preset = normalize(value.preset) end
            return value
        end)
        if ok then
            local name = '[Mod] ' .. entry.label
            while result.presets[name] or (userPresets or {})[name] do name = name .. '*' end
            if result.regions[value.region] then
                warn(path .. ' replaces ' .. result.sources[result.regions[value.region]] .. ' for ' .. value.region)
            end
            result.presets[name], result.sources[name] = value.preset, path
            result.regions[value.region] = name
        else
            warn('Skipping ' .. path .. ': ' .. tostring(value))
        end
    end
    return result
end

return M
