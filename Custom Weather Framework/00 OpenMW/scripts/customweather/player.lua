local core = require('openmw.core')
local input = require('openmw.input')
local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local storage = require('openmw.storage')
local self = require('openmw.self')
local I = require('openmw.interfaces')
local data = require('scripts.customweather.common')
local regionFiles = require('scripts.customweather.regionfiles')
local color = require('scripts.customweather.color')

local preferences = storage.playerSection(data.storage .. 'Editor')
local config, personalConfig, regions, currentRegion, draft
local packaged = {}
local selected, tab, weatherIndex, timeIndex, listPage = 'default', 'Colours', 1, 2, 1
local pageSize = 6
local window, waiting, dirty, captureKey
local undo, redo = {}, {}
local nameInput, shareText = '', ''
local exportRegion, shareFormat, sharePath = '', 'JSON', ''
local refresh, close
local whiteTexture = ui.texture { path = 'white' }
local picker, pickerDrag
local pickerTextures = {}
for _, name in ipairs { 'sv', 'hue', 'cursor' } do
    pickerTextures[name] = ui.texture { path = 'textures/customweather/' .. name .. '.dds' }
end

local function send(action, values)
    values = values or {}
    values.action = action
    core.sendGlobalEvent(data.event, values)
end

local layout = { width = 760, gap = 12, rowGap = 8, label = 136, swatch = 76, rgb = 128, action = 104 }

local function spacer(width, height)
    return { type = ui.TYPE.Widget, props = { size = util.vector2(width, height) } }
end

local function text(value, width, height)
    return {
        template = I.MWUI.templates.textNormal,
        -- Text defaults to autoSize, which ignores size and collapses table columns.
        props = { text = value, autoSize = width == nil,
            size = util.vector2(width or 0, height or 28), textAlignV = ui.ALIGNMENT.Center },
    }
end

local function spaced(items, horizontal, gap)
    local content = {}
    for i, item in ipairs(items) do
        if i > 1 and gap > 0 then
            content[#content + 1] = spacer(horizontal and gap or 0, horizontal and 0 or gap)
        end
        content[#content + 1] = item
    end
    return {
        type = ui.TYPE.Flex,
        props = { horizontal = horizontal, arrange = horizontal and ui.ALIGNMENT.Center or ui.ALIGNMENT.Start },
        content = ui.content(content),
    }
end

local function row(items, gap)
    return spaced(items, true, gap or layout.gap)
end

local function column(items, gap)
    return spaced(items, false, gap or layout.rowGap)
end

local function padded(content, amount)
    return row({ spacer(amount, 0), column({ spacer(0, amount), content, spacer(0, amount) }, 0),
        spacer(amount, 0) }, 0)
end

local function divider()
    return { template = I.MWUI.templates.horizontalLine,
        props = { size = util.vector2(layout.width, 2), relativeSize = util.vector2(0, 0) } }
end

local function note(value)
    local result = text(value, layout.width, 44)
    result.props.multiline, result.props.wordWrap = true, true
    return result
end

local function heading(value)
    local result = text(value, layout.width)
    result.template = I.MWUI.templates.textHeader
    return result
end

local function button(label, callback, width)
    return {
        template = I.MWUI.templates.box,
        content = ui.content {
            row({ spacer(8, 28), text(label, width and width - 20), spacer(8, 28) }, 0),
        },
        events = { mouseClick = async:callback(function() callback(); return false end) },
    }
end

local function edit(value, width, changed, multiline)
    return {
        template = I.MWUI.templates.box,
        content = ui.content {
            row({ spacer(8, 0), {
                template = multiline and I.MWUI.templates.textEditBox or I.MWUI.templates.textEditLine,
                props = { text = value, autoSize = false,
                    size = util.vector2(width - 20, multiline and 180 or 28),
                    textAlignV = multiline and ui.ALIGNMENT.Start or ui.ALIGNMENT.Center },
                events = { textChanged = async:callback(changed) },
            }, spacer(8, 0) }, 0),
        },
    }
end

local function preview()
    send('preview', { preset = draft })
end

local function selectPreset(name)
    selected = config.presets[name] and name or 'default'
    draft = data.copy(config.presets[selected])
    dirty, undo, redo = false, {}, {}
    nameInput = selected == 'default' and '' or selected
    preview()
    refresh()
end

local function changeDraft(change)
    undo[#undo + 1] = data.copy(draft)
    if #undo > 50 then table.remove(undo, 1) end
    redo = {}
    change()
    dirty = true
    preview()
    refresh()
end

local function selectWeather(index)
    weatherIndex = index
    send('weather', { index = weatherIndex })
    refresh()
end

local function finishPicker(cancel)
    if cancel then
        draft, dirty, undo, redo = picker.original, picker.dirty, picker.undo, picker.redo
        preview()
    end
    picker, pickerDrag = nil, nil
    refresh()
end

local function openPicker(label, field)
    picker = { label = label, field = field, weather = data.names[weatherIndex],
        original = data.copy(draft), dirty = dirty, undo = data.copy(undo), redo = data.copy(redo),
        hsv = color.toHSV(draft[data.names[weatherIndex]][field]) }
    refresh()
end

local function pickerLayout()
    local p, width, height = picker, 352, 224
    local rgb = draft[p.weather][p.field]
    local function image(resource, w, h, tint)
        return { type = ui.TYPE.Image, props = { resource = resource,
            size = util.vector2(w, h), color = util.color.rgb(unpack(tint or { 1, 1, 1 })) } }
    end
    local plane = image(whiteTexture, width, height, color.toRGB { p.hsv[1], 1, 1 })
    plane.name = 'pickerSV'
    local marker = image(pickerTextures.cursor, 16, 16)
    local overlay = image(pickerTextures.sv, width, height)
    plane.content = ui.content { overlay, marker }
    local hue = image(pickerTextures.hue, 28, height)
    hue.name = 'pickerHue'
    local hueMarker = image(whiteTexture, 28, 4, { 0, 0, 0 })
    local inner = image(whiteTexture, 26, 2)
    inner.props.position = util.vector2(1, 1)
    hueMarker.content = ui.content { inner }
    hue.content = ui.content { hueMarker }
    local swatch = image(whiteTexture, 52, 28, rgb)
    -- MyGUI uses #RRGGBB as a colour tag; double # renders a literal hash.
    local readout = text(color.label(rgb) .. '   #' .. color.hex(rgb), 410)
    local inputValue = color.hex(rgb)
    local entry = edit('#' .. inputValue, 320, function(value) inputValue = value:gsub('##', '#') end)
    local inputNode = entry.content[1].content[2]
    local function update()
        local value = color.toRGB(p.hsv)
        draft[p.weather][p.field] = value
        dirty = true
        plane.props.color = util.color.rgb(unpack(color.toRGB { p.hsv[1], 1, 1 }))
        marker.props.position = util.vector2(p.hsv[2] * (width - 1) - 8, (1 - p.hsv[3]) * (height - 1) - 8)
        hueMarker.props.position = util.vector2(0, p.hsv[1] * (height - 1) - 2)
        swatch.props.color = util.color.rgb(unpack(value))
        readout.props.text = color.label(value) .. '   #' .. color.hex(value)
        inputValue = color.hex(value)
        inputNode.props.text = '#' .. inputValue
        preview()
        window:update()
    end
    local function checkpoint()
        undo[#undo + 1] = data.copy(draft)
        if #undo > 50 then table.remove(undo, 1) end
        redo = {}
    end
    local function drag(event)
        local d = pickerDrag
        if not d then return false end
        local x, y = event.position.x - d.x, event.position.y - d.y
        if d.hue then p.hsv[1] = color.clamp(y / (height - 1))
        else p.hsv[2], p.hsv[3] = color.clamp(x / (width - 1)), 1 - color.clamp(y / (height - 1)) end
        update()
        return false
    end
    local function startDrag(e, isHue)
        if e.button ~= 1 then return false end
        checkpoint()
        pickerDrag = { hue = isHue, x = e.position.x - e.offset.x, y = e.position.y - e.offset.y }
        return drag(e)
    end
    local function handlers(isHue)
        return {
            mousePress = async:callback(function(e) return startDrag(e, isHue) end),
            mouseMove = async:callback(function(e) if e.button == 1 then return drag(e) end; return false end),
            mouseRelease = async:callback(function(e)
                if e.button == 1 and pickerDrag then drag(e); pickerDrag = nil end
                return false
            end),
        }
    end
    plane.events, overlay.events = handlers(false), handlers(false)
    hue.events = handlers(true)
    -- Marker events use their parent's coordinates, including presses on the marker itself.
    local function markerHandlers(node, isHue, offset)
        local events = handlers(isHue)
        node.events = {
            mousePress = async:callback(function(e)
                local position = offset and offset() or node.props.position
                return startDrag({ button = e.button, position = e.position,
                    offset = util.vector2(e.offset.x + position.x, e.offset.y + position.y) }, isHue)
            end), mouseMove = events.mouseMove, mouseRelease = events.mouseRelease,
        }
    end
    marker.props.position = util.vector2(p.hsv[2] * (width - 1) - 8, (1 - p.hsv[3]) * (height - 1) - 8)
    hueMarker.props.position = util.vector2(0, p.hsv[1] * (height - 1) - 2)
    markerHandlers(marker, false)
    markerHandlers(hueMarker, true)
    markerHandlers(inner, true, function()
        return util.vector2(1 + hueMarker.props.position.x, 1 + hueMarker.props.position.y)
    end)
    local result = column {
        text(p.label .. ' — ' .. p.weather .. ', ' .. data.times[timeIndex], 480),
        row { swatch, readout },
        row { plane, hue },
        text('Saturation / brightness                          Hue', 480),
        row { entry, button('Apply', function()
            local value = color.parse(inputValue)
            if not value then ui.showMessage('Enter #RRGGBB or RGB values such as 38, 166, 191.'); return end
            checkpoint()
            p.hsv = color.toHSV(value, p.hsv[1]); update()
        end, 104) },
        row { button('Done', function() finishPicker(false) end),
            button('Cancel', function() finishPicker(true) end) },
    }
    -- Catch drags beyond the controls using the absolute origin saved on press.
    result.events = {
        mouseMove = async:callback(function(e) if e.button == 1 then return drag(e) end; return false end),
        mouseRelease = async:callback(function(e)
            if e.button == 1 and pickerDrag then drag(e); pickerDrag = nil end
            return false
        end),
    }
    return result
end

local function colorRow(label, field)
    local rgb = draft[data.names[weatherIndex]][field]
    local values = {}
    local items = { text(label, layout.label) }
    items[#items + 1] = {
        template = I.MWUI.templates.box,
        name = 'colorSwatch:' .. field,
        events = { mouseClick = async:callback(function() openPicker(label, field); return false end) },
        content = ui.content {
            { type = ui.TYPE.Image, props = { resource = whiteTexture,
                color = util.color.rgb(rgb[1], rgb[2], rgb[3]), size = util.vector2(layout.swatch - 4, 24) } },
        },
    }
    for i = 1, 3 do
        local component = i
        values[i] = string.format('%.2f', rgb[i] * 255)
        items[#items + 1] = edit(values[i], layout.rgb, function(value) values[component] = value end)
    end
    items[#items + 1] = button('Apply', function()
        local converted = {}
        for i = 1, 3 do
            local value = tonumber(values[i])
            if not data.finite(value) or value < 0 or value > 255 then
                ui.showMessage('Enter red, green and blue values between 0 and 255.')
                return
            end
            converted[i] = value / 255
        end
        changeDraft(function() draft[data.names[weatherIndex]][field] = converted end)
    end, layout.action)
    return row(items)
end

local function colours()
    local items = {
        row {
            text('Weather', layout.label),
            button('< Weather', function() selectWeather((weatherIndex - 2) % #data.names + 1) end, 104),
            text(data.names[weatherIndex], 192),
            button('Weather >', function() selectWeather(weatherIndex % #data.names + 1) end, 104),
            button('Preview weather', function()
                send('weather', { index = weatherIndex })
            end, 176),
        },
    }
    local times = { text('Time of day', layout.label) }
    for index, time in ipairs(data.times) do
        local n = index
        times[#times + 1] = button((n == timeIndex and '* ' or '') .. time, function()
            timeIndex = n
            send('time', { index = timeIndex })
            refresh()
        end, 144)
    end
    items[#items + 1] = row(times)
    items[#items + 1] = divider()
    items[#items + 1] = row { text('Colour', layout.label), text('Preview', layout.swatch),
        text('Red', layout.rgb), text('Green', layout.rgb), text('Blue', layout.rgb), text('', layout.action) }
    for _, group in ipairs(data.groups) do
        items[#items + 1] = colorRow(group, group .. data.times[timeIndex] .. 'Color')
    end
    if timeIndex == 3 then items[#items + 1] = colorRow('Sun disc', 'sundiscSunsetColor') end
    items[#items + 1] = divider()
    local cloud = draft[data.names[weatherIndex]].cloudTexture
    items[#items + 1] = row {
        text('Cloud texture', layout.label),
        edit(cloud, layout.width - layout.label - layout.action - 2 * layout.gap, function(value) cloud = value end),
        button('Apply', function()
            if cloud == '' then ui.showMessage('Enter a texture path.'); return end
            changeDraft(function() draft[data.names[weatherIndex]].cloudTexture = cloud end)
        end, layout.action),
    }
    items[#items + 1] = divider()
    items[#items + 1] = row {
        button('Undo', function()
            if #undo == 0 then return end
            redo[#redo + 1], draft = data.copy(draft), table.remove(undo)
            dirty = true; preview(); refresh()
        end),
        button('Redo', function()
            if #redo == 0 then return end
            undo[#undo + 1], draft = data.copy(draft), table.remove(redo)
            dirty = true; preview(); refresh()
        end),
        button('Revert', function() selectPreset(selected) end),
        button('Save preset', function()
            if selected == 'default' or packaged[selected] then
                ui.showMessage('Use Presets > Create copy to save your own preset.')
            else
                send('save', { name = selected, preset = draft })
            end
        end),
    }
    items[#items + 1] = note('Weather and time selections change the game. Closing restores the region’s assigned preset.')
    return items
end

local function pageRows(items, keys, render)
    local pages = math.max(1, math.ceil(#keys / pageSize))
    listPage = math.min(listPage, pages)
    for i = (listPage - 1) * pageSize + 1, math.min(#keys, listPage * pageSize) do
        items[#items + 1] = render(keys[i])
    end
    items[#items + 1] = row {
        button('<', function() listPage = (listPage - 2) % pages + 1; refresh() end),
        text(string.format('Page %d / %d', listPage, pages), 150),
        button('>', function() listPage = listPage % pages + 1; refresh() end),
    }
end

local function presets()
    local items = { heading('Saved presets'),
        note('Select a preset to preview it. Use Create copy to edit default or installed [Mod] colours.') }
    pageRows(items, data.sortedKeys(config.presets), function(name)
        return button((selected == name and '* ' or '') .. name, function() selectPreset(name) end, layout.width)
    end)
    items[#items + 1] = divider()
    items[#items + 1] = heading('Manage selected preset')
    items[#items + 1] = row { text('Name', layout.label),
        edit(nameInput, layout.width - layout.label - layout.gap, function(value) nameInput = value end) }
    items[#items + 1] = row {
        button('Create copy', function()
            if not data.validName(nameInput) or nameInput == 'default' or config.presets[nameInput] then
                ui.showMessage('Enter a unique preset name.'); return
            end
            selected = nameInput
            send('save', { name = selected, preset = draft })
        end),
        button('Rename', function()
            local newName = nameInput
            if selected == 'default' or packaged[selected] or not data.validName(newName) or config.presets[newName] then
                ui.showMessage('Enter a unique name for a custom preset.'); return
            end
            send('rename', { name = selected, newName = newName })
            selected = newName
        end),
        button('Delete', function()
            if selected == 'default' or packaged[selected] then return end
            send('delete', { name = selected })
            selected = 'default'
        end),
    }
    return items
end

local function exportLua(region, preset)
    if not regions[region:lower()] then ui.showMessage('Choose a valid region ID.'); return end
    exportRegion, shareFormat = region:lower(), 'Lua'
    shareText = regionFiles.export(exportRegion, preset)
    sharePath = regionFiles.directory .. regionFiles.filename(exportRegion)
    tab = 'Import / Export'
    refresh()
end

local function regionList()
    local sorted = data.sortedKeys(regions)
    table.sort(sorted, function(a, b)
        local nameA = (regions[a] ~= '' and regions[a] or a):lower()
        local nameB = (regions[b] ~= '' and regions[b] or b):lower()
        if nameA == nameB then return a < b end
        return nameA < nameB
    end)
    local currentName = currentRegion and regions[currentRegion]
    local items = { heading('Current region: ' ..
        (currentName and currentName ~= '' and currentName or currentRegion or 'Interior')) }
    if currentRegion then
        local current = { text('Region ID: ' .. currentRegion, layout.width - 160 - layout.gap) }
        if currentName then
            current[#current + 1] = button('Show current', function()
                for i, id in ipairs(sorted) do
                    if id == currentRegion then
                        listPage = math.ceil(i / pageSize)
                        refresh()
                        return
                    end
                end
            end, 160)
        end
        items[#items + 1] = row(current)
    end
    items[#items + 1] = note('Assign uses ' .. selected .. '. Reset restores installed mod colours, or defaults. Export uses the assignment.')
    items[#items + 1] = divider()
    items[#items + 1] = row { text('Region', 220), text('Assigned preset', 198), text('Actions', 318) }
    pageRows(items, sorted, function(id)
        local label = regions[id] ~= '' and regions[id] or id
        if #label > 26 then label = label:sub(1, 23) .. '...' end
        return row {
            text(label, 220),
            button(config.regions[id] or 'default', function() selectPreset(config.regions[id] or 'default') end, 198),
            button('Assign', function() send('assign', { region = id, name = selected }) end, 86),
            button('Reset', function() send('resetRegion', { region = id }) end, 86),
            button('Export Lua', function()
                exportLua(id, config.presets[config.regions[id] or 'default'])
            end, 122),
        }
    end)
    return items
end

local function sharing()
    return {
        heading('Share region colours as a mod'),
        row { text('Region ID', layout.label),
            edit(exportRegion, 400, function(value) exportRegion = value end),
            button('Export region Lua', function() exportLua(exportRegion, draft) end, 200) },
        note('Export region Lua uses the current preview, including unsaved edits. Regions > Export Lua uses its assignment.'),
        note(shareFormat == 'Lua' and ('Save as ' .. sharePath)
            or 'Export JSON backs up personal settings. Import replaces them; installed mod files stay installed.'),
        edit(shareText, layout.width, function(value) shareText = value; shareFormat = 'Text' end, true),
        row {
            button('Export JSON', function()
                local value = data.copy(personalConfig)
                value.presets.default = nil
                shareFormat = 'JSON'
                shareText = data.json(value)
                refresh()
            end),
            button('Import text', function()
                if shareFormat == 'Lua' then
                    ui.showMessage('Save region Lua in the displayed mod folder, then restart OpenMW. Import text accepts JSON.')
                    return
                end
                send('import', { text = shareText })
            end),
            button('Import MWSE file', function() send('import', { path = data.importPath }) end),
        },
        divider(),
        note('Click the text, then Ctrl+A / Ctrl+C. Save UTF-8 text as .lua for a region mod, or .json for a backup.'),
        note('Package the scripts folder with your mod. Colours load automatically when Weather Adjuster is enabled.'),
    }
end

local function keyLabel()
    local binding = preferences:get('keybind')
    if not binding then return 'Shift+F4' end
    return (binding.shift and 'Shift+' or '') .. (binding.ctrl and 'Ctrl+' or '')
        .. (binding.alt and 'Alt+' or '') .. input.getKeyName(binding.code)
end

local function options()
    local duration = tostring(config.transitionDuration)
    return {
        heading('Weather behaviour'),
        button('Region messages: ' .. (config.messageOnRegionChange and 'On' or 'Off'), function()
            send('option', { key = 'messageOnRegionChange', value = not config.messageOnRegionChange })
        end),
        button('Disable sky texture changes: ' .. (config.disableSkyTextureChanges and 'On' or 'Off'), function()
            send('option', { key = 'disableSkyTextureChanges', value = not config.disableSkyTextureChanges })
        end),
        row {
            text('Transition seconds (0–300)', 320),
            edit(duration, layout.rgb, function(value) duration = value end),
            button('Apply', function()
                local value = tonumber(duration)
                if not data.finite(value) or value < 0 or value > 300 then
                    ui.showMessage('Enter a duration between 0 and 300 seconds.'); return
                end
                send('option', { key = 'transitionDuration', value = value })
            end),
        },
        divider(),
        heading('Editor shortcut'),
        button(captureKey and 'Press a key combination; Escape cancels' or 'Editor key: ' .. keyLabel(), function()
            captureKey = true; refresh()
        end),
        button('Reset key to Shift+F4', function() preferences:set('keybind', nil); refresh() end),
        divider(),
        heading('Weather Adjuster 3.0 — OpenMW edition'),
        text('Original mod: Hrnchamd. Requires OpenMW 0.51 or newer.', layout.width),
        note('Presets and assignments are shared across saves and stored by OpenMW.'),
        note('The MGE XE scattering and cloud vertex patch are specific to the MWSE edition.'),
    }
end

refresh = function()
    if not window then return end
    if picker then
        window.layout = { layer = 'Windows', template = I.MWUI.templates.boxTransparent,
            props = { relativePosition = util.vector2(0.5, 0.5), anchor = util.vector2(0.5, 0.5) },
            content = ui.content { padded(pickerLayout(), 16) } }
        window:update()
        return
    end
    local tabs = {}
    for _, label in ipairs { 'Colours', 'Presets', 'Regions', 'Import / Export', 'Options' } do
        local name = label
        tabs[#tabs + 1] = button((tab == name and '* ' or '') .. name, function()
            tab, listPage = name, 1; refresh()
        end, name == 'Import / Export' and 200 or 128)
    end
    local builders = { Colours = colours, Presets = presets, Regions = regionList,
        ['Import / Export'] = sharing, Options = options }
    window.layout = {
        layer = 'Windows',
        template = I.MWUI.templates.boxTransparent,
        props = { relativePosition = util.vector2(0.5, 0.5), anchor = util.vector2(0.5, 0.5) },
        content = ui.content {
            padded(column({
                row { text('Weather Adjuster — ' .. selected .. (dirty and ' (unsaved)' or ''),
                        layout.width - layout.action - layout.gap),
                    button('Close', close, layout.action) },
                row(tabs),
                divider(),
                column(builders[tab]()),
            }, 12), 16),
        },
    }
    window:update()
end

close = function()
    picker, pickerDrag = nil, nil
    waiting, captureKey = false, false
    if window then window:destroy(); window = nil end
    I.UI.removeMode(I.UI.MODE.Interface)
    send('close')
end

local function receive(state)
    if state.message then ui.showMessage(state.message) end
    if not state.config then return end
    config, regions, currentRegion = state.config, state.regions, state.region
    personalConfig, packaged = state.personalConfig or state.config, state.packaged or {}
    if exportRegion == '' then exportRegion = currentRegion or data.sortedKeys(regions)[1] or '' end
    if not window and not waiting then return end
    if not config.presets[selected] then selected = state.activePreset or 'default' end
    if state.resetDraft or not draft then
        picker, pickerDrag = nil, nil
        draft = data.copy(config.presets[selected])
        dirty, undo, redo = false, {}, {}
    end
    if waiting then
        waiting = false
        selected = state.activePreset or 'default'
        draft = data.copy(config.presets[selected])
        nameInput = selected == 'default' and '' or selected
        I.UI.addMode(I.UI.MODE.Interface, { windows = {} })
        window = ui.create { layer = 'Windows', type = ui.TYPE.Widget }
    end
    preview()
    refresh()
end

local function keyPress(key)
    if captureKey then
        for _, modifier in ipairs { 'LeftShift', 'RightShift', 'LeftCtrl', 'RightCtrl',
            'LeftAlt', 'RightAlt', 'LeftSuper', 'RightSuper' } do
            if key.code == input.KEY[modifier] then return end
        end
        if key.withSuper then return end
        if key.code ~= input.KEY.Escape then
            preferences:set('keybind', { code = key.code, shift = key.withShift,
                ctrl = key.withCtrl, alt = key.withAlt })
        end
        captureKey = false; refresh(); return
    end
    if window and key.code == input.KEY.Escape then
        if picker then finishPicker(true) else close() end
        return
    end
    local binding = preferences:get('keybind') or { code = input.KEY.F4, shift = true, ctrl = false, alt = false }
    if key.code ~= binding.code or key.withShift ~= binding.shift
        or key.withCtrl ~= binding.ctrl or key.withAlt ~= binding.alt or key.withSuper then return end
    if window then close()
    elseif not waiting and not I.UI.getMode() then waiting = true; send('request') end
end

return {
    engineHandlers = {
        onKeyPress = keyPress,
        onTeleported = function()
            waiting = false
            send('teleported')
            if window then close() end
        end,
        onFrame = function()
            if window and I.UI.getMode() ~= I.UI.MODE.Interface then close() end
        end,
    },
    eventHandlers = { [data.reply] = receive },
}
