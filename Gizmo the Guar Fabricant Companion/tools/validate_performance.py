"""Run behavior/save/packaging checks sequentially and record source fingerprints."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys

from performance_openmw import CACHE, ROOT


def main():
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument('--checks', nargs='+', default=['package', 'scope', 'behavior', 'migration',
                                                       'bridge', 'ai', 'lifecycle', 'whistle', 'storage', 'mwse'])
    args = parser.parse_args()
    checks = {
        'package': [('validate_openmw.py', '--lua-dll', 'D:/Games/OpenMW/OpenMW 0.51.0 Dev/lua51.dll')],
        'scope': [('check_openmw_scopes.py',)],
        'behavior': [('check_openmw_behavior.py',)],
        'behavior_threads1': [('check_openmw_behavior.py', '--threads', '1')],
        'migration': [('check_openmw_migration.py',)],
        'migration_threads1': [('check_openmw_migration.py', '--threads', '1')],
        'bridge': [('create_engine_check.py',), ('run_openmw.py',)],
        'ai': [('create_ai_check.py',), ('run_openmw.py', '--timeout', '45')],
        'lifecycle': [('create_gameplay_check.py',), ('run_openmw.py',)],
        'whistle': [('create_whistle_check.py',), ('run_openmw.py',)],
        'storage': [('create_storage_check.py',), ('run_openmw.py',)],
        'mwse': [('check_mwse_performance.py',)],
    }
    log_paths = {name: CACHE / folder / 'openmw.log' for name, folder in [
        ('scope', 'scope-check'), ('behavior', 'behavior'), ('migration', 'migration')]}
    log_paths['behavior_threads1'] = CACHE / 'behavior/openmw.log'
    log_paths['migration_threads1'] = CACHE / 'migration/openmw.log'
    fingerprint = {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
                   for folder in ('00 Core', '01 OpenMW', '01 MWSE')
                   for p in (ROOT / folder).rglob('*') if p.is_file()}
    out = CACHE / 'validation.json'
    existing = json.loads(out.read_text()) if out.exists() else {}
    results = {}
    for name, result in existing.get('checks', {}).items():
        prefixes = ('00 Core/', '01 MWSE/') if name == 'mwse' else ('00 Core/', '01 OpenMW/')
        if name == 'package':
            prefixes = ('00 Core/', '01 OpenMW/', '01 MWSE/')
        old = {p: h for p, h in existing.get('source_sha256', {}).items() if p.startswith(prefixes)}
        current = {p: h for p, h in fingerprint.items() if p.startswith(prefixes)}
        if old == current:
            results[name] = result
    logs = CACHE / 'validation-logs'
    logs.mkdir(parents=True, exist_ok=True)
    for name in args.checks:
        if name not in checks:
            parser.error(f'Unknown check: {name}')
        print('CHECK', name, flush=True)
        output = []
        for command in checks[name]:
            proc = subprocess.run([sys.executable, '-B', str(ROOT / 'tools' / command[0]), *command[1:]],
                                  stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            print(proc.stdout, end='', flush=True)
            output.append(proc.stdout)
            if proc.returncode:
                (logs / f'{name}-process.log').write_text(''.join(output), encoding='utf-8')
                raise SystemExit(proc.returncode)
        path = log_paths.get(name, ROOT / 'tools/.cache/engine/openmw.log')
        if name == 'bridge':
            saves = sorted((ROOT / 'tools/.cache/engine').rglob('*.omwsave'), key=lambda p: p.stat().st_mtime)
            assert saves, 'Bridge save missing'
            proc = subprocess.run([sys.executable, '-B', str(ROOT / 'tools/run_openmw.py'),
                                   '--load-savegame', str(saves[-1])], capture_output=True, text=True)
            output.append(proc.stdout + proc.stderr)
            print(proc.stdout, end='', flush=True)
            if proc.returncode:
                raise SystemExit(proc.returncode)
        (logs / f'{name}-process.log').write_text(''.join(output), encoding='utf-8')
        result = {'passed': True, 'commands': [list(c) for c in checks[name]]}
        if name not in ('package', 'mwse') and path.exists():
            shutil.copy2(path, logs / f'{name}-openmw.log')
            text = path.read_text(encoding='utf-8', errors='replace')
            assert 'FG TEST COMPLETE' in text or 'FG TEST PASS pending retained' in text
            assert 'Lua error:' not in text and 'FG TEST FAIL' not in text and 'callTimer failed' not in text
            result['assertions'] = [line.split('FG TEST PASS ', 1)[1] for line in text.splitlines()
                                    if 'FG TEST PASS ' in line]
        results[name] = result
        out.write_text(json.dumps({'source_sha256': fingerprint, 'checks': results}, indent=2))
        print('PASS', name, flush=True)
    print('Validation record:', out)


if __name__ == '__main__':
    main()
