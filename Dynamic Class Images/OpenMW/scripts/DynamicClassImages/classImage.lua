local types = require('openmw.types')
local self = require('openmw.self')
local ui = require('openmw.ui')
local util = require('openmw.util')
local vfs = require('openmw.vfs')
local storage = require('openmw.storage')
local config = require('scripts.DynamicClassImages.pieces')

local settings = storage.playerSection('SettingsDynamicClassImages')
local textures = {}
local pieces, sourceOrder = {}, {}
for index, piece in ipairs(config.imagePieces) do
    pieces[index] = piece
    sourceOrder[piece] = index
end
table.sort(pieces, function(a, b)
    if a.priority == b.priority then return sourceOrder[a] < sourceOrder[b] end
    return a.priority < b.priority
end)

local function toSet(values)
    local set = {}
    for _, value in ipairs(values) do set[value] = true end
    return set
end

local function matches(present, requirement)
    if requirement.negative then return not present end
    return present
end

local function validForClass(piece, classId, class, major, minor, attributes)
    local classRequirement = (piece.classRequirements or {})[1]
    if classRequirement then return classRequirement.type:lower() == classId end

    local hasSkill = false
    for _, requirement in ipairs(piece.skillRequirements) do
        local present
        if requirement.major then
            present = major[requirement.type]
        elseif requirement.minor then
            present = minor[requirement.type]
        else
            present = major[requirement.type] or minor[requirement.type]
        end
        if piece.isOr then
            -- Preserve MWSE's OR behavior: only skill membership matters.
            hasSkill = hasSkill or present
        elseif not matches(present, requirement) then
            return false
        end
    end
    if piece.isOr and not hasSkill then return false end

    for _, requirement in ipairs(piece.attributeRequirements) do
        if not matches(attributes[requirement.type], requirement) then return false end
    end
    for _, requirement in ipairs(piece.specialisationRequirements) do
        if not matches(class.specialization == requirement.type, requirement) then return false end
    end
    return true
end

local function canAdd(piece, slots, piecesAdded, hasShield, hasGold)
    for _, slot in ipairs(piece.slots) do
        if slots[slot] then return false end
    end
    if piece.shieldState == 'requiresShield' and not hasShield then return false end
    if piece.shieldState == 'noShield' and hasShield then return false end
    for _, priority in ipairs(piece.excludedPieces) do
        if piecesAdded[priority] then return false end
    end
    return not (piece.isGold and hasGold)
end

local function image(path)
    if not textures[path] then textures[path] = ui.texture { path = path } end
    return {
        type = ui.TYPE.Image,
        props = { resource = textures[path], relativeSize = util.vector2(1, 1) },
    }
end

local function widget(size, layers)
    return {
        type = ui.TYPE.Widget,
        props = { size = size },
        content = ui.content(layers),
    }
end

-- Required from player scripts; each call reads the player's current class.
return function(size, fallbackPath)
    if settings:get('enabled') == false then
        if fallbackPath then return widget(size, { image(fallbackPath) }) end
        return nil
    end

    local classId = types.NPC.record(self).class:lower()
    local class = types.NPC.classes.record(classId)
    local override = 'textures/levelup/' .. classId .. '.dds'
    if vfs.fileExists(override) then return widget(size, { image(override) }) end

    -- Engine lists can be userdata; copy them with ipairs before selection.
    local major, minor = toSet(class.majorSkills), toSet(class.minorSkills)
    local attributes = toSet(class.attributes)
    local slots, piecesAdded = {}, {}
    local count, hasShield, hasGold = 0, false, false
    for _, filler in ipairs({ false, true }) do
        for _, piece in ipairs(pieces) do
            if count >= config.maxPieces then break end
            if (piece.isFiller == true) == filler
                and validForClass(piece, classId, class, major, minor, attributes)
                and canAdd(piece, slots, piecesAdded, hasShield, hasGold)
            then
                piecesAdded[piece.priority] = piece
                hasShield = hasShield or piece.shieldState == 'isShield'
                hasGold = hasGold or piece.isGold
                for _, slot in ipairs(piece.slots) do
                    slots[slot] = true
                    count = count + 1
                end
            end
        end
    end

    local layers = { image('textures/classImages/0.background.tga') }
    for _, slot in ipairs(config.slotsOrdered) do
        for _, piece in ipairs(pieces) do
            if piecesAdded[piece.priority] == piece then
                for _, occupied in ipairs(piece.slots) do
                    if occupied == slot then
                        layers[#layers + 1] = image('textures/classImages/' .. piece.texture .. '.tga')
                        piecesAdded[piece.priority] = nil
                        break
                    end
                end
            end
        end
    end
    layers[#layers + 1] = image('textures/classImages/0.vignette.tga')
    return widget(size, layers)
end
