package.path = '00 OpenMW/?.lua;00 MWSE/MWSE/mods/?.lua;' .. package.path
local files = require('scripts.customweather.regionfiles')
local count = 0
local function test(name, fn)
    local ok, err = pcall(fn)
    assert(ok, name .. ': ' .. tostring(err))
    count = count + 1; print('PASS ' .. name)
end
local function equal(a, b) assert(a == b, tostring(a) .. ' ~= ' .. tostring(b)) end
local function read(path)
    local handle = assert(io.open(path, 'rb'))
    local value = handle:read('*a'); handle:close(); return value
end
local prefix = files.directory

test('portable loader is identical in both engine packages', function()
    equal(read('00 OpenMW/scripts/customweather/regionfiles.lua'),
        read('00 MWSE/MWSE/mods/customweather/regionfiles.lua'))
end)

test('Lua exports round trip all colours and escape arbitrary string content', function()
    local preset = { Clear = { skyDayColor = { 1 / 3, 0, 1 },
        cloudTexture = 'textures/quote"slash\\newline\n0.dds' } }
    -- Invalid texture controls are rejected before export.
    assert(not pcall(files.export, 'Test', preset))
    preset.Clear.cloudTexture = 'textures/quote"slash\\.dds'
    local region = 'A "quoted" \\ region'
    local raw = assert(loadstring(files.export(region, preset)))()
    equal(raw.region, region:lower())
    equal(raw.preset.Clear.skyDayColor[1], 1 / 3)
    equal(raw.preset.Clear.cloudTexture, preset.Clear.cloudTexture)
    assert(not pcall(files.export, 'bad\nregion', preset))
    assert(not pcall(files.export, 'Test', { Clear = { skyDayColor = { math.huge, 0, 0 } } }))
    equal(files.filename('../Bitter Coast Region'), 'bitter_coast_region.lua')
    local data = require('scripts.customweather.common')
    local complete = {}
    for _, name in ipairs(data.names) do
        complete[name] = {}
        for i, field in ipairs(data.fields) do complete[name][field] = { i / 17, 0, 1 } end
    end
    local roundTrip = assert(loadstring(files.export('Test', complete)))().preset
    for _, name in ipairs(data.names) do
        for i, field in ipairs(data.fields) do equal(roundTrip[name][field][1], i / 17) end
    end
end)

test('discovery ignores unrelated files and isolates malformed definitions', function()
    local values = {
        ['a.lua'] = { version = 1, region = 'Test', preset = { Clear = { skyDayColor = { 1, 0, 0 } } } },
        ['b.lua'] = { version = 1, region = 'TEST', preset = { Clear = { skyDayColor = { 0, 1, 0 } } } },
        ['bad.lua'] = { version = 1, region = 'test', preset = { Rain = { skyDayColor = { 5, 0, 0 } } } },
        ['future.lua'] = { version = 2, region = 'test', preset = {} },
    }
    local paths = { prefix .. 'b.lua', prefix .. 'bad.lua', prefix .. 'a.lua', prefix .. 'broken.lua',
        prefix .. 'future.lua', prefix .. 'nested/no.lua', prefix .. 'readme.txt', 'other/a.lua' }
    local warnings, defaults = {}, { Clear = { skyDayColor = { 0.2, 0.3, 0.4 } }, Rain = { fogDayColor = { 0, 0, 0 } } }
    local result = files.load(paths, function(path)
        assert(values[path:sub(#prefix + 1)], 'syntax error'); return values[path:sub(#prefix + 1)]
    end, defaults, nil, function(message) warnings[#warnings + 1] = message end, { ['[Mod] a'] = {} })
    equal(#warnings, 4)
    equal(result.regions.test, '[Mod] b')
    equal(result.presets['[Mod] b'].Clear.skyDayColor[2], 1)
    equal(result.presets['[Mod] b'].Rain.fogDayColor[1], 0)
    assert(result.presets['[Mod] a*'])
    equal(defaults.Clear.skyDayColor[1], 0.2)
end)

test('Azurian Isles interops target the plugin record IDs in both editions', function()
    -- NAME fields from MD_Azurian Isles.esm; FNAM display names include Lyithdonea.
    local regionIds = {
        azurian_isles = 'AZ_Region_Azurian Isles',
        thousand_isles = 'AZ_Region_Thousand Isles',
        scabrous_residuum = 'AZ_Region_Scabrous Residuum',
    }
    local root = 'interops/MD_Azurian Isles/'
    for stem, id in pairs(regionIds) do
        local openmw = dofile(root .. 'scripts/weatheradjust/regions/md_azurian_isles_' .. stem .. '.lua')
        local mwse = dofile(root .. 'MWSE/mods/az/weatheradjust/' .. stem .. '.lua')
        equal(files.definition(openmw).region, id:lower())
        equal(files.definition(mwse).region, id:lower())
        equal(require('scripts.customweather.common').json(openmw.preset),
            require('scripts.customweather.common').json(mwse.preset))
    end
end)

print(string.format('%d region file tests passed.', count))
