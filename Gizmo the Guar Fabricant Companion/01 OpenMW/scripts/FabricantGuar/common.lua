local types = require('openmw.types')

local M = {}

function M.valid(object)
    return object ~= nil and object:isValid()
end

function M.alive(object)
    return M.valid(object) and object.enabled and types.Actor.objectIsInstance(object)
        and not types.Actor.isDead(object)
end

function M.near(a, b, radius)
    return M.valid(a) and M.valid(b) and a.cell ~= nil and b.cell ~= nil
        and a.cell:isInSameSpace(b) and (a.position - b.position):length() < radius
end

function M.isGuar(object)
    local id = object.recordId:lower()
    return types.Creature.objectIsInstance(object) and id:find('guar') ~= nil
        and id:find('guar%a') == nil
end

return M
