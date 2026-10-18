"""Run an isolated OpenMW check without editing the user's configuration."""
import argparse
from pathlib import Path
import subprocess
import re

ROOT = Path(__file__).resolve().parents[1]


def run(engine, config, timeout=45, extra=()):
    config = Path(config).resolve()
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = 0
    args = [str(engine), '--config', str(config), '--resources', str(Path(engine).parent / 'resources'), *extra]
    with (config / 'process.log').open('w') as log:
        proc = subprocess.Popen(args, stdout=log, stderr=subprocess.STDOUT, startupinfo=startup)
        try:
            code = proc.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            proc.terminate()
            code = proc.wait(timeout=10)
            print(f'Engine timeout after {timeout}s; process {proc.pid} stopped.')
    path = config / 'openmw.log'
    text = path.read_text(encoding='utf-8', errors='replace') if path.exists() else ''
    failed = bool(re.search(r'FG TEST (FAIL|timeout)|Lua error:|\[scripts/[^]]+\]\s+\w+\s+failed|Not supported handler', text))
    if 'FG TEST' in text and not any(s in text for s in ('FG TEST COMPLETE', 'FG TEST PASS pending retained')):
        failed = True
    print(f'Engine exit: {code}; log: {path}')
    if failed:
        print('FAIL: integration test did not pass; inspect openmw.log.')
    return 0 if code == 0 and not failed else 1


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--engine', default='D:/Games/OpenMW/OpenMW 0.51.0 Dev/openmw.exe')
    parser.add_argument('--config', default=str(ROOT / 'tools/.cache/engine'))
    parser.add_argument('--timeout', type=int, default=45)
    opts, extra = parser.parse_known_args()
    raise SystemExit(run(opts.engine, opts.config, opts.timeout, extra))
