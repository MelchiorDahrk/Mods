local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local I = require('openmw.interfaces')
local l10n = require('openmw.core').l10n('UntoDust')
local lists = require('scripts.UntoDust.cellLists')
local List = require('scripts.UntoDust.virtual_list.extras').VirtualListExt
local states, needsFocusToggle = {}, {}
local paneWidth, paneHeight, rowHeight, gap = 456, 208, 20, 16

local function space(width, height)
    return { type = ui.TYPE.Widget, props = { size = util.vector2(width, height) } }
end

local function button(name, caption, callback)
    return {
        name = name,
        template = I.MWUI.templates.box,
        content = ui.content { {
            template = I.MWUI.templates.padding,
            content = ui.content { {
                template = I.MWUI.templates.textNormal,
                props = { text = caption },
            } },
        } },
        events = { mouseClick = async:callback(callback) },
    }
end

local function indexOf(entries, name)
    for index, entry in ipairs(entries) do
        if entry == name then return index end
    end
end

local function render(value, set, argument)
    argument = argument or {}
    local key = argument.key or 'whitelist'
    local state = states[key] or { available = { query = '' }, selected = { query = '' } }
    states[key] = state
    local names, selected = {}, {}
    for _, name in ipairs(argument.cells or {}) do names[name:lower()] = name end
    for name in pairs(lists.read(value)) do
        -- Keep unavailable cells removable, using installed spelling when possible.
        names[name:lower()] = names[name:lower()] or name
        selected[names[name:lower()]] = true
    end
    local allNames = {}
    for _, name in pairs(names) do allNames[#allNames + 1] = name end
    table.sort(allNames, function(a, b) return a:lower() < b:lower() end)

    local panes = {}
    local function savePositions()
        for id, pane in pairs(panes) do
            local index = pane.list:getFirstVisibleIndex()
            state[id].anchor = {
                name = pane.entries[index], index = index,
                offset = pane.list:getItemViewportOffset(index),
            }
        end
    end

    local function transfer(id, include)
        local pane = panes[id]
        local name = pane.entries[pane.list:getSelectedIndex()]
        if not name then return end
        selected[name] = include or nil
        savePositions()
        local result = {}
        for entry in pairs(selected) do result[entry] = true end
        set(result) -- Native Settings replaces the renderer after a storage change.
    end

    local function createPane(id, include)
        local paneState = state[id]
        local entries = {}
        local function filter()
            entries = {}
            local query = paneState.query:match('^%s*(.-)%s*$'):lower()
            for _, name in ipairs(allNames) do
                if (not not selected[name]) ~= include and name:lower():find(query, 1, true) then
                    entries[#entries + 1] = name
                end
            end
        end
        filter()
        local caption = l10n(include and 'AvailableCells' or 'SelectedCells')
        local heading = ui.create {
            name = 'heading', template = I.MWUI.templates.textHeader,
            props = { text = caption .. ' (' .. #entries .. ')' },
        }
        local list = List.create {
            viewportSize = util.vector2(paneWidth, paneHeight),
            -- Leave room for the scrollbar; cell names stay on a single row.
            itemSize = util.vector2(paneWidth - 24, rowHeight),
            itemCount = math.max(1, #entries),
            itemLayout = function(index, controller)
                if #entries == 0 then
                    return controller:createPlaceholder {
                        text = l10n(include and 'NoCells' or
                            (paneState.query:find('%S') and 'NoSelectedMatches' or 'NoSelectedCells')),
                    }
                end
                local name = entries[index]
                local row = controller:createItemLayout {
                    index = index, props = { text = name },
                    onMousePress = function(event)
                        if event.button == 1 then paneState.selection = name end
                    end,
                }
                row.name = name
                return row
            end,
        }
        list:getElement().layout.name = 'list'
        panes[id] = { list = list, entries = entries }

        local function select(index)
            if entries[index] then
                paneState.selection = entries[index]
                list:changeSelection(index)
            end
        end
        local selectedIndex = indexOf(entries, paneState.selection) or (#entries > 0 and 1 or nil)
        if selectedIndex then select(selectedIndex) end
        list:setKeyPressHandler {
            -- The upstream keyboard handler expects an index even for an empty list.
            getSelectedIndex = function() return list:getSelectedIndex() or 1 end,
            setSelectedIndex = select,
        }
        if paneState.anchor and #entries > 0 then
            local anchor = paneState.anchor
            local index = indexOf(entries, anchor.name) or math.min(anchor.index, #entries)
            list:scrollToIndex(index, anchor.offset)
        end

        local search = list:createSearchBox {
            text = l10n(include and 'SearchInteriors' or 'SearchSelected'),
            initialText = paneState.query,
            onTextChanged = function(query)
                paneState.query = query
                local oldIndex = list:getSelectedIndex()
                filter()
                panes[id].entries = entries
                local newIndex = indexOf(entries, paneState.selection) or (#entries > 0 and 1 or nil)
                paneState.selection = entries[newIndex]
                paneState.anchor = nil
                list:resetSelection()
                list:setSelectedIndex(newIndex)
                list:rebuildAndScroll(math.max(1, #entries), oldIndex, newIndex)
                heading.layout.props.text = caption .. ' (' .. #entries .. ')'
                heading:update()
            end,
            onTextCleared = function(element)
                needsFocusToggle[#needsFocusToggle + 1] = element
            end,
        }
        search.layout.name = 'input'
        search.layout.props.size = util.vector2(paneWidth - 4, 24)
        return {
            name = id, type = ui.TYPE.Flex,
            content = ui.content {
                heading, space(0, 6),
                {
                    type = ui.TYPE.Container, template = I.MWUI.templates.borders,
                    content = ui.content { search },
                },
                space(0, 6),
                {
                    type = ui.TYPE.Container, template = I.MWUI.templates.borders,
                    content = ui.content { list:getElement() },
                },
                space(0, 6),
                button('transfer', l10n(include and 'AddCell' or 'RemoveCell'), function() transfer(id, include) end),
            },
        }
    end

    local content = {
        {
            name = 'title', template = I.MWUI.templates.textHeader,
            props = { text = l10n(key == 'blacklist' and 'BlacklistName' or 'WhitelistName') },
        },
        space(0, 8),
    }
    if not argument.ready then
        content[#content + 1] = {
            name = 'help', template = I.MWUI.templates.textParagraph,
            props = { text = l10n('LoadGameForCells'), size = util.vector2(paneWidth * 2 + gap, 0) },
        }
        content[#content + 1] = space(0, 8)
    end
    content[#content + 1] = {
        name = 'panes', type = ui.TYPE.Flex, props = { horizontal = true },
        content = ui.content { createPane('available', true), space(gap, 0), createPane('selected', false) },
    }
    content[#content + 1] = space(0, 8)
    content[#content + 1] = button('clear', l10n('ClearList'), function()
        if next(selected) then
            savePositions()
            set({})
        end
    end)
    return ui.create { name = 'cellPicker', type = ui.TYPE.Flex, content = ui.content(content) }
end

-- Match the search focus workaround used by assetReviewTools. Destroyed
-- elements are dropped when native Settings rebuilds the renderer.
local function onFrame()
    for index = #needsFocusToggle, 1, -1 do
        local element = needsFocusToggle[index]
        local layout = element.layout
        if not layout then
            table.remove(needsFocusToggle, index)
        else
            layout.props.visible = layout.props.visible == false
            local ok = pcall(function() element:update() end)
            if not ok or layout.props.visible then table.remove(needsFocusToggle, index) end
        end
    end
end

return { render = render, onFrame = onFrame, onMouseWheel = List.getMouseWheelHandler() }
