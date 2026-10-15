local self = require 'openmw.self'
local types = require 'openmw.types'
return {engineHandlers={onUpdate=function() types.Actor.stats.dynamic.health(self).current=1000000 end},eventHandlers={ArachnophobiaSave=function() types.Player.sendMenuEvent(self, 'ArachnophobiaSave', {}) end}}
