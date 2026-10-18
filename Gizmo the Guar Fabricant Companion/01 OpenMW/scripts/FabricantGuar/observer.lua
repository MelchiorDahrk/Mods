local core = require('openmw.core')
local I = require('openmw.interfaces')
local self = require('openmw.self')
local common = require('scripts.FabricantGuar.common')

local player, epoch
local empty = {}
local lastTargets, lastAllied, lastSent = empty, false, -math.huge
local interface = {}

local function inspect()
    if not I.AI or not common.alive(self) or not common.valid(player) then return end
    local targets, allied = nil, false
    I.AI.forEachPackage(function(p)
        if p.type == 'Combat' and common.valid(p.target) then
            targets = targets or {}
            targets[#targets + 1] = p.target
        end
        if p.sideWithTarget and p.target == player then allied = true end
    end)
    targets = targets or empty
    local changed = allied ~= lastAllied or #targets ~= #lastTargets
    if not changed and #targets > 0 then
        local membership = {}
        for _, target in ipairs(lastTargets) do
            if common.valid(target) then membership[target.id] = true end
        end
        for _, target in ipairs(targets) do
            if not membership[target.id] then changed = true; break end
        end
    end
    if changed or allied or #targets > 0 then
        local now = core.getSimulationTime()
        if changed or now - lastSent >= 1 then
            core.sendGlobalEvent('FGCombatReport', { actor = self.object, targets = targets,
                allied = allied, epoch = epoch })
            lastSent = now
        end
    end
    lastTargets, lastAllied = targets, allied
end

local function observe(data)
    if player == data.player and epoch == data.epoch then return end
    player, epoch = data.player, data.epoch
    lastTargets, lastAllied, lastSent = empty, false, -math.huge
    inspect()
end

return {
    interfaceName = 'Combat',
    interface = interface,
    engineHandlers = {
        onInterfaceOverride = function(base)
            -- Own an interface layer rather than appending an unremovable hit
            -- callback to another script. Removal restores the previous layer.
            for key, value in pairs(base) do interface[key] = value end
            interface.onHit = function(attack)
                if player and common.valid(attack.attacker) then
                    core.sendGlobalEvent('FGHit', { actor = self.object,
                        attacker = attack.attacker, epoch = epoch })
                end
                return base.onHit(attack)
            end
        end,
        onInit = observe,
        onLoad = function()
            player, epoch = nil, nil
        end,
        onInactive = function()
            if player then
                core.sendGlobalEvent('FGCombatInactive', { actor = self.object, epoch = epoch })
            end
            player, epoch = nil, nil
        end,
    },
    eventHandlers = {
        FGObserve = observe,
        FGInspectCombat = function(data) if data.epoch == epoch then inspect() end end,
    },
}
