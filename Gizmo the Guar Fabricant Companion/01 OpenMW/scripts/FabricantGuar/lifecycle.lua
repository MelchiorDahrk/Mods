-- Global-context lifecycle helper. MWScript keeps its source alive through
-- this handshake. All in-flight data is serializable and saved by global.lua.
local world = require('openmw.world')
local types = require('openmw.types')
local util = require('openmw.util')
local common = require('scripts.FabricantGuar.common')
local M = {}

local function snapshotStats(actor)
    local result = { dynamic = {}, attributes = {}, ai = {}, level = types.Actor.stats.level(actor).current }
    for _, name in ipairs({ 'health', 'magicka', 'fatigue' }) do
        local s = types.Actor.stats.dynamic[name](actor)
        result.dynamic[name] = { base = s.base, current = s.current, modifier = s.modifier }
    end
    for _, name in ipairs({ 'strength', 'intelligence', 'willpower', 'agility', 'speed', 'endurance', 'personality', 'luck' }) do
        local s = types.Actor.stats.attributes[name](actor)
        result.attributes[name] = { base = s.base, damage = s.damage, modifier = s.modifier }
    end
    for _, name in ipairs({ 'fight', 'flee', 'alarm', 'hello' }) do
        local s = types.Actor.stats.ai[name](actor)
        result.ai[name] = { base = s.base, modifier = s.modifier }
    end
    return result
end

function M.hasGuarSoul(player)
    for _, item in ipairs(types.Actor.inventory(player):getAll(types.Miscellaneous)) do
        local soul = types.Item.itemData(item).soul
        if soul == 'guar' or soul == 'guar_feral' then return true end
    end
    return false
end

function M.capture(source, revive)
    if not common.valid(source) or source.cell == nil then return nil end
    return { source = source, cellId = source.cell.id, position = source.position,
        rotation = source.rotation, revive = revive, phase = 'prepare' }
end

function M.step(request, gizmo, player, globals)
    if not common.valid(gizmo) then return false end
    local script = request.source and common.valid(request.source) and world.mwscript.getLocalScript(request.source)
    local vars = script and script.variables
    if request.phase == 'prepare' then
        if request.revive and types.Actor.isDead(gizmo) then
            if not M.hasGuarSoul(player) then
                -- The native matrix prompt requires a soul but never consumes
                -- it. Recheck after the prompt, preserving that effective rule.
                player:sendEvent('FGMessage', '[A guar soul is required to revive Gizmo.]')
                if vars then vars.omwsummon = 0; vars.untangle = 0; vars.omwrevive = 0 end
                return true
            end
            if not vars then return false end
            request.stats = snapshotStats(gizmo)
            request.stash = world.createObject('mdfg_omw_revival_store')
            -- Objects with no cell are not part of a saved world. Place the
            -- stash in the ESP's existing storage cell before moving items.
            request.stash:teleport('toddtest', util.vector3(0, 0, -10000))
            for _, item in ipairs(types.Actor.inventory(gizmo):getAll()) do item:moveInto(request.stash) end
            -- Object moves apply at the frame boundary, before the next
            -- MWScript executes its native Resurrect command.
            vars.omwsummon = 2
            request.phase = 'resurrect'
            return false
        end
        request.phase = 'teleport'
    elseif request.phase == 'resurrect' then
        request.stash.enabled = false
        if not vars or vars.omwsummon ~= 3 or types.Actor.isDead(gizmo) then return false end
        -- Native Resurrect rebuilds base inventory; remove that copy first.
        for _, item in ipairs(types.Actor.inventory(gizmo):getAll()) do item:remove() end
        for _, item in ipairs(types.Container.content(request.stash):getAll()) do item:moveInto(gizmo) end
        request.phase = 'restore'
        return false
    elseif request.phase == 'restore' then
        -- Leave a frame for inventory moves and stat writes to complete.
        request.stash:remove()
        request.stash = nil
        request.phase = 'teleport'
    end
    if request.phase == 'teleport' then
        local cell = world.getCellById(request.cellId)
        globals.mdfg_global_new = 1
        if request.revive then
            globals.mdfg_global_dead = 0
            globals.mdfg_global_following = 1
            globals.mdfg_global_foraging = 0
        end
        if vars then
            if request.source.recordId == 'mdfg_matrix' then globals.mdfg_global_matrixform = 0
            elseif request.source.recordId == 'mdfg_imperfect' then globals.mdfg_global_imperfect = 0 end
            world.createObject('mdfg_effect_matrix'):teleport(cell, request.position, request.rotation)
            vars.omwsummon = 4
        end
        gizmo:teleport(cell, request.position, request.rotation)
        -- Stat writes are supported only on local self. Teleport activates the
        -- revived actor so its local script can restore the saved values.
        if request.stats then gizmo:sendEvent('FGRestoreStats', request.stats) end
        request.phase = 'finish'
        return false
    elseif request.phase == 'finish' then
        if request.stats and not request.statsRestored then
            -- Re-deliver after loading even if the pre-save event was lost.
            gizmo:sendEvent('FGRestoreStats', request.stats)
            return false
        end
        if request.revive then gizmo:sendEvent('FGRevived', { player = player }) end
        return true
    end
    return false
end

return M
