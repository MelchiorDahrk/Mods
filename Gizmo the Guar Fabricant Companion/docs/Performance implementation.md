# Performance implementation

Implemented October 16, 2026. See [the evaluation](Performance%20improvement%20plan.md) and [measured results](Performance%20results.md).

## OpenMW

The manifest no longer automatically attaches actor.lua to Player, NPCs, or creatures. The old path remains an inert CUSTOM script so existing saved instances are recognized and removed when their objects activate. The controller retains the original placed Gizmo reference.

| Role | Lifetime and work |
| --- | --- |
| player.lua | Existing Player UI and repair acknowledgement; unchanged. |
| companion.lua | Original Gizmo only. Event-only guard validation, assistance, revival, and stat restoration. |
| imperfect.lua | Mod Imperfect references. Retains the 0.25-second target logic and valid-target retention; uses squared distance. |
| guar.lua | Eligible nearby guar while attraction is active. Event-only adapter retains combat and existing Follow checks. |
| observer.lua | Active hit recipients during a qualifying guard session. No frame handler or local timer; the global controller requests inspection every 0.5 simulation seconds. |

Guard requires living, enabled Gizmo and Player in the same space, within 3,000 units, with the existing Guard/Patrol command. Forage and incompatible later commands are excluded. The actual 1,024-unit attraction radius, one-second attraction cadence, 1,000-unit Imperfect radius, and targeting rules remain unchanged.

Guard observers deliberately cover all active hit recipients during a qualifying session. A simple radius filter would lose existing long-range Player hits and distant Follow/Escort ally relationships. The improvements remove blanket attachment outside these sessions, per-frame actor dispatch, duplicate package passes, empty/unchanged report replies, and the global cache/scan of empty reports. Inspection requests remain real work and are counted in the measurements.

Meaningful combat/ally state refreshes every second, retaining the existing 1.5-second expiry. Changes and clears are sent on inspection. Empty unchanged actors allocate no new target/membership table. Attraction caches matching actor references and record classifications; a bounded active-membership reconciliation remains necessary because a reference can be valid while inactive.

Hit observation owns a removable Combat interface layer and delegates original behavior to its predecessor. It does not append an unremovable callback to another script. Both the native Hit path and direct I.Combat.onHit calls remain supported. Tests remove/re-add this layer beneath a second Combat override, checking chained interface ownership.

An initial local-timer design was rejected after engine tests showed pending timers log errors after script removal. The shipped observer uses the central schedule.

## Save compatibility

Global save data has version 2 and still accepts unversioned data. Original reference, accepted requests, destinations, request phases, staged inventory, repair IDs/acknowledgements, and attraction progress retain their fields and meaning.

Subscriptions, candidates, reports, and guard eligibility rebuild after load. Saved observers stay neutral until configured. Legacy blanket instances use the inert file until activation cleanup; the controller does not load every cell solely for cleanup.

Guard session epochs protect reports, hits, assistance, and acknowledgements against late delivery. The companion also checks its current AI command. Rapid inactivity/reactivation cannot let an old notification remove a rebuilt subscription.

Repair, whistle, and matrix/Imperfect handshakes retain frame processing, including during paused dialogue. This fixed-size bridge work was retained to preserve response timing and inventory/resurrection frame boundaries. Native companion/day-wait scripts also remain intact. Both ESPs are byte-identical to the pre-optimization files.

A real migration test saves with the original Lua during revival, exits the engine, loads that save with the scoped implementation, and completes the original-reference, inventory, condition, health, storage, and transformation checks.

## MWSE

Transient actor/guar sets use safe handles. Load/cell-change handlers rebuild them; activation/deactivation maintains them. Imperfect acquisition visits actors instead of scenery/items, retaining the original cadence and own-base exclusion.

Guard retains the original running MWScript flag as its saved command authority. Repeated override calls take a cheap pending check; a 0.1-second simulation controller performs pending checks and combatStarted wakes it promptly. Loading a save with the native guard hook running restores that work. No new persistent MWSE fields are introduced. Guard consumes its pending request before calling into AI, preventing a reentrant combatStarted callback from issuing Follow twice; the fixture exercises that event ordering.

The controller reconciles atomizer changes, including enabling it during Follow and entering Follow from Guard. Leaving the mode cancels unnecessary attraction work. Iteration no longer creates a coroutine each tick; range comparisons use squared distance.

The executable fixture runs the actual old/new modules, registered callbacks, timers, loading/cell changes, invalid handles, target exclusions, and saved native guard state. Its timings are Lua algorithm measurements, not native Morrowind FPS measurements. Native Morrowind/MWSE playtesting remains a release check.

## Reproduction

The pinned original runtime is tools/fixtures/performance-baseline.zip. The snapshot command restores it into ignored cache storage if absent. Profiles, overlays, logs, saves, and temporary plugins stay under tools/.cache/. Personal profiles and existing saves are not edited.

~~~powershell
python -B tools/performance_openmw.py --snapshot
python -B tools/validate_performance.py
python -B tools/performance_openmw.py --variant baseline --scenarios idle guard far attract unavailable
python -B tools/performance_openmw.py --variant candidate --scenarios idle guard far attract unavailable

# Separate diagnostics; their frame times include instrumentation overhead.
python -B tools/performance_openmw.py --variant baseline --instrument --counts 200
python -B tools/performance_openmw.py --variant candidate --instrument --counts 200

# Engine/physics reference without the mod's Lua.
python -B tools/performance_openmw.py --variant control --scenarios guard far unavailable --counts 0 200 500
python -B tools/report_performance.py
~~~

Defaults select this installation's OpenMW development binary, data paths, and Lua DLL. Adjust paths for another installation. Integration generators share their laboratory profile and run sequentially. Timing runs also run sequentially without another engine instance. Results record source hashes, engine revision, individual samples, frame percentiles, simulation/wall duration, peak process working set, and diagnostic handler/event counts.

The behavior/churn and real cross-version revival-save checks also pass with one Lua thread; timing runs use zero. Evidence applies to the tested build and paths. Final-release OpenMW, native Morrowind/MWSE, other combat mods, ordinary prompt navigation, and full playthrough coverage retain the release boundaries in [OpenMW implementation.md](OpenMW%20implementation.md).
