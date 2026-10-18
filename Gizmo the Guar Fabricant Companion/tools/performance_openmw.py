"""Repeatable real-engine timing/counter comparison in an isolated OpenMW profile.

The baseline is captured before editing gameplay files with --snapshot. Timing
runs never instrument gameplay Lua. --instrument is a separate workload audit;
its timings must not be compared with uninstrumented timings.
"""
import argparse
import ctypes
from ctypes import wintypes
import hashlib
import json
from pathlib import Path
import re
import shutil
import statistics
import struct
import subprocess
import time
import zipfile

from esp import encode_record, field, plugin, records, string

ROOT = Path(__file__).resolve().parents[1]
CACHE = ROOT / 'tools/.cache/performance'
ENGINE = Path('D:/Games/OpenMW/OpenMW 0.51.0 Dev/openmw.exe')
DATA = Path('D:/Games/Morrowind/Data Files')

SCENE = '''local world = require('openmw.world')
local core = require('openmw.core')
local types = require('openmw.types')
local util = require('openmw.util')
local player, gizmo
local elapsed, phase = 0, 0
local counts = {}
return { engineHandlers = {
 onPlayerAdded = function(p)
  player = p
  world.createObject('in_hlaalu_room_center'):teleport(p.cell, util.vector3(0,0,0))
  p:teleport(p.cell, util.vector3(0,0,40))
  types.Actor.spells(p):add('mdfg_ability_lev_real')
  gizmo = world.getObjectByFormId(core.getFormId('Fabricant Guar.ESP',1))
  if not gizmo:isValid() then
   -- The no-Lua control does not have the mod controller to load the placement.
   world.getExteriorCell(6,-9):getAll(types.Creature)
   world.getCellByName('toddtest'):getAll(types.Creature)
   gizmo = world.getObjectByFormId(core.getFormId('Fabricant Guar.ESP',1))
  end
  gizmo:teleport(p.cell, util.vector3(200,0,40))
  types.Actor.spells(gizmo):add('mdfg_ability_lev_real')
  local g=world.mwscript.getGlobalVariables()
  g.mdfg_global_new=0; g.mdfg_global_following=SCENARIO == 'attract' and 1 or 0
  g.mdfg_global_foraging=0; g.mdfg_global_muskatomizer=SCENARIO == 'attract' and 1 or 0
  gizmo:sendEvent('StartAIPackage',{type='Wander',distance=0})
  for i=1,POPULATION do
   local a=world.createObject(SCENARIO == 'attract' and 'fg_perf_guar' or 'fg_perf_rat')
   -- Far actors remain active in this interior but cannot threaten the player.
   local x=((SCENARIO == 'far' or SCENARIO == 'unavailable') and 10000 or 400) + ((i-1)%25)*45
   a:teleport(p.cell,util.vector3(x,300+math.floor((i-1)/25)*45,40))
   types.Actor.spells(a):add('mdfg_ability_lev_real')
  end
  if SCENARIO == 'idle' or SCENARIO == 'unavailable' then gizmo.enabled=false end
 end,
 onUpdate = function(dt)
  elapsed=elapsed+dt
  if gizmo and gizmo:isValid() then
   local script=world.mwscript.getLocalScript(gizmo)
   if script then script.variables.timer=-10000 end
  end
  if phase==0 and elapsed >= WARMUP then
   phase=1; counts={}
   player:sendEvent('FGPerfStart',{})
   if INSTRUMENT then
    core.sendGlobalEvent('FGPerfReset',{})
    for _,a in ipairs(world.activeActors) do a:sendEvent('FGPerfReset',{}) end
   end
  elseif phase==1 and elapsed >= WARMUP+DURATION then
   phase=2; player:sendEvent('FGPerfStop',{})
   if INSTRUMENT then
    core.sendGlobalEvent('FGPerfCollect',{})
    for _,a in ipairs(world.activeActors) do a:sendEvent('FGPerfCollect',{}) end
   end
  elseif phase==2 and elapsed >= WARMUP+DURATION+0.25 then
   phase=3
   if INSTRUMENT then
    for _,actor in ipairs(world.activeActors) do
     for _,role in ipairs({'actor','observer','guar','companion','imperfect'}) do
      if actor:hasScript('scripts/FabricantGuar/'..role..'.lua') then
       local key='active_instances.'..role; counts[key]=(counts[key] or 0)+1
      end
     end
    end
   end
   for k,v in pairs(counts) do print('FG PERF COUNT '..k..' '..v) end
   print('FG TEST COMPLETE performance')
   types.Player.sendMenuEvent(player,'FGPerfQuit',{})
  end
 end,
}, eventHandlers={ FGPerfCounts=function(data)
 for k,v in pairs(data) do counts[k]=(counts[k] or 0)+v end
end } }
'''

PLAYER = '''local core=require('openmw.core')
local self=require('openmw.self')
local types=require('openmw.types')
local frames, sim, started
local function percentile(values,q)
 table.sort(values); return values[math.max(1,math.ceil(#values*q))] or 0
end
return {engineHandlers={onFrame=function(dt)
 if not frames then return end
 frames[#frames+1]=core.getRealFrameDuration(); sim=sim+dt
end},eventHandlers={
 FGPerfStart=function() frames={}; sim=0; started=core.getRealTime() end,
 FGPerfStop=function()
  if not frames then return end
  local n=#frames; local wall=core.getRealTime()-started
  print(string.format('FG PERF TIMING frames=%d wall=%.9f simulation=%.9f median_ms=%.9f p95_ms=%.9f',
   n,wall,sim,percentile(frames,0.5)*1000,percentile(frames,0.95)*1000))
  frames=nil
 end,
} }
'''

INSTRUMENT = '''
local __core = require('openmw.core')
for __group, __handlers in pairs(__result) do
 if __group == 'engineHandlers' or __group == 'eventHandlers' then
  for __name, __handler in pairs(__handlers) do
   __handlers[__name] = function(...)
    local key = '__NAME__.' .. __name
    __counts[key] = (__counts[key] or 0) + 1
    local started = __core.getRealTime()
    local a,b,c = __handler(...)
    __counts[key .. '_seconds'] = (__counts[key .. '_seconds'] or 0) + __core.getRealTime() - started
    return a,b,c
   end
  end
 end
end
__result.eventHandlers = __result.eventHandlers or {}
__result.eventHandlers.FGPerfReset = function() __counts = {} end
__result.eventHandlers.FGPerfCollect = function()
 __core.sendGlobalEvent('FGPerfCounts', __counts)
end
return __result
'''


def snapshot():
    dest = CACHE / 'baseline'
    if not dest.exists():
        dest.mkdir(parents=True)
        fixture = ROOT / 'tools/fixtures/performance-baseline.zip'
        if fixture.exists():
            with zipfile.ZipFile(fixture) as archive:
                for entry in archive.infolist():
                    target = (dest / entry.filename).resolve()
                    assert target.is_relative_to(dest.resolve()), entry.filename
                    target.parent.mkdir(parents=True, exist_ok=True)
                    target.write_bytes(archive.read(entry))
        else:
            for folder in ('01 OpenMW', '01 MWSE'):
                shutil.copytree(ROOT / folder, dest / folder)
    return dest


def prepare(variant, scenario, count, instrument, engine, duration, warmup):
    run = CACHE / 'runs' / f'{variant}-{scenario}-{count}-{"counts" if instrument else "timing"}'
    run.mkdir(parents=True, exist_ok=True)
    (run / 'scripts').mkdir(exist_ok=True)
    source = CACHE / 'baseline/01 OpenMW' if variant == 'baseline' else ROOT / '01 OpenMW'
    overlay = run / 'mod'
    overlay.mkdir(exist_ok=True)
    # Only the manifest and Lua are overlaid; the ESP always uses identical data.
    for src in source.rglob('*'):
        if src.is_file() and src.suffix in ('.lua', '.omwscripts'):
            dest = overlay / src.relative_to(source)
            dest.parent.mkdir(parents=True, exist_ok=True)
            code = src.read_text(encoding='utf-8-sig')
            if instrument and src.suffix == '.lua' and '\nreturn {\n' in code:
                code = 'local __counts = {}\n' + code
                if src.stem == 'global':
                    loop = 'for _, actor in ipairs(world.activeActors) do'
                    code = code.replace(loop, loop + " __counts['global.active_visits']=(__counts['global.active_visits'] or 0)+1;")
                    loop = 'for id, actor in pairs(guarCandidates) do'
                    code = code.replace(loop, loop + " __counts['global.guar_visits']=(__counts['global.guar_visits'] or 0)+1;")
                    loop = 'for id, report in pairs(reports) do'
                    code = code.replace(loop, loop + " __counts['global.report_visits']=(__counts['global.report_visits'] or 0)+1;")
                for name, following in [('inspect', 'observe'), ('reportCombat', 'onUpdate')]:
                    marker = f'local function {following}('
                    if f'local function {name}(' in code and marker in code:
                        wrapper = f'''local __original_{name} = {name}
{name} = function(...)
    local started = core.getRealTime()
    __counts['{src.stem}.inspections'] = (__counts['{src.stem}.inspections'] or 0) + 1
    local a,b,c = __original_{name}(...)
    __counts['{src.stem}.inspection_seconds'] = (__counts['{src.stem}.inspection_seconds'] or 0) + core.getRealTime() - started
    return a,b,c
end

'''
                        code = code.replace(marker, wrapper + marker, 1)
                code = code.replace('\nreturn {\n', '\nlocal __result = {\n', 1)
                code += INSTRUMENT.replace('__NAME__', src.stem)
            dest.write_text(code, encoding='utf-8')
    body = [encode_record(b'CELL', [(b'NAME', b'FG performance laboratory\0'),
                                  (b'DATA', struct.pack('<III', 1, 0, 0))])]
    wanted = {'rat': 'fg_perf_rat', 'guar': 'fg_perf_guar'}
    for tag, fs, unknown, flags in records(DATA / 'Morrowind.esm'):
        if tag == b'CREA' and string(field(fs, b'NAME')).lower() in wanted:
            record_id = wanted[string(field(fs, b'NAME')).lower()]
            fs = [(k, record_id.encode() + b'\0' if k == b'NAME' else
                   bytes(12) if k == b'AIDT' else v) for k, v in fs if k != b'SCRI']
            body.append(encode_record(tag, fs, unknown, flags))
    plugin(run / 'FG performance.esp', body, [DATA / 'Morrowind.esm', ROOT / '00 Core/Fabricant Guar.ESP'])
    definitions = f"local SCENARIO='{scenario}'\nlocal POPULATION={count}\nlocal WARMUP={warmup}\nlocal DURATION={duration}\nlocal INSTRUMENT={'true' if instrument else 'false'}\n"
    (run / 'scripts/perf_global.lua').write_text(definitions + SCENE)
    (run / 'scripts/perf_player.lua').write_text(PLAYER)
    (run / 'scripts/perf_menu.lua').write_text("local menu=require('openmw.menu')\nreturn {eventHandlers={FGPerfQuit=function() menu.quit() end}}\n")
    (run / 'FG performance.omwscripts').write_text('GLOBAL: scripts/perf_global.lua\nPLAYER: scripts/perf_player.lua\nMENU: scripts/perf_menu.lua\n')
    paths = [engine.parent / 'resources/vfs', engine.parent / 'resources/vfs-mw', DATA,
             ROOT / '00 Core', ROOT / '01 OpenMW', overlay, run]
    cfg = ['replace=config', 'replace=data', 'replace=content', 'replace=groundcover',
           'replace=fallback-archive', 'replace=data-local', f'data-local="{run.as_posix()}"',
           f'user-data="{run.as_posix()}"']
    cfg += [f'data="{p.as_posix()}"' for p in paths]
    cfg += [f'content={p}' for p in ['Morrowind.esm', 'Tribunal.esm', 'Bloodmoon.esm',
                                    'Fabricant Guar.ESP', 'Fabricant Guar - OpenMW.esp', 'FG performance.esp']]
    if variant != 'control':
        cfg.append('content=Fabricant Guar.omwscripts')
    cfg += ['content=FG performance.omwscripts']
    cfg += [f'fallback-archive={p}.bsa' for p in ['Morrowind', 'Tribunal', 'Bloodmoon']]
    cfg += ['no-sound=1', 'skip-menu=1', 'start=FG performance laboratory']
    (run / 'openmw.cfg').write_text('\n'.join(cfg) + '\n')
    (run / 'settings.cfg').write_text('[Video]\nresolution x = 640\nresolution y = 480\nfullscreen = false\nvsync = false\nframerate limit = 0\n[Navigator]\nenable = false\n[Lua]\nlua num threads = 0\n')
    return run


class MemoryCounters(ctypes.Structure):
    _fields_ = [('cb', wintypes.DWORD), ('PageFaultCount', wintypes.DWORD)] + [
        (name, ctypes.c_size_t) for name in ('PeakWorkingSetSize', 'WorkingSetSize',
        'QuotaPeakPagedPoolUsage', 'QuotaPagedPoolUsage', 'QuotaPeakNonPagedPoolUsage',
        'QuotaNonPagedPoolUsage', 'PagefileUsage', 'PeakPagefileUsage')]


def execute(run, engine, timeout):
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = 0
    started = time.monotonic()
    with (run / 'process.log').open('w') as output:
        proc = subprocess.Popen([str(engine), '--config', str(run), '--resources', str(engine.parent / 'resources')],
                                stdout=output, stderr=subprocess.STDOUT, startupinfo=startup)
        peak = 0
        try:
            while proc.poll() is None:
                mem = MemoryCounters(); mem.cb = ctypes.sizeof(mem)
                if ctypes.windll.psapi.GetProcessMemoryInfo(wintypes.HANDLE(proc._handle), ctypes.byref(mem), mem.cb):
                    peak = max(peak, mem.PeakWorkingSetSize)
                if time.monotonic() - started > timeout:
                    raise TimeoutError(f'Engine timeout: {run}')
                time.sleep(0.1)
        finally:
            if proc.poll() is None:
                proc.terminate(); proc.wait(timeout=10)
    log = (run / 'openmw.log').read_text(encoding='utf-8', errors='replace')
    if proc.returncode or 'FG TEST COMPLETE performance' not in log or re.search(r'Lua error:|\[scripts/[^]]+\]\s+\w+\s+failed|Not supported handler|FG TEST FAIL', log):
        raise RuntimeError(f'Performance run failed: {run / "openmw.log"}')
    match = re.search(r'FG PERF TIMING ([^\r\n]+)', log)
    assert match, run
    result = {k: float(v) for k, v in re.findall(r'(\w+)=([\d.]+)', match[1])}
    result['peak_working_set_bytes'] = peak
    result['counts'] = {k: float(v) for k, v in re.findall(r'FG PERF COUNT ([\w.]+) ([\d.eE+-]+)', log)}
    return result


def main():
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument('--snapshot', action='store_true')
    parser.add_argument('--variant', choices=['baseline', 'candidate', 'control'], default='baseline')
    parser.add_argument('--scenarios', nargs='+', default=['idle', 'guard', 'far', 'attract'])
    parser.add_argument('--counts', nargs='+', type=int, default=[0, 50, 200, 500])
    parser.add_argument('--repeats', type=int, default=3)
    parser.add_argument('--seconds', type=float, default=5)
    parser.add_argument('--warmup', type=float, default=2)
    parser.add_argument('--instrument', action='store_true')
    parser.add_argument('--engine', type=Path, default=ENGINE)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    if args.snapshot:
        print(snapshot()); return
    if args.variant == 'baseline' and not (CACHE / 'baseline').exists():
        parser.error('Capture --snapshot before changing the mod.')
    samples = []
    output = args.output or CACHE / f'{args.variant}-{"counts" if args.instrument else "timing"}.json'
    source = CACHE / 'baseline/01 OpenMW' if args.variant == 'baseline' else ROOT / '01 OpenMW'
    hashes = {p.relative_to(source).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
              for p in source.rglob('*') if p.is_file()}
    metadata = dict(variant=args.variant, instrumented=args.instrument, engine=str(args.engine),
                    engine_build=(args.engine.parent / 'CI-ID.txt').read_text(encoding='utf-8-sig'),
                    seconds=args.seconds, warmup=args.warmup, source_sha256=hashes)
    for scenario in args.scenarios:
        for count in args.counts:
            run = prepare(args.variant, scenario, count, args.instrument, args.engine, args.seconds, args.warmup)
            for repeat in range(args.repeats):
                result = execute(run, args.engine, args.seconds + args.warmup + 35)
                result.update(scenario=scenario, population=count, repeat=repeat + 1)
                samples.append(result)
                output.parent.mkdir(parents=True, exist_ok=True)
                output.write_text(json.dumps(dict(metadata=metadata, samples=samples), indent=2))
                print(f'{args.variant} {scenario} {count} #{repeat+1}: median={result["median_ms"]:.3f}ms p95={result["p95_ms"]:.3f}ms', flush=True)
    print('Results:', output)


if __name__ == '__main__':
    main()
