"""Save with the unmodified baseline during revival, restart with new Lua, finish.

This is a real cross-version save, not a synthetic onLoad table. All profiles,
saves and logs remain in tools/.cache/performance/migration.
"""
from pathlib import Path
import argparse
import re
import shutil
import subprocess
import sys

from performance_openmw import CACHE, ENGINE, ROOT
from run_openmw import run as run_engine


def main():
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument('--threads', type=int, choices=(0, 1), default=0)
    args = parser.parse_args()
    subprocess.run([sys.executable, '-B', str(ROOT / 'tools/create_gameplay_check.py')], check=True)
    source = ROOT / 'tools/.cache/engine'
    dest = CACHE / 'migration'
    dest.mkdir(parents=True, exist_ok=True)
    for name in ('FG tests.esp', 'FG tests.omwscripts', 'settings.cfg'):
        shutil.copy2(source / name, dest / name)
    settings = dest / 'settings.cfg'
    settings.write_text(settings.read_text().replace('lua num threads = 0', f'lua num threads = {args.threads}'))
    shutil.copytree(source / 'scripts', dest / 'scripts', dirs_exist_ok=True)
    cfg = (source / 'openmw.cfg').read_text().replace(source.as_posix(), dest.as_posix())
    old_cfg = cfg.replace((ROOT / '01 OpenMW').as_posix(), (CACHE / 'baseline/01 OpenMW').as_posix())
    (dest / 'openmw.cfg').write_text(old_cfg)
    menu = (dest / 'scripts/test_menu.lua').read_text()
    # The first save/reload stores disabled Gizmo. The second stores the pending
    # native-resurrection/inventory transaction. Stop the old engine there.
    old_menu = menu.replace('local reloadAt', 'local crossSaves = 0\nlocal reloadAt')
    old_menu = old_menu.replace('reloadAt = nil\n', "reloadAt = nil\n  if crossSaves == 2 then print('FG MIGRATION SAVED'); menu.quit(); return end\n", 1)
    old_menu = old_menu.replace('FGTestSaveReload = function()', 'FGTestSaveReload = function()\n  crossSaves = crossSaves + 1')
    (dest / 'scripts/test_menu.lua').write_text(old_menu)
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = 0
    with (dest / 'baseline-process.log').open('w') as output:
        proc = subprocess.run([str(ENGINE), '--config', str(dest), '--resources', str(ENGINE.parent / 'resources')],
                              stdout=output, stderr=subprocess.STDOUT, startupinfo=startup, timeout=40)
    log = (dest / 'openmw.log').read_text(encoding='utf-8', errors='replace')
    (dest / 'baseline-openmw.log').write_text(log, encoding='utf-8')
    assert proc.returncode == 0 and 'FG MIGRATION SAVED' in log and 'FG TEST FAIL' not in log, dest
    saves = sorted(dest.rglob('*.omwsave'), key=lambda p: p.stat().st_mtime)
    assert saves, 'No baseline save created'
    saved = saves[-1]
    print('Baseline save captured:', saved, flush=True)
    (dest / 'openmw.cfg').write_text(cfg)
    (dest / 'scripts/test_menu.lua').write_text(menu)
    driver = (dest / 'scripts/gameplay_test.lua').read_text()
    driver = driver.replace("msg('COMPLETE lifecycle smoke test')", """for _, actor in ipairs(world.activeActors) do
    check(not actor:hasScript('scripts/FabricantGuar/actor.lua'), 'legacy script removed from active actor '..actor.recordId)
   end
   check(gizmo:hasScript('scripts/FabricantGuar/companion.lua'), 'original Gizmo owns scoped restoration script')
   msg('COMPLETE lifecycle smoke test; real baseline-to-scoped migration')""")
    (dest / 'scripts/gameplay_test.lua').write_text(driver)
    result = run_engine(ENGINE, dest, timeout=40, extra=('--load-savegame', str(saved)))
    log = (dest / 'openmw.log').read_text(encoding='utf-8', errors='replace')
    assert 'real baseline-to-scoped migration' in log and 'FG TEST FAIL' not in log
    raise SystemExit(result)


if __name__ == '__main__':
    main()
