local I = require('openmw.interfaces')
local classTooltip = require('scripts.DynamicClassImages.classTooltip')

-- Register independently of SWE so the level-up picture can be toggled too.
I.Settings.registerPage {
    key = 'DynamicClassImages',
    l10n = 'DynamicClassImages',
    name = 'name',
    description = 'description',
}
I.Settings.registerGroup {
    key = 'SettingsDynamicClassImages',
    page = 'DynamicClassImages',
    l10n = 'DynamicClassImages',
    name = 'artwork',
    permanentStorage = true,
    settings = {
        { key = 'enabled', renderer = 'checkbox', name = 'enabled',
            description = 'enabledDescription', default = true },
    },
}

local statsWindow = I.StatsWindow
local classLineId = statsWindow and statsWindow.Constants.DefaultLines.CLASS
local line = statsWindow and statsWindow.getLine(classLineId)
if line and type(line.tooltip) == 'function' then
    local baseTooltip = line.tooltip
    statsWindow.modifyLine(classLineId, {
        tooltip = function(...)
            return classTooltip.addPicture(baseTooltip(...))
        end,
    })
end

return require('scripts.DynamicClassImages.statReview')
