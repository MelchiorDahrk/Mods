"""Create the repeatable MWScript bridge prototype in an isolated profile."""
from pathlib import Path
import struct
from esp import encode_record, script, plugin

ROOT = Path(__file__).resolve().parents[1]
RUN = ROOT / 'tools/.cache/engine'
RUN.mkdir(parents=True, exist_ok=True)
(RUN / 'scripts').mkdir(exist_ok=True)
body = [encode_record(b'CELL', [(b'NAME', b'FG Lua laboratory\0'),
    (b'DATA', struct.pack('<III', 1, 0, 0))]), script('FG_test_driver', '''Begin FG_test_driver
short stage
float timer
set timer to ( timer + GetSecondsPassed )
if ( timer < 0.15 )
    return
endif
set timer to 0
if ( stage < 4 )
    StartScript mdFG_script_RepairModule
    StartScript mdFG_script_RepairModule
    set stage to ( stage + 1 )
elseif ( stage == 4 )
    Player->StartScript mdFG_script_SummonGizmo
    set stage to 5
endif
End
'''), encode_record(b'SSCR', [(b'DATA', b''), (b'NAME', b'FG_test_driver\0')])]
plugin(RUN / 'FG tests.esp', body, [ROOT / '00 Core/Fabricant Guar.ESP'])
(RUN / 'FG tests.omwscripts').write_text('GLOBAL: scripts/bridge_test.lua\nMENU: scripts/test_menu.lua\n')
(RUN / 'scripts/bridge_test.lua').write_text('''local world = require('openmw.world')
local types = require('openmw.types')
local count, elapsed, saved = 0, 0, false
return { engineHandlers = {
 onLoad = function(data) count = data.count; saved = true; print('FG TEST loaded count=' .. count) end,
 onSave = function() return { count = count } end,
 onUpdate = function(dt)
  elapsed = elapsed + dt
  local r = world.mwscript.getGlobalScript('mdfg_script_repairmodule')
  local driver = world.mwscript.getGlobalScript('fg_test_driver')
  if r and r.variables.pending > 0 and count < 3 then
   assert(not r.isRunning, 'request did not stop')
   count = count + r.variables.pending
   print('FG TEST repair accepted=' .. count .. ' caller=' .. tostring(r.object))
   r.variables.pending = 0
  end
  local s = world.mwscript.getGlobalScript('mdfg_script_summongizmo')
  if s and s.variables.pending > 0 and not saved then
   assert(s.object == world.players[1], 'summon lost player caller')
   assert(r.variables.pending == 1, 'fourth repair request not retained')
   assert(count == 3, 'rapid StartScript must coalesce per engine semantics')
   print('FG TEST PASS repeated requests, coalescing, stopped locals, summon caller')
   types.Player.sendMenuEvent(world.players[1], 'FGTestSave', {})
   saved = true
  end
  if elapsed > 2 and saved then
   assert(count == 3 and r.variables.pending == 1, 'pending lost on load')
   print('FG TEST PASS pending retained; summon object=' .. tostring(s.object))
   print('FG TEST persisted pending=' .. r.variables.pending)
   types.Player.sendMenuEvent(world.players[1], 'FGTestQuit', {})
  end
 end,
} }
''')
(RUN / 'scripts/test_menu.lua').write_text('''local menu = require('openmw.menu')
return { eventHandlers = {
 FGTestSave = function() menu.saveGame('FG bridge pending request', 'bridge'); print('FG TEST saving') end,
 FGTestQuit = function() print('FG TEST quitting'); menu.quit() end,
} }
''')
paths = ['D:/Games/OpenMW/OpenMW 0.51.0 Dev/resources/vfs',
         'D:/Games/OpenMW/OpenMW 0.51.0 Dev/resources/vfs-mw',
         'D:/Games/Morrowind/Data Files', str(ROOT / '00 Core'), str(ROOT / '01 OpenMW'), str(RUN)]
cfg = ['replace=config', 'replace=data', 'replace=content', 'replace=groundcover',
       'replace=fallback-archive', 'replace=data-local', f'data-local="{RUN.as_posix()}"',
       f'user-data="{RUN.as_posix()}"']
cfg += [f'data="{Path(p).as_posix()}"' for p in paths]
cfg += ['content=' + p for p in ['Morrowind.esm', 'Tribunal.esm', 'Bloodmoon.esm',
        'Fabricant Guar.ESP', 'Fabricant Guar - OpenMW.esp', 'FG tests.esp', 'FG tests.omwscripts']]
cfg += ['fallback-archive=' + p + '.bsa' for p in ['Morrowind', 'Tribunal', 'Bloodmoon']]
cfg += ['no-sound=1', 'skip-menu=1', 'start=FG Lua laboratory', 'script-all=1', 'script-all-dialogue=1']
(RUN / 'openmw.cfg').write_text('\n'.join(cfg) + '\n')
(RUN / 'settings.cfg').write_text('''[Video]
resolution x = 640
resolution y = 480
fullscreen = false
vsync = false
[Navigator]
enable = false
[Lua]
lua num threads = 0
''')
print(RUN)
