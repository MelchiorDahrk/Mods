local animation = require('openmw.animation')
local core = require('openmw.core')
local nearby = require('openmw.nearby')
local self = require('openmw.self')
local util = require('openmw.util')
local up = util.vector3(0, 0, 1)

return {
    eventHandlers = {
        KegDripGroundRay = function(data)
            if not data.keg:isValid() or not data.keg.enabled or data.keg.cell ~= self.cell then return end
            local from = data.landing + up * (32 * self.scale)
            local hit = nearby.castRay(from, from - up * 4096, {
                ignore = data.keg,
                collisionType = nearby.COLLISION_TYPE.World + nearby.COLLISION_TYPE.HeightMap,
            })
            if not hit.hit or not hit.hitNormal or hit.hitNormal.z <= 0.05 then return end
            local normal = hit.hitNormal
            local rotation = util.transform.identity
            if normal.z < 0.999999 then
                rotation = util.transform.rotate(math.acos(math.min(1, normal.z)), util.vector3(-normal.y, normal.x, 0))
            end
            core.sendGlobalEvent('KegDripGround', {
                effect = self.object,
                landing = data.landing,
                position = hit.hitPos + normal * 0.1,
                rotation = rotation,
            })
        end,
    },
    engineHandlers = {
        onActive = function()
            -- Keep the existing idle animation and its dripKeg sound keys, but
            -- give each tap its own phase instead of synchronizing the room.
            animation.playBlended(self, 'idle', {
                loops = 1000000,
                startPoint = math.random(),
                forceLoop = true,
            })
        end,
    },
}
