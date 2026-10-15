local animation = require('openmw.animation')
local core = require('openmw.core')
local self = require('openmw.self')
return { eventHandlers = { KegDripSmokeProbe = function()
    assert(animation.isPlaying(self, 'idle'), 'KEG DRIP TEST FAILED: idle is not playing')
    core.sendGlobalEvent('KegDripSmokeAnimated', self.object.id)
end } }
