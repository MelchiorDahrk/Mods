"""Publish raw samples and a qualified before/after report from completed runs."""
import hashlib
import json
from pathlib import Path
import statistics
from performance_openmw import CACHE, ROOT

SCENARIOS = ['idle', 'guard', 'far', 'attract', 'unavailable']


def load(name):
    return json.loads((CACHE / name).read_text())


def median(samples, key):
    return statistics.median(s[key] for s in samples)


def rates(sample):
    c = sample['counts']
    return {
        'actor_updates_per_frame': c.get('actor.onUpdate', 0) / sample['frames'],
        'report_replies_per_sim_second': c.get('global.FGCombatReport', 0) / sample['simulation'],
        'inspection_requests_per_sim_second': c.get('observer.FGInspectCombat', 0) / sample['simulation'],
        'report_cache_visits_per_sim_second': c.get('global.report_visits', 0) / sample['simulation'],
    }


def main():
    baseline = load('baseline-timing.json')
    extra = load('baseline-unavailable.json')
    candidate = load('candidate-timing.json')
    control = load('control-timing.json')
    old_counts, new_counts = load('baseline-counts.json'), load('candidate-counts.json')
    validation, mwse = load('validation.json'), load('mwse-fixture.json')
    for bundle in (baseline, extra, candidate, control):
        assert not bundle['metadata']['instrumented']
    for bundle in (old_counts, new_counts):
        assert bundle['metadata']['instrumented']
    current = {p.relative_to(ROOT / '01 OpenMW').as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
               for p in (ROOT / '01 OpenMW').rglob('*') if p.is_file()}
    assert candidate['metadata']['source_sha256'] == current, 'Runtime changed since timing'
    assert new_counts['metadata']['source_sha256'] == current, 'Runtime changed since diagnostic run'
    for path, digest in validation['source_sha256'].items():
        assert hashlib.sha256((ROOT / path).read_bytes()).hexdigest() == digest, path
    scope_log = (CACHE / 'scope-check/openmw.log').read_text(encoding='utf-8', errors='replace')
    assert '100 attach/detach cycles beneath another Combat interface' in scope_log
    assert 'FG TEST COMPLETE scope ownership' in scope_log and 'Lua error:' not in scope_log
    validation['checks']['scope'] = {'passed': True, 'command': 'python -B tools/check_openmw_scopes.py',
                                     'evidence': '100 removal/re-addition cycles beneath another Combat interface'}
    old_samples = baseline['samples'] + extra['samples']
    rows = []
    for scenario in SCENARIOS:
        for n in (0, 50, 200, 500):
            before = [s for s in old_samples if s['scenario'] == scenario and s['population'] == n]
            after = [s for s in candidate['samples'] if s['scenario'] == scenario and s['population'] == n]
            assert len(before) == len(after) == 3, (scenario, n)
            b, a = median(before, 'median_ms'), median(after, 'median_ms')
            row = {'scenario': scenario, 'population': n, 'before_median_ms': b, 'after_median_ms': a,
                   'change_percent': (a / b - 1) * 100,
                   'before_p95_ms': median(before, 'p95_ms'), 'after_p95_ms': median(after, 'p95_ms'),
                   'before_wall_fps': statistics.median(s['frames'] / s['wall'] for s in before),
                   'after_wall_fps': statistics.median(s['frames'] / s['wall'] for s in after),
                   'before_run_median_range_ms': [min(s['median_ms'] for s in before), max(s['median_ms'] for s in before)],
                   'after_run_median_range_ms': [min(s['median_ms'] for s in after), max(s['median_ms'] for s in after)]}
            rows.append(row)
    result = {'baseline': baseline, 'baseline_unavailable': extra, 'candidate': candidate, 'control': control,
              'baseline_diagnostics': old_counts, 'candidate_diagnostics': new_counts, 'mwse_fixture': mwse,
              'validation': validation, 'summary': rows,
              'baseline_fixture_sha256': hashlib.sha256((ROOT / 'tools/fixtures/performance-baseline.zip').read_bytes()).hexdigest()}
    dest = ROOT / 'docs/performance'
    dest.mkdir(exist_ok=True)
    (dest / 'measurements.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
    lines = [
        '# Performance results', '',
        'Measured October 16, 2026. [Implementation and reproduction](Performance%20implementation.md); '
        '[all raw samples, source hashes, and validation records](performance/measurements.json).', '',
        '## Method', '',
        'Actual Windows OpenMW development build 1409c532c8, LuaJIT/Lua 5.1, Lua threads 0, '
        '640 x 480, VSync/frame limit off, navigation off, sound off. Each timing scene uses '
        'a fresh isolated engine process, two simulation seconds of warm-up and five simulation '
        'seconds of sampling, with three repetitions. No benchmark engines run concurrently. '
        'Gameplay Lua is uninstrumented in timing runs. Diagnostic runs are separate.', '',
        'Populations count additional actors; Player and available Gizmo are extra. Idle places '
        'ordinary actors nearby with Gizmo disabled; guard places them nearby with Gizmo guarding; '
        'far keeps Gizmo guarding but places other actors 10,000+ units away in the active interior; '
        'unavailable uses the distant population with Gizmo disabled. Attract places eligible guar '
        'nearby and enables native Follow through the atomizer. These are synthetic laboratory '
        'scenes, not a prediction for a particular mod list or playthrough.', '',
        '## Engine timing', '',
        'Values are the median of three per-run medians/95th percentiles. Lower milliseconds '
        'are better. Small changes with overlapping run ranges are inconclusive; individual '
        'ranges and samples are included in the JSON. Three short samples are not a formal '
        'statistical significance test.', '',
        '| Scene | Extra actors | Before median ms | After median ms | Change | Before p95 ms | After p95 ms |',
        '| --- | ---: | ---: | ---: | ---: | ---: | ---: |',
    ]
    for r in rows:
        def frame(value):
            return 'capped' if value >= 199.999 else f'{value:.3f}'
        change = 'capped' if r['before_median_ms'] >= 199.999 or r['after_median_ms'] >= 199.999 else f"{r['change_percent']:+.1f}%"
        lines.append(f"| {r['scenario']} | {r['population']} | {frame(r['before_median_ms'])} | "
                     f"{frame(r['after_median_ms'])} | {change} | {frame(r['before_p95_ms'])} | {frame(r['after_p95_ms'])} |")
    lines += [
        '', 'OpenMW caps its reported frame duration at approximately 200 ms. The 500-guar '
        'attraction stress test reaches that cap; those percentile values cannot establish a '
        'speedup. Actual wall duration and frame count are also recorded. Approximate wall '
        'throughput for this case is shown below; sampling boundary effects are larger with '
        'so few frames.', '',
        '| 500-guar stress scene | Before frames/wall second | After frames/wall second |',
        '| --- | ---: | ---: |',
    ]
    saturated = next(r for r in rows if r['scenario'] == 'attract' and r['population'] == 500)
    lines.append(f"| Attract | {saturated['before_wall_fps']:.2f} | {saturated['after_wall_fps']:.2f} |")
    lines += ['', '## Measured script work', '',
              'Separate instrumented runs use 200 extra actors. Actor updates include the old '
              'blanket script on Player/Gizmo where active. Rates are normalized by that run’s '
              'actual frame/simulation counts. These are observed runtime counts, not just '
              'estimates from the source.', '',
              '| Scene | Actor updates/frame before → after | Full report replies/s before → after | New inspect requests/s | Report-cache visits/s before → after |',
              '| --- | ---: | ---: | ---: | ---: |']
    diagnostic_summary = []
    for scenario in SCENARIOS:
        before = next(s for s in old_counts['samples'] if s['scenario'] == scenario)
        after = next(s for s in new_counts['samples'] if s['scenario'] == scenario)
        b, a = rates(before), rates(after)
        diagnostic_summary.append(dict(scenario=scenario, before=b, after=a))
        lines.append(f"| {scenario} | {b['actor_updates_per_frame']:.1f} → {a['actor_updates_per_frame']:.1f} | "
                     f"{b['report_replies_per_sim_second']:.1f} → {a['report_replies_per_sim_second']:.1f} | "
                     f"{a['inspection_requests_per_sim_second']:.1f} | "
                     f"{b['report_cache_visits_per_sim_second']:.1f} → {a['report_cache_visits_per_sim_second']:.1f} |")
    lines += ['', 'Guard still sends small inspection requests. Eliminating full replies does not '
              'mean eliminating all event traffic. Active script-instance counts, candidate visits, '
              'raw handler wall times, and peak process working sets are in the JSON. Instrumented '
              'handler times include measurement overhead and must not be interpreted as '
              'uninstrumented CPU savings. Process memory is not isolated Lua memory.', '',
              '## Engine reference without mod Lua', '',
              'The same peaceful actor scenes run without the mod’s Lua. This contextualizes '
              'engine/physics/render cost; it does not remove the core content or engine scripts.', '',
              '| Scene | Extra actors | Control median ms | Control p95 ms |',
              '| --- | ---: | ---: | ---: |']
    for scenario in ('guard', 'far', 'unavailable'):
        for n in (200, 500):
            samples = [s for s in control['samples'] if s['scenario'] == scenario and s['population'] == n]
            assert len(samples) == 3
            lines.append(f"| {scenario} | {n} | {median(samples,'median_ms'):.3f} | {median(samples,'p95_ms'):.3f} |")
    lines += ['', '## MWSE algorithm fixture', '',
              'The actual old/new MWSE modules execute in a deterministic Lua API fixture. '
              'Each sample performs 1,000 Imperfect acquisitions; cache construction is outside '
              'the acquisition sample. These are not native Morrowind FPS results.', '',
              '| Scenery references | Before median seconds | After median seconds | References/handles visited per search before → after |',
              '| ---: | ---: | ---: | ---: |']
    for scenery in (0, 5000, 20000):
        b = next(s for s in mwse['samples'] if s['variant'] == 'baseline' and s['scenery'] == scenery)
        a = next(s for s in mwse['samples'] if s['variant'] == 'candidate' and s['scenery'] == scenery)
        lines.append(f"| {scenery} | {statistics.median(b['seconds']):.3f} | {statistics.median(a['seconds']):.3f} | "
                     f"{b['reference_visits'][0]//b['iterations']} → {a['handle_lookups'][0]//a['iterations']} |")
    lines += ['', 'The fixture preserves tested nearest-target selection, own-base exclusion, dead/'
              'disabled handling, actor activation/deactivation, invalid-handle pruning, cell/load '
              'rebuilds, and the saved native Guard flag. It also verifies the atomizer now starts '
              'when enabled during Follow; the baseline reproduces that startup gap.', '',
              '## Behavior and save evidence', '']
    for name, check in validation['checks'].items():
        assert check['passed']
        lines.append(f'- {name}: passed.')
    lines += ['', 'Specific engine checks cover 100 real guard-mode cycles, 100 interface removal/'
              're-addition cycles beneath another Combat override, native Player melee, direct '
              'combat callbacks, distant allies after the report TTL, range/cell transitions, '
              'stale events, and a real original-version save loaded during revival. Existing '
              'bridge, AI, lifecycle, whistle, storage, and repair-open/cancel checks pass. '
              'Both ESPs retain their original checksums.', '',
              'Remaining release boundaries: final-release OpenMW binary, native Morrowind/MWSE '
              'runtime/FPS checks, other combat mods, full prompt/navigation paths and playthrough '
              'regressions. The fixture and tested development build do not certify those paths.']
    result['diagnostic_summary'] = diagnostic_summary
    paired = CACHE / 'paired-timing.json'
    if paired.exists():
        paired = json.loads(paired.read_text())
        assert paired['source_sha256']['candidate'] == current
        result['paired_confirmation'] = paired
        lines += ['', '## Interleaved confirmation', '',
                  'An additional quiet unavailable-Gizmo scene with 500 distant actors alternates '
                  'the two implementations in three adjacent pairs (AB, BA, AB). This checks '
                  'whether the result survives changing run order after both sets are warm.', '',
                  '| Pair | Before median ms | After median ms | Change |',
                  '| --- | ---: | ---: | ---: |']
        for pair in (1, 2, 3):
            b = next(s for s in paired['samples'] if s['variant'] == 'baseline' and s['pair'] == pair)
            a = next(s for s in paired['samples'] if s['variant'] == 'candidate' and s['pair'] == pair)
            lines.append(f"| {pair} | {b['median_ms']:.3f} | {a['median_ms']:.3f} | {(a['median_ms']/b['median_ms']-1)*100:+.1f}% |")
    (dest / 'measurements.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
    report = ROOT / 'docs/Performance results.md'
    report.write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print('Published:', report)
    for r in rows:
        if r['population'] == 500:
            print(r)


if __name__ == '__main__':
    main()
