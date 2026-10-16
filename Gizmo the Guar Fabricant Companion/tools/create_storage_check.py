"""Exercise real storage upgrade results, level updates, migration, and save/load.

--baseline ESP reads a pre-fix core plugin. It must fail at the second upgrade
(ModStrength's 100 cap).
The harness executes the original INFO result bodies on Gizmo; dialogue button
navigation and the original Morrowind executable remain manual checks.
"""
import argparse
from pathlib import Path
from esp import records, field, string, script, encode_record, plugin
import create_engine_check as bridge

ROOT, RUN = bridge.ROOT, bridge.RUN
parser = argparse.ArgumentParser()
parser.add_argument('--baseline', type=Path, metavar='ESP', help='pre-fix core plugin to reproduce the failure')
args = parser.parse_args()
source = args.baseline or ROOT / '00 Core/Fabricant Guar.ESP'
recs = list(records(source))
cell = next(encode_record(t, fs, u, f) for t, fs, u, f in records(RUN / 'FG tests.esp') if t == b'CELL')
body = [cell]
if args.baseline:
    fs = next(fs for t, fs, *_ in recs if t == b'SCPT'
              and string(field(fs, b'SCHD')[:32]).lower() == 'mdfg_script_gizmo')
    body.append(script('mdFG_script_gizmo', string(field(fs, b'SCTX')).replace('\r', '')))
ids = ('8370743075113210', '3004223443178475751', '16709141131934011502')
commands = []
for tier, id_ in enumerate(ids, 1):
    fs = next(fs for t, fs, *_ in recs if t == b'INFO' and string(field(fs, b'INAM')) == id_)
    name = f'FG_storage_upgrade{tier}'
    result = string(field(fs, b'BNAM')).replace('\r', '')
    body.append(script(name, f'Begin {name}\n{result}\nStopScript {name}\nEnd\n'))
    commands.append(f'if ( command == {tier} )\n    "mdFG_gizmo"->StartScript {name}')
commands += ['''if ( command == 10 )
    "mdFG_gizmo"->AiWander 0 0 0
    "mdFG_gizmo"->SetStrength 100''']
for level in (1, 25, 50):
    commands.append(f'''if ( command == {100 + level} )
    Player->SetLevel {level}
    "mdFG_gizmo"->AiFollow Player 0 0 0 0''')
driver = ('Begin FG_storage_driver\nshort command\n' +
          '\nelse'.join(commands) + '\nendif\nset command to 0\nEnd\n')
body += [script('FG_storage_driver', driver),
         encode_record(b'SSCR', [(b'DATA', b''), (b'NAME', b'FG_storage_driver\0')])]
plugin(RUN / 'FG tests.esp', body, [ROOT / '00 Core/Fabricant Guar.ESP'])
cfg = RUN / 'openmw.cfg'
cfg.write_text(cfg.read_text().replace('content=FG tests.omwscripts',
               'content=Fabricant Guar.omwscripts\ncontent=FG tests.omwscripts'))
(RUN / 'FG tests.omwscripts').write_text(
    'GLOBAL: scripts/storage_test.lua\nCREATURE: scripts/storage_actor.lua\nMENU: scripts/test_menu.lua\n')
(RUN / 'scripts/storage_actor.lua').write_text('''local self = require('openmw.self')
local types = require('openmw.types')
return { eventHandlers = { FGStorageEffects = function(data)
 local strength = types.Actor.stats.attributes.strength(self)
 strength.damage = data.damage; strength.modifier = data.modifier
end } }
''')
(RUN / 'scripts/test_menu.lua').write_text('''local menu = require('openmw.menu')
local core = require('openmw.core')
local start, reloadAt, saveDir = core.getRealTime()
return { engineHandlers = { onFrame = function()
 if core.getRealTime() - start > 25 then print('FG TEST timeout'); menu.quit() end
 if reloadAt and core.getRealTime() >= reloadAt then
  reloadAt = nil
  for slot, info in pairs(menu.getSaves(saveDir)) do
   if info.description == 'FG storage regression' then menu.loadGame(saveDir, slot); return end
  end
  error('FG TEST FAIL storage save missing')
 end
end }, eventHandlers = {
 FGTestQuit = function() menu.quit() end,
 FGStorageSaveReload = function()
  menu.saveGame('FG storage regression', 'storage')
  saveDir = menu.getCurrentSaveDir(); reloadAt = core.getRealTime() + 0.2
 end,
} }
''')
(RUN / 'scripts/storage_test.lua').write_text('''local world = require('openmw.world')
local core = require('openmw.core')
local types = require('openmw.types')
local util = require('openmw.util')
local player, gizmo, globals
local stage, nextAt, reloaded, done = 1, 0, false, false
local function vars() return world.mwscript.getLocalScript(gizmo).variables end
local function command(value) world.mwscript.getGlobalScript('fg_storage_driver').variables.command = value end
local function check(value, name)
 if not value then
  done = true; types.Player.sendMenuEvent(player, 'FGTestQuit', {})
  error('FG TEST FAIL ' .. name)
 end
 print('FG TEST PASS ' .. name)
end
local function capacity(expected, name)
 local strength = types.Actor.stats.attributes.strength(gizmo)
 check(strength.base * core.getGMST('fEncumbranceStrMult') == expected,
       name .. ' capacity=' .. tostring(strength.base * core.getGMST('fEncumbranceStrMult')))
end
local steps = {
 function()
  vars().companion = 1
  capacity(250, 'unupgraded')
  command(1)
 end,
 function()
  capacity(500, 'first purchased tier')
  check(globals.mdfg_global_storage == 100 and types.Actor.inventory(player):countOf('ingred_adamantium_ore_01') == 15,
        'first upgrade costs three ore and records tier')
  command(2)
 end,
 function()
  capacity(750, 'second purchased tier')
  check(globals.mdfg_global_storage == 200 and types.Actor.inventory(player):countOf('ingred_adamantium_ore_01') == 9,
        'second upgrade costs six ore and records tier')
  command(3)
 end,
 function()
  capacity(1000, 'third purchased tier')
  check(globals.mdfg_global_storage == 300 and types.Actor.inventory(player):countOf('ingred_adamantium_ore_01') == 0,
        'third upgrade costs nine ore and records tier')
  vars().companion = 0; command(101)
 end,
 function()
  capacity(1000, 'level one refresh')
  check(types.Actor.stats.level(gizmo).current == 1 and types.Actor.stats.dynamic.health(gizmo).base == 1000,
        'original level and health scaling retained at level one')
  vars().companion = 0; command(125)
 end,
 function()
  capacity(1000, 'level twenty-five refresh')
  check(types.Actor.stats.level(gizmo).current == 25 and types.Actor.stats.dynamic.health(gizmo).base == 25000,
        'original level and health scaling retained at level twenty-five')
  vars().companion = 0; command(150)
 end,
 function()
  capacity(1000, 'level fifty refresh')
  vars().companion = 1; vars().storagestrength = 0
  globals.mdfg_global_storage = 100; globals.mdfg_global_following = 0; command(10)
 end,
 function()
  capacity(500, 'existing first-tier save while stationary')
  vars().storagestrength = 0; globals.mdfg_global_storage = 200; command(10)
 end,
 function()
  capacity(750, 'existing second-tier save while stationary')
  vars().storagestrength = 0; globals.mdfg_global_storage = 300; command(10)
 end,
 function()
  capacity(1000, 'existing third-tier save while stationary')
  gizmo:sendEvent('FGStorageEffects', {damage = 10, modifier = 25})
 end,
 function()
  local strength = types.Actor.stats.attributes.strength(gizmo)
  check(strength.base == 200 and strength.damage == 10 and strength.modifier == 25,
        'idle storage sync preserves attribute damage and modifiers')
  gizmo:sendEvent('FGStorageEffects', {damage = 0, modifier = 0})
 end,
 function()
  types.Player.sendMenuEvent(player, 'FGStorageSaveReload', {})
 end,
 function()
  if not reloaded then stage = stage - 1; return end
  capacity(1000, 'actual save and reload')
  check(globals.mdfg_global_storage == 300 and vars().storagestrength == 200,
        'purchased tier and cached storage strength survive reload')
  print('FG TEST COMPLETE storage regression')
  done = true; types.Player.sendMenuEvent(player, 'FGTestQuit', {})
 end,
}
return { engineHandlers = {
 onSave = function() return {stage = stage, gizmo = gizmo} end,
 onLoad = function(data) stage = data.stage; gizmo = data.gizmo; reloaded = true end,
 onPlayerAdded = function(p)
  player = p; globals = world.mwscript.getGlobalVariables()
  nextAt = core.getRealTime() + 0.8
  if reloaded then return end
  world.createObject('in_hlaalu_room_center'):teleport(p.cell, util.vector3(0,0,0))
  p:teleport(p.cell, util.vector3(0,0,40))
  gizmo = world.getObjectByFormId(core.getFormId('Fabricant Guar.ESP', 1))
  gizmo:teleport(p.cell, util.vector3(200,0,40))
  globals.mdfg_global_new = 0
  globals.mdfg_global_following = 0; globals.mdfg_global_storage = 0
  world.createObject('ingred_adamantium_ore_01', 18):moveInto(p)
 end,
 onUpdate = function()
  if done or not player or core.getRealTime() < nextAt then return end
  nextAt = core.getRealTime() + 0.5
  steps[stage](); stage = stage + 1
 end,
} }
''')
print('Storage profile generated:', RUN, '(original baseline)' if args.baseline else '(fixed core)')
