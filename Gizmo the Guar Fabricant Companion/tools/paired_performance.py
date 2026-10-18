"""Interleave baseline/candidate processes to check timing drift in a quiet scene."""
import hashlib
import json
from performance_openmw import CACHE, ENGINE, ROOT, execute, prepare


def main():
    samples = []
    sources = {}
    for variant in ('baseline', 'candidate'):
        source = (CACHE / 'baseline' if variant == 'baseline' else ROOT) / '01 OpenMW'
        sources[variant] = {p.relative_to(source).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
                            for p in source.rglob('*') if p.is_file()}
    for pair in range(3):
        order = ('baseline', 'candidate') if pair % 2 == 0 else ('candidate', 'baseline')
        for variant in order:
            run = prepare(variant, 'unavailable', 500, False, ENGINE, 5, 2)
            result = execute(run, ENGINE, 42)
            result.update(variant=variant, pair=pair+1, scenario='unavailable', population=500)
            samples.append(result)
            print(f'Pair {pair+1} {variant}: {result["median_ms"]:.3f} ms median, {result["p95_ms"]:.3f} ms p95', flush=True)
    (CACHE / 'paired-timing.json').write_text(json.dumps({'source_sha256': sources, 'samples': samples}, indent=2))


if __name__ == '__main__':
    main()
