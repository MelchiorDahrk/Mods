local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local I = require('openmw.interfaces')
local l10n = require('openmw.core').l10n('UntoDust')
local lists = require('scripts.UntoDust.cellLists')
local states = {}
local resultLimit = 8
local pickerWidth = 440

local function text(name, caption, width)
    return {
        name = name,
        template = I.MWUI.templates.textParagraph,
        props = { text = caption, size = util.vector2(width, 0) },
    }
end

local function space(height)
    return { type = ui.TYPE.Widget, props = { size = util.vector2(0, height) } }
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

local function sortedNames(names)
    local result = {}
    for _, name in pairs(names) do result[#result + 1] = name end
    table.sort(result, function(a, b) return a:lower() < b:lower() end)
    return result
end

local function render(value, set, argument)
    argument = argument or {}
    local key = argument.key or 'whitelist'
    local state = states[key] or { query = '' }
    states[key] = state
    local names = {}
    for _, name in ipairs(argument.cells or {}) do names[name:lower()] = name end
    local selected = {}
    for name in pairs(lists.read(value)) do
        -- Retain unavailable cells so users can remove old plugin selections.
        names[name:lower()] = names[name:lower()] or name
        selected[names[name:lower()]] = true
    end
    local allNames = sortedNames(names)
    local element, build
    local function refresh()
        element.layout = build()
        element:update()
    end

    local function transfer(name, include)
        selected[name] = include or nil
        local result = {}
        for entry in pairs(selected) do result[entry] = true end
        set(result)
        -- Settings owns the replacement element after a storage change.
    end

    local function section(id, caption, entries, include, limit)
        local rows = {}
        for index = 1, math.min(limit or #entries, #entries) do
            local name = entries[index]
            rows[#rows + 1] = {
                name = name,
                type = ui.TYPE.Flex,
                props = { horizontal = true, arrange = ui.ALIGNMENT.Center },
                content = ui.content {
                    text('cellName', name, pickerWidth - 90),
                    { type = ui.TYPE.Widget, props = { size = util.vector2(12, 0) } },
                    button('transfer', l10n(include and 'AddCell' or 'RemoveCell'), function() transfer(name, include) end),
                },
            }
            rows[#rows + 1] = space(6)
        end
        if #entries == 0 then rows[1] = text('empty', l10n('NoSelectedCells'), pickerWidth) end
        return {
            name = id,
            type = ui.TYPE.Flex,
            content = ui.content {
                {
                    name = 'heading',
                    template = I.MWUI.templates.textHeader,
                    props = { text = caption .. ' (' .. #entries .. ')' },
                },
                space(6),
                {
                    name = 'rows',
                    type = ui.TYPE.Flex,
                    content = ui.content(rows),
                },
            },
        }
    end

    build = function()
        local available, chosen = {}, {}
        local exactMatch
        local query = state.query:match('^%s*(.-)%s*$'):lower()
        for _, name in ipairs(allNames) do
            if selected[name] then
                chosen[#chosen + 1] = name
            elseif query ~= '' and name:lower():find(query, 1, true) then
                if name:lower() == query then exactMatch = name
                else available[#available + 1] = name end
            end
        end
        -- A short cell name must remain reachable even if many longer names
        -- contain it and would otherwise fill the limited result list.
        if exactMatch then table.insert(available, 1, exactMatch) end
        local content = {
            {
                name = 'title',
                template = I.MWUI.templates.textHeader,
                props = { text = l10n(key == 'blacklist' and 'BlacklistName' or 'WhitelistName') },
            },
            space(8),
            text('searchLabel', l10n('SearchInteriors'), pickerWidth),
            space(4),
            {
                name = 'search',
                template = I.MWUI.templates.box,
                content = ui.content { {
                    template = I.MWUI.templates.padding,
                    content = ui.content { {
                        name = 'input',
                        template = I.MWUI.templates.textEditLine,
                        props = { text = state.query, size = util.vector2(pickerWidth - 16, 0) },
                        events = { textChanged = async:callback(function(queryText)
                            state.query = queryText
                            refresh()
                        end) },
                    } },
                } },
            },
            space(8),
        }
        if not argument.ready then
            content[#content + 1] = text('help', l10n('LoadGameForCells'), pickerWidth)
        elseif query == '' then
            content[#content + 1] = text('help', l10n('SearchPrompt'), pickerWidth)
        elseif #available == 0 then
            content[#content + 1] = text('noResults', l10n('NoCells'), pickerWidth)
        else
            content[#content + 1] = section('available', l10n('SearchResults'), available, true, resultLimit)
            if #available > resultLimit then
                content[#content + 1] = text('moreResults', l10n('RefineSearch'), pickerWidth)
            end
        end
        content[#content + 1] = space(16)
        content[#content + 1] = section('selected', l10n('SelectedCells'), chosen, false)
        if #chosen > 0 then
            content[#content + 1] = space(6)
            content[#content + 1] = button('clear', l10n('ClearList'), function() set({}) end)
        end
        return {
            name = 'cellPicker',
            type = ui.TYPE.Flex,
            props = { size = util.vector2(pickerWidth, 0) },
            content = ui.content(content),
        }
    end
    element = ui.create(build())
    return element
end

return { render = render }
