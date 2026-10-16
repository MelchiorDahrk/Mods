"""Isolated engine integration checks. Run after create_engine_check.py."""
from pathlib import Path
import sys
from esp import script, encode_record, plugin
import create_engine_check as bridge

ROOT, RUN = bridge.ROOT, bridge.RUN
# Reuse the laboratory cell, without the bridge prototype's request driver.
from esp import records
cell = next(encode_record(t, fs, u, f) for t, fs, u, f in records(RUN / 'FG tests.esp') if t == b'CELL')
driver = script('FG_test_driver', '''Begin FG_test_driver
short stage
float timer
set timer to ( timer + GetSecondsPassed )
if ( timer < 0.3 )
    return
endif
set timer to 0
if ( stage < 3 )
    StartScript mdFG_script_RepairModule
    set stage to ( stage + 1 )
elseif ( stage == 3 )
    Player->StartScript mdFG_script_SummonGizmo
    set stage to 4
elseif ( stage == 4 )
    Player->AddItem "mdFG_integral" 1
    set stage to 5
endif
End
''')
plugin(RUN / 'FG tests.esp', [cell, driver,
    encode_record(b'SSCR', [(b'DATA', b''), (b'NAME', b'FG_test_driver\0')])], [ROOT / '00 Core/Fabricant Guar.ESP'])
(RUN / 'openmw.cfg').write_text((RUN / 'openmw.cfg').read_text().replace(
    'content=FG tests.omwscripts', 'content=Fabricant Guar.omwscripts\ncontent=FG tests.omwscripts'))
(RUN / 'FG tests.omwscripts').write_text('GLOBAL: scripts/gameplay_test.lua\nPLAYER: scripts/gameplay_player.lua\nCREATURE: scripts/gameplay_actor.lua\nMENU: scripts/test_menu.lua\n')
(RUN / 'scripts/gameplay_actor.lua').write_text('''local self = require('openmw.self')
local types = require('openmw.types')
return { eventHandlers = { FGTestKill = function() types.Actor.stats.dynamic.health(self).current = 0 end } }
''')
(RUN / 'scripts/test_menu.lua').write_text('''local menu = require('openmw.menu')
local core = require('openmw.core')
local start = core.getRealTime()
local reloadAt
local saveDir
return { engineHandlers = { onFrame = function()
 if core.getRealTime() - start > 16 then print('FG TEST timeout'); menu.quit() end
 if reloadAt and core.getRealTime() >= reloadAt then
  reloadAt = nil
  local newestSlot, newestTime = nil, -1
  for slot, info in pairs(menu.getSaves(saveDir)) do
   if info.description == 'FG mid-revival' and info.creationTime > newestTime then
    newestSlot, newestTime = slot, info.creationTime
   end
  end
  assert(newestSlot, 'FG TEST FAIL save not found')
  menu.loadGame(saveDir, newestSlot)
 end
end }, eventHandlers = {
 FGTestQuit = function() menu.quit() end,
 FGTestSave = function() menu.saveGame('FG gameplay', 'gameplay') end,
 FGTestSaveReload = function()
  menu.saveGame('FG mid-revival', 'revival')
  saveDir = menu.getCurrentSaveDir()
  reloadAt = core.getRealTime() + 0.15
 end,
} }
''')
(RUN / 'scripts/gameplay_player.lua').write_text('''local I = require('openmw.interfaces')
local core = require('openmw.core')
local self = require('openmw.self')
local now = 0
local count = 0
return { engineHandlers = { onFrame = function()
 if I.UI.getMode() == 'MerchantRepair' and core.getRealTime() - now > 0.15 then
  count = count + 1
  print('FG TEST native repair opened and cancelled ' .. count)
  I.UI.setMode(nil)
  now = core.getRealTime()
 end
end }, eventHandlers = { FGTestPackage = function(data)
 core.sendGlobalEvent('FGTestPackageResult', { actor = self.object, data = data })
end } }
''')
(RUN / 'scripts/gameplay_test.lua').write_text('''local world = require('openmw.world')
local core = require('openmw.core')
local types = require('openmw.types')
local util = require('openmw.util')
local common = require('scripts.FabricantGuar.common')
local player, gizmo, guar, matrix, imperfect, token
local g
local stage, elapsed = 0, 0
local reloaded = false
local loadCount = 0
local function vars(obj) return world.mwscript.getLocalScript(obj).variables end
local function msg(s) print('FG TEST ' .. s) end
local function check(value, name) assert(value, 'FG TEST FAIL ' .. name); msg('PASS ' .. name) end
return { engineHandlers = {
 onSave = function() return {stage = stage, loadCount = loadCount, gizmo = gizmo, matrix = matrix, guar = guar, token = token, imperfect = imperfect} end,
 onLoad = function(data)
  stage, gizmo, matrix, guar, token, imperfect = data.stage, data.gizmo, data.matrix, data.guar, data.token, data.imperfect
  reloaded = true
  loadCount = (data.loadCount or 0) + 1
  msg('loaded lifecycle save ' .. loadCount)
 end,
 onPlayerAdded = function(p)
  player = p; g = world.mwscript.getGlobalVariables()
  if reloaded then return end
  world.createObject('in_hlaalu_room_center'):teleport(p.cell, util.vector3(0,0,0))
  p:teleport(p.cell, util.vector3(0,0,40))
  gizmo = world.getObjectByFormId(core.getFormId('Fabricant Guar.ESP', 1))
  g.mdfg_global_new = 1
  guar = world.createObject('guar')
  guar:teleport(p.cell, util.vector3(150,0,40))
  token = world.createObject('iron dagger')
  token:moveInto(gizmo)
  types.Item.itemData(token).condition = 25
  local damaged = world.createObject('iron dagger')
  types.Item.itemData(damaged).condition = 30
  damaged:moveInto(player)
  world.createObject('gold_001', 1000):moveInto(player)
 end,
 onUpdate = function(dt)
  if stage == 6 and loadCount < 2 and vars(matrix).omwsummon == 2 then
   types.Player.sendMenuEvent(player, 'FGTestSaveReload', {})
   stage = 60
  elseif stage == 60 then stage = 61
  elseif stage == 61 and reloaded then stage = 6 end
  elapsed = elapsed + dt
  if elapsed < 0.6 then return end
  elapsed = 0
  if stage == 0 then
   if world.mwscript.getGlobalScript('fg_test_driver').variables.stage < 5 then return end
   g.mdfg_global_following = 1; g.mdfg_global_muskatomizer = 1
   check(types.Actor.inventory(player):countOf('mdfg_integral') == 1, 'corrected greeting AddItem spelling')
   stage = 1
  elseif stage == 1 then
   check(common.near(gizmo, player, 300), 'whistle moved original reference')
   check(types.Actor.inventory(gizmo):countOf('iron dagger') == 1, 'whistle inventory retained')
   matrix = world.createObject('mdfg_matrix')
   matrix:teleport(player.cell, util.vector3(-200,0,40))
   g.mdfg_global_matrixform = 1
   vars(gizmo).timer = -10000
   gizmo:teleport('toddtest', util.vector3(0,0,0))
   stage = 2
  elseif stage == 2 then
   gizmo.enabled = false
   stage = 21
   types.Player.sendMenuEvent(player, 'FGTestSaveReload', {})
  elseif stage == 21 and reloaded then
   check(not gizmo.enabled and gizmo.cell.name:lower() == 'toddtest', 'disabled Gizmo in storage survives actual save/load')
   vars(matrix).omwsummon = 1
   stage = 3
  elseif stage == 3 then
   check(gizmo.enabled and (gizmo.position - util.vector3(-200,0,40)):length() < 80, 'matrix destination and enabled state')
   check(g.mdfg_global_matrixform == 0, 'matrix reversion flag')
   check(types.Actor.inventory(gizmo):countOf('iron dagger') == 1, 'matrix inventory retained')
   gizmo:sendEvent('FGTestKill', {})
   stage = 4
  elseif stage == 4 then
   check(types.Actor.isDead(gizmo), 'native actor death')
   gizmo.enabled = false
   g.mdfg_global_dead = 1; g.mdfg_global_matrixform = 1; g.mdfg_global_following = 0
   matrix = world.createObject('mdfg_matrix')
   matrix:teleport(player.cell, util.vector3(200,200,40))
   local gem = world.createObject('misc_soulgem_common')
   types.Item.itemData(gem).soul = 'guar'; gem:moveInto(player)
   stage = 5
  elseif stage == 5 then
   vars(matrix).omwrevive = 1; vars(matrix).omwsummon = 1
   stage = 6
  elseif stage == 6 then
   check(not types.Actor.isDead(gizmo) and gizmo.enabled, 'actual resurrection')
   check(types.Actor.inventory(gizmo):countOf('iron dagger') == 1, 'revival inventory no loss or duplicates')
   local found = types.Actor.inventory(gizmo):find('iron dagger')
   check(types.Item.itemData(found).condition == 25, 'revival condition retained')
   check(g.mdfg_global_dead == 0 and g.mdfg_global_following == 1, 'revival globals')
   local health = types.Actor.stats.dynamic.health(gizmo)
   check(health.current == health.base + health.modifier, 'revival full health')
   check(loadCount == 2, 'revival survived actual save/load')
   g.mdfg_global_imperfect = 2
   imperfect = world.createObject('mdfg_imperfect')
   imperfect:teleport(player.cell, util.vector3(-100,200,40))
   stage = 7
  elseif stage == 7 then
   check(g.mdfg_global_imperfect == 0, 'imperfect reversion completes')
   check((gizmo.position - util.vector3(-100,200,40)):length() < 100, 'imperfect source destination')
   check(types.Actor.inventory(gizmo):countOf('iron dagger') == 1, 'imperfect inventory retained')
   msg('COMPLETE lifecycle smoke test')
   types.Player.sendMenuEvent(player, 'FGTestQuit', {})
   stage = 8
  end
 end,
} }
''')
print('Gameplay profile generated:', RUN)
