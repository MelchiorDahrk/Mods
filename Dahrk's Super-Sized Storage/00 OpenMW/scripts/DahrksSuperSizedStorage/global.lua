--[[
    Mod: Dahrk's Super-Sized Storage
    Author: Melchior Dahrk

    OpenMW Lua runtime conversion of the MWSE version.
]]

local types = require('openmw.types')
local world = require('openmw.world')

local CAPACITY_MULTIPLIER = 100

local scaledRecordByOriginal = {}
local generatedScaledRecords = {}
local warnedCreateRecord = false
local warnedMissingRefPersistApi = false

local function normalizeId(recordId)
    return recordId and string.lower(recordId) or nil
end

local function rememberGeneratedRecord(recordId)
    local normalized = normalizeId(recordId)
    if normalized then
        generatedScaledRecords[normalized] = true
    end
end

local function hasValue(value)
    return value ~= nil and value ~= false and value ~= ''
end

local function getObjectField(object, field)
    local ok, value = pcall(function()
        return object[field]
    end)

    if ok then
        return value
    end

    return nil
end

local function hasRefPersistFlag(object)
    local fieldNames = {
        'isPersistent',
        'persistent',
        'refPersists',
        'refPersistent',
        'persists',
    }

    for _, field in ipairs(fieldNames) do
        if hasValue(getObjectField(object, field)) then
            return true
        end
    end

    if not warnedMissingRefPersistApi then
        print("Dahrk's Super-Sized Storage: OpenMW Lua did not expose a documented ref-persist flag; only exposed persistence fields can be skipped.")
        warnedMissingRefPersistApi = true
    end

    return false
end

local function hasScript(object, record)
    if hasValue(record.mwscript) then
        return true
    end

    local ok, localScript = pcall(function()
        return world.mwscript.getLocalScript(object)
    end)

    return ok and localScript ~= nil
end

local function getScaledRecordId(record)
    local originalId = normalizeId(record.id)
    if not originalId then
        return nil
    end

    if scaledRecordByOriginal[originalId] then
        return scaledRecordByOriginal[originalId]
    end

    local ok, result = pcall(function()
        local draft = types.Container.createRecordDraft({
            isOrganic = record.isOrganic,
            isRespawning = record.isRespawning,
            model = record.model,
            mwscript = record.mwscript,
            name = record.name,
            weight = record.weight * CAPACITY_MULTIPLIER,
        })

        return world.createRecord(draft)
    end)

    if not ok then
        if not warnedCreateRecord then
            print("Dahrk's Super-Sized Storage: failed to create scaled container records: " .. tostring(result))
            warnedCreateRecord = true
        end
        return nil
    end

    scaledRecordByOriginal[originalId] = result.id
    rememberGeneratedRecord(result.id)
    return result.id
end

local function copyLockState(fromObject, toObject)
    local lockable = types.Lockable

    if lockable.isLocked(fromObject) then
        lockable.lock(toObject, lockable.getLockLevel(fromObject))
    else
        lockable.unlock(toObject)
    end

    local key = lockable.getKeyRecord(fromObject)
    if key then
        lockable.setKeyRecord(toObject, key.id)
    end

    local trap = lockable.getTrapSpell(fromObject)
    if trap then
        lockable.setTrapSpell(toObject, trap.id)
    end
end

local function moveInventory(fromObject, toObject)
    local fromInventory = types.Container.inventory(fromObject)
    if not fromInventory:isResolved() then
        fromInventory:resolve()
    end

    local toInventory = types.Container.inventory(toObject)
    for _, item in ipairs(fromInventory:getAll()) do
        item:moveInto(toInventory)
    end
end

local function replaceContainer(object)
    if not types.Container.objectIsInstance(object) then
        return
    end

    if generatedScaledRecords[normalizeId(object.recordId)] then
        return
    end

    local record = types.Container.record(object)
    if not record or not record.weight or record.weight == 0 then
        return
    end

    if hasScript(object, record) or hasRefPersistFlag(object) then
        return
    end

    local scaledRecordId = getScaledRecordId(record)
    if not scaledRecordId then
        return
    end

    local cell = object.cell
    if not cell then
        return
    end

    local replacement = world.createObject(scaledRecordId, 1)
    replacement:setScale(object.scale)
    copyLockState(object, replacement)
    moveInventory(object, replacement)
    replacement:teleport(cell, object.position, { rotation = object.rotation, onGround = false })
    object:remove()
end

local function onObjectActive(object)
    replaceContainer(object)
end

local function onSave()
    return {
        version = 1,
        scaledRecordByOriginal = scaledRecordByOriginal,
        generatedScaledRecords = generatedScaledRecords,
        warnedCreateRecord = warnedCreateRecord,
        warnedMissingRefPersistApi = warnedMissingRefPersistApi,
    }
end

local function onLoad(data)
    if not data or data.version ~= 1 then
        return
    end

    scaledRecordByOriginal = data.scaledRecordByOriginal or {}
    generatedScaledRecords = data.generatedScaledRecords or {}
    warnedCreateRecord = data.warnedCreateRecord or false
    warnedMissingRefPersistApi = data.warnedMissingRefPersistApi or false
end

return {
    engineHandlers = {
        onObjectActive = onObjectActive,
        onSave = onSave,
        onLoad = onLoad,
    },
}
