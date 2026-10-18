local I = require('openmw.interfaces')
local self = require('openmw.self')
local common = require('scripts.FabricantGuar.common')

return {
    eventHandlers = { FGAttract = function(data)
        if not common.alive(self) or not common.alive(data.player)
            or not common.isGuar(self) or not common.near(self, data.player, 1024) then return end
        local busy = false
        I.AI.forEachPackage(function(p)
            if (p.type == 'Combat' and p.target) or (p.type == 'Follow' and p.target == data.player) then busy = true end
        end)
        if not busy then I.AI.startPackage({ type = 'Follow', target = data.player }) end
    end },
}
