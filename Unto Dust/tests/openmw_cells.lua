-- Exercise the real picker and vendored virtual list without a game UI.
local renderers = {}
local templates = { box = {}, borders = {}, padding = {}, textNormal = {}, textHeader = {}, textParagraph = {} }
package.preload['openmw.interfaces'] = function()
    return {
        MWUI = { templates = templates },
        Settings = { registerRenderer = function(key, renderer) renderers[key] = renderer end },
    }
end
package.preload['openmw.core'] = function()
    return { l10n = function() return function(key) return key end end, getGMST = function() return '202,165,96' end }
end
package.preload['openmw.async'] = function() return { callback = function(_, fn) return fn end } end
package.preload['openmw.util'] = function()
    return {
        vector2 = function(x, y) return { x = x, y = y } end,
        clamp = function(value, low, high) return math.max(low, math.min(high, value)) end,
        color = { rgb = function(r, g, b) return { r, g, b } end },
    }
end
local keys = { Home = 1, End = 2, PageUp = 3, PageDown = 4, UpArrow = 5, DownArrow = 6 }
package.preload['openmw.input'] = function() return { KEY = keys, isShiftPressed = function() return false end } end
package.preload['openmw.ambient'] = function() return { playSound = function() end } end
package.preload['openmw.ui'] = function()
    return {
        TYPE = { Flex = 'Flex', Widget = 'Widget', Container = 'Container', Text = 'Text', TextEdit = 'TextEdit', Image = 'Image' },
        texture = function(value) return value end,
        content = function(value)
            return setmetatable(value, {
                __index = function(self, name)
                    if name == 'add' then return function(_, child) self[#self + 1] = child end end
                    for _, child in ipairs(self) do
                        if (child.layout or child).name == name then return child end
                    end
                end,
                __newindex = function(self, name, child)
                    if type(name) == 'number' then rawset(self, name, child); return end
                    for index, old in ipairs(self) do
                        if (old.layout or old).name == name then
                            if child == nil then table.remove(self, index) else rawset(self, index, child) end
                            return
                        end
                    end
                    error('Unknown content name: ' .. name)
                end,
            })
        end,
        create = function(layout)
            return {
                layout = layout,
                update = function(self) assert(self.layout); self.updates = (self.updates or 0) + 1 end,
                destroy = function(self) self.layout = nil end,
            }
        end,
    }
end
for _, module in ipairs({ 'cellLists', 'cellPicker', 'virtual_list', 'virtual_list.styles',
    'virtual_list.extras', 'virtual_list.extras.extended', 'virtual_list.extras.font_color', 'virtual_list.extras.list_state' }) do
    local path = '00 OpenMW/scripts/UntoDust/' .. module:gsub('%.', '/')
    if module == 'virtual_list' or module == 'virtual_list.extras' then path = path .. '/init' end
    package.preload['scripts.UntoDust.' .. module] = assert(loadfile(path .. '.lua'))
end
local menu = assert(loadfile('00 OpenMW/scripts/UntoDust/menu.lua'))()
local render = assert(renderers.UntoDustCells, 'menu did not register the picker renderer')
assert(menu.engineHandlers.onFrame and menu.engineHandlers.onMouseWheel)

local cells = {
    { name = 'Balmora, Guild of Mages', isExterior = false },
    { name = 'Mod Interior; with [punctuation]', isExterior = false },
    { name = 'BALMORA, GUILD OF MAGES', isExterior = false },
    { name = 'Tomb outside', isExterior = true }, { name = '', isExterior = false },
}
for i = 1, 10000 do cells[#cells + 1] = { name = string.format('Unvisited Mod Interior %05d', i), isExterior = false } end
package.preload['openmw.world'] = function() return { cells = cells } end
local names
local global = assert(loadfile('00 OpenMW/scripts/UntoDust/global.lua'))()
global.engineHandlers.onPlayerAdded { sendEvent = function(_, event, value)
    assert(event == 'UntoDustCells'); names = value
end }
assert(#names == 10002 and names[1] == 'Balmora, Guild of Mages')
assert(names[2] == 'Mod Interior; with [punctuation]' and names[#names] == 'Unvisited Mod Interior 10000')

local function find(layout, name)
    layout = layout.layout or layout
    if layout.name == name then return layout end
    for _, child in ipairs(layout.content or {}) do
        local result = find(child, name)
        if result then return result end
    end
end
local function event(layout, name, data) layout.events[name](data, layout) end
local current, value
local arguments = { key = 'whitelist', cells = names, ready = true }
local function set(newValue) value = newValue; current = render(value, set, arguments) end
value = ' BALMORA, GUILD OF MAGES ; Missing Plugin Interior '
current = render(value, set, arguments)
local function pane(side) return assert(find(current, side)) end
local function controller(side) return find(pane(side), 'list').userData.scrollData end
local function search(query, side)
    local input = find(pane(side or 'available'), 'input')
    input.props.text = query
    event(input, 'textChanged', query)
end
local function transfer(name, side)
    local row = assert(find(pane(side), name), 'cell missing from picker: ' .. name)
    event(row, 'mousePress', { button = 1 })
    event(find(pane(side), 'transfer'), 'mouseClick')
end
local function key(side, code) event(find(pane(side), 'list'), 'keyPress', { code = code }) end
local function count(side) return find(pane(side), 'heading').props.text end

-- Empty filters browse the complete catalogue, with only visible rows created.
assert(find(pane('selected'), 'Balmora, Guild of Mages'))
assert(find(pane('selected'), 'Missing Plugin Interior'))
assert(find(current, 'title').props.text == 'WhitelistName')
assert(controller('available'):getLastIndex() == 10001)
assert(#controller('available'):getContent() <= 11, 'catalogue was rendered eagerly')
transfer('Balmora, Guild of Mages', 'selected')
assert(not value['Balmora, Guild of Mages'] and value['Missing Plugin Interior'])
search('BALMORA')
transfer('Balmora, Guild of Mages', 'available')
assert(value['Balmora, Guild of Mages'])
assert(find(pane('available'), 'input').props.text == 'BALMORA')
-- Restored queries must survive focus gain as well as renderer replacement.
event(find(pane('available'), 'input'), 'focusGain')
assert(find(pane('available'), 'input').props.text == 'BALMORA')

search('unvisited')
assert(count('available') == 'AvailableCells (10000)')
assert(controller('available'):getLastIndex() == 10000)
key('available', keys.End)
assert(find(pane('available'), 'Unvisited Mod Interior 10000'))
assert(controller('available'):getScrollOffset() > 0)
-- Transferring the last result retains the filter and scroll position.
transfer('Unvisited Mod Interior 10000', 'available')
assert(value['Unvisited Mod Interior 10000'])
assert(controller('available'):getScrollOffset() > 190000)
assert(count('available') == 'AvailableCells (9999)')
key('available', keys.Home)
assert(controller('available'):getFirstVisibleIndex() == 1)
local listLayout = find(pane('available'), 'list')
event(listLayout, 'focusGain')
menu.engineHandlers.onMouseWheel(-1, 0)
assert(controller('available'):getScrollOffset() > 0, 'wheel was not forwarded')
local oldOffset = controller('available'):getScrollOffset()
event(listLayout, 'focusLoss')
menu.engineHandlers.onMouseWheel(-1, 0)
assert(controller('available'):getScrollOffset() == oldOffset, 'unfocused list scrolled')
key('available', keys.PageDown)
key('available', keys.UpArrow)
key('available', keys.DownArrow)
key('available', keys.PageUp)

-- Searching is literal, ignores case/outer whitespace, and keeps selected cells.
search(' MOD INTERIOR; WITH [PUNCTUATION] ')
transfer('Mod Interior; with [punctuation]', 'available')
assert(value['Mod Interior; with [punctuation]'])
assert(count('available') == 'AvailableCells (0)')
key('available', keys.DownArrow) -- Empty placeholders must be safe to navigate.
key('available', keys.End)
assert(find(pane('selected'), 'Balmora, Guild of Mages'))
search('punctuation', 'selected')
assert(count('selected') == 'SelectedCells (1)')
transfer('Mod Interior; with [punctuation]', 'selected')
assert(not value['Mod Interior; with [punctuation]'])
assert(find(pane('selected'), 'input').props.text == 'punctuation')
event(find(current, 'clear'), 'mouseClick')
assert(next(value) == nil, 'Clear did not reset hidden selections')
search('missing interior')
assert(count('available') == 'AvailableCells (0)')
search(' \t ')
assert(count('available') == 'AvailableCells (10002)')

-- Independent filters, saved unavailable cells, and search focus cleanup.
arguments = { key = 'blacklist', cells = names, ready = true }
current = render({}, set, arguments)
assert(find(pane('available'), 'input').props.text == 'SearchInteriors')
assert(find(current, 'title').props.text == 'BlacklistName')
search('Balmora')
transfer('Balmora, Guild of Mages', 'available')
assert(value['Balmora, Guild of Mages'])
current = render({ ['Missing Plugin Interior'] = true }, set, { key = 'notLoaded', cells = {} })
assert(find(current, 'help').props.text == 'LoadGameForCells')
assert(find(pane('selected'), 'Missing Plugin Interior'))
menu.engineHandlers.onFrame(); menu.engineHandlers.onFrame()
assert(find(pane('available'), 'input').props.visible == true)
local input = find(pane('available'), 'input')
event(input, 'focusLoss')
input.props = nil -- Destroyed queued elements must not break the menu frame handler.
-- Simulate Element:destroy, which clears layout (the queued object owns it).
for _, child in ipairs(pane('available').content) do
    for _, element in ipairs(child.content or {}) do
        if element.layout == input then element:destroy() end
    end
end
menu.engineHandlers.onFrame()
local listElement
for _, child in ipairs(pane('available').content) do
    for _, element in ipairs(child.content or {}) do
        if element.layout and element.layout.name == 'list' then listElement = element end
    end
end
event(listElement.layout, 'focusGain')
listElement:destroy()
menu.engineHandlers.onMouseWheel(-1, 0)
print('PASS OpenMW virtual-list MCM: 10,000 cells, bounded row creation, full browsing, keyboard/wheel, independent filters, retained query/scroll, Add/Remove/Clear, legacy and unavailable cells')
