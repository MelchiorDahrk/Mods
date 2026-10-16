local core = require('openmw.core')
local types = require('openmw.types')
local world = require('openmw.world')
local common = require('scripts.FabricantGuar.common')
local lifecycle = require('scripts.FabricantGuar.lifecycle')

local globals
local player, gizmo
local sources, reports, watched = {}, {}, {}
local requests = {}
local repair, repairId = nil, 0
local elapsed, atomizerElapsed = 0, 0
local watchState, imperfectState

local function resolveGizmo()
    if common.valid(gizmo) then return gizmo end
    gizmo = world.getObjectByFormId(core.getFormId('Fabricant Guar.ESP', 1))
    if not common.valid(gizmo) then
        -- getObjectByFormId does not itself load a cell. Register the original
        -- placement and disabled storage location, without activating either.
        world.getExteriorCell(6, -9):getAll(types.Creature)
        world.getCellByName('toddtest'):getAll(types.Creature)
    end
    if common.valid(gizmo) and gizmo.recordId == 'mdfg_gizmo' then return gizmo end
    return nil
end

local function guarding()
    -- "new" requests the post-summon greeting, which clears it back to 0.
    -- Guard/Patrol remain available after that greeting.
    return globals ~= nil and globals.mdfg_global_following == 0
        and globals.mdfg_global_foraging == 0 and globals.mdfg_global_dead == 0
        and globals.mdfg_global_matrixform == 0 and globals.mdfg_global_imperfect == 0
end

local function watch(actor, enabled)
    if watched[actor.id] ~= enabled then
        actor:sendEvent('FGWatchCombat', { enabled = enabled, player = player })
        watched[actor.id] = enabled
    end
end

local function active(object)
    if object.recordId == 'mdfg_gizmo' then gizmo = object end
    if object.recordId == 'mdfg_matrix' or object.recordId == 'mdfg_imperfect' then sources[object.id] = object end
    if types.Actor.objectIsInstance(object) and player then
        watched[object.id] = nil
        watch(object, guarding())
    end
end

local function pollSourceRequests()
    for id, source in pairs(sources) do
        if not common.valid(source) then sources[id] = nil
        else
            local script = world.mwscript.getLocalScript(source)
            if script and script.variables.omwsummon == 1 then
                local revive = source.recordId == 'mdfg_matrix' and script.variables.omwrevive == 1
                local request = lifecycle.capture(source, revive)
                if request then
                    requests[#requests + 1] = request
                    script.variables.omwsummon = 5 -- accepted; source must wait
                end
            end
        end
    end
end

local function pollWhistle()
    local script = world.mwscript.getGlobalScript('mdfg_script_summongizmo')
    if not script or not script.variables.pending or script.variables.pending <= 0 then return end
    -- Only the whistle still uses this hook. After load a stopped global
    -- script's .object can be nil, so the whistle's explicit Player is valid.
    local source = script.object or player
    local request = lifecycle.capture(source, false)
    if request then
        request.source = nil -- no local handshake for the whistle
        requests[#requests + 1] = request
        script.variables.pending = 0
    end
end

local function pollRepair(dt)
    if repair then
        repair.retry = repair.retry - dt
        if repair.retry <= 0 then
            player:sendEvent('FGRepair', { id = repair.id })
            repair.retry = 1
        end
        return
    end
    local script = world.mwscript.getGlobalScript('mdfg_script_repairmodule')
    if script and script.variables.pending and script.variables.pending > 0 then
        repairId = repairId + 1
        repair = { id = repairId, retry = 0 }
        -- Transfer one request into Lua's saved state. A second request stays
        -- in the MWScript counter until the player acknowledges this one.
        script.variables.pending = script.variables.pending - 1
    end
end

local function allied(actor)
    if actor == player or actor == gizmo then return true end
    local report = common.valid(actor) and reports[actor.id]
    return report and report.allied and world.getSimulationTime() - report.time < 1.5
end

local function assist()
    if guarding() and common.alive(gizmo) and common.alive(player) and common.near(gizmo, player, 3000) then
        gizmo:sendEvent('FGAssist', { player = player })
    end
end

local function combatTick()
    local now = world.getSimulationTime()
    for id, report in pairs(reports) do
        if now - report.time > 1.5 or not common.alive(report.actor) then reports[id] = nil
        else
            for _, target in ipairs(report.targets) do
                if common.alive(target) and (allied(report.actor) or allied(target))
                    and common.near(report.actor, player, 3000) then
                    assist()
                    return
                end
            end
        end
    end
end

local function stateTick()
    local state = guarding()
    local imperfect = globals.mdfg_global_imperfect == 1
    if state ~= watchState then
        watchState = state
        if not state then reports = {} end
        for _, actor in ipairs(world.activeActors) do watch(actor, state) end
    end
    if imperfect ~= imperfectState then
        imperfectState = imperfect
        for _, source in pairs(sources) do
            if common.valid(source) and source.recordId == 'mdfg_imperfect' then
                source:sendEvent('FGImperfectActive', imperfect)
            end
        end
    end
    if state then combatTick() end
end

local function onUpdate(dt)
    if not player or not globals then return end
    -- UI requests must also be serviced while dialogue pauses simulation.
    pollRepair(dt)
    pollSourceRequests()
    pollWhistle()
    if #requests > 0 then
        local companion = resolveGizmo()
        if companion and lifecycle.step(requests[1], companion, player, globals) then table.remove(requests, 1) end
    end
    if dt <= 0 then return end
    elapsed, atomizerElapsed = elapsed + dt, atomizerElapsed + dt
    if elapsed >= 0.25 then elapsed = elapsed % 0.25; stateTick() end
    if atomizerElapsed >= 1 then
        atomizerElapsed = atomizerElapsed % 1
        if globals.mdfg_global_following == 1 and globals.mdfg_global_muskatomizer == 1 then
            for _, actor in ipairs(world.activeActors) do
                if common.alive(actor) and common.isGuar(actor) and common.near(actor, player, 1024) then
                    actor:sendEvent('FGAttract', { player = player })
                end
            end
        end
    end
end

local function onActivate(object, actor)
    if actor ~= player or not common.isGuar(object) or globals.mdfg_global_sample_guar ~= 0 then return end
    for _, item in pairs(types.Actor.getEquipment(player)) do
        if item.recordId == 'mdfg_w_collector' then
            globals.mdfg_global_sample_guar = 1
            player:sendEvent('FGMessage', '[Guar musk sample collected.]')
            return -- normal engine activation remains intact
        end
    end
end

return {
    engineHandlers = {
        onPlayerAdded = function(object)
            player = object
            globals = world.mwscript.getGlobalVariables()
            resolveGizmo()
            -- Rebuild transient caches; saved requests retain their own refs.
            for _, actor in ipairs(world.activeActors) do active(actor) end
        end,
        onObjectActive = active,
        onUpdate = onUpdate,
        onActivate = onActivate,
        onSave = function()
            return { gizmo = gizmo, requests = requests, repair = repair, repairId = repairId,
                atomizerElapsed = atomizerElapsed }
        end,
        onLoad = function(data)
            data = data or {}
            gizmo, requests = data.gizmo, data.requests or {}
            repair, repairId = data.repair, data.repairId or 0
            if repair then repair.retry = 0 end
            atomizerElapsed = data.atomizerElapsed or 0
            player, globals = nil, nil
            sources, reports, watched = {}, {}, {}
            watchState, imperfectState = nil, nil
        end,
    },
    eventHandlers = {
        FGRevivalStatsRestored = function(data)
            if data.actor == gizmo and requests[1] and requests[1].phase == 'finish' then
                requests[1].statsRestored = true
            end
        end,
        FGCombatReport = function(data)
            if not common.valid(data.actor) or not guarding() then return end
            data.time = world.getSimulationTime()
            reports[data.actor.id] = data
        end,
        FGCombatInactive = function(data)
            reports[data.actor.id], watched[data.actor.id] = nil, nil
        end,
        FGHit = function(data)
            if guarding() and common.alive(data.attacker)
                and (allied(data.actor) or allied(data.attacker)) then assist() end
        end,
        FGGuardFollowing = function(data)
            if data.actor == gizmo and guarding() then globals.mdfg_global_following = 1 end
        end,
        FGRepairAccepted = function(data)
            if repair and data.id == repair.id then repair = nil end
        end,
    },
}
