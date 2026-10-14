local I = require('openmw.interfaces')
local self = require('openmw.self')
local storage = require('openmw.storage')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')
local classTooltip = require('scripts.DynamicClassImages.classTooltip')

local settings = storage.playerSection('SettingsDynamicClassImages')
local element, lastClass, lastEnabled, lastWidth, lastHeight

local function hide()
    if element then element:destroy() end
    element, lastClass = nil, nil
end

local function classKey(class)
    local parts = { class.id, class.name, class.description, class.specialization }
    for _, list in ipairs({ class.majorSkills, class.minorSkills, class.attributes }) do
        for _, value in ipairs(list) do parts[#parts + 1] = value end
    end
    return table.concat(parts, '\n')
end

local function refresh()
    -- ChargenClassReview is also the mode opened by EnableStatReviewMenu.
    if I.UI.getMode() ~= 'ChargenClassReview' then
        hide()
        return
    end
    local layer = ui.layers[ui.layers.indexOf('Notification')]
    local screen = layer.size -- Logical UI coordinates, including GUI scaling.
    local class = types.NPC.classes.record(types.NPC.record(self).class)
    local key, enabled = classKey(class), settings:get('enabled') ~= false
    if element and key == lastClass and enabled == lastEnabled
        and screen.x == lastWidth and screen.y == lastHeight then return end

    -- The native review dialog is centered and 541 UI pixels wide.
    local x = math.floor((screen.x + 541) / 2 + 12)
    local available = screen.x - x - 18
    local width = math.min(400, math.max(192, available))
    x = math.max(8, math.min(x, screen.x - width - 18))
    local layout = classTooltip.build(class, width)
    layout.name = 'DynamicClassImagesStatReview'
    layout.props = {
        position = util.vector2(x, 0),
        relativePosition = util.vector2(0, 0.5),
        anchor = util.vector2(0, 0.5),
    }
    if element then
        element.layout = layout
        element:update()
    else
        element = ui.create(layout)
    end
    lastClass, lastEnabled, lastWidth, lastHeight = key, enabled, screen.x, screen.y
end

return {
    engineHandlers = { onFrame = refresh, onLoad = hide },
    eventHandlers = { UiModeChanged = refresh },
}
