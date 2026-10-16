"""Exercise the whistle MWScript in inventory and native dialogue in OpenMW.

The laboratory adds counters around real MessageBox calls. Equip events are
injected through OnPCEquip; native inventory input and prompt buttons still
need manual testing. --baseline reproduces the bug using the original script.
"""
import argparse
from esp import records, field, string, script, encode_record, plugin
import create_engine_check as bridge

ROOT, RUN = bridge.ROOT, bridge.RUN
parser = argparse.ArgumentParser()
parser.add_argument('--baseline', action='store_true')
args = parser.parse_args()
source_path = ROOT / ('00 Core/Fabricant Guar.ESP' if args.baseline else
                      '01 OpenMW/Fabricant Guar - OpenMW.esp')
source = next(string(field(fs, b'SCTX')).replace('\r', '')
              for tag, fs, *_ in records(source_path)
              if tag == b'SCPT' and string(field(fs, b'SCHD')[:32]).lower() == 'mdfg_script_gizmokey')
source = source.replace('short status', 'long testWarnings\nlong testFrames\nlong testPrompts\nshort status', 1)
start = source.index('\nif (')
source = source[:start] + '\nset testFrames to ( testFrames + 1 )\n' + source[start:]
for message in ('Gizmo is dead.', 'Gizmo does not respond while entangled.',
                'Gizmo does not respond while transformed.'):
    source = source.replace(f'MessageBox "{message}"',
                            f'set testWarnings to ( testWarnings + 1 )\nMessageBox "{message}"')
source = source.replace('MessageBox "Call Gizmo?"',
                        'set testPrompts to ( testPrompts + 1 )\nMessageBox "Call Gizmo?"')
cell = next(encode_record(t, fs, u, f) for t, fs, u, f in records(RUN / 'FG tests.esp') if t == b'CELL')
plugin(RUN / 'FG tests.esp', [cell, script('mdFG_script_gizmoKey', source)],
       [ROOT / '00 Core/Fabricant Guar.ESP'])
cfg = RUN / 'openmw.cfg'
cfg.write_text(cfg.read_text().replace('content=FG tests.omwscripts',
               'content=Fabricant Guar.omwscripts\ncontent=FG tests.omwscripts'))
(RUN / 'FG tests.omwscripts').write_text(
    'GLOBAL: scripts/whistle_test.lua\nPLAYER: scripts/whistle_player.lua\nMENU: scripts/test_menu.lua\n')
(RUN / 'scripts/whistle_player.lua').write_text('''local I = require('openmw.interfaces')
local core = require('openmw.core')
return { eventHandlers = { FGTestDialogue = function(actor)
 I.UI.setMode('Dialogue', {target = actor})
end }, engineHandlers = { onFrame = function()
 core.sendGlobalEvent('FGTestMode', I.UI.getMode() or '')
end } }
''')
(RUN / 'scripts/test_menu.lua').write_text('''local menu = require('openmw.menu')
local core = require('openmw.core')
local start = core.getRealTime()
return { engineHandlers = { onFrame = function()
 if core.getRealTime() - start > 15 then print('FG TEST timeout'); menu.quit() end
end }, eventHandlers = { FGTestQuit = function() menu.quit() end } }
''')
(RUN / 'scripts/whistle_test.lua').write_text('''local world = require('openmw.world')
local core = require('openmw.core')
local types = require('openmw.types')
local util = require('openmw.util')
local player, gizmo, key, g
local stage, nextAt, frames = 0, 0, 0
local mode = ''
local done = false
local function check(value, name)
 if not value then
  done = true; types.Player.sendMenuEvent(player, 'FGTestQuit', {})
  error('FG TEST FAIL ' .. name)
 end
 print('FG TEST PASS ' .. name)
end
local function vars(obj) return world.mwscript.getLocalScript(obj).variables end
return { eventHandlers = { FGTestMode = function(value) mode = value end }, engineHandlers = {
 onPlayerAdded = function(p)
  player = p; g = world.mwscript.getGlobalVariables()
  world.createObject('in_hlaalu_room_center'):teleport(p.cell, util.vector3(0,0,0))
  p:teleport(p.cell, util.vector3(0,0,40))
  gizmo = world.getObjectByFormId(core.getFormId('Fabricant Guar.ESP', 1))
  gizmo:teleport(p.cell, util.vector3(200,0,40))
  key = world.createObject('mdfg_key_02'); key:moveInto(p)
  g.mdfg_global_new = 0; g.mdfg_global_following = 0
  nextAt = core.getRealTime() + 0.4
 end,
 onUpdate = function()
  if done or not player or core.getRealTime() < nextAt then return end
  nextAt = core.getRealTime() + 0.3
  local v = vars(key)
  -- Hold the companion's normal world update below its timer threshold, so
  -- the test can independently inspect each unavailable-form warning.
  vars(gizmo).timer = -10000; vars(gizmo).companion = 1
  if stage == 0 then
   check(v.testframes > 1 and v.testwarnings == 0, 'idle inventory script runs without warnings')
   player:sendEvent('FGTestDialogue', gizmo)
  elseif stage == 1 then
   check(mode == 'Dialogue', 'native Gizmo dialogue opened')
   g.mdfg_global_matrixform = 1
   frames = v.testframes
  elseif stage == 2 then
   check(mode == 'Dialogue' and v.testframes > frames + 1, 'inventory script continues during dialogue')
   check(v.testwarnings == 0, 'entering matrix form does not spam dialogue')
   player:sendEvent('SetUiMode', {})
  elseif stage == 3 then
   check(mode == '' and v.testwarnings == 0, 'matrix idle stays quiet after dialogue closes')
   v.onpcequip = 1
  elseif stage == 4 then
   check(v.onpcequip == 0 and v.status == 0 and v.testwarnings == 1,
         'matrix whistle use consumes event and warns once')
  elseif stage == 5 then
   check(v.testwarnings == 1, 'matrix warning does not repeat on later frames')
   v.onpcequip = 1
  elseif stage == 6 then
   check(v.testwarnings == 2, 'second matrix whistle use warns once again')
   g.mdfg_global_matrixform = 0; g.mdfg_global_imperfect = 1
  elseif stage == 7 then
   check(v.testwarnings == 2, 'transformed idle stays quiet')
   v.onpcequip = 1
  elseif stage == 8 then
   check(v.onpcequip == 0 and v.testwarnings == 3, 'transformed whistle use warns once')
  elseif stage == 9 then
   check(v.testwarnings == 3, 'transformed warning does not repeat')
   g.mdfg_global_imperfect = 0; g.mdfg_global_dead = 1
  elseif stage == 10 then
   check(v.testwarnings == 3, 'dead idle stays quiet')
   v.onpcequip = 1
  elseif stage == 11 then
   check(v.onpcequip == 0 and v.testwarnings == 4, 'dead whistle use warns once')
  elseif stage == 12 then
   check(v.testwarnings == 4, 'dead warning does not repeat')
   g.mdfg_global_dead = 0
   player:sendEvent('FGTestDialogue', gizmo)
  elseif stage == 13 then
   check(mode == 'Dialogue', 'dialogue reopened for pending equip check')
   v.onpcequip = 1
  elseif stage == 14 then
   check(v.onpcequip == 1 and v.testprompts == 0, 'whistle use waits until dialogue closes')
   player:sendEvent('SetUiMode', {})
  elseif stage == 15 then
   check(v.onpcequip == 0 and v.testprompts == 1 and v.status == 20,
         'available Gizmo opens the native call prompt after dialogue')
   check(v.testwarnings == 4, 'available Gizmo has no unavailable-form warning')
   print('FG TEST COMPLETE whistle dialogue regression')
   done = true; types.Player.sendMenuEvent(player, 'FGTestQuit', {})
  end
  stage = stage + 1
 end,
} }
''')
print('Whistle profile generated:', RUN, '(original baseline)' if args.baseline else '(patched)')
