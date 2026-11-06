"""Isolated real-engine cell transition benchmark. No normal settings or saves touched."""
import argparse
import configparser
import json
import os
from pathlib import Path
import re
import statistics
import subprocess

ROOT = Path(__file__).resolve().parent.parent


def percentile(values, fraction):
    ordered = sorted(values)
    return ordered[min(len(ordered) - 1, int((len(ordered) - 1) * fraction))]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--engine', type=Path, required=True)
    parser.add_argument('--data', type=Path, required=True)
    parser.add_argument('--mod', type=Path, default=ROOT / '00 OpenMW')
    parser.add_argument('--label', required=True)
    parser.add_argument('--without-mod', action='store_true')
    parser.add_argument('--shader-profile', type=Path,
                        help='Read post-processing data paths and rendering settings from this config directory')
    args = parser.parse_args()
    if not re.fullmatch(r'[\w-]+', args.label):
        parser.error('label must contain only letters, digits, underscores or hyphens')
    output = ROOT / '.validation-cache/performance' / args.label
    output.mkdir(parents=True, exist_ok=False)
    config = output / 'config'
    config.mkdir()
    user = output / 'user-data'
    (user / 'data').mkdir(parents=True)
    lines = [f'user-data="{user.as_posix()}"', f'data-local="{(user / "data").as_posix()}"',
             f'resources="{(args.engine / "resources").as_posix()}"']
    for folder in [args.engine / 'resources/vfs-mw', args.data, args.mod, ROOT / 'tests/openmw_performance']:
        lines.append(f'data="{folder.resolve().as_posix()}"')
    if args.shader_profile:
        profile_cfg = (args.shader_profile / 'openmw.cfg').read_text(encoding='utf-8-sig')
        lines += [line for line in profile_cfg.splitlines()
                  if line.startswith('data=') and 'PostProcessingShaders' in line]
    lines += ['fallback-archive=Morrowind.bsa', 'content=Morrowind.esm']
    if not args.without_mod:
        lines.append('content=UntoDust.omwscripts')
    lines += ['content=UntoDustPerf.omwscripts', 'no-sound=1', 'no-grab=1', 'skip-menu=1',
              'start=Andrano Ancestral Tomb']
    (config / 'openmw.cfg').write_text('\n'.join(lines), encoding='utf-8')
    (config / 'settings.cfg').write_text('''[Video]
fullscreen = false
resolution x = 1280
resolution y = 720
vsync = false
window border = false
[Post Processing]
enabled = true
transparent postpass = true
''', encoding='utf-8')
    if args.shader_profile:
        profile = configparser.ConfigParser()
        profile.read(args.shader_profile / 'settings.cfg', encoding='utf-8-sig')
        controlled = configparser.ConfigParser()
        controlled.read(config / 'settings.cfg')
        for section, keys in [('Video', ['antialiasing', 'resolution x', 'resolution y']),
                              ('Post Processing', ['chain'])]:
            for key in keys:
                controlled[section][key] = profile[section][key]
        with (config / 'settings.cfg').open('w') as file:
            controlled.write(file)
        shader_settings = args.shader_profile / 'shaders.yaml'
        if shader_settings.exists():
            (config / 'shaders.yaml').write_bytes(shader_settings.read_bytes())
    startup = None
    if os.name == 'nt':
        startup = subprocess.STARTUPINFO()
        startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        startup.wShowWindow = 0
    with (output / 'engine.log').open('w', encoding='utf-8') as log:
        result = subprocess.run([str(args.engine / 'openmw.exe'), '--replace', 'config', '--config', str(config)],
                                cwd=args.engine, stdout=log, stderr=subprocess.STDOUT,
                                startupinfo=startup, timeout=120)
    log = (output / 'engine.log').read_text(encoding='utf-8', errors='replace')
    if result.returncode or 'DUST_PERF_DONE' not in log or re.search(r'\[.* E\]|glCompileShader.*FAILED|glLinkProgram.*FAILED', log):
        raise RuntimeError(f'Engine benchmark failed: {output}')
    rows = []
    for match in re.finditer(r'DUST_PERF\|(\d+)\|(\d+)\|([\d.,]+)', log):
        values = [float(value) for value in match[3].split(',')]
        rows.append(dict(transition=int(match[1]), route=int(match[2]), frames_ms=values,
                         max_ms=max(values), p99_ms=percentile(values, .99)))
    assert len(rows) == 36
    warm = rows[6:]
    summary = {'label': args.label, 'settings': (config / 'settings.cfg').read_text(), 'warm_transitions': len(warm),
               'median_transition_max_ms': statistics.median(r['max_ms'] for r in warm),
               'p95_transition_max_ms': percentile([r['max_ms'] for r in warm], .95),
               'worst_ms': max(r['max_ms'] for r in warm),
               'frames_over_33ms': sum(v > 33.333 for r in warm for v in r['frames_ms']),
               # Interval zero includes the synchronous cell load/unload. The
               # next 19 capture the deferred render-chain rebuild separately.
               'median_postload_peak_ms': statistics.median(max(r['frames_ms'][1:20]) for r in warm),
               'p95_postload_peak_ms': percentile([max(r['frames_ms'][1:20]) for r in warm], .95),
               'postload_intervals_over_16_67ms': sum(v > 1000 / 60 for r in warm for v in r['frames_ms'][1:20]),
               'median_settled_interval_ms': statistics.median(v for r in warm for v in r['frames_ms'][20:]),
               'by_route_median_max_ms': {str(i): statistics.median(r['max_ms'] for r in warm if r['route'] == i)
                                          for i in range(1, 7)}}
    (output / 'results.json').write_text(json.dumps({'summary': summary, 'transitions': rows}, indent=2))
    print(json.dumps(summary, indent=2))


if __name__ == '__main__':
    main()
