# Performance evaluation and improvement plan

Reviewed October 16, 2026. Scope: OpenMW Lua, MWSE Lua, shared ESP scripts, and packaged assets. This records the original evaluation. The implemented design is documented in [Performance implementation.md](Performance%20implementation.md), with measurements in [Performance results.md](Performance%20results.md). The priorities below reflect the original code structure, before runtime measurement.

The highest-priority issue is OpenMW's blanket actor script. Replace it with scripts on Gizmo and the Imperfect, an event-only adapter on eligible guar, and temporary combat observers used only when Gizmo can assist. Preserve the existing combat, attraction, summoning, inventory, and save behavior. Measure before and after each stage.

## Findings

Source locations below refer to the reviewed files, before implementation.

| Priority | Finding and evidence | Performance implication |
| --- | --- | --- |
| High | `01 OpenMW/Fabricant Guar.omwscripts:4` assigns `actor.lua` to `PLAYER, NPC, CREATURE`. `actor.lua:84-97,101-113` supplies an update handler, combat callback, and inactive handler to every instance. | Every active actor dispatches the mod's update handler every frame, including when its body returns immediately. Each instance also initializes modules, state, and a hit callback. Inactive actors do not continue ordinary frame updates. |
| High | `global.lua:28-34,130-146` enables watching using form/command globals alone. Gizmo's health, proximity, and actual Guard/Patrol package are checked later in `assist()` and the local handler. The relevant ESP globals all default to zero. | Combat monitoring can run before recruitment or while Gizmo is disabled, elsewhere, or unable to assist. Ordinary NPCs still report even if Gizmo eventually rejects assistance. |
| High | `actor.lua:74-81,90-95` inspects combat targets and the package sequence, then sends a complete report approximately every 0.5 simulation seconds, including empty and unchanged reports. `global.lua:114-127` consumes reports every 0.25 seconds. | Work and event traffic scale with all watched actors. Empty reports allocate tables, cross script contexts, and enter the global report cache. |
| Medium | `global.lua:162-169` scans `world.activeActors` every simulation second while attraction is enabled. `common.lua:19-22` classifies guar repeatedly. | Attraction scales with every active actor instead of the usually much smaller eligible-guar set. Existing local checks correctly avoid interrupting combat or replacing an existing Follow targeting Player. |
| Medium | MWSE `main.lua:92-113` visits every reference in every active cell to find the Imperfect's nearest actor. The core Imperfect script requests its hook at a nominal 0.1-second cadence. `main.lua:135-147` polls Guard through a running script override. | When the Imperfect lacks a combat target, searches include scenery and items. Guard repeats reference lookup and distance work until player combat triggers assistance. MWSE does **not** attach this mod's Lua script to unrelated actors. |
| Low | `global.lua:149-158` polls repair, whistle, and matrix/Imperfect source scripts every frame, before the paused-time return. | Worth separating by urgency after actor work is addressed. Repair intentionally needs paused dialogue processing; lifecycle transitions need frame boundaries. Blanket throttling would risk regressions. |
| Low | `common.lua:14-16` takes a square root for range checks; `actor.lua:65-68` calculates distance again for a successful nearest-target candidate. | Use squared distance and reuse positions after reducing the number of candidates. These are secondary savings. |

Let **N** be all active actors, **R** the relevant guard observers, **G** eligible active guar, and **F** updates per second. Currently, the blanket script adds about **F × N** update-handler calls, plus about **2 × N** combat reports per simulation second while watching. For 200 actors at 60 updates/second, that is approximately **12,000 calls and 400 reports/second**. These are derived workload counts, **not CPU timings or an FPS prediction**. Low frame rates can reduce the effective report cadence.

The core ESP attaches its own native scripts to the mod's creatures/items, not ordinary world NPCs. Gizmo's native controller is already throttled to a nominal 0.1 seconds after activation/quest checks. Rewriting all retained MWScript is lower priority than fixing the actor-wide Lua work.

## API constraints that shape the plan

- OpenMW 0.51 supports dynamically attaching `CUSTOM` scripts from global Lua using `addScript`, `hasScript`, and `removeScript`. It cannot remove a script while that script is still classified as automatically started. Changing the manifest and testing migration are required; calling `removeScript` against today's auto-started `actor.lua` is insufficient. [Object API](https://raw.githubusercontent.com/OpenMW/openmw/openmw-0.51.0/files/lua_api/openmw/core.lua), [binding implementation](https://raw.githubusercontent.com/OpenMW/openmw/openmw-0.51.0/apps/openmw/mwlua/objectbindings.cpp).
- The reviewed public AI interface inspects the local actor's package sequence. A global controller cannot simply inspect every other actor through `I.AI`, and the reviewed actor API has no direct public equivalent of MWSE's player `inCombat`. Moving all logic into global Lua would lose information. [AI implementation](https://raw.githubusercontent.com/OpenMW/openmw/openmw-0.51.0/files/data/scripts/omw/ai.lua), [actor API](https://raw.githubusercontent.com/OpenMW/openmw/openmw-0.51.0/files/lua_api/openmw/types.lua).
- The built-in `StartAIPackage` event can issue Follow without a mod script on the recipient. However, sending it blindly bypasses the current combat and existing-Follow checks. An event-only guar adapter is the behavior-preserving default; removing even that adapter needs a proven equivalent. [AI implementation](https://raw.githubusercontent.com/OpenMW/openmw/openmw-0.51.0/files/data/scripts/omw/ai.lua).
- `Combat.addOnHitHandler` appends a callback to the built-in script's list; this interface exposes no unregister operation. Repeatedly removing/re-adding the current actor script may retain callbacks. Prototype observation of the normal `Hit` event, without returning false or changing damage, before using detachable observers. Direct calls to `I.Combat.onHit` bypass that event and need an explicit compatibility decision and test. [Combat implementation](https://raw.githubusercontent.com/OpenMW/openmw/openmw-0.51.0/files/data/scripts/omw/combat/interface.lua).
- Global activation handlers exist; a matching global object-inactive handler is not listed for this target. Reconcile candidates against current active actors, with local inactivity notifications as a fast path. Events arrive with frame delay. [Engine handlers](https://raw.githubusercontent.com/OpenMW/openmw/openmw-0.51.0/docs/source/reference/lua-scripting/engine_handlers.rst), [scripting overview](https://raw.githubusercontent.com/OpenMW/openmw/openmw-0.51.0/docs/source/reference/lua-scripting/overview.rst).

The objective is to eliminate blanket attachment and recurring work on unrelated actors. Some narrowly scoped local scripts remain appropriate for the API and current behavior.

## Implementation sequence

### 1. Establish measurements and prove script lifecycle behavior

Create an isolated performance profile under `tools/.cache/performance`, separate from the existing integration profile. Add a reproducible generator and results table under `tools/` and `docs/` during implementation.

Compare the current mod, each proposed stage, and a control with equivalent actors but the mod's Lua work disabled. Keep engine build, Lua thread count, camera, graphics, actor AI, and scene identical. Run at least three samples after warm-up; measure simulation and wall time separately. Test 0, 50, 200, and 500 additional actors, including a variant where most actors are outside assistance range. Test guar populations separately.

Record mod script instances, per-frame callbacks, inspection requests, reports, package visits, candidate visits, Lua execution time where engine profiling supports it, median/p95 frame time, and process memory. Count attach/detach operations and callback deliveries across repeated mode changes, cell transitions, and save/load. Aggregate diagnostics instead of logging every actor every frame. Do not ship instrumentation enabled.

Before committing to the split, prototype `CUSTOM` attachment/removal, event ordering, save/load, and normal melee/ranged/magic `Hit` delivery. Test whether callbacks registered in another script survive removal. Do not assume removal cleans up cross-script closures. Also verify what happens to the old auto-started script in an existing save after its manifest flags change.

**Exit:** reproducible baseline and a demonstrated safe attachment/hit-observation strategy. No claimed speedup before measurement.

### 2. Reduce current guard work before the larger split

In `global.lua`, separate global command eligibility from the decision to monitor actors. Monitoring additionally requires living, enabled Player and Gizmo in the same space and within the existing 3,000-unit assistance radius. Use Gizmo's local package inspection to confirm Guard/Patrol, including its command beneath stacked Combat. Recheck on a bounded cadence so entering range can enable assistance even when the globals do not change.

In `actor.lua`, reject actors outside the relevant space/range before package inspection. Combine Combat-target and `sideWithTarget` extraction into one package pass. Send reports when target membership or ally status changes, plus a bounded refresh for meaningful unchanged reports. Send an explicit clear when previously meaningful state disappears. Empty, unchanged non-allied actors should not repeatedly report.

Update report expiry together with refresh behavior: simply suppressing unchanged reports would make the existing 1.5-second timeout discard valid combat or ally state. Retain hit forwarding and the actual Guard/Patrol check at the point of assistance.

This stage reduces scans and messages, but the manifest still incurs actor-wide frame dispatch until stage 3.

**Exit:** no combat reports when Gizmo cannot assist; unchanged empty actors stop producing reports; existing guard/ally cases still pass.

### 3. Replace blanket attachment with scoped roles

Keep the global controller and player UI script. Replace the `PLAYER, NPC, CREATURE: actor.lua` entry with `CUSTOM` role scripts and attach only as needed:

| Proposed role | Attachment and work |
| --- | --- |
| Companion | Original Gizmo reference only. Guard package validation, assistance, restoration, and revival handlers. Preserve the placed reference identity, not just a matching base ID. |
| Imperfect | The mod's active Imperfect instances. Keep the current 0.25-second target logic and stop searching while a valid combat target exists. |
| Guar attraction | Eligible living guar while Follow + atomizer is enabled and they are within the relevant area. Event-only handler; no frame update and no combat callback. It retains the present combat and Follow checks before acting. |
| Combat observer | Relevant actors only, while Gizmo can assist. Event-only package inspection and safe hit observation; no per-frame handler. Include referenced actors needed to establish ally relationships, even when a simple radius filter would omit them. |

Use a central 0.5-second inspection schedule for the observer set, distributing requests across frames if measurements show spikes. Prefer change reports; refresh only meaningful state as above. Polling events still cost work, so compare total request **and** reply traffic against the baseline, including a crowded scene where R approaches N. Do not silently cap actor count or lengthen combat latency to make a benchmark look better.

Attraction uses a cached guar set populated on activation and rebuilt after load. Reconcile and prune periodically using active membership, validity, enabled/living state, and worldspace. A reference can remain valid while inactive. Eligibility classification can be cached by record ID; range and health cannot. Keep the 1,024-unit radius and one-second simulation cadence.

Use `hasScript` to prevent duplicates. Supply role/player initialization before sending requests; verify attachment readiness for revival stat events. Use a command generation in requests/replies so late reports from a previous guard session cannot trigger the next command. Remove observers/adapters after relevance ends, with a small subscription margin if needed to reduce boundary churn; actual gameplay radii remain unchanged.

If `Hit` observation cannot preserve required callback behavior, do not repeatedly register permanent callbacks in detachable scripts. Resolve callback ownership first or retain a narrowly scoped, measured compatibility bridge. Any known change to direct `I.Combat.onHit` integration must be documented and tested separately from native hits.

**Exit:** no automatic mod script on ordinary NPCs/creatures; zero mod frame-update handlers on ordinary actors; no combat observers while assistance is unavailable; no duplicate callbacks or accumulating attachments after repeated transitions.

### 4. Make migration and remaining global work bounded

Version the global save data. Preserve all existing request destinations, request phases, original Gizmo reference, staged inventory, repair IDs/acknowledgements, and attraction interval progress. Rebuild transient candidate/subscription sets after load.

Test an actual save made with the old blanket manifest. Do not assume changing its flags removes existing attachments. If necessary, retain the old `actor.lua` path temporarily as an inert `CUSTOM` migration entry and remove old instances as actors become available. Ensure old and new scripts cannot both restore stats, forward hits, or manage AI. Do not load every world cell solely for cleanup.

Remove the unconditional inactive broadcast from ordinary non-observers. Prune stale sources and subscriptions without discarding a pending lifecycle request. Keep source retention and frame boundaries through matrix reversion/resurrection.

Separate the paused-time repair path from ordinary simulation work. Prototype a modest discovery cadence for idle whistle/source polling only if measured worthwhile; once a transaction is accepted, advance its handshake on the required frames. Repair must still open from paused dialogue, and pending requests must survive reload. Avoid introducing a second owner for existing native timers or flags.

**Exit:** old/new saves and saves during every lifecycle phase retain behavior; paused menus stop gameplay timers while UI remains responsive; caches track current relevance rather than exploration history.

### 5. Optimize MWSE independently

Use the existing `mobileActivated` / `mobileDeactivated` pattern to maintain an actor candidate set as well as guar candidates. Rebuild transient sets on load, use safe reference ownership appropriate to MWSE, and validate candidates before accessing mobile data. Replace `cell:iterateReferences()` with an actor-only nearest-target search. Preserve the original indiscriminate targeting rules and 1,000-unit radius. Keep target acquisition responsive at the present cadence initially; only reduce it after latency measurements.

Use confirmed `combatStarted` / `combatStopped` events to wake Guard checks and Imperfect reacquisition where applicable, with a bounded simulation-time fallback for already-running combat, loading, entering range, and target invalidation. Stop repeated Guard override work once the controller has accepted the command. Confirm API availability against the advertised MWSE minimum before relying on newer features. [MWSE combatStarted](https://mwse.github.io/MWSE/events/combatStarted/), [combatStopped](https://mwse.github.io/MWSE/events/combatStopped/), [object lifetimes](https://mwse.github.io/MWSE/guides/object-lifetimes/).

Make atomizer scheduling reconcile state changes: enabling the upgrade during Follow or entering Follow from Guard must start it; leaving the mode must cancel unnecessary work. This also addresses the existing startup gap. A low-frequency controller can read globals; it should not scan actors while attraction is inactive. Replace the per-tick coroutine wrapper with direct iteration if profiling warrants it.

**Exit:** no Imperfect scan through scenery/items, safe caches after load/cell changes, unchanged targeting, and reliable atomizer startup/stop. Original Morrowind runtime validation is required; OpenMW tests cannot certify this stage.

### 6. Apply small optimizations only where measurements justify them

Use squared distances for boolean/nearest comparisons, cache positions within a scan, test cheap type/record eligibility before expensive health/package work, and avoid redundant stat/AI writes. Preserve strict range boundaries.

Review the single Gizmo native controller and four native day-wait scripts only if they remain material in profiles. Keep time-sensitive following, levitation alignment, death, scaling, activation, and dialogue behavior at appropriate cadences. Preserve native bytecode and local-variable layout for MWSE; use the existing source/import workflow and update checksum assertions deliberately if the core changes.

The 13 SD DDS files total 997,176 bytes; HD totals 5,441,336 bytes. The largest dimensions are 1,024 x 1,024 in both sets. Mesh/animation files total 1,632,828 bytes. These are packaged file sizes, not resident GPU memory or render-cost measurements. There is no evidence yet that asset reduction should precede scripting work. Keep SD as the existing lower-memory option and profile rendering separately if it remains a concern.

## Acceptance and regression checks

| Area | Required evidence |
| --- | --- |
| Idle scaling | With Gizmo unavailable and attraction off, unrelated actors receive no mod polling or per-frame callbacks. After initial discovery/migration, steady work should be close to fixed controller cost. Record unavoidable reconciliation visits separately. |
| Guard scaling | Work tracks relevant actors, with a bounded discovery/reconciliation pass. Empty non-allied actors produce no steady report replies. Inspect requests, meaningful heartbeats, and replies are all counted. |
| Runtime benefit | Compare median/p95 Lua and frame time in all density scenarios. Crowded-scene gains must exceed run-to-run noise; ordinary-scene timing must not materially regress. No fixed FPS or percentage promise before baseline. |
| Assistance latency | Measure from Combat acquisition or hit to the native Follow package. Preserve the current 0.5-second inspection and 0.25-second decision responsiveness, including event delays; investigate any worse p95 latency. Test initialization/entering range separately. |
| Attraction | Preserve one-second cadence, ID heuristic, mod-added guar, radius boundaries, existing combat, and correct Follow target. Toggle while already following and load in every mode. |
| Combat semantics | Guard and Patrol beneath stacked Combat; player-initiated attacks; attacks on Player, Gizmo, and Follow/Escort allies; peaceful actors; fleeing; melee/ranged/magic; target death/deletion/disable; unrelated interiors; distant allies; immediate later commands; Forage exclusion. Native hit tests supplement the existing injected callback test. |
| Lifetime and migration | Repeated attach/detach, same actor leaving/re-entering range, 100 mode/cell transitions, old-save migration, and actual save/reload. No duplicate deliveries or continuing growth in callbacks, attached instances, or retained references after cleanup. Record serialized attachment/save-size changes. |
| Lifecycle/UI | Existing bridge, AI, storage, whistle, summon, repair, matrix, and revival checks still pass. Test save/reload during each handshake phase, including pending stat restoration; preserve item condition/count and original identity. Repair works during paused dialogue. |
| Packaging | Update manifest/import assertions for the new roles, retain deterministic patch generation, verify both FOMOD engine choices, and run final-release OpenMW and original Morrowind/MWSE checks separately. |

Existing checks are `tools/validate_openmw.py`, `create_engine_check.py`, `create_ai_check.py`, `create_gameplay_check.py`, `create_whistle_check.py`, and `create_storage_check.py`, run through `tools/run_openmw.py`. Run profile generators sequentially because they reuse `tools/.cache/engine`. Extend these checks during implementation rather than replacing established lifecycle coverage.

Recommended delivery order: baseline/lifecycle prototype; guard gating and change reports; scoped role scripts with migration; bounded global polling; MWSE actor/event improvements; measured secondary cleanup. The manifest split is the main architectural change and should ship only with its migration and callback-lifetime checks.
