# Performance results

Measured October 16, 2026. [Implementation and reproduction](Performance%20implementation.md); [all raw samples, source hashes, and validation records](performance/measurements.json).

## Method

Actual Windows OpenMW development build 1409c532c8, LuaJIT/Lua 5.1, Lua threads 0, 640 x 480, VSync/frame limit off, navigation off, sound off. Each timing scene uses a fresh isolated engine process, two simulation seconds of warm-up and five simulation seconds of sampling, with three repetitions. No benchmark engines run concurrently. Gameplay Lua is uninstrumented in timing runs. Diagnostic runs are separate.

Populations count additional actors; Player and available Gizmo are extra. Idle places ordinary actors nearby with Gizmo disabled; guard places them nearby with Gizmo guarding; far keeps Gizmo guarding but places other actors 10,000+ units away in the active interior; unavailable uses the distant population with Gizmo disabled. Attract places eligible guar nearby and enables native Follow through the atomizer. These are synthetic laboratory scenes, not a prediction for a particular mod list or playthrough.

## Engine timing

Values are the median of three per-run medians/95th percentiles. Lower milliseconds are better. Small changes with overlapping run ranges are inconclusive; individual ranges and samples are included in the JSON. Three short samples are not a formal statistical significance test.

| Scene | Extra actors | Before median ms | After median ms | Change | Before p95 ms | After p95 ms |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| idle | 0 | 0.500 | 0.497 | -0.6% | 0.740 | 0.733 |
| idle | 50 | 1.178 | 1.180 | +0.2% | 1.927 | 1.932 |
| idle | 200 | 5.693 | 5.534 | -2.8% | 8.109 | 8.306 |
| idle | 500 | 30.411 | 29.720 | -2.3% | 48.532 | 44.356 |
| guard | 0 | 0.492 | 0.502 | +2.1% | 0.773 | 0.786 |
| guard | 50 | 1.327 | 1.175 | -11.4% | 2.156 | 1.867 |
| guard | 200 | 5.794 | 5.467 | -5.6% | 8.450 | 7.727 |
| guard | 500 | 31.849 | 31.074 | -2.4% | 46.531 | 45.357 |
| far | 0 | 0.498 | 0.505 | +1.4% | 0.788 | 0.789 |
| far | 50 | 0.585 | 0.556 | -5.0% | 1.078 | 0.999 |
| far | 200 | 0.953 | 0.861 | -9.7% | 2.089 | 1.938 |
| far | 500 | 1.767 | 1.622 | -8.2% | 3.530 | 3.308 |
| attract | 0 | 0.491 | 0.503 | +2.5% | 0.766 | 0.788 |
| attract | 50 | 1.443 | 1.429 | -1.0% | 4.982 | 4.978 |
| attract | 200 | 69.889 | 67.473 | -3.5% | 77.470 | 73.016 |
| attract | 500 | capped | capped | capped | capped | capped |
| unavailable | 0 | 0.493 | 0.498 | +1.1% | 0.770 | 0.744 |
| unavailable | 50 | 0.533 | 0.530 | -0.5% | 1.013 | 0.918 |
| unavailable | 200 | 0.915 | 0.815 | -10.9% | 2.002 | 1.823 |
| unavailable | 500 | 1.719 | 1.545 | -10.1% | 3.455 | 3.227 |

OpenMW caps its reported frame duration at approximately 200 ms. The 500-guar attraction stress test reaches that cap; those percentile values cannot establish a speedup. Actual wall duration and frame count are also recorded. Approximate wall throughput for this case is shown below; sampling boundary effects are larger with so few frames.

| 500-guar stress scene | Before frames/wall second | After frames/wall second |
| --- | ---: | ---: |
| Attract | 3.78 | 3.80 |

## Measured script work

Separate instrumented runs use 200 extra actors. Actor updates include the old blanket script on Player/Gizmo where active. Rates are normalized by that run’s actual frame/simulation counts. These are observed runtime counts, not just estimates from the source.

| Scene | Actor updates/frame before → after | Full report replies/s before → after | New inspect requests/s | Report-cache visits/s before → after |
| --- | ---: | ---: | ---: | ---: |
| idle | 201.0 → 0.0 | 399.7 → 0.0 | 0.0 | 799.4 → 0.0 |
| guard | 202.0 → 0.0 | 402.1 → 0.0 | 403.8 | 804.3 → 0.0 |
| far | 202.0 → 0.0 | 402.0 → 0.0 | 404.2 | 804.0 → 0.0 |
| attract | 202.0 → 0.0 | 0.0 → 0.0 | 0.0 | 0.0 → 0.0 |
| unavailable | 201.0 → 0.0 | 400.0 → 0.0 | 0.0 | 799.9 → 0.0 |

Guard still sends small inspection requests. Eliminating full replies does not mean eliminating all event traffic. Active script-instance counts, candidate visits, raw handler wall times, and peak process working sets are in the JSON. Instrumented handler times include measurement overhead and must not be interpreted as uninstrumented CPU savings. Process memory is not isolated Lua memory.

## Engine reference without mod Lua

The same peaceful actor scenes run without the mod’s Lua. This contextualizes engine/physics/render cost; it does not remove the core content or engine scripts.

| Scene | Extra actors | Control median ms | Control p95 ms |
| --- | ---: | ---: | ---: |
| guard | 200 | 5.311 | 7.833 |
| guard | 500 | 29.271 | 44.315 |
| far | 200 | 0.846 | 1.849 |
| far | 500 | 1.576 | 3.166 |
| unavailable | 200 | 0.808 | 1.804 |
| unavailable | 500 | 1.534 | 3.122 |

## MWSE algorithm fixture

The actual old/new MWSE modules execute in a deterministic Lua API fixture. Each sample performs 1,000 Imperfect acquisitions; cache construction is outside the acquisition sample. These are not native Morrowind FPS results.

| Scenery references | Before median seconds | After median seconds | References/handles visited per search before → after |
| ---: | ---: | ---: | ---: |
| 0 | 0.003 | 0.001 | 107 → 107 |
| 5000 | 0.089 | 0.001 | 5107 → 107 |
| 20000 | 0.367 | 0.001 | 20107 → 107 |

The fixture preserves tested nearest-target selection, own-base exclusion, dead/disabled handling, actor activation/deactivation, invalid-handle pruning, cell/load rebuilds, and the saved native Guard flag. It also verifies the atomizer now starts when enabled during Follow; the baseline reproduces that startup gap.

## Behavior and save evidence

- behavior: passed.
- migration: passed.
- bridge: passed.
- ai: passed.
- lifecycle: passed.
- whistle: passed.
- storage: passed.
- scope: passed.
- package: passed.
- mwse: passed.
- behavior_threads1: passed.
- migration_threads1: passed.

Specific engine checks cover 100 real guard-mode cycles, 100 interface removal/re-addition cycles beneath another Combat override, native Player melee, direct combat callbacks, distant allies after the report TTL, range/cell transitions, stale events, and a real original-version save loaded during revival. Existing bridge, AI, lifecycle, whistle, storage, and repair-open/cancel checks pass. Both ESPs retain their original checksums.

Remaining release boundaries: final-release OpenMW binary, native Morrowind/MWSE runtime/FPS checks, other combat mods, full prompt/navigation paths and playthrough regressions. The fixture and tested development build do not certify those paths.

## Interleaved confirmation

An additional quiet unavailable-Gizmo scene with 500 distant actors alternates the two implementations in three adjacent pairs (AB, BA, AB). This checks whether the result survives changing run order after both sets are warm.

| Pair | Before median ms | After median ms | Change |
| --- | ---: | ---: | ---: |
| 1 | 1.712 | 1.572 | -8.2% |
| 2 | 1.709 | 1.535 | -10.2% |
| 3 | 1.683 | 1.550 | -7.9% |
