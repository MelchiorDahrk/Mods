local core = require('openmw.core')
local util = require('openmw.util')
local world = require('openmw.world')
local elapsed, stage = 0, 'first-person'
local entrances = {
    ['Andrano Ancestral Tomb'] = util.vector3(1376, 7552, 14624),
    ['Samarys Ancestral Tomb'] = util.vector3(-2272, 992, 352),
    ["Balmora, Caius Cosades' House"] = util.vector3(163, -228, 192),
}

local function move(player, cell, position, expected)
    print('UNTO DUST SMOKE: entering ' .. cell)
    player:teleport(cell, position or assert(entrances[cell]), {
        rotation = util.transform.rotateZ(-math.pi / 2),
    })
    player:sendEvent('UntoDustSmokeExpect', expected ~= false)
    elapsed = 0
end

local function lists(player, whitelist, blacklist, expected)
    player:sendEvent('UntoDustSmokeLists', {
        whitelist = whitelist, blacklist = blacklist, expected = expected,
    })
    elapsed = 0
end

return {
    engineHandlers = {
        onUpdate = function(dt)
            local player = world.players[1]
            if not player then return end
            elapsed = elapsed + dt
            if elapsed < 2 then return end
            if stage == 'first-person' then
                assert(player.cell.name == 'Andrano Ancestral Tomb')
                player:sendEvent('UntoDustSmokeView', false)
                player:sendEvent('UntoDustSmokeDensity', 32)
                lists(player, '', '', true)
                print('UNTO DUST SMOKE: running with API revision ' .. core.API_REVISION)
                stage, elapsed = 'third-person', 0
            elseif stage == 'third-person' then
                player:sendEvent('UntoDustSmokeView', true)
                player:sendEvent('UntoDustSmokeDensity', 0)
                stage, elapsed = 'density-off', 0
            elseif stage == 'density-off' then
                player:sendEvent('UntoDustSmokeDensity', 85)
                stage, elapsed = 'blacklist-tomb', 0
            elseif stage == 'blacklist-tomb' then
                lists(player, '', ' ANDRANO ANCESTRAL TOMB ; ', false)
                stage = 'clear-tomb'
            elseif stage == 'clear-tomb' then
                lists(player, '', '', true)
                stage = 'ordinary-interior'
            elseif stage == 'ordinary-interior' then
                move(player, "Balmora, Caius Cosades' House", nil, false)
                stage = 'whitelist-house'
            elseif stage == 'whitelist-house' then
                lists(player, " Uvirith's Grave ; BALMORA, CAIUS COSADES' HOUSE ; ", '', true)
                stage = 'overlap-house'
            elseif stage == 'overlap-house' then
                lists(player, "Balmora, Caius Cosades' House", "Balmora, Caius Cosades' House", false)
                stage = 'clear-house'
            elseif stage == 'clear-house' then
                lists(player, "Balmora, Caius Cosades' House", 'Samarys Ancestral Tomb', true)
                stage = 'exterior'
            elseif stage == 'exterior' then
                move(player, '', util.vector3(-17000, -58000, 1000), false)
                stage = 'second-tomb'
            elseif stage == 'second-tomb' then
                move(player, 'Samarys Ancestral Tomb', nil, false)
                stage = 'first-tomb'
            elseif stage == 'first-tomb' then
                move(player, 'Andrano Ancestral Tomb')
                player:sendEvent('UntoDustSmokeView', false)
                stage = 'save'
            elseif stage == 'save' then
                print('UNTO DUST SMOKE: saving in a tomb')
                player:sendEvent('UntoDustSmokeSave', {})
                stage = 'await-load'
            elseif stage == 'loaded' then
                assert(player.cell.name == 'Andrano Ancestral Tomb')
                print('UNTO DUST SMOKE: save/load completed')
                player:sendEvent('UntoDustSmokeCheckDensity', {})
                player:sendEvent('UntoDustSmokeView', false)
                stage, elapsed = 'loaded-whitelist', 0
            elseif stage == 'loaded-whitelist' then
                move(player, "Balmora, Caius Cosades' House")
                stage = 'loaded-blacklist'
            elseif stage == 'loaded-blacklist' then
                move(player, 'Samarys Ancestral Tomb', nil, false)
                stage = 'finish'
            elseif stage == 'finish' then
                print('UNTO DUST SMOKE PASSED: both views, interior/exterior transitions, live cell lists, blacklist priority, save/load')
                core.quit()
                stage = 'done'
            end
        end,
        onSave = function() return true end,
        onLoad = function(saved)
            if saved then stage, elapsed = 'loaded', 0 end
        end,
    },
}
