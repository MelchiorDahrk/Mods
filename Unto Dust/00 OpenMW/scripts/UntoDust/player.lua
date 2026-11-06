local postprocessing = require('openmw.postprocessing')
local self = require('openmw.self')
local async = require('openmw.async')
local settings = require('scripts.UntoDust.settings')
local lists = require('scripts.UntoDust.cellLists')
local keywords = { 'tomb', 'barrow', 'crypt', 'catacomb', 'burial' }
local shader = postprocessing.load('UntoDust')
local lastCell
local refresh = true
local active = false
local elapsed = 0

local function isDustCell(cell)
    if not cell or cell.isExterior then
        return false
    end

    local name = cell.name:lower()
    if name == '' then return false end
    if lists.contains(settings:getCopy('blacklist'), name) then return false end
    if lists.contains(settings:getCopy('whitelist'), name) then return true end
    for _, keyword in ipairs(keywords) do
        if name:find(keyword, 1, true) then
            return true
        end
    end
    return false
end

local function reset()
    -- Keep the pass resident: changing the chain rebuilds OpenMW render state.
    shader:setFloat('dustDensity', 0)
    lastCell = nil
    refresh = true
    active = false
    elapsed = 0
end

local function updateShader()
    local cell = self.cell
    local percent = settings:get('density')
    if type(percent) ~= 'number' or percent ~= percent then percent = 32 end
    local density = math.max(0, math.min(100, percent)) / 100
    active = density > 0 and isDustCell(cell)
    shader:setFloat('dustDensity', active and density or 0)
    if active then
        shader:setFloat('dustTime', elapsed)
    end
    -- OpenMW clears dynamic shaders on game load. Restore once, then only
    -- change uniforms across cell/settings changes, including tomb -> tomb.
    -- Dust belongs to the scene, before lens effects and tone mapping.
    if not shader:isEnabled() then shader:enable(1) end
    lastCell = cell
    refresh = false
end

-- Storage callbacks run for menu changes too, while simulation is paused.
settings:subscribe(async:callback(function(_, key)
    if key == nil or key == 'density' or key == 'whitelist' or key == 'blacklist' then
        updateShader()
    end
end))

local function onUpdate(dt)
    if refresh or self.cell ~= lastCell then
        updateShader()
    end
    if active then
        elapsed = elapsed + dt
        shader:setFloat('dustTime', elapsed)
    end
end

return {
    eventHandlers = {
        UntoDustCells = function(names)
            local I = require('openmw.interfaces')
            for _, key in ipairs({ 'whitelist', 'blacklist' }) do
                I.Settings.updateRendererArgument('SettingsUntoDust', key, {
                    key = key,
                    cells = names,
                    ready = true,
                })
            end
        end,
    },
    engineHandlers = {
        onActive = reset,
        onLoad = reset,
        onUpdate = onUpdate,
    },
}
