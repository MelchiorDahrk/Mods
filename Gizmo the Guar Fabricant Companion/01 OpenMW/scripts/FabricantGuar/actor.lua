local core = require('openmw.core')
local I = require('openmw.interfaces')
local nearby = require('openmw.nearby')
local self = require('openmw.self')
local types = require('openmw.types')
local common = require('scripts.FabricantGuar.common')

local isGizmo = self.recordId == 'mdfg_gizmo'
local isImperfect = self.recordId == 'mdfg_imperfect'
local elapsed, reportElapsed = 0, 0
local watching, imperfectActive = false, true
local player

local function follows(target)
    local found = false
    I.AI.forEachPackage(function(p)
        if p.type == 'Follow' and p.target == target then found = true end
    end)
    return found
end

local function guardPackage()
    -- Guard and Patrol have these native Wander distances. Forage uses 1800.
    -- Combat can temporarily sit above the command, especially after load.
    local guard, anotherCommand = false, false
    I.AI.forEachPackage(function(p)
        if p.type == 'Wander' then
            if p.distance == 0 or p.distance == 800 then guard = true
            else anotherCommand = true end
        elseif p.type == 'Follow' or p.type == 'Escort' or p.type == 'Travel' then
            anotherCommand = true
        end
    end)
    return guard and not anotherCommand
end

local function attract(data)
    if not I.AI or not common.alive(self) or not common.alive(data.player) then return end
    if not common.isGuar(self) or not common.near(self, data.player, 1024) then return end
    -- Let existing fights finish; do not wipe a valid follow or stacked combat.
    if #I.AI.getTargets('Combat') > 0 or follows(data.player) then return end
    I.AI.startPackage({ type = 'Follow', target = data.player })
end

local function assist(data)
    if not isGizmo or not common.alive(self) or not common.alive(data.player)
        or not common.near(self, data.player, 3000) or not guardPackage() then return end
    I.AI.startPackage({ type = 'Follow', target = data.player, cancelOther = false })
    core.sendGlobalEvent('FGGuardFollowing', { actor = self.object })
end

local function imperfectTick()
    if not imperfectActive or not common.alive(self) then return end
    local hasTarget = false
    I.AI.filterPackages(function(p)
        if p.type ~= 'Combat' then return true end
        if common.alive(p.target) and self.cell:isInSameSpace(p.target) then
            hasTarget = true
            return true
        end
        return false
    end)
    if hasTarget then return end
    local closest, distance = nil, 1000
    for _, actor in ipairs(nearby.actors) do
        if actor.recordId ~= self.recordId and common.alive(actor)
            and common.near(self, actor, distance) then
            closest, distance = actor, (self.position - actor.position):length()
        end
    end
    if closest then I.AI.startPackage({ type = 'Combat', target = closest, cancelOther = false }) end
end

local function reportCombat()
    if not I.AI or not player or not common.alive(self) then return end
    local targets = I.AI.getTargets('Combat')
    local allied = false
    I.AI.forEachPackage(function(p)
        if p.sideWithTarget and p.target == player then allied = true end
    end)
    core.sendGlobalEvent('FGCombatReport', { actor = self.object, targets = targets, allied = allied })
end

local function onUpdate(dt)
    if dt <= 0 or (not watching and not isImperfect) then return end
    elapsed = elapsed + dt
    if elapsed < 0.25 then return end
    elapsed = elapsed % 0.25
    if isImperfect then imperfectTick() end
    if watching then
        reportElapsed = reportElapsed + 0.25
        if reportElapsed >= 0.5 then
            reportElapsed = 0
            reportCombat()
        end
    end
end

-- Public combat callbacks include successful player-initiated attacks as well
-- as attacks on the player; do not change damage or suppress other handlers.
I.Combat.addOnHitHandler(function(attack)
    if watching and common.valid(attack.attacker) then
        core.sendGlobalEvent('FGHit', { actor = self.object, attacker = attack.attacker })
    end
end)

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onInactive = function()
            watching, player = false, nil
            core.sendGlobalEvent('FGCombatInactive', { actor = self.object })
        end,
    },
    eventHandlers = {
        FGWatchCombat = function(data) watching, player = data.enabled, data.player end,
        FGImperfectActive = function(active) imperfectActive = active end,
        FGAttract = attract,
        FGAssist = assist,
        FGRestoreStats = function(stats)
            if not isGizmo then return end
            types.Actor.stats.level(self).current = stats.level
            for category, values in pairs(stats) do
                if type(values) == 'table' then
                    for name, props in pairs(values) do
                        local stat = types.Actor.stats[category][name](self)
                        for property, value in pairs(props) do
                            if category == 'dynamic' and name == 'health' and property == 'current' then
                                value = math.max(1, props.base + props.modifier)
                            end
                            stat[property] = value
                        end
                    end
                end
            end
            core.sendGlobalEvent('FGRevivalStatsRestored', { actor = self.object })
        end,
        FGRevived = function(data)
            if isGizmo and common.alive(self) then
                I.AI.removePackages('Combat')
                I.AI.startPackage({ type = 'Follow', target = data.player })
            end
        end,
    },
}
