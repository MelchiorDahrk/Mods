local core = require('openmw.core')
local I = require('openmw.interfaces')
local self = require('openmw.self')
local types = require('openmw.types')
local common = require('scripts.FabricantGuar.common')
local guardEpoch

local function guardPackage()
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

return {
    eventHandlers = {
        FGGuardSession = function(data) guardEpoch = data.enabled and data.epoch or nil end,
        FGGuardCheck = function(data)
            core.sendGlobalEvent('FGGuardState', { actor = self.object, request = data.request,
                eligible = common.alive(self) and common.alive(data.player)
                    and common.near(self, data.player, 3000) and guardPackage() })
        end,
        FGAssist = function(data)
            if data.epoch ~= guardEpoch or guardEpoch == nil
                or not common.alive(self) or not common.alive(data.player)
                or not common.near(self, data.player, 3000) or not guardPackage() then return end
            I.AI.startPackage({ type = 'Follow', target = data.player, cancelOther = false })
            core.sendGlobalEvent('FGGuardFollowing', { actor = self.object, epoch = data.epoch })
        end,
        FGRestoreStats = function(stats)
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
            if common.alive(self) then
                I.AI.removePackages('Combat')
                I.AI.startPackage({ type = 'Follow', target = data.player })
            end
        end,
    },
}
