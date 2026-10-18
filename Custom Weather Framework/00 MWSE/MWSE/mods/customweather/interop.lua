-- Mods register their data when their own scripts run; no folder scanning is used.
local files = require('customweather.regionfiles')
local M = { version = 1, event = 'HrnWeatherAdjusterRegionsChanged' }
local entries, sequence = {}, 0

local function changed()
    if event and event.trigger then event.trigger(M.event) end
end

-- id is optional: exported scripts are identified by their calling Lua source.
-- Higher priority wins; equal priorities use the most recent registration.
function M.registerRegion(definition)
    assert(type(definition) == 'table', 'Expected a region definition')
    local value = files.definition({ version = definition.version == nil and 1 or definition.version,
        region = definition.region, preset = definition.preset })
    local source = debug.getinfo(2, 'S')
    local id = definition.id
    if id == nil then id = ((source and source.source) or 'WeatherAdjuster') .. ':' .. value.region end
    assert(type(id) == 'string' and #id > 0 and not id:find('%c'), 'Invalid registration id')
    local priority = definition.priority == nil and 0 or definition.priority
    assert(type(priority) == 'number' and priority == priority and math.abs(priority) < math.huge,
        'priority must be a finite number')
    sequence = sequence + 1
    entries[id] = { region = value.region, preset = value.preset, priority = priority, order = sequence }
    changed()
    return id
end

function M.unregisterRegion(id)
    if entries[id] then entries[id] = nil; changed(); return true end
    return false
end

-- The runtime requests a fresh snapshot once engine defaults are available.
function M.getRegions(defaults, userPresets)
    local sorted, result = {}, { presets = {}, regions = {}, sources = {} }
    for id, entry in pairs(entries) do sorted[#sorted + 1] = { id = id, value = entry } end
    table.sort(sorted, function(a, b)
        if a.value.priority == b.value.priority then return a.value.order < b.value.order end
        return a.value.priority < b.value.priority
    end)
    for _, item in ipairs(sorted) do
        local id, entry = item.id, item.value
        local preset = files.preset(entry.preset, defaults)
        -- MWSE cloud names are relative to the textures directory.
        for _, weather in pairs(preset) do
            if type(weather) == 'table' and weather.cloudTexture then
                weather.cloudTexture = weather.cloudTexture:gsub('\\', '/')
                    :gsub('^[Tt][Ee][Xx][Tt][Uu][Rr][Ee][Ss]/', '')
            end
        end
        local name = '[Mod] ' .. id:gsub('^@', ''):sub(1, 90)
        while result.presets[name] or (userPresets or {})[name] do name = name .. '*' end
        local previous = result.regions[entry.region]
        if previous then
            mwse.log('[Weather Adjuster] %s replaces %s for %s', id, result.sources[previous], entry.region)
        end
        result.presets[name], result.sources[name] = preset, id
        result.regions[entry.region] = name
    end
    return result
end

return M
