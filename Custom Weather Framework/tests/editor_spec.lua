-- Exercise the editor's public input/event handlers and generated UI callbacks.
package.path = '00 OpenMW/?.lua;' .. package.path
local data = require('scripts.customweather.common')
local count, created, messages, commands = 0, nil, {}, {}
local function test(name, fn)
    local ok, err = pcall(fn)
    assert(ok, name .. ': ' .. tostring(err))
    count = count + 1; print('PASS ' .. name)
end
local function equal(a, b) assert(a == b, tostring(a) .. ' ~= ' .. tostring(b)) end
local defaults = {}
for _, name in ipairs(data.names) do
    defaults[name] = { cloudTexture = 'textures/default.dds' }
    for _, field in ipairs(data.fields) do defaults[name][field] = { 0.2, 0.3, 0.4 } end
end
local config = data.config({}, defaults)
local mode
local keys = { 'F4', 'F5', 'Escape', 'LeftShift', 'RightShift', 'LeftCtrl', 'RightCtrl',
    'LeftAlt', 'RightAlt', 'LeftSuper', 'RightSuper' }
local KEY = {}; for i, name in ipairs(keys) do KEY[name] = i end
local ui = {
    TYPE = { Flex = 'Flex', Widget = 'Widget', Image = 'Image' },
    ALIGNMENT = { Start = 'Start', Center = 'Center' },
    content = function(x) return x end,
    texture = function(options) return options end,
    showMessage = function(s) messages[#messages + 1] = s end,
    create = function(layout)
        created = { layout = layout, update = function() end, destroy = function(self) self.destroyed = true end }
        return created
    end,
}
local templates = {}
for _, name in ipairs { 'textNormal', 'textHeader', 'box', 'padding', 'textEditBox', 'textEditLine',
    'boxTransparent', 'horizontalLine' } do
    templates[name] = {}
end
local prefs = {}
package.loaded['openmw.core'] = { sendGlobalEvent = function(_, e) commands[#commands + 1] = data.copy(e) end }
package.loaded['openmw.input'] = { KEY = KEY, getKeyName = function(code) return keys[code] end }
package.loaded['openmw.ui'] = ui
package.loaded['openmw.util'] = { vector2 = function(x, y) return {x = x, y = y} end,
    color = { rgb = function(r, g, b) return {r = r, g = g, b = b} end } }
package.loaded['openmw.async'] = { callback = function(_, f) return f end }
package.loaded['openmw.self'] = {}
package.loaded['openmw.storage'] = { playerSection = function() return {
    get = function(_, k) return prefs[k] end, set = function(_, k, v) prefs[k] = v end,
} end }
package.loaded['openmw.interfaces'] = {
    MWUI = { templates = templates },
    UI = { MODE = { Interface = 'Interface' },
        addMode = function(m) mode = m end, removeMode = function() mode = nil end,
        getMode = function() return mode end },
}
local editor = require('scripts.customweather.player')
local function reply(reset)
    editor.eventHandlers[data.reply] { config = data.copy(config), regions = { ashlands = 'Ashlands' },
        region = 'ashlands', activePreset = 'default', resetDraft = reset }
end
local function find(node, predicate)
    if predicate(node) then return node end
    for _, child in ipairs(node.content or {}) do
        local result = find(child, predicate)
        if result then return result end
    end
end
local function withText(value)
    return find(created.layout, function(node) return node.props and node.props.text == value end)
end
local function click(value)
    local target = find(created.layout, function(node)
        return node.events and node.events.mouseClick and find(node, function(child)
            return child.props and child.props.text == value
        end)
    end)
    assert(target, 'Missing button ' .. value)
    target.events.mouseClick()
end
local function colorRow()
    return find(created.layout, function(node)
        return node.content and node.content[1] and node.content[1].props
            and node.content[1].props.text == 'sky'
    end)
end
local function inputs(node)
    local result = {}
    local function collect(child)
        if child.events and child.events.textChanged then result[#result + 1] = child end
        for _, nested in ipairs(child.content or {}) do collect(nested) end
    end
    collect(node)
    return result
end
local function applyRow(node)
    find(node, function(child)
        return child.events and child.events.mouseClick and find(child, function(label)
            return label.props and label.props.text == 'Apply'
        end)
    end).events.mouseClick()
end
local function lastCommand() return commands[#commands] end
local function key(code, shift, ctrl, alt)
    editor.engineHandlers.onKeyPress { code = KEY[code], withShift = shift or false,
        withCtrl = ctrl or false, withAlt = alt or false, withSuper = false }
end

test('editor opens on Shift+F4 and constructs every tab', function()
    key('F4', true); equal(lastCommand().action, 'request')
    reply(true); equal(mode, 'Interface')
    assert(withText('Clear'))
    click('Sunset'); assert(withText('Sun disc'))
    for _, tab in ipairs { 'Presets', 'Regions', 'Import / Export', 'Options', 'Colours' } do click(tab) end
end)

test('RGB edits preview immediately and undo/redo preserve values', function()
    local row = colorRow()
    local fields = inputs(row)
    fields[1].events.textChanged('255')
    fields[2].events.textChanged('0')
    fields[3].events.textChanged('0')
    applyRow(row)
    equal(lastCommand().preset.Clear.skySunsetColor[1], 1)
    click('Undo'); equal(lastCommand().preset.Clear.skySunsetColor[1], 0.2)
    click('Redo'); equal(lastCommand().preset.Clear.skySunsetColor[1], 1)
    row = colorRow(); inputs(row)[1].events.textChanged('-1'); applyRow(row)
    equal(messages[#messages], 'Enter red, green and blue values between 0 and 255.')
end)

test('time buttons send game time changes, including the already selected time', function()
    click('* Sunset'); equal(lastCommand().action, 'time'); equal(lastCommand().index, 3)
    for index, label in ipairs(data.times) do
        click(label)
        equal(lastCommand().action, 'time'); equal(lastCommand().index, index)
        assert(withText('* ' .. label))
        click('* ' .. label)
        equal(lastCommand().action, 'time'); equal(lastCommand().index, index)
    end
    click('Sunset')
end)

test('weather arrows change game weather and wrap in both directions', function()
    click('< Weather'); equal(lastCommand().action, 'weather'); equal(lastCommand().index, 10)
    assert(withText('Blizzard'))
    click('Weather >'); equal(lastCommand().index, 1); assert(withText('Clear'))
    for index = 2, #data.names do
        click('Weather >'); equal(lastCommand().action, 'weather'); equal(lastCommand().index, index)
        assert(withText(data.names[index]))
    end
    click('Weather >'); equal(lastCommand().index, 1)
    click('Preview weather'); equal(lastCommand().action, 'weather'); equal(lastCommand().index, 1)
    click('Undo'); equal(lastCommand().preset.Clear.skySunsetColor[1], 0.2)
    click('Redo'); equal(lastCommand().preset.Clear.skySunsetColor[1], 1)
end)

test('option changes retain unsaved colour edits', function()
    click('Options'); click('Region messages: Off')
    equal(lastCommand().key, 'messageOnRegionChange')
    config.messageOnRegionChange = true; reply(false)
    equal(lastCommand().preset.Clear.skySunsetColor[1], 1)
end)

test('rebinding skips modifier keys and accepts a combination', function()
    click('Editor key: Shift+F4')
    key('LeftCtrl', false, true); equal(prefs.keybind, nil)
    key('F5', false, true); equal(prefs.keybind.code, KEY.F5)
    equal(prefs.keybind.ctrl, true)
    key('F5', false, true); assert(created.destroyed); equal(mode, nil)
    key('F5', false, true); equal(lastCommand().action, 'request'); reply(true)
end)

test('preset creation and JSON export carry edited colours', function()
    click('Colours'); click('Presets')
    local nameRow = find(created.layout, function(node)
        return node.content and node.content[1] and node.content[1].props
            and node.content[1].props.text == 'Name'
    end)
    inputs(nameRow)[1].events.textChanged('Editor preset'); click('Create copy')
    equal(lastCommand().name, 'Editor preset')
    config.presets['Editor preset'] = data.copy(lastCommand().preset); reply(true)
    click('Import / Export'); click('Export JSON')
    local edit = find(created.layout, function(node) return node.template == templates.textEditBox end)
    assert(edit.props.text:find('Editor preset', 1, true))
    click('Import text'); equal(lastCommand().text, edit.props.text)
end)

test('region Lua export includes unsaved preview colours and a portable region ID', function()
    click('Colours')
    local row = colorRow()
    inputs(row)[2].events.textChanged('127.5'); applyRow(row)
    click('Import / Export'); click('Export region Lua')
    local edit = find(created.layout, function(node) return node.template == templates.textEditBox end)
    local chunk = assert(loadstring(edit.props.text))
    local value = chunk()
    equal(value.version, 1); equal(value.region, 'ashlands')
    equal(value.preset.Clear.skySunsetColor[2], 0.5)
    assert(withText('Save as scripts/weatheradjust/regions/ashlands.lua'))
    local before = #commands
    click('Import text'); equal(#commands, before)
    edit.events.textChanged('{"presets":{}}')
    click('Import text'); equal(lastCommand().action, 'import')
    equal(lastCommand().text, '{"presets":{}}')
end)

test('region row exports its assignment and JSON stays a personal backup', function()
    config.presets['[Mod] test'] = data.copy(defaults)
    config.presets['[Mod] test'].Clear.skyDayColor = { 0.8, 0.7, 0.6 }
    config.regions.ashlands = '[Mod] test'
    local personal = data.copy(config)
    personal.presets['[Mod] test'], personal.regions.ashlands = nil, nil
    editor.eventHandlers[data.reply] { config = data.copy(config), personalConfig = personal,
        packaged = { ['[Mod] test'] = 'scripts/weatheradjust/regions/test.lua' },
        regions = { ashlands = 'Ashlands' }, region = 'ashlands', activePreset = 'default' }
    click('Regions'); click('Export Lua')
    local edit = find(created.layout, function(node) return node.template == templates.textEditBox end)
    equal(assert(loadstring(edit.props.text))().preset.Clear.skyDayColor[1], 0.8)
    click('Export JSON')
    edit = find(created.layout, function(node) return node.template == templates.textEditBox end)
    assert(not edit.props.text:find('[Mod]', 1, true))
    assert(edit.props.text:find('Editor preset', 1, true))
    click('Regions'); click('Reset'); equal(lastCommand().action, 'resetRegion')
end)

test('Show current finds a region by ID on its display-name page', function()
    local id = 'az_region_thousand isles'
    local regionNames = { [id] = 'Lyithdonea, Thousand Isles', z = 'West Gash' }
    for i = 1, 6 do regionNames['a' .. i] = 'Ashlands ' .. i end
    editor.eventHandlers[data.reply] { config = data.copy(config), regions = regionNames,
        region = id, activePreset = 'default' }
    click('* Regions')
    assert(withText('Page 1 / 2'))
    assert(withText('Current region: Lyithdonea, Thousand Isles'))
    assert(withText('Region ID: ' .. id))
    click('Show current')
    assert(withText('Page 2 / 2'))
    click('Assign'); equal(lastCommand().region, id)
    click('Reset'); equal(lastCommand().region, id)
    click('Export Lua')
    local edit = find(created.layout, function(node) return node.template == templates.textEditBox end)
    equal(assert(loadstring(edit.props.text))().region, id)
    editor.eventHandlers[data.reply] { config = data.copy(config), regions = regionNames,
        activePreset = 'default' }
    click('Regions')
    assert(withText('Current region: Interior'))
    assert(not withText('Show current'))
end)

test('Escape and teleport release the editor mode and preview', function()
    key('Escape'); equal(mode, nil); equal(lastCommand().action, 'close')
    key('F5', false, true); reply(true)
    editor.engineHandlers.onTeleported(); equal(mode, nil); equal(lastCommand().action, 'close')
end)

local function named(name)
    return assert(find(created.layout, function(node) return node.name == name end), 'Missing ' .. name)
end
local function mouse(x, y, button)
    return { button = button or 1, offset = { x = x, y = y }, position = { x = x + 100, y = y + 200 } }
end
local function choose()
    named('colorSwatch:skySunsetColor').events.mouseClick()
end
test('picker drags preview live, clamp at edges and undo as one gesture', function()
    key('F5', false, true); reply(true); click('Colours')
    local original = data.copy(config.presets.default.Clear.skySunsetColor)
    choose()
    equal(inputs(created.layout)[1].props.text, '##334D66')
    local plane = named('pickerSV')
    plane.events.mousePress(mouse(351, 0, 3)) -- right click must not edit
    equal(lastCommand().preset.Clear.skySunsetColor[1], original[1])
    plane.events.mousePress(mouse(0, 0))
    equal(lastCommand().preset.Clear.skySunsetColor[1], 1)
    plane.events.mouseMove(mouse(80, 100))
    plane.events.mouseMove(mouse(-30, 500))
    plane.events.mouseRelease(mouse(-30, 500))
    for i = 1, 3 do equal(lastCommand().preset.Clear.skySunsetColor[i], 0) end
    click('Done'); click('Undo')
    for i = 1, 3 do equal(lastCommand().preset.Clear.skySunsetColor[i], original[i]) end
    click('Redo'); equal(lastCommand().preset.Clear.skySunsetColor[1], 0)
end)

test('picker hue, exact entry, cancellation and Escape preserve history', function()
    choose()
    inputs(created.layout)[1].events.textChanged('#FF0000'); click('Apply')
    local hue = named('pickerHue')
    hue.events.mousePress(mouse(14, 223 / 3))
    hue.events.mouseRelease(mouse(14, 223 / 3))
    assert(lastCommand().preset.Clear.skySunsetColor[2] > 0.9999)
    inputs(created.layout)[1].events.textChanged('rgb(38, 166, 191)'); click('Apply')
    equal(lastCommand().preset.Clear.skySunsetColor[1], 38 / 255)
    equal(lastCommand().preset.Clear.skySunsetColor[3], 191 / 255)
    equal(inputs(created.layout)[1].props.text, '##26A6BF')
    inputs(created.layout)[1].events.textChanged('#BADHEX'); click('Apply')
    equal(messages[#messages], 'Enter #RRGGBB or RGB values such as 38, 166, 191.')
    click('Cancel'); equal(lastCommand().preset.Clear.skySunsetColor[1], 0)
    click('Undo'); equal(lastCommand().preset.Clear.skySunsetColor[1], 0.2)
    choose(); inputs(created.layout)[1].events.textChanged('#FFFFFF'); click('Apply')
    key('Escape'); assert(withText('Weather Adjuster — default (unsaved)'))
    equal(lastCommand().preset.Clear.skySunsetColor[1], 0.2)
    key('Escape'); equal(mode, nil)
end)

print(string.format('%d editor tests passed.', count))
