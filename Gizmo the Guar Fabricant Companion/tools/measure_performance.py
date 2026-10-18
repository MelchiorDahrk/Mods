"""Run the timing and separate counter matrices sequentially; never two engines."""
import json
import hashlib
import subprocess
import sys
from performance_openmw import CACHE, ROOT


def measure(*args):
    subprocess.run([sys.executable, '-B', str(ROOT / 'tools/performance_openmw.py'), *args], check=True)

def complete(name, variant, count, instrumented=False):
    path = CACHE / name
    if not path.exists():
        return False
    data = json.loads(path.read_text())
    source = (CACHE / 'baseline' if variant == 'baseline' else ROOT) / '01 OpenMW'
    hashes = {p.relative_to(source).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
              for p in source.rglob('*') if p.is_file()}
    return (len(data['samples']) == count and data['metadata']['variant'] == variant
            and data['metadata']['instrumented'] == instrumented
            and data['metadata']['source_sha256'] == hashes)


def main():
    validation = json.loads((CACHE / 'validation.json').read_text())
    required = {'package', 'behavior', 'migration', 'bridge', 'ai', 'lifecycle', 'whistle', 'storage', 'mwse'}
    assert required <= validation['checks'].keys()
    assert all(validation['checks'][name]['passed'] for name in required)
    baseline = CACHE / 'baseline-timing.json'
    if not complete('baseline-timing.json', 'baseline', 48):
        measure('--variant', 'baseline', '--output', str(baseline))
    if not complete('baseline-unavailable.json', 'baseline', 12):
        measure('--variant', 'baseline', '--scenarios', 'unavailable',
                '--output', str(CACHE / 'baseline-unavailable.json'))
    if not complete('candidate-timing.json', 'candidate', 60):
        measure('--variant', 'candidate', '--scenarios', 'idle', 'guard', 'far', 'attract', 'unavailable',
                '--output', str(CACHE / 'candidate-timing.json'))
    if not complete('control-timing.json', 'control', 18):
        measure('--variant', 'control', '--scenarios', 'guard', 'far', 'unavailable', '--counts', '200', '500',
                '--output', str(CACHE / 'control-timing.json'))
    for variant in ('baseline', 'candidate'):
        if not complete(f'{variant}-counts.json', variant, 5, True):
            measure('--variant', variant, '--scenarios', 'idle', 'guard', 'far', 'attract', 'unavailable',
                    '--counts', '200', '--repeats', '1', '--instrument',
                    '--output', str(CACHE / f'{variant}-counts.json'))
    if not (CACHE / 'paired-timing.json').exists():
        subprocess.run([sys.executable, '-B', str(ROOT / 'tools/paired_performance.py')], check=True)
    subprocess.run([sys.executable, '-B', str(ROOT / 'tools/report_performance.py')], check=True)


if __name__ == '__main__':
    main()
