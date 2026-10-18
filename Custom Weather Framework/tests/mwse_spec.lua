-- MWSE adapters and event handlers, with an in-memory filesystem and engine.
package.path = '00 MWSE/MWSE/mods/?.lua;00 OpenMW/?.lua;' .. package.path
local files = require('customweather.regionfiles')
local data = require('scripts.customweather.common')
local count, disk, directories, logs, messages = 0, {}, {}, {}, {}
local originalOpen, originalLoadfile = io.open, loadfile
local function test(name, fn)
    local ok, err = pcall(fn)
    assert(ok, name .. ': ' .. tostring(err))
    count = count + 1; print('PASS ' .. name)
end
local function equal(a, b) assert(a == b, tostring(a) .. ' ~= ' .. tostring(b)) end
table.deepcopy = data.copy
package.loaded.lfs = {
    directoryexists = function(path) return directories[path] or false end,
    mkdir = function(path) directories[path] = true; return true end,
    attributes = function(path, field)
        if disk[path] then return field and 'file' or { mode = 'file' } end
        if directories[path] or directories[path .. '/'] then
            return field and 'directory' or { mode = 'directory' }
        end
    end,
    dir = function() error('MWSE must not scan folders for region definitions') end,
}
io.open = function(path, mode)
    equal(mode, 'wb')
    return { write = function(self, text) disk[path] = text; return self end, close = function() return true end }
end
loadfile = function(path) return loadstring(assert(disk[path], 'Missing file'), '@' .. path) end
mwse = { log = function(format, ...) logs[#logs + 1] = string.format(format, ...) end }
local regionIO = require('customweather.regionio')
local interop = require('customweather.interop')
local regionA, regionB = { id = 'West Gash Region' }, { id = 'Bitter Coast Region' }
local defaults = {}
for _, name in ipairs(data.names) do
    defaults[name] = { cloudTexture = 'tx_default.dds' }
    for _, field in ipairs(data.fields) do defaults[name][field] = { 0.2, 0.3, 0.4 } end
end
local path

test('MWSE exports files and never overwrites an existing definition', function()
    local preset = data.copy(defaults)
    preset.Clear.skyDayColor = { 0.6, 0.7, 0.8 }
    preset.Clear.cloudTexture = 'textures/tx_mod.dds'
    path = regionIO.export(regionA.id, preset)
    equal(path, 'Data Files/' .. files.directory .. 'west_gash_region.lua')
    equal(regionIO.export(regionA.id, preset), path:sub(1, -5) .. '_2.lua')
    equal(assert(loadstring(disk[path]))().preset.Clear.skyDayColor[1], 0.6)
    disk[path:sub(1, -5) .. '_2.lua'] = nil
end)

test('MWSE interop validates before replacing data and keeps caller tables separate', function()
    local definition = { id = 'MyMod:coast', region = regionA.id,
        preset = { Clear = { skyDayColor = { 0.4, 0.5, 0.6 }, cloudTexture = 'textures/tx_mod.dds' } } }
    equal(interop.registerRegion(definition), 'MyMod:coast')
    definition.preset.Clear.skyDayColor[1] = 5
    assert(not pcall(interop.registerRegion, definition))
    for _, key in ipairs { 'id', 'priority', 'version' } do
        local invalid = { region = regionA.id, preset = {} }
        invalid[key] = false
        assert(not pcall(interop.registerRegion, invalid))
    end
    local registry = interop.getRegions(defaults, {})
    equal(registry.presets['[Mod] MyMod:coast'].Clear.skyDayColor[1], 0.4)
    equal(registry.presets['[Mod] MyMod:coast'].Clear.cloudTexture, 'tx_mod.dds')
    registry.presets['[Mod] MyMod:coast'].Clear.skyDayColor[1] = 0
    equal(interop.getRegions(defaults, {}).presets['[Mod] MyMod:coast'].Clear.skyDayColor[1], 0.4)
    assert(interop.unregisterRegion('MyMod:coast'))
end)

test('MWSE interop priorities and replacement are independent of folder names', function()
    interop.registerRegion { id = 'first', region = regionA.id, priority = 10,
        preset = { Clear = { skyDayColor = { 1, 0, 0 } } } }
    interop.registerRegion { id = 'second', region = regionA.id,
        preset = { Clear = { skyDayColor = { 0, 1, 0 } } } }
    equal(interop.getRegions(defaults, {}).regions[regionA.id:lower()], '[Mod] first')
    interop.registerRegion { id = 'second', region = regionA.id, priority = 10,
        preset = { Clear = { skyDayColor = { 0, 0, 1 } } } }
    equal(interop.getRegions(defaults, {}).regions[regionA.id:lower()], '[Mod] second')
    assert(interop.unregisterRegion('second'))
    equal(interop.getRegions(defaults, {}).regions[regionA.id:lower()], '[Mod] first')
    interop.unregisterRegion('first')
    assert(not interop.unregisterRegion('missing'))
    local first = interop.registerRegion { region = regionA.id, preset = {} }
    local second = interop.registerRegion { region = regionB.id, preset = {} }
    assert(first ~= second)
    local regions = interop.getRegions(defaults, {}).regions
    assert(regions[regionA.id:lower()] and regions[regionB.id:lower()])
    interop.unregisterRegion(first); interop.unregisterRegion(second)
end)

local exportSource = '@Data Files/MWSE/mods/SomeAuthor/MyMod/anywhere/region.lua'
local exportId = exportSource .. ':' .. regionA.id:lower()
local nameA, nameB
test('MWSE exports register from arbitrary locations and tolerate a missing framework', function()
    local oldInclude = include
    include = function(name) equal(name, 'customweather.interop'); return interop end
    assert(loadstring(disk[path], exportSource))()
    assert(loadstring(files.export(regionB.id, { Clear = { skyDayColor = { 0.8, 0.7, 0.6 } } }),
        '@Data Files/MWSE/mods/MODNAME/any/subfolder/coast.lua'))()
    assert(loadstring(files.export(regionB.id, { Clear = { skyDayColor = { 0.9, 0.8, 0.7 } } }),
        '@Data Files/MWSE/mods/Other Mod/totally/different/coast.lua'))()
    local registry = interop.getRegions(defaults, {})
    nameA, nameB = registry.regions[regionA.id:lower()], registry.regions[regionB.id:lower()]
    equal(registry.sources[nameA], exportId)
    equal(registry.presets[nameB].Clear.skyDayColor[1], 0.9)
    include = function() return nil end
    equal(assert(loadstring(disk[path], '@absent-framework.lua'))().region, regionA.id:lower())
    equal(interop.getRegions(defaults, {}).regions[regionA.id:lower()], nameA)
    include = oldInclude
end)

local handlers, saved, menu, keysDown = {}, nil, nil, {}
local wc = { weathers = {}, updateVisuals = function() end,
    sunriseHour = 6, sunriseDuration = 2, sunsetHour = 18, sunsetDuration = 2 }
for i, name in ipairs(data.names) do
    local weather = { index = i - 1, cloudTexture = defaults[name].cloudTexture }
    for _, field in ipairs(data.fields) do weather[field] = { r = 0.2, g = 0.3, b = 0.4 } end
    wc.weathers[i] = weather
end
wc.currentWeather = wc.weathers[1]
function wc:switchImmediate(index) self.currentWeather = self.weathers[index + 1] end
function wc:switchTransition(index) self.nextWeather = self.weathers[index + 1] end
local cell = { region = regionA }
tes3 = {
    scanCode = { F4 = 62, lShift = 42, rShift = 54, lCtrl = 29, rCtrl = 157 },
    event = { initialized = 'initialized', loaded = 'loaded', cellChanged = 'cellChanged',
        weatherChangedImmediate = 'weatherChangedImmediate', keyDown = 'keyDown',
        modConfigReady = 'modConfigReady', simulate = 'simulate' },
    uiEvent = { mouseClick = 'mouseClick', mouseLeave = 'mouseLeave', keyEnter = 'keyEnter',
        mouseDown = 'mouseDown', mouseStillPressed = 'mouseStillPressed', mouseRelease = 'mouseRelease', help = 'help' },
    flowDirection = { leftToRight = 1, topToBottom = 2 },
    worldController = { weatherController = wc, hour = { value = 13 }, inputController = {
        isKeyDown = function(_, key) assert(key, 'Unknown scan code'); return keysDown[key] or false end } },
    getPlayerCell = function() return cell end,
    getCurrentWeather = function() return wc.currentWeather end,
    dataHandler = { nonDynamicData = { regions = { regionA, regionB } } },
    iterate = ipairs,
    messageBox = function(value) messages[#messages + 1] = value.message end,
}
-- tes3.iterate yields objects rather than array indices.
tes3.iterate = function(values)
    local i = 0; return function() i = i + 1; return values[i] end
end
event = { register = function(name, fn) handlers[name] = fn end,
    unregister = function(name) handlers[name] = nil end,
    trigger = function(name) if handlers[name] then handlers[name]() end end }
mge = { weather = {
    getScattering = function() return { outscatter = { 0.1, 0.2, 0.3 }, inscatter = { 0.1, 0.2, 0.3 } } end,
    setScattering = function() end,
} }
mwse.loadConfig = function(_, fallback) return data.copy(fallback) end
mwse.saveConfig = function(_, value) saved = data.copy(value) end
package.loaded['customweather.patch'] = { patchCloudVertexColours = function() end }
local methods = {}
local function element(options, parent)
    local node = setmetatable({ children = {}, callbacks = {}, parent = parent,
        widget = { state = 1 }, maxWidth = 1024 }, { __index = methods })
    for key, value in pairs(options or {}) do node[key] = value end
    if parent then parent.children[#parent.children + 1] = node end
    return node
end
for _, method in ipairs { 'createBlock', 'createButton', 'createLabel', 'createThinBorder',
    'createTextInput', 'createVerticalScrollPane', 'createTextSelect', 'createDivider', 'createRect', 'createImage' } do
    methods[method] = function(self, options) return element(options, self) end
end
function methods:register(name, fn) self.callbacks[name] = fn end
function methods:updateLayout() end
function methods:loadMenuPosition() end
function methods:getContentElement() return self end
function methods:destroyChildren() self.children = {} end
function methods:getTopLevelParent() return self.parent and self.parent:getTopLevelParent() or self end
methods.getTopLevelMenu = methods.getTopLevelParent
function methods:triggerEvent() end
function methods:findChild(id)
    if self.id == id then return self end
    for _, child in ipairs(self.children) do local found = child:findChild(id); if found then return found end end
end
tes3ui = {
    registerID = function(id) return id end,
    findMenu = function(id) return menu and menu.id == id and menu or nil end,
    createMenu = function(options) menu = element(options); return menu end,
    menuMode = function() return true end,
    captureMouseDrag = function(value) tes3ui.dragCaptured = value end,
    acquireTextInput = function(value) tes3ui.focusedInput = value end,
}
local function findText(text, node)
    node = node or menu
    if node.text == text then return node end
    for _, child in ipairs(node.children) do local found = findText(text, child); if found then return found end end
end
local function click(text)
    local node = assert(findText(text), 'Missing UI item ' .. text)
    assert(node.callbacks.mouseClick, 'Not clickable: ' .. text) { source = node }
end
require('customweather.main')
local config = require('customweather.mcm').config

test('MWSE loaded and cell events apply packaged regions with personal precedence', function()
    handlers.initialized(); handlers.loaded()
    equal(wc.currentWeather.skyDayColor.r, 0.6)
    equal(config.regions[regionA.id:lower()], nil)
    config.presets.personal = data.copy(defaults)
    config.presets.personal.Clear.skyDayColor = { 0.9, 0.1, 0.2 }
    config.regions[regionA.id:lower()] = 'personal'
    handlers.weatherChangedImmediate(); handlers.cellChanged()
    equal(wc.currentWeather.skyDayColor.r, 0.9)
    config.regions[regionA.id:lower()] = nil
    handlers.loaded()
    equal(wc.currentWeather.skyDayColor.r, 0.6)
    require('customweather.mcm').onClose()
    equal(saved.presets[nameA], nil)
    cell.region = regionB
    handlers.weatherChangedImmediate(); handlers.cellChanged()
    equal(wc.currentWeather.skyDayColor.r, 0.9)
    equal(saved.presets[nameB], nil)
    cell.region = regionA
    handlers.weatherChangedImmediate(); handlers.cellChanged()
end)

test('MWSE region editor exports preview and assigned colours and resets overrides', function()
    handlers.keyDown { keyCode = 62, isShiftDown = true, isAltDown = false, isControlDown = false }
    click('Regions')
    wc.currentWeather.skyDayColor.r = 0.55
    click('Export preview Lua')
    local exported = path:sub(1, -5) .. '_2.lua'
    equal(assert(loadstring(disk[exported]))().preset.Clear.skyDayColor[1], 0.55)
    click('Export assigned Lua')
    equal(assert(loadstring(disk[path:sub(1, -5) .. '_3.lua']))().preset.Clear.skyDayColor[1], 0.6)
    disk[exported], disk[path:sub(1, -5) .. '_3.lua'] = nil, nil
    config.regions[regionA.id:lower()] = 'personal'
    keysDown[tes3.scanCode.lCtrl] = true; click(regionA.id); keysDown = {}
    equal(config.regions[regionA.id:lower()], nil)
    equal(wc.currentWeather.skyDayColor.r, 0.6)
    click(regionA.id)
    keysDown[tes3.scanCode.lShift] = true; click(regionB.id); keysDown = {}
    local name = config.regions[regionB.id:lower()]
    assert(config.presets[name] and name ~= nameA)
    equal(saved.presets[name].Clear.skyDayColor[1], 0.6)
end)

test('MWSE unregistering a definition immediately restores the original region defaults', function()
    assert(interop.unregisterRegion(exportId))
    equal(wc.currentWeather.skyDayColor.r, 0.2)
    handlers.loaded()
    equal(wc.currentWeather.skyDayColor.r, 0.2)
    assert(config.presets.personal)
end)

test('MWSE registrations after game load update colours immediately', function()
    interop.registerRegion { id = 'late mod', region = regionA.id,
        preset = { Clear = { skyDayColor = { 0.3, 0.5, 0.7 } } } }
    equal(wc.currentWeather.skyDayColor.r, 0.3)
    interop.unregisterRegion('late mod')
    equal(wc.currentWeather.skyDayColor.r, 0.2)
end)

test('MWSE loading an interior leaves a valid default preset for the editor', function()
    cell.region = nil; handlers.loaded()
    equal(wc.currentWeather.skyDayColor.r, 0.2)
    click('Presets'); click('Copy')
    assert(config.presets['default (1)'])
    cell.region = regionA
end)

local function pickerNode(id)
    return assert(menu:findChild(id), 'Missing picker ' .. id)
end
local function findCallback(node, name)
    if node.callbacks[name] then return node end
    for _, child in ipairs(node.children) do
        local found = findCallback(child, name); if found then return found end
    end
end
local function chooseSky()
    local block = pickerNode('Hrn:WeatherAdjust.ColourBlock')
    local row = block.children[2]
    row.children[1].callbacks.mouseClick()
end
test('MWSE picker previews one drag, restores Cancel, and supports undo/redo', function()
    click('Editor')
    local original = data.copy(wc.currentWeather.skyDayColor)
    chooseSky()
    local plane = pickerNode('Hrn:WeatherAdjust.PickerSV')
    plane.callbacks.mouseDown { relativeX = 0, relativeY = 0 }
    equal(tes3ui.dragCaptured, true)
    equal(wc.currentWeather.skyDayColor.r, 1)
    plane.callbacks.mouseStillPressed { relativeX = 200, relativeY = 110 }
    plane.callbacks.mouseRelease { relativeX = -20, relativeY = 500 }
    equal(tes3ui.dragCaptured, false)
    equal(wc.currentWeather.skyDayColor.r, 0)
    click('Cancel'); equal(wc.currentWeather.skyDayColor.r, original.r)
    chooseSky(); plane = pickerNode('Hrn:WeatherAdjust.PickerSV')
    plane.callbacks.mouseDown { relativeX = 0, relativeY = 0 }
    plane.callbacks.mouseStillPressed { relativeX = 100, relativeY = 50 }
    plane.callbacks.mouseRelease { relativeX = 100, relativeY = 50 }
    local chosen = wc.currentWeather.skyDayColor.r
    click('Done'); click('Undo'); equal(wc.currentWeather.skyDayColor.r, original.r)
    click('Redo'); equal(wc.currentWeather.skyDayColor.r, chosen)
end)
test('MWSE picker accepts exact hex and RGB entry and saves the selected colour', function()
    chooseSky()
    local entry = assert(findCallback(menu, 'keyEnter'))
    entry.text = '#26A6BF'; click('Apply')
    assert(math.abs(wc.currentWeather.skyDayColor.r - 38 / 255) < 1e-12)
    entry.text = '127.5, 0, 255'; entry.callbacks.keyEnter()
    equal(wc.currentWeather.skyDayColor.r, 0.5)
    entry.text = '#invalid'; click('Apply')
    equal(messages[#messages], 'Enter #RRGGBB or RGB values such as 38, 166, 191.')
    equal(wc.currentWeather.skyDayColor.r, 0.5)
    click('Done'); click('Save as new preset')
    equal(saved.presets['New Preset 1'].Clear.skyDayColor[1], 0.5)
    click('Atmos.')
    local block = pickerNode('Hrn:WeatherAdjust.ColourBlock')
    block.children[4].children[1].callbacks.mouseClick() -- atmosphere outscatter
    entry = assert(findCallback(menu, 'keyEnter'))
    entry.text = '#FFFFFF'; click('Apply'); click('Done'); click('Save preset')
    equal(saved.presets['New Preset 1'].outscatter[1], 0.005)
end)

io.open, loadfile = originalOpen, originalLoadfile
print(string.format('%d MWSE tests passed.', count))
