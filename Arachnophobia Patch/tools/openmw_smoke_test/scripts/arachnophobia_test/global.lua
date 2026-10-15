local core = require 'openmw.core'
local world = require 'openmw.world'
local types = require 'openmw.types'
local util = require 'openmw.util'
local I = require 'openmw.interfaces'
local expected = require 'scripts.arachnophobia_test.cases'
local sources, exclusions = {}, {}
local frames, stage = 0, 'spawn'
local destinationCounts = {}
local function check(condition, message)
  if not condition then error('ARACHNOPHOBIA TEST FAILED: ' .. message) end
end
local function countDestinations()
  local counts = {}
  for _, actor in ipairs(world.activeActors) do
    if actor.enabled and destinationCounts[actor.recordId] then
      check(math.abs(actor.scale - 1.25) < 0.001, 'replacement scale was not preserved: ' .. actor.recordId)
      counts[actor.recordId] = (counts[actor.recordId] or 0) + 1 end
  end
  return counts
end
local function verify()
  local counts = countDestinations()
  for _, case in ipairs(sources) do
    check(case.object:isValid() and not case.object.enabled, 'source was not disabled: ' .. case.id)
  end
  for _, object in ipairs(exclusions) do
    check(object:isValid(), 'excluded actor was deleted: ' .. object.recordId)
    -- Quest centurions may disable themselves through their original MWScript.
    -- Replacement counts below still detect an unwanted SSS swap.
    if not object.recordId:find('^centurion_spider_') then
      check(object.enabled, 'excluded actor was replaced: ' .. object.recordId)
    end
    if object.recordId == 'centurion_spider' then check(types.Actor.isDead(object), 'corpse became alive') end
  end
  for id, count in pairs(destinationCounts) do
    check(counts[id] == count, 'wrong replacement count for ' .. id .. ': ' .. tostring(counts[id]))
  end
end
local function spawn()
  print('ARACHNOPHOBIA TEST: API revision ' .. core.API_REVISION)
  check(I.StaticSwitcher_G ~= nil, 'SSS global interface missing')
  local player = world.players[1]
  for n, case in ipairs(expected) do
    local object = world.createObject(case[1])
    object:setScale(1.25)
    object:teleport(player.cell, player.position + util.vector3(80 * n, 0, 0))
    sources[#sources + 1] = {object=object, id=case[1]}
    destinationCounts[case[2]] = (destinationCounts[case[2]] or 0) + 1
  end
  for _, id in ipairs({'centurion_spider_tga1', 'centurion_spider_tga2', 'centurion_spider_nchur', 'ab_fau_spiderparasol', 't_dae_cre_spiderdae_02'}) do
    local object = world.createObject(id)
    object:teleport(player.cell, player.position + util.vector3(0, 200, 0))
    exclusions[#exclusions + 1] = object
  end
  local dead = world.createObject('centurion_spider')
  dead:addScript('scripts/arachnophobia_test/dead.lua')
  dead:teleport(player.cell, player.position + util.vector3(0, 400, 0))
  exclusions[#exclusions + 1] = dead
  print('ARACHNOPHOBIA TEST: spawned ' .. #sources .. ' sources and ' .. #exclusions .. ' exclusions')
end
return {
  engineHandlers = {
    onUpdate = function()
      frames = frames + 1
      if not world.players[1] then return end
      local ok, err = pcall(function()
      if stage == 'spawn' then
        spawn(); stage = 'verify'; frames = 0
      elseif stage == 'verify' and frames == 60 then
        verify()
        print('ARACHNOPHOBIA TEST: initial replacement and exclusions passed')
        world.players[1]:sendEvent('ArachnophobiaSave', {})
        stage = 'await-load'
      elseif stage == 'loaded' and frames == 60 then
        verify()
        world.players[1]:teleport('Balmora, South Wall Cornerclub', util.vector3(0, 0, 128))
        stage = 'away'; frames = 0
      elseif stage == 'away' and frames == 60 then
        world.players[1]:teleport(sources[1].object.cell, util.vector3(0, 0, 128))
        stage = 'returned'; frames = 0
      elseif stage == 'returned' and frames == 60 then
        verify()
        print('ARACHNOPHOBIA TEST: cell re-entry passed')
        sources[1].object.enabled = true
        stage = 'reenabled'; frames = 0
      elseif stage == 'reenabled' and frames == 60 then
        check(sources[1].object.enabled, 'saved once-cache did not suppress reapplication')
        local counts = countDestinations()
        for id, count in pairs(destinationCounts) do check(counts[id] == count, 'duplicate replacement after reactivation') end
        sources[1].object.enabled = false
        print('ARACHNOPHOBIA TEST PASSED: 15 replacements, 6 exclusions, scales, save/load, cell re-entry, and saved once-cache')
        core.quit()
        stage = 'done' 
      end
      end)
      if not ok then print(tostring(err)); stage = 'done'; core.quit() end
    end,
    onSave = function() return {sources=sources, exclusions=exclusions, destinationCounts=destinationCounts} end,
    onLoad = function(data)
      if data then
        sources=data.sources; exclusions=data.exclusions; destinationCounts=data.destinationCounts
        stage='loaded'; frames=0
      end
    end
  }
}
