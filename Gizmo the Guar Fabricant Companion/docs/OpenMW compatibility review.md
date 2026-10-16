# OpenMW compatibility review

Reviewed: October 15, 2026. Target assessed: OpenMW 0.51.0.

## Assessment

An OpenMW version is feasible. The reviewed MWSE Lua does not contain memory patches, external DLL dependencies, or another feature that inherently prevents a port. All of its gameplay features have a credible OpenMW implementation path. However, this is a source and API feasibility assessment, not confirmation of complete behavioral parity: player combat detection, repair service behavior, and the full summon/revival lifecycle need prototypes and in-game verification.

OpenMW 0.51.0 is the current released version checked for this review. It is a sensible initial testing target; this review does not establish the oldest supported release. [Official release listing](https://openmw.org/)

The existing MWSE file cannot run directly in OpenMW. Add an OpenMW implementation and explicit integration with the ESP's existing scripts and dialogue.

## Inspected scope

- The complete 198-line `01 MWSE/MWSE/mods/FabricantGuar/main.lua`.
- `00 Core/Fabricant Guar.ESP`: all 13 embedded script sources and the result scripts in its 153 dialogue INFO records, plus globals, creature identities, and placed references.
- The readme, MWSE metadata, directory layout, and FOMOD configuration.
- Official OpenMW documentation and relevant source files pinned to the `openmw-0.51.0` tag.

The ESP has 231 records and depends on Morrowind, Tribunal, and Bloodmoon. Its SHA-256 at review time was `9728aeb0d30bcbb01246ac46b86654566ea8daa7e300627205cc33b553500a61`.

No OpenMW session or OpenMW script compilation was run. Meshes, animation files, textures, and audio were inventoried, but were not rendered or played. The only project change made for this review is this document.

## Feature mapping

| Existing behavior and Lua lines | OpenMW approach | Assessment |
| --- | --- | --- |
| Identify nearby guar, 15–39 | Filter `world.activeActors` in a global script, or `nearby.actors` in a local script; use `recordId` for the existing ID heuristic and retain the 1,024-unit radius. | Straightforward. Restrict to creatures and reject invalid, disabled, and dead references. |
| Collect musk on activation, 58–70 | Global `onActivate(object, actor)`, a creature check, and the player's equipped item record ID; update the existing sample global and send the player a message. | Straightforward. Preserve normal activation after sampling. |
| Attract guar, 46–56 and 72–87 | One simulation-second update cadence; send a `StartAIPackage` event with a `Follow` package to eligible guar. | Straightforward, with AI package and timer fixes described below. |
| Imperfect attacks the nearest actor, 92–130 | Actor-local AI inspection and nearest living target selection; start a `Combat` package within 1,000 units. | Feasible. Preserve the intended indiscriminate aggression and existing target exclusions. |
| Guard/patrol resumes following during player combat, 135–148 | Detect actors with combat packages targeting the player and notify Gizmo; retain the 3,000-unit range check. | Feasible behavior, but an inferred threat state is not a proven equivalent of MWSE's player `inCombat` flag. |
| Repair service, 153–156 | Player-side `I.UI.setMode('MerchantRepair', {target = serviceActor})`. | Native UI route exists. Test opening from dialogue, prices, payment, cancellation, and repeated use. |
| Summoning, 163–174 | Resolve the original Gizmo reference, snapshot the caller's location/rotation, and use global `GameObject:teleport`. | Feasible. Requires careful caller capture and lifecycle tests. |
| Five MWSE script overrides, 185–190 | Replace the hooks or their call sites with an explicit MWScript/Lua bridge. | Required integration work. There is no direct `mwse.overrideScript` substitution in the reviewed public API. |
| Existing globals, 191–196 | Global Lua reads/writes `world.mwscript.getGlobalVariables()`. | Supported. Keep ESP globals as shared state for existing dialogue and MWScript. |

OpenMW exposes active actors and mutable MWScript globals through its global world package, while nearby object access is local. [World API](https://openmw.readthedocs.io/en/openmw-0.51.0/reference/lua-scripting/openmw_world.html), [nearby API source](https://raw.githubusercontent.com/OpenMW/openmw/openmw-0.51.0/files/lua_api/openmw/nearby.lua)

Activation and simulation updates have engine handlers. Equipment can be inspected through `types.Actor.getEquipment`; compare the equipped object's `recordId` with `mdfg_w_collector`. Do not pass an item ID string to `Actor.hasEquipped`, whose documented parameter is an item object. [Engine handlers](https://openmw.readthedocs.io/en/stable/reference/lua-scripting/engine_handlers.html), [actor/equipment API source](https://raw.githubusercontent.com/OpenMW/openmw/openmw-0.51.0/files/lua_api/openmw/types.lua)

The built-in AI interface supports inspecting local AI packages. Built-in `StartAIPackage` events provide a public route to request Follow and Combat packages on another actor. [AI interface](https://openmw.readthedocs.io/en/stable/reference/lua-scripting/interface_ai.html), [versioned AI implementation](https://raw.githubusercontent.com/OpenMW/openmw/openmw-0.51.0/files/data/scripts/omw/ai.lua)

## Required integration work

### Replace the empty MWSE hook scripts

These five ESP scripts have no executable behavior beyond their empty script bodies:

- `mdFG_script_AIFollow`
- `mdFG_script_AIGuard`
- `mdFG_script_imperfectFight`
- `mdFG_script_RepairModule`
- `mdFG_script_SummonGizmo`

Their existing callers still run in OpenMW. Follow dialogue already issues vanilla `AiFollow`, but its hook starts the musk timer. Guard and patrol dialogue start the guard hook. The Imperfect's local script starts its combat hook approximately every 0.1 simulation seconds. Repair dialogue starts the repair hook. The whistle, matrix, and transformation scripts start the summon hook.

Therefore, loading the current ESP without MWSE loses essential behavior, even if ordinary dialogue and following initially appear to work.

A small OpenMW compatibility plugin is a practical approach: override the necessary hooks/call sites, add request/acknowledgement variables, and retain the main ESP for shared content. One-shot MWScript requests should stop themselves and support repeated requests; guard mode needs an explicit lifetime. OpenMW can inspect MWScript instances and variables, but its `isRunning` property is read-only and the reviewed binding supplies no general Lua start/stop/override operation. Polling the existing empty scripts alone does not reproduce MWSE's callbacks reliably. [MWScript binding source](https://raw.githubusercontent.com/OpenMW/openmw/openmw-0.51.0/apps/openmw/mwlua/mwscriptbindings.cpp)

### Preserve the source of each summon request

`mdFG_script_SummonGizmo(e)` uses `e.reference`, not necessarily the player:

- `mdFG_script_gizmoKey`: the whistle explicitly starts the script on the player.
- `mdFG_script_MatrixModule`: untanglement starts it from the matrix object.
- `mdFG_script_imperfect`: reverting starts it from the transformed creature.

Always teleporting Gizmo to the player would change the latter two paths. Capture the destination before the matrix or Imperfect is disabled/deleted. A bridge that only stores a boolean summon request is insufficient unless it separately records the caller and destination.

Preserve the original Gizmo reference and its inventory. The ESP places one `mdFG_gizmo` reference at Ald Sotha, with raw reference number `0x000001`. OpenMW distinguishes a base `recordId` from an individual object's identity: resolve/cache the actual placed reference, and account for its disabled storage location in `toddtest`. Dynamically spawned Imperfect instances must be tracked separately.

OpenMW teleportation is deferred until the next frame and enables disabled objects. This gives a suitable replacement for moving Gizmo, but does not establish that MWSE's subsequent disable/enable cycle has identical side effects. [Object manipulation API source](https://raw.githubusercontent.com/OpenMW/openmw/openmw-0.51.0/files/lua_api/openmw/core.lua)

### Prototype the guard combat trigger

The reviewed OpenMW actor API has no direct public player `inCombat` flag. AI packages are inspectable from actor-local scripts, so a practical design is for active actors to report whether a Combat package targets the player. Check package sequences as well as the active package when appropriate, and clear reports when actors die or become inactive.

This should reproduce the common case of a nearby guard joining a fight, but player-initiated attacks, fleeing opponents, allied combat, and changes of target require validation. Weapon stance or a recent hit alone would be weaker substitutes. Treat exact combat-state parity as unresolved until tested.

### Prototype the native repair service

The current call `tes3.showRepairServiceMenu()` omits `serviceActor`, which MWSE documents as defaulting to the player. Do not silently substitute Gizmo as the price-setting actor. [MWSE repair service documentation](https://mwse.github.io/MWSE/apis/tes3/#tes3showrepairservicemenu)

OpenMW's UI interface accepts a mode and target, and its 0.51.0 bindings explicitly expose `MerchantRepair`. That is the candidate equivalent; `Repair` is the separate repair-tool window. The player is a sensible first target for matching the existing call, subject to testing service pricing and gold handling. A custom condition-editing UI is a fallback if native behavior proves unsuitable, and would need its own price rules. [UI interface](https://openmw.readthedocs.io/en/stable/reference/lua-scripting/interface_ui.html), [UI mode bindings](https://raw.githubusercontent.com/OpenMW/openmw/openmw-0.51.0/apps/openmw/mwlua/uibindings.cpp), [repair-tool implementation](https://raw.githubusercontent.com/OpenMW/openmw/openmw-0.51.0/apps/openmw/mwgui/repair.cpp)

## Existing issues to address during the port

1. **Atomizer startup can be missed.** The timer is created only on loading or through `mdFG_script_AIFollow`. Installing/enabling the atomizer while already following does not start it if no timer exists. Guard-triggered following also does not call `muskAtomizerStart`. An always-available controller that checks current globals at its simulation cadence avoids these gaps.
2. **Follow-package checks ignore the target.** Lines 50–54 treat every Follow package as already correct. A guar following someone else will not be redirected. Decide whether to preserve that behavior or verify both package type and target.
3. **Actor/reference assumptions need guards.** Lines 47, 119–121, and 137–141 assume relevant references and mobile actors are available. OpenMW code should validate identity, availability, enabled state, and life state, and compare positions only within the same world space.
4. **The guar test is an ID convention.** `guar` must occur in the base ID without an immediately following letter. This supports many mod-added guar, but not every possible mod's naming scheme. Preserve the heuristic initially and document it; an extensible allowlist can be added later.
5. **Revival is not demonstrated by the summon function.** The matrix MWScript clears the mod's dead flag, but the Lua summon override contains no explicit resurrection or health restoration. Verify actual resurrection, inventory preservation, and the claimed soul requirement in OpenMW rather than assuming enabling a dead reference revives it. This is a lifecycle concern, not proof that revival is impossible.

Two ESP dialogue result sources also need compiler verification/correction:

- `[Augment]`, INFO `2324171041221531644`: the final option is `"[Cancel] 1000`, with no closing quote.
- `Greeting 1`, INFO `474631467945721504`: `Player->AddItem" mdFG_integral" 1` contains a leading space inside the item ID and no separating space before the quote.

These observations come from the ESP's embedded text, not an OpenMW compiler diagnostic. Include dialogue results in compilation checks; validating only the standalone SCPT records would miss them. OpenMW documents a number of differences from original Morrowind that also justify testing the retained MWScript. [Engine differences](https://openmw.readthedocs.io/en/stable/reference/modding/differences.html)

## Packaging and implementation outline

`01 OpenMW` is currently empty. Add an `.omwscripts` manifest and scripts under a mod-specific `scripts/` directory. A compact design is a global controller for ESP state and requests, a player script for UI/messages, and actor-local behavior for AI inspection and threat reports. Restrict work by record ID and active mode, and rebuild transient state after loading. OpenMW separates these script contexts and connects them through events. [Versioned scripting overview](https://raw.githubusercontent.com/OpenMW/openmw/openmw-0.51.0/docs/source/reference/lua-scripting/overview.rst)

The FOMOD also needs correction before either engine option is released:

| FOMOD line | Current source | Actual location |
| --- | --- | --- |
| 9 | `00 Core/MWSE` | `01 MWSE/MWSE` |
| 12 | `00 Core/Fabricant Guar-metadata.toml` | `01 MWSE/Fabricant Guar-metadata.toml` |
| 22 | `01 HD Textures/Textures` | `02 HD Textures/Textures` |

Add an engine selection that installs the appropriate implementation. Keep assets shared. Document activation of both the main ESP and OpenMW script manifest, plus the compatibility plugin if used. Update the readme's MWSE-only requirements; its version is 1.3.0 while the MWSE metadata still says 1.2.0.

## Release acceptance checks

1. Compile all retained and patched MWScript, including dialogue result scripts. Confirm the manifest loads with no missing-module or API errors.
2. Test musk collection with/without the equipped collector, repeat activation, vanilla/mod-added guar, and ordinary activation behavior.
3. Toggle the atomizer while already following, enter Follow from Guard/Patrol, save/load in each state, and check menus do not advance its simulation timer.
4. Verify guards join combat within 3,000 units, remain inactive outside the range/across unrelated interiors, and respect later Follow/Forage/Guard commands.
5. Check Imperfect target selection, existing combat, target death, repeated transformations, and intended treatment of the player and allies.
6. Open repair repeatedly from dialogue; test damaged weapons/armor, prices, insufficient funds, cancellation, and keyboard/gamepad navigation.
7. Exercise whistle summons across cells, matrix untanglement away from the player, reversion at the Imperfect's location, and save/load while Gizmo is disabled. Confirm no duplicate companions or lost items.
8. Test death with/without matrix unlocked, revival, soul requirements, companion inventory, and subsequent AI/health state.
9. Regression-test native dialogue, upgrades, foraging/cooldowns, scaling, health restoration, water walking, levitation, quest progression, and the custom assets.
10. Verify fresh FOMOD installs for each engine and both texture choices.

Compatibility should be advertised after these checks. The review establishes a viable porting approach; it does not yet certify a working OpenMW build.
