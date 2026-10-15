-- Behavior tests for the packaged OpenMW player script, using Lua 5.1/LuaJIT.
local player = { cell = nil }
local enabled, enables, disables, loads = false, 0, 0, 0
local uniforms = {}
local values, subscribers = {}, {}
local page, group
local rendererArguments = {}
local settings = {}
function settings:get(key) return values[key] end
function settings:getCopy(key) return values[key] end
function settings:set(key, value)
    values[key] = value
    for _, callback in ipairs(subscribers) do callback('SettingsUntoDust', key) end
end
package.preload['openmw.storage'] = function()
    return { playerSection = function(key)
        assert(key == 'SettingsUntoDust')
        return settings
    end }
end
function settings:subscribe(callback) subscribers[#subscribers + 1] = callback end
package.preload['openmw.async'] = function()
    return { callback = function(_, callback) return callback end }
end
package.preload['openmw.interfaces'] = function()
    return { Settings = {
        registerPage = function(options) page = options end,
        updateRendererArgument = function(groupKey, settingKey, value)
            assert(groupKey == 'SettingsUntoDust')
            rendererArguments[settingKey] = value
        end,
        registerGroup = function(options)
            group = options
            for _, setting in ipairs(options.settings) do
                if values[setting.key] == nil then values[setting.key] = setting.default end
            end
        end,
    } }
end
local shader = {}
function shader:enable(position)
    assert(position == 1, 'dust should precede lens effects')
    enabled, enables = true, enables + 1
end
function shader:disable() enabled, disables = false, disables + 1 end
function shader:setFloat(name, value)
    assert(name == 'dustDensity' or name == 'dustTime')
    uniforms[name] = value
end
package.preload['openmw.self'] = function() return player end
package.preload['openmw.postprocessing'] = function()
    return { load = function(name)
        assert(name == 'UntoDust')
        loads = loads + 1
        return shader
    end }
end
package.preload['scripts.UntoDust.settings'] = assert(loadfile('00 OpenMW/scripts/UntoDust/settings.lua'))
package.preload['scripts.UntoDust.cellLists'] = assert(loadfile('00 OpenMW/scripts/UntoDust/cellLists.lua'))
local script = assert(loadfile('00 OpenMW/scripts/UntoDust/player.lua'))()
local handlers = script.engineHandlers
script.eventHandlers.UntoDustCells({ 'Andrano Ancestral Tomb', 'Unvisited Mod Interior' })
for _, key in ipairs({ 'whitelist', 'blacklist' }) do
    assert(rendererArguments[key].key == key and rendererArguments[key].ready)
    assert(rendererArguments[key].cells[2] == 'Unvisited Mod Interior')
end
assert(page.key == 'UntoDust' and group.page == page.key)
assert(group.key == 'SettingsUntoDust' and group.permanentStorage)
local control = group.settings[1]
assert(control.key == 'density' and control.default == 32 and control.renderer == 'number')
assert(control.argument.min == 0 and control.argument.max == 100 and control.argument.integer)
local controls = {}
for _, setting in ipairs(group.settings) do controls[setting.key] = setting end
for _, key in ipairs({ 'whitelist', 'blacklist' }) do
    assert(controls[key] and controls[key].renderer == 'UntoDustCells')
    assert(controls[key].name == 'PickerSettingName', 'native side label should not crowd the picker heading')
    assert(type(controls[key].default) == 'table' and next(controls[key].default) == nil)
    assert(type(values[key]) == 'table' and next(values[key]) == nil)
end

local function enter(name, interior, expected)
    player.cell = setmetatable({ name = name, isExterior = not interior }, {
        __index = function(_, key) error('Unsupported OpenMW Cell property: ' .. key) end,
    })
    handlers.onUpdate(1 / 60)
    assert(enabled == expected, name)
end

handlers.onLoad(nil)
handlers.onUpdate(0)
assert(not enabled)
enter('Andrano Ancestral Tomb', true, true)
assert(uniforms.dustDensity == 0.32)
local previousEnables, previousDisables = enables, disables
local time = uniforms.dustTime
for _ = 1, 600 do handlers.onUpdate(1 / 60) end
assert(enables == previousEnables and disables == previousDisables, 'repeated shader-chain changes')
assert(math.abs(uniforms.dustTime - time - 10) < 0.00001)
time = uniforms.dustTime
handlers.onUpdate(0)
assert(uniforms.dustTime == time, 'animation advanced with zero simulation time')

-- Menu changes apply without advancing simulation or entering another cell.
settings:set('density', 85)
assert(enabled and uniforms.dustDensity == 0.85 and uniforms.dustTime == time)
settings:set('density', 0)
assert(not enabled and uniforms.dustDensity == 0)
handlers.onUpdate(10)
assert(uniforms.dustTime == time, 'disabled dust still animated')
settings:set('density', 100)
assert(enabled and uniforms.dustDensity == 1)
settings:set('density', 32)
assert(enabled and uniforms.dustDensity == 0.32, 'reset did not restore default')

for _, name in ipairs({
    'A Modded TOMB', 'Nordic Barrow', 'Modded Crypt', 'Royal Catacombs', 'Ashlander Burial',
}) do enter(name, true, true) end
assert(loads == 1, 'shader loaded more than once')
enter('Another Tomb', true, true)
enter('Tomb outside', false, false)
enter("Uvirith's Grave", true, false)
enter('Balmora, Guild of Mages', true, false)
settings:set('density', 85)
assert(not enabled and uniforms.dustDensity == 0.85, 'MCM enabled dust outside a burial cell')
time = uniforms.dustTime
handlers.onUpdate(10)
assert(uniforms.dustTime == time, 'inactive dust still updates uniforms')

-- A missing cell disables dust immediately and recovers without actor VFX.
enter('Andrano Ancestral Tomb', true, true)
player.cell = nil
handlers.onUpdate(0)
assert(not enabled)
enter('Andrano Ancestral Tomb', true, true)
for _, reset in ipairs({ handlers.onLoad, handlers.onActive }) do
    local cell = player.cell
    reset()
    assert(not enabled)
    player.cell = nil
    handlers.onUpdate(0)
    assert(not enabled)
    player.cell = cell
    handlers.onUpdate(0)
    assert(enabled and uniforms.dustTime == 0)
end
-- A new script context must retain the permanent setting instead of its default.
assert(loadfile('tests/cell_filters.lua'))()(enter, function(key, value)
    settings:set(key, value)
end, function(expected, message)
    assert(enabled == expected, message)
end)
settings:set('density', 85)
settings:set('whitelist', 'Balmora, Guild of Mages')
settings:set('blacklist', 'Andrano Ancestral Tomb')
enter('Balmora, Guild of Mages', true, true)
subscribers = {}
package.loaded['scripts.UntoDust.settings'] = nil
handlers = assert(loadfile('00 OpenMW/scripts/UntoDust/player.lua'))().engineHandlers
handlers.onLoad(nil)
handlers.onUpdate(0)
assert(enabled and uniforms.dustDensity == 0.85, 'persistent density lost on restart')
assert(values.whitelist == 'Balmora, Guild of Mages' and values.blacklist == 'Andrano Ancestral Tomb')
enter('Andrano Ancestral Tomb', true, false)
enter('Balmora, Guild of Mages', true, true)
settings:set('density', -10)
assert(not enabled and uniforms.dustDensity == 0)
settings:set('density', 110)
assert(enabled and uniforms.dustDensity == 1)
print('PASS OpenMW Lua: MCM registration, live density and cell lists while paused, exact matching, blacklist priority, persistence, shader lifecycle')
