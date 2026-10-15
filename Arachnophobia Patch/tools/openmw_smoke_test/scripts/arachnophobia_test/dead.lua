local self = require 'openmw.self'
local types = require 'openmw.types'
return {engineHandlers={onInit=function() types.Actor.stats.dynamic.health(self).current=0 end}}
