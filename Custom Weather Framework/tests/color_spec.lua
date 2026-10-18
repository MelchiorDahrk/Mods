package.path = '00 OpenMW/?.lua;00 MWSE/MWSE/mods/?.lua;' .. package.path
local color = require('scripts.customweather.color')
local count = 0
local function test(name, fn)
    local ok, err = pcall(fn)
    assert(ok, name .. ': ' .. tostring(err))
    count = count + 1; print('PASS ' .. name)
end
local function near(a, b) assert(math.abs(a - b) < 1e-12, tostring(a) .. ' ~= ' .. tostring(b)) end
test('both engines ship identical colour math and picker textures', function()
    local function read(path)
        local file = assert(io.open(path, 'rb')); local value = file:read('*a'); file:close(); return value
    end
    assert(read('00 OpenMW/scripts/customweather/color.lua') == read('00 MWSE/MWSE/mods/customweather/color.lua'))
    for _, name in ipairs { 'sv', 'hue', 'cursor' } do
        local path = '/textures/customweather/' .. name .. '.dds'
        assert(read('00 OpenMW' .. path) == read('00 MWSE' .. path))
    end
end)
test('HSV round trips primaries, neutrals, black and intermediate colours', function()
    for r = 0, 10 do for g = 0, 10 do for b = 0, 10 do
        local rgb = { r / 10, g / 10, b / 10 }
        local result = color.toRGB(color.toHSV(rgb))
        for i = 1, 3 do near(result[i], rgb[i]) end
    end end end
    near(color.toHSV({ 0.5, 0.5, 0.5 }, 0.7)[1], 0.7)
    near(color.toHSV({ 0, 0, 0 }, 1)[1], 1)
end)
test('RGB and hex entry accept exact values and reject malformed input', function()
    assert(color.hex(color.parse('#26a6bf')) == '#26A6BF')
    assert(color.label(color.parse('38, 166, 191')) == 'rgb(38, 166, 191)')
    near(color.parse('rgb(127.5, 0, 255)')[1], 0.5)
    for _, value in ipairs { '', '#fff', '#ffffffff', 'rgba(1,2,3,1)', '-1,2,3', '256,0,0', '1,2', 'nan,0,0', '1..2,0,0' } do
        assert(color.parse(value) == nil, value)
    end
end)
print(string.format('%d colour picker tests passed.', count))
