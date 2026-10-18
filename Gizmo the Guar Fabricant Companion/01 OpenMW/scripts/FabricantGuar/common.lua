local types = require('openmw.types')

local M = {}
local guarRecords = {}

function M.valid(object)
    return object ~= nil and object:isValid()
end

function M.alive(object)
    return M.valid(object) and object.enabled and types.Actor.objectIsInstance(object)
        and not types.Actor.isDead(object)
end

function M.near(a, b, radius)
    return M.valid(a) and M.valid(b) and a.cell ~= nil and b.cell ~= nil
        and a.cell:isInSameSpace(b) and (a.position - b.position):length2() < radius * radius
end

function M.isGuar(object)
    if not types.Creature.objectIsInstance(object) then return false end
    local id = object.recordId
    local result = guarRecords[id]
    if result == nil then
        result = id:find('guar') ~= nil and id:find('guar%a') == nil
        guarRecords[id] = result
    end
    return result
end

return M
