-- Behavior tests for the packaged MWSE script without the game runtime.
local handlers, logs = {}, {}
event = { register = function(name, callback) handlers[name] = callback end }
tes3 = { player = nil }
local config, slider, closeMenu, saved, registered
local fields = {}
mwse = {
    log = function(message) logs[#logs + 1] = message end,
    loadConfig = function(path, defaults)
        assert(path == 'UntoDust' and defaults.density == 32)
        assert(type(defaults.whitelist) == 'table' and next(defaults.whitelist) == nil)
        assert(type(defaults.blacklist) == 'table' and next(defaults.blacklist) == nil)
        config = {}
        for key, value in pairs(saved or { density = defaults.density }) do config[key] = value end
        -- Deliberately omit the new keys on first load, like an older config.
        return config
    end,
    mcm = { createTemplate = function(options)
        assert(options.name == 'Unto Dust' and options.config == config)
        return {
            saveOnClose = function(_, path, data)
                assert(path == 'UntoDust' and data == config)
                closeMenu = function()
                    saved = {}
                    for key, value in pairs(data) do saved[key] = value end
                end
            end,
            createSideBarPage = function()
                return {
                    createSlider = function(_, options) slider = options end,
                }
            end,
            createExclusionsPage = function(_, options)
                fields[options.configKey] = options
                options.createSearchBar = function(self, _, listName)
                    self.arrows = self.arrows or {}
                    self.arrows[listName] = self.toggleText
                end
                return options
            end,
            register = function() registered = true end,
        }
    end },
}
local shader = { enabled = false }
local available, loadable, loads = true, true, 0
mge = {
    enabled = function() return available end,
    shaders = { load = function(options)
        assert(options.name == 'UntoDust')
        loads = loads + 1
        if loadable then return shader end
    end },
}
assert(loadfile('00 MWSE/MWSE/mods/UntoDust/main.lua'))()
handlers.modConfigReady()
assert(registered and slider.configKey == 'density' and slider.defaultSetting == 32)
assert(slider.min == 0 and slider.max == 100 and slider.step == 1)
for _, key in ipairs({ 'whitelist', 'blacklist' }) do
    local control = fields[key]
    assert(control and control.variable.class == 'Custom' and control.showReset)
    assert(type(config[key]) == 'table' and next(config[key]) == nil)
    control:createSearchBar(nil, 'leftList')
    control:createSearchBar(nil, 'rightList')
    assert(control.arrows.leftList == '>>' and control.arrows.rightList == '<<')
    control.variable:setter({}) -- Menu may be opened before loading a game.
end
slider.callback() -- Menu may be opened before loading a game.
handlers.cellChanged()
handlers.simulate { delta = 1 }
handlers.loaded()
assert(not shader.enabled and shader.dustDensity == 0.32)

local function enter(name, interior, expected)
    tes3.player = { cell = { id = name, isInterior = interior } }
    handlers.cellChanged()
    assert(shader.enabled == expected, name)
end
for _, name in ipairs({ 'Modded TOMB', 'Barrow', 'Crypt', 'Catacombs', 'Burial' }) do
    enter(name, true, true)
end
assert(loads == 1)
for _ = 1, 600 do handlers.simulate { delta = 1 / 60 } end
assert(math.abs(shader.dustTime - 10) < 0.00001)
config.density = 85
slider.callback()
assert(shader.enabled and shader.dustDensity == 0.85)
local menuTime = shader.dustTime
config.density = 0
slider.callback()
assert(not shader.enabled and shader.dustDensity == 0)
handlers.simulate { delta = 10 }
assert(shader.dustTime == menuTime)
config.density = 100
slider.callback()
assert(shader.enabled and shader.dustDensity == 1)
config.density = 32
slider.callback()
assert(shader.enabled and shader.dustDensity == 0.32)
handlers.simulate { delta = 0 }
assert(math.abs(shader.dustTime - 10) < 0.00001)
enter('Another Tomb', true, true)
enter('Tomb outside', false, false)
enter("Uvirith's Grave", true, false)
enter('Balmora, Guild of Mages', true, false)
config.density = 85
slider.callback()
assert(not shader.enabled and shader.dustDensity == 0.85)
local time = shader.dustTime
handlers.simulate { delta = 10 }
assert(shader.dustTime == time)
enter('Andrano Ancestral Tomb', true, true)
handlers.load()
assert(not shader.enabled)
handlers.loaded()
assert(shader.enabled and shader.dustTime == 0)
local function set(key, value)
    config[key] = value
    slider.callback()
end
assert(loadfile('tests/cell_filters.lua'))()(enter, set, function(expected, message)
    assert(shader.enabled == expected, message)
end)

-- Native exclusions pages list every installed interior, including unvisited
-- mod-added cells. Their variable setter handles cell clicks, arrows and Reset.
tes3.dataHandler = { nonDynamicData = { cells = {
    { id = 'Mod Interior; with punctuation', isInterior = true },
    { id = 'Andrano Ancestral Tomb', isInterior = true },
    { id = 'Balmora, Guild of Mages', isInterior = true },
    { id = 'Balmora, Guild of Mages', isInterior = true },
    { id = 'Tomb outside', isInterior = false },
    { id = '', isInterior = true },
} } }
config.whitelist = ' BALMORA, GUILD OF MAGES; Missing Plugin Interior '
local choices = fields.whitelist.filters[1].callback()
assert(#choices == 4 and choices[1] == 'Andrano Ancestral Tomb')
assert(choices[2] == 'Balmora, Guild of Mages' and choices[3] == 'Missing Plugin Interior')
assert(choices[4] == 'Mod Interior; with punctuation')
assert(fields.whitelist.variable:getter()['Balmora, Guild of Mages'])
enter('Balmora, Guild of Mages', true, true)
local function transfer(key, name, include)
    local variable = fields[key].variable
    local value = variable:getter()
    value[name] = include
    variable:setter(value)
end
transfer('blacklist', 'Balmora, Guild of Mages', true)
assert(not shader.enabled, 'blacklist cell transfer did not apply while paused')
transfer('blacklist', 'Balmora, Guild of Mages', false)
assert(shader.enabled, 'removing cell from blacklist did not apply while paused')
fields.whitelist.variable:setter(fields.whitelist.variable.defaultSetting)
assert(not shader.enabled, 'Reset did not clear the whitelist')
transfer('whitelist', 'Mod Interior; with punctuation', true)
enter('Mod Interior; with punctuation', true, true)
transfer('whitelist', 'Mod Interior; with punctuation', false)
assert(not shader.enabled, 'removing whitelisted cell did not apply while paused')

tes3.player = nil
handlers.cellChanged()
assert(not shader.enabled)
available = false
handlers.loaded()
assert(#logs == 1)
available, loadable = true, false
handlers.loaded()
assert(#logs == 2)
-- MCM close writes a user config, which the next script context reads.
set('density', 85)
fields.whitelist.variable:setter({ ['Balmora, Guild of Mages'] = true })
fields.blacklist.variable:setter({ ['Andrano Ancestral Tomb'] = true })
closeMenu()
available, loadable = true, true
assert(loadfile('00 MWSE/MWSE/mods/UntoDust/main.lua'))()
handlers.modConfigReady()
enter('Balmora, Guild of Mages', true, false) -- Shader loads after the loaded event.
handlers.loaded()
assert(shader.enabled and shader.dustDensity == 0.85, 'saved MCM density lost on restart')
enter('Andrano Ancestral Tomb', true, false)
assert(config.whitelist['Balmora, Guild of Mages'] and config.blacklist['Andrano Ancestral Tomb'])
-- Invalid saved list values are reset before the MCM tries to display them.
saved.whitelist, saved.blacklist = {}, false
assert(loadfile('00 MWSE/MWSE/mods/UntoDust/main.lua'))()
assert(next(config.whitelist) == nil and next(config.blacklist) == nil)
print('PASS MWSE Lua: native cell browsers, complete interior catalogue, transfers and Reset, saved-list migration, live filtering, persistence, shader lifecycle')
