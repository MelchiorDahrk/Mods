local core = require('openmw.core')
local types = require('openmw.types')
local world = require('openmw.world')
local common = require('scripts.FabricantGuar.common')
local lifecycle = require('scripts.FabricantGuar.lifecycle')

local globals
local player, gizmo
local sources, reports, watched, attracted = {}, {}, {}, {}
local guarCandidates, attractionState = {}, false
local epoch, guardRequest, guardApplied = 0, 0, 0
local companionPath = "scripts/FabricantGuar/companion.lua"
local imperfectPath = "scripts/FabricantGuar/imperfect.lua"
local observerPath = "scripts/FabricantGuar/observer.lua"
local guarPath = "scripts/FabricantGuar/guar.lua"
local legacyPath = "scripts/FabricantGuar/actor.lua"

local function attach(object, path, init)
    if not object:hasScript(path) then object:addScript(path, init) end
end

local function detach(object, path)
    if common.valid(object) and object:hasScript(path) then object:removeScript(path) end
end
local requests = {}
local repair, repairId = nil, 0
local elapsed, atomizerElapsed, inspectElapsed = 0, 0, 0
local watchState, imperfectState

local function resolveGizmo()
    if common.valid(gizmo) then attach(gizmo, companionPath); return gizmo end
    gizmo = world.getObjectByFormId(core.getFormId('Fabricant Guar.ESP', 1))
    if not common.valid(gizmo) then
        -- getObjectByFormId does not itself load a cell. Register the original
        -- placement and disabled storage location, without activating either.
        world.getExteriorCell(6, -9):getAll(types.Creature)
        world.getCellByName('toddtest'):getAll(types.Creature)
    end
    if common.valid(gizmo) and gizmo.recordId == 'mdfg_gizmo' then
        attach(gizmo, companionPath)
        return gizmo
    end
    return nil
end

local function guarding()
    -- "new" requests the post-summon greeting, which clears it back to 0.
    -- Guard/Patrol remain available after that greeting.
    return globals ~= nil and globals.mdfg_global_following == 0
        and globals.mdfg_global_foraging == 0 and globals.mdfg_global_dead == 0
        and globals.mdfg_global_matrixform == 0 and globals.mdfg_global_imperfect == 0
end

local function canMonitor()
    return guarding() and common.alive(gizmo) and common.alive(player)
        and common.near(gizmo, player, 3000)
end

local function watch(actor)
    if watched[actor.id] then return end
    attach(actor, observerPath, { player = player, epoch = epoch })
    actor:sendEvent('FGObserve', { player = player, epoch = epoch })
    watched[actor.id] = actor
end

local function setWatching(enabled)
    if watchState == enabled then return end
    epoch = epoch + 1
    watchState = enabled
    if common.valid(gizmo) then
        gizmo:sendEvent('FGGuardSession', { enabled = enabled, epoch = epoch })
    end
    reports = {}
    for _, actor in pairs(watched) do detach(actor, observerPath) end
    watched = {}
    if enabled then
        -- All active hit recipients remain relevant: long-range player hits
        -- and distant followers were observable in the original version.
        -- Observers have no frame handler and report only meaningful changes.
        for _, actor in ipairs(world.activeActors) do watch(actor) end
    end
end

local function active(object)
    if types.Actor.objectIsInstance(object) then
        detach(object, legacyPath)
        if object.recordId == 'mdfg_gizmo' and object == resolveGizmo() then
            attach(object, companionPath)
        end
        if object.recordId == 'mdfg_imperfect' then
            attach(object, imperfectPath)
            object:sendEvent('FGImperfectActive', globals == nil or globals.mdfg_global_imperfect == 1)
        end
        if player and watchState then watched[object.id] = nil; watch(object)
        else detach(object, observerPath) end
        -- Saved attraction adapters are rebuilt at the next atomizer tick.
        detach(object, guarPath)
        attracted[object.id] = nil
        if globals and globals.mdfg_global_following == 1 and globals.mdfg_global_muskatomizer == 1
            and common.isGuar(object) then guarCandidates[object.id] = object end
    end
    if object.recordId == 'mdfg_matrix' or object.recordId == 'mdfg_imperfect' then
        sources[object.id] = object
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
        gizmo:sendEvent('FGAssist', { player = player, epoch = epoch })
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
    if canMonitor() then
        guardRequest = guardRequest + 1
        gizmo:sendEvent('FGGuardCheck', { player = player, request = guardRequest })
    else
        setWatching(false)
    end
    local imperfect = globals.mdfg_global_imperfect == 1
    if imperfect ~= imperfectState then
        imperfectState = imperfect
        for _, source in pairs(sources) do
            if common.valid(source) and source.recordId == 'mdfg_imperfect' then
                source:sendEvent('FGImperfectActive', imperfect)
            end
        end
    end
    if watchState then combatTick() end
end

local function attractionTick()
    local enabled = globals.mdfg_global_following == 1 and globals.mdfg_global_muskatomizer == 1
    local current, activeIds = {}, {}
    -- Reconcile only while a feature is active. No ordinary-actor cache grows
    -- with exploration while Gizmo cannot assist and the atomizer is off.
    if enabled or watchState then
        for _, actor in ipairs(world.activeActors) do
            activeIds[actor.id] = true
            if watchState then watch(actor) end
            if enabled and not attractionState and common.isGuar(actor) then guarCandidates[actor.id] = actor end
        end
    end
    if enabled then
        for id, actor in pairs(guarCandidates) do
            if not activeIds[id] then guarCandidates[id] = nil
            elseif common.alive(actor) and common.near(actor, player, 1024) then
                attach(actor, guarPath)
                current[id] = actor
                actor:sendEvent('FGAttract', { player = player })
            end
        end
    else
        guarCandidates = {}
    end
    attractionState = enabled
    for id, actor in pairs(attracted) do
        if not current[id] then detach(actor, guarPath) end
    end
    attracted = current
    for id, actor in pairs(watched) do
        if not activeIds[id] then
            detach(actor, observerPath)
            watched[id], reports[id] = nil, nil
        end
    end
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
    inspectElapsed = inspectElapsed + dt
    if inspectElapsed >= 0.5 then
        inspectElapsed = inspectElapsed % 0.5
        if watchState then
            for _, actor in pairs(watched) do
                if common.valid(actor) then actor:sendEvent('FGInspectCombat', { epoch = epoch }) end
            end
        end
    end
    if atomizerElapsed >= 1 then
        atomizerElapsed = atomizerElapsed % 1
        attractionTick()
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
            return { version = 2, epoch = epoch, gizmo = gizmo, requests = requests, repair = repair, repairId = repairId,
                atomizerElapsed = atomizerElapsed }
        end,
        onLoad = function(data)
            data = data or {}
            gizmo, requests = data.gizmo, data.requests or {}
            repair, repairId = data.repair, data.repairId or 0
            if repair then repair.retry = 0 end
            atomizerElapsed = data.atomizerElapsed or 0
            player, globals = nil, nil
            sources, reports, watched, attracted = {}, {}, {}, {}
            guarCandidates, attractionState = {}, false
            watchState, imperfectState = false, nil
            epoch = (data.epoch or 0) + 1
            guardRequest, guardApplied, elapsed, inspectElapsed = 0, 0, 0, 0
        end,
    },
    eventHandlers = {
        FGGuardState = function(data)
            if data.actor == gizmo and data.request > guardApplied and data.request <= guardRequest then
                guardApplied = data.request
                setWatching(data.eligible and canMonitor() or false)
            end
        end,
        FGRevivalStatsRestored = function(data)
            if data.actor == gizmo and requests[1] and requests[1].phase == 'finish' then
                requests[1].statsRestored = true
            end
        end,
        FGCombatReport = function(data)
            if data.epoch ~= epoch or not watchState or not common.valid(data.actor) then return end
            data.time = world.getSimulationTime()
            reports[data.actor.id] = data
        end,
        FGCombatInactive = function(data)
            if data.epoch == epoch and common.valid(data.actor) then
                -- A quick deactivate/reactivate can overtake the notification.
                -- Do not tear down the subscription rebuilt by onObjectActive.
                for _, actor in ipairs(world.activeActors) do if actor == data.actor then return end end
                reports[data.actor.id], watched[data.actor.id] = nil, nil
                detach(data.actor, observerPath)
            end
        end,
        FGHit = function(data)
            if data.epoch == epoch and watchState and canMonitor() and common.alive(data.attacker)
                and (allied(data.actor) or allied(data.attacker)) then assist() end
        end,
        FGGuardFollowing = function(data)
            if data.actor == gizmo and data.epoch == epoch and watchState and guarding() then
                globals.mdfg_global_following = 1
                setWatching(false)
            end
        end,
        FGRepairAccepted = function(data)
            if repair and data.id == repair.id then repair = nil end
        end,
    },
}
