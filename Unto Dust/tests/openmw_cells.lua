-- Exercise the actual picker callbacks and world catalogue without a game UI.
local renderers, arguments = {}, {}
local templates = { box = {}, padding = {}, textNormal = {}, textHeader = {}, textParagraph = {}, textEditLine = {}, interval = {} }
package.preload['openmw.interfaces'] = function()
    return {
        MWUI = { templates = templates },
        Settings = { registerRenderer = function(key, renderer) renderers[key] = renderer end },
    }
end
package.preload['openmw.core'] = function() return { l10n = function() return function(key) return key end end } end
package.preload['openmw.async'] = function() return { callback = function(_, fn) return fn end } end
package.preload['openmw.util'] = function() return { vector2 = function(x, y) return { x = x, y = y } end } end
package.preload['openmw.ui'] = function()
    return {
        TYPE = { Flex = 'Flex', Widget = 'Widget' }, ALIGNMENT = { Center = 'Center' },
        content = function(value) return value end,
        create = function(layout)
            return { layout = layout, update = function(self) self.updates = (self.updates or 0) + 1 end }
        end,
    }
end
package.preload['scripts.UntoDust.cellLists'] = assert(loadfile('00 OpenMW/scripts/UntoDust/cellLists.lua'))
package.preload['scripts.UntoDust.cellPicker'] = assert(loadfile('00 OpenMW/scripts/UntoDust/cellPicker.lua'))
assert(loadfile('00 OpenMW/scripts/UntoDust/menu.lua'))()
local render = assert(renderers.UntoDustCells, 'menu did not register the picker renderer')

local cells = {
    { name = 'Balmora, Guild of Mages', isExterior = false },
    { name = 'Mod Interior; with [punctuation]', isExterior = false },
    { name = 'BALMORA, GUILD OF MAGES', isExterior = false },
    { name = 'Tomb outside', isExterior = true },
    { name = '', isExterior = false },
}
for i = 1, 20 do cells[#cells + 1] = { name = string.format('Unvisited Mod Interior %02d', i), isExterior = false } end
package.preload['openmw.world'] = function() return { cells = cells } end
local names
local global = assert(loadfile('00 OpenMW/scripts/UntoDust/global.lua'))()
global.engineHandlers.onPlayerAdded { sendEvent = function(_, event, value)
    assert(event == 'UntoDustCells')
    names = value
end }
assert(#names == 22 and names[1] == 'Balmora, Guild of Mages')
assert(names[2] == 'Mod Interior; with [punctuation]' and names[22] == 'Unvisited Mod Interior 20')

local function find(layout, name)
    layout = layout.layout or layout
    if layout.name == name then return layout end
    for _, child in ipairs(layout.content or {}) do
        local result = find(child, name)
        if result then return result end
    end
end

local current, value
arguments = { key = 'whitelist', cells = names, ready = true }
local function set(newValue)
    value = newValue
    current = render(value, set, arguments)
end
value = ' BALMORA, GUILD OF MAGES ; Missing Plugin Interior '
current = render(value, set, arguments)
local function search(query)
    find(current, 'input').events.textChanged(query)
end
local function transfer(name, side)
    local row = assert(find(find(current, side), name), 'cell missing from picker: ' .. name)
    find(row, 'transfer').events.mouseClick()
end
-- Saved case-insensitive names are displayed using the catalogue's spelling.
assert(find(find(current, 'selected'), 'Balmora, Guild of Mages'))
assert(find(find(current, 'selected'), 'Missing Plugin Interior'))
assert(find(current, 'title').props.text == 'WhitelistName')
assert(not find(current, 'available') and find(current, 'help').props.text == 'SearchPrompt')
transfer('Balmora, Guild of Mages', 'selected')
assert(not value['Balmora, Guild of Mages'] and value['Missing Plugin Interior'])
search('BALMORA')
assert(find(find(current, 'available'), 'Balmora, Guild of Mages'))
transfer('Balmora, Guild of Mages', 'available')
assert(value['Balmora, Guild of Mages'])
-- A broad search stays compact; refining it can reach every installed cell.
search('unvisited')
assert(find(current, 'moreResults') and not find(current, 'paging'))
assert(not find(find(current, 'available'), 'Unvisited Mod Interior 20'))
for i = 1, 20 do
    local name = string.format('Unvisited Mod Interior %02d', i)
    search(name)
    assert(find(find(current, 'available'), name))
    assert(not find(current, 'moreResults'))
end
-- Selected cells remain visible even when the search does not match them.
assert(find(find(current, 'selected'), 'Balmora, Guild of Mages'))
search(' \t ')
assert(not find(current, 'available') and find(current, 'help').props.text == 'SearchPrompt')
-- Searching is case-insensitive, literal, and survives a storage re-render.
search('MOD INTERIOR; WITH [PUNCTUATION]')
transfer('Mod Interior; with [punctuation]', 'available')
assert(value['Mod Interior; with [punctuation]'])
assert(find(current, 'input').props.text == 'MOD INTERIOR; WITH [PUNCTUATION]')
assert(not find(current, 'available')) -- Already selected, so it isn't offered twice.
transfer('Mod Interior; with [punctuation]', 'selected')
assert(not value['Mod Interior; with [punctuation]'])
find(current, 'clear').events.mouseClick()
assert(next(value) == nil, 'Clear did not reset the list')
assert(not find(current, 'clear'), 'empty list still offers a redundant Clear button')
search('missing interior')
assert(find(current, 'noResults'))

-- Blacklist search is independent of the whitelist.
arguments = { key = 'blacklist', cells = names, ready = true }
current = render({}, set, arguments)
assert(find(current, 'input').props.text == '')
assert(find(current, 'title').props.text == 'BlacklistName')
search('Balmora')
transfer('Balmora, Guild of Mages', 'available')
assert(value['Balmora, Guild of Mages'])
current = render({ ['Missing Plugin Interior'] = true }, set, { key = 'notLoaded', cells = {} })
assert(find(current, 'help').props.text == 'LoadGameForCells')
assert(find(find(current, 'selected'), 'Missing Plugin Interior'))
local overlapping = { 'Crypt' }
for i = 1, 20 do overlapping[#overlapping + 1] = string.format('A Modded Crypt %02d', i) end
current = render({}, set, { key = 'exactMatch', cells = overlapping, ready = true })
search('crypt')
assert(find(find(current, 'available'), 'Crypt'), 'exact cell name hidden by the result limit')
print('PASS OpenMW cell picker: complete catalogue, search-first results, bounded broad searches, persistent selected list, Add/Remove, Clear, legacy and unavailable cells')
