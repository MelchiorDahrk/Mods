local I = require('openmw.interfaces')
local nearby = require('openmw.nearby')
local self = require('openmw.self')
local common = require('scripts.FabricantGuar.common')
local elapsed, active = 0, true

local function tick()
    if not active or not common.alive(self) then return end
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
    local closest, distance2 = nil, 1000 * 1000
    local position = self.position
    for _, actor in ipairs(nearby.actors) do
        if actor.recordId ~= self.recordId and common.alive(actor)
            and actor.cell ~= nil and self.cell:isInSameSpace(actor) then
            local candidate2 = (position - actor.position):length2()
            if candidate2 < distance2 then closest, distance2 = actor, candidate2 end
        end
    end
    if closest then I.AI.startPackage({ type = 'Combat', target = closest, cancelOther = false }) end
end

return {
    engineHandlers = { onUpdate = function(dt)
        if dt <= 0 then return end
        elapsed = elapsed + dt
        if elapsed >= 0.25 then elapsed = elapsed % 0.25; tick() end
    end },
    eventHandlers = { FGImperfectActive = function(value) active = value end },
}
