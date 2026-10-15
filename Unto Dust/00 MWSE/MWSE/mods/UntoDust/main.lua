local config = mwse.loadConfig('UntoDust', { density = 32, whitelist = {}, blacklist = {} })
if type(config.density) ~= 'number' or config.density ~= config.density then
    config.density = 32
end
config.density = math.floor(math.max(0, math.min(100, config.density)) + 0.5)
local keywords = { 'tomb', 'barrow', 'crypt', 'catacomb', 'burial' }
local shader
local elapsed = 0

local function readList(list)
    local result = {}
    if type(list) == 'string' then
        -- Preserve selections saved by the former text fields.
        for entry in list:gmatch('[^;\r\n]+') do
            entry = entry:match('^%s*(.-)%s*$')
            if entry ~= '' then result[entry] = true end
        end
    elseif type(list) == 'table' then
        for name, selected in pairs(list) do
            if type(name) == 'string' and name ~= '' and selected == true then
                result[name] = true
            end
        end
    end
    return result
end

for _, key in ipairs({ 'whitelist', 'blacklist' }) do
    config[key] = readList(config[key])
end

local function listHasCell(list, name)
    for entry in pairs(readList(list)) do
        if entry:lower() == name then return true end
    end
    return false
end

local function isDustCell(cell)
    if not cell or not cell.isInterior then return false end
    local name = cell.id:lower()
    if name == '' then return false end
    if listHasCell(config.blacklist, name) then return false end
    if listHasCell(config.whitelist, name) then return true end
    for _, keyword in ipairs(keywords) do
        if name:find(keyword, 1, true) then return true end
    end
    return false
end

local function updateCell()
    if shader then
        shader.dustDensity = config.density / 100
        shader.enabled = config.density > 0 and isDustCell(tes3.player and tes3.player.cell)
    end
end

local function cellChoices(key)
    local names = {}
    local data = tes3.dataHandler and tes3.dataHandler.nonDynamicData
    for _, cell in ipairs(data and data.cells or {}) do
        if cell.isInterior and cell.id ~= '' then names[cell.id:lower()] = cell.id end
    end
    -- Keep saved entries from missing plugins visible so they can be removed.
    for name in pairs(readList(config[key])) do
        names[name:lower()] = names[name:lower()] or name
    end
    local selected = {}
    for name in pairs(readList(config[key])) do selected[names[name:lower()]] = true end
    config[key] = selected
    local result = {}
    for _, name in pairs(names) do result[#result + 1] = name end
    table.sort(result, function(a, b) return a:lower() < b:lower() end)
    return result
end

event.register('modConfigReady', function()
    local template = mwse.mcm.createTemplate { name = 'Unto Dust', config = config }
    template:saveOnClose('UntoDust', config)
    local page = template:createSideBarPage { label = 'Settings' }
    page:createSlider {
        label = 'Dust density (%)',
        description = 'How many dust motes appear. 0% disables dust; 32% is the default, and 85% matches the former denser option. Changes apply immediately.',
        configKey = 'density',
        defaultSetting = 32,
        min = 0,
        max = 100,
        step = 1,
        jump = 5,
        callback = updateCell,
    }
    for _, options in ipairs({
        { key = 'whitelist', label = 'Cell whitelist', selected = 'Whitelisted interiors',
            description = 'Add dust to extra interiors. The blacklist takes priority; exteriors stay excluded and 0% density disables all dust.' },
        { key = 'blacklist', label = 'Cell blacklist', selected = 'Blacklisted interiors',
            description = 'Disable dust in selected interiors, including automatic burial matches and whitelisted cells.' },
    }) do
        local key = options.key
        local exclusions = template:createExclusionsPage {
            label = options.label,
            configKey = key,
            description = options.description .. ' Browse all installed interiors, or search either list. Click a cell to move it, or use the arrows to move all search results. Changes apply immediately. Reset clears this list.',
            leftListLabel = options.selected,
            rightListLabel = 'Available interiors',
            showReset = true,
            variable = {
                class = 'Custom',
                defaultSetting = {},
                getter = function() return config[key] end,
                setter = function(_, value)
                    config[key] = readList(value)
                    updateCell()
                end,
            },
            filters = { { label = 'All interiors', callback = function() return cellChoices(key) end } },
        }
        -- The native page's header buttons move the filtered cells in either direction.
        local createSearchBar = exclusions.createSearchBar
        exclusions.createSearchBar = function(self, parent, listName)
            self.toggleText = listName == 'leftList' and '>>' or '<<'
            createSearchBar(self, parent, listName)
        end
    end
    template:register()
end)

event.register('loaded', function()
    if not mge or not mge.enabled() then
        mwse.log('[Unto Dust] MGE XE must be enabled for the dust shader.')
        return
    end
    shader = mge.shaders.load { name = 'UntoDust' }
    if not shader then
        mwse.log('[Unto Dust] Could not load shaders/XEshaders/UntoDust.fx; check mgeXE.log.')
        return
    end
    elapsed = 0
    shader.dustTime = elapsed
    updateCell()
end)

event.register('cellChanged', updateCell)
event.register('load', function()
    if shader then shader.enabled = false end
end)
event.register('simulate', function(e)
    if shader and shader.enabled then
        elapsed = elapsed + e.delta
        shader.dustTime = elapsed
    end
end)
