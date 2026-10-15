local types = require('openmw.types')
local util = require('openmw.util')
local world = require('openmw.world')
local I = require('openmw.interfaces')
local storage = require('openmw.storage')

I.Settings.registerGroup {
    key = 'SettingsGlobalKegDrip',
    page = 'KegDrip',
    l10n = 'KegDrip',
    name = 'GroupName',
    permanentStorage = true,
    settings = {
        {
            key = 'formPuddles',
            renderer = 'checkbox',
            name = 'FormPuddlesName',
            description = 'FormPuddlesDescription',
            default = true,
        },
    },
}
local settings = storage.globalSection('SettingsGlobalKegDrip')
local formPuddles = settings:get('formPuddles') ~= false

-- These records use the existing effect-only NIFs, at the keg's own transform.
local kegs = {
    ['f/furn_com_kegstand.nif'] = { id = 'furn_com_kegstand_dr', offset = util.vector3(0, -54.4, -64) },
    ['f/furn_de_kegstand.nif'] = { id = 'furn_de_kegstand_dr', offset = util.vector3(0, -54.4, -64) },
    ['f/furn_winekeg00.nif'] = { id = 'furn_winekeg00_dr', offset = util.vector3(0, -43.4, -69.5) },
    ['hf/f/hf_furn_kegstand_01.nif'] = { id = 'hf_furn_kegstand_01_dr', offset = util.vector3(0, -54.4, -64) },
    ['hr/f/hr_furn_kegstand_01.nif'] = { id = 'hr_furn_kegstand_01_dr', offset = util.vector3(0, -54.4, -64) },
    ['sky/f/sky_furn_n_m_keg_01.nif'] = { id = 'sky_furn_n_m_keg_01_dr', offset = util.vector3(0, -54.4, -64) },
}
local effectIds = {}
for _, keg in pairs(kegs) do effectIds[keg.id] = true end
local effectScript = 'scripts/KegDrip/effect.lua'
local up, forward = util.vector3(0, 0, 1), util.vector3(0, 1, 0)
local minimumUp = math.cos(math.rad(5))
local puddleId = 'kegpuddle' -- OpenMW normalizes record IDs to lowercase.
local puddleGrowth = 1 / 60
local ground = {}
local activeCells = {}
local temporaryPuddles = {}
local elapsed = 1
local previousCell

local function normalizeMesh(mesh)
    return mesh and mesh:lower():gsub('\\', '/'):gsub('^meshes/', '')
end

local function available(object)
    return object:isValid() and object.enabled and object.count > 0
end

local function hasReceiver(landing, receivers)
    for _, receiver in ipairs(receivers) do
        if (receiver.position - landing):length() <= 22 then return true end
    end
    return false
end

local function samePlacement(effect, keg)
    return (effect.position - keg.position):length() < 0.01
        and math.abs(effect.scale - keg.scale) < 0.001
        and (effect.rotation * up - keg.rotation * up):length() < 0.001
        and (effect.rotation * forward - keg.rotation * forward):length() < 0.001
end

local function refreshCell(cell, dt, resetPuddles)
    local receivers, effects, puddles, used = {}, {}, {}, {}
    for _, object in ipairs(cell:getAll(types.Miscellaneous)) do
        if available(object) then
            local mesh = normalizeMesh(types.Miscellaneous.record(object).model)
            if mesh and (mesh:find('bucket', 1, true) or mesh:find('bowl', 1, true)) then
                receivers[#receivers + 1] = object
            end
        end
    end
    for _, object in ipairs(cell:getAll(types.Activator)) do
        if object:isValid() and object.count > 0 then
            if effectIds[object.recordId] then effects[#effects + 1] = object
            elseif object.recordId == puddleId then
                if resetPuddles then object:remove()
                else puddles[#puddles + 1] = object end
            end
        end
    end
    for _, keg in ipairs(cell:getAll()) do
        if available(keg) then
            local record = keg.type.record and keg.type.record(keg)
            local definition = record and kegs[normalizeMesh(record.model)]
            if definition and (keg.rotation * up).z >= minimumUp then
                local landing = keg.position + keg.rotation * (definition.offset * keg.scale)
                local effect
                for _, candidate in ipairs(effects) do
                    if not used[candidate.id] and available(candidate)
                        and candidate.recordId == definition.id and samePlacement(candidate, keg) then
                        effect = candidate
                        break
                    end
                end
                local covered = (formPuddles or not effect) and hasReceiver(landing, receivers)
                -- Preserve drips that started before their bucket was removed.
                if formPuddles or covered or effect then
                    if not effect then
                        effect = world.createObject(definition.id)
                        effect:setScale(keg.scale)
                        effect:addScript(effectScript)
                        effect:teleport(cell, keg.position, { rotation = keg.rotation, onGround = false })
                    elseif not effect:hasScript(effectScript) then
                        effect:addScript(effectScript)
                    end
                    used[effect.id] = true
                    if formPuddles then
                        local puddle, initialScale
                        for _, candidate in ipairs(puddles) do
                            local delta = candidate.position - landing
                            if not used[candidate.id] and available(candidate)
                                and delta.x * delta.x + delta.y * delta.y < 0.25
                                and delta.z < 32 * keg.scale and delta.z > -4096 then
                                puddle = candidate
                                break
                            end
                        end
                        if not covered and not puddle then
                            local hit = ground[effect.id]
                            if hit and (hit.landing - landing):length() < 0.01 then
                                puddle = world.createObject(puddleId)
                                initialScale = 0.01
                                puddle:setScale(0.01)
                                puddle:teleport(cell, hit.position, { rotation = hit.rotation, onGround = false })
                            else
                                -- Physics raycasts are local-only; the drip's local
                                -- script reports the surface back to this global script.
                                effect:sendEvent('KegDripGroundRay', { landing = landing, keg = keg })
                            end
                        end
                        ground[effect.id] = nil
                        if puddle then
                            used[puddle.id] = true
                            temporaryPuddles[puddle.id] = puddle
                            -- setScale is deferred in OpenMW; a new object still
                            -- reports scale 1 until the queued action is applied.
                            if not covered then puddle:setScale(math.min(1, (initialScale or puddle.scale) + dt * puddleGrowth)) end
                        end
                    end
                end
            end
        end
    end
    -- Discover saved effects from the cell itself, so save/load needs no Lua cache.
    for _, puddle in ipairs(puddles) do effects[#effects + 1] = puddle end
    for _, effect in ipairs(effects) do
        if not used[effect.id] then
            ground[effect.id] = nil
            effect:remove()
        end
    end
end

local function containsCell(cells, cell)
    for _, candidate in ipairs(cells) do
        if candidate == cell then return true end
    end
    return false
end

local function clearPuddles()
    -- remove() changes the count immediately, before the engine writes cells.
    -- Deleted dynamic references are omitted from the save entirely.
    for _, puddle in pairs(temporaryPuddles) do
        if puddle:isValid() and puddle.count > 0 then puddle:remove() end
    end
    temporaryPuddles = {}
    ground = {}
end

local function refresh(cell, dt)
    local cells = {}
    -- Include the surrounding loaded exterior cells as well as the player's cell.
    if cell.isExterior then
        for x = cell.gridX - 1, cell.gridX + 1 do
            for y = cell.gridY - 1, cell.gridY + 1 do
                cells[#cells + 1] = world.getExteriorCell(x, y, cell)
            end
        end
    else
        cells[1] = cell
    end
    for id, puddle in pairs(temporaryPuddles) do
        if not puddle:isValid() or puddle.count == 0 then temporaryPuddles[id] = nil
        elseif not containsCell(cells, puddle.cell) then
            puddle:remove()
            temporaryPuddles[id] = nil
        end
    end
    for _, candidate in ipairs(cells) do
        local newlyActive = not containsCell(activeCells, candidate)
        if formPuddles or newlyActive then refreshCell(candidate, dt, newlyActive) end
    end
    activeCells = cells
end

return {
    eventHandlers = {
        KegDripGround = function(data)
            if formPuddles and available(data.effect) and effectIds[data.effect.recordId] then
                ground[data.effect.id] = data
            end
        end,
    },
    engineHandlers = {
        onPlayerAdded = function()
            previousCell = nil
            elapsed = 1
            ground = {}
            activeCells = {}
            temporaryPuddles = {}
        end,
        onSave = clearPuddles,
        onLoad = function()
            ground = {}
            activeCells = {}
            temporaryPuddles = {}
            previousCell = nil
            elapsed = 1
        end,
        onUpdate = function(dt)
            local enabled = settings:get('formPuddles') ~= false
            if enabled ~= formPuddles then
                formPuddles = enabled
                clearPuddles()
                activeCells = {}
                previousCell = nil
                elapsed = 0
            end
            if dt == 0 then return end
            local player = world.players[1]
            if not player or not player.cell then return end
            if formPuddles then elapsed = elapsed + dt end
            if player.cell ~= previousCell or (formPuddles and elapsed >= 1) then
                local growthTime = player.cell == previousCell and elapsed or 0
                previousCell = player.cell
                elapsed = 0
                refresh(player.cell, growthTime)
            end
        end,
    },
}
