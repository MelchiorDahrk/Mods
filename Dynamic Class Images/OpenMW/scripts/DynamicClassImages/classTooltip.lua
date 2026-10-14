local core = require('openmw.core')
local I = require('openmw.interfaces')
local ui = require('openmw.ui')
local util = require('openmw.util')
local classImage = require('scripts.DynamicClassImages.classImage')

local M = {}

-- Keep artwork insertion identical in the hover tooltip and review window.
function M.addPicture(layout, size)
    local padding = layout and layout.content and layout.content[1]
    local tooltip = padding and padding.content and padding.content.tooltip
    if tooltip and tooltip.content then
        local picture = classImage(size or util.vector2(384, 192))
        if picture then
            tooltip.content:insert(1, {
                template = I.MWUI.templates.box,
                content = ui.content { picture },
            })
            local base = I.StatsWindow and I.StatsWindow.Templates.BASE
            tooltip.content:insert(2, base and base.padding(4) or {
                type = ui.TYPE.Widget,
                props = { size = util.vector2(4, 4) },
            })
        end
    end
    return layout
end

function M.build(class, width)
    local specialization = core.getGMST('sSpecialization') .. ': '
        .. core.getGMST('sSpecialization' .. class.specialization:gsub('^%l', string.upper))
    local swe = I.StatsWindow
    local layout
    if swe then
        layout = swe.TooltipBuilders.HEADER(class.name, class.description, specialization)
    else
        local templates = I.MWUI.templates
        layout = {
            layer = 'Notification',
            template = templates.boxSolid,
            content = ui.content { {
                name = 'padding',
                type = ui.TYPE.Container,
                content = ui.content { {
                    name = 'tooltip',
                    type = ui.TYPE.Flex,
                    props = { position = util.vector2(4, 4), align = ui.ALIGNMENT.Center,
                        arrange = ui.ALIGNMENT.Center },
                    content = ui.content {
                        { name = 'header', template = templates.textHeader,
                            props = { text = class.name, textAlignH = ui.ALIGNMENT.Center } },
                        { type = ui.TYPE.Widget, props = { size = util.vector2(4, 4) } },
                        { name = 'body', template = templates.textParagraph,
                            props = { text = class.description, size = util.vector2(width, 0), autoSize = true } },
                        { type = ui.TYPE.Widget, props = { size = util.vector2(4, 4) } },
                        { name = 'subBody', template = templates.textNormal,
                            props = { text = specialization, textAlignH = ui.ALIGNMENT.Center } },
                    },
                }, {
                    type = ui.TYPE.Widget,
                    props = { position = util.vector2(4, 4), relativePosition = util.vector2(1, 1),
                        size = util.vector2(4, 4) },
                } },
            } },
        }
    end
    local tooltip = layout.content[1].content.tooltip
    tooltip.content.body.props.size = util.vector2(width, 0)
    local pictureWidth = math.min(384, width - 2)
    return M.addPicture(layout, util.vector2(pictureWidth, pictureWidth / 2))
end

return M
