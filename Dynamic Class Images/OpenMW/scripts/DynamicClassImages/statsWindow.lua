local I = require('openmw.interfaces')
local classTooltip = require('scripts.DynamicClassImages.classTooltip')

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
