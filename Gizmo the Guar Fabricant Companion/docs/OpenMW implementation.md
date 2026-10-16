# Fabricant Guar for OpenMW

Implemented October 16, 2026. Target: OpenMW 0.51.0.

The implementation is in `01 OpenMW`. The core ESP and the entire MWSE option are unchanged. This is an implemented port with automated engine integration checks, not a certification of every gameplay interaction on the final 0.51.0 release.

## Installation

Choose **OpenMW 0.51.0** and a texture resolution in the FOMOD. Register its installed data directory with OpenMW. Enable, in order:

```ini
content=Fabricant Guar.ESP
content=Fabricant Guar - OpenMW.esp
content=Fabricant Guar.omwscripts
```

For manual installation, combine `00 Core` and `01 OpenMW` into one mod data directory. Optionally overwrite its textures with `02 HD Textures/Textures`. All three Bethesda masters are required. Keep the engine's bundled Lua scripts enabled. No MWSE installation is required.

Original Morrowind users choose the MWSE option and enable only the core ESP. The compatibility ESP has source-only scripts for OpenMW's compiler and must not be used in original Morrowind.

Keep the compatibility ESP and manifest enabled in saves made with this implementation, especially during transformation or revival. Back up existing saves before changing engines; transferring an MWSE save to OpenMW was not tested.

## The five hooks

| Original hook | OpenMW implementation | Reason |
| --- | --- | --- |
| `mdFG_script_AIFollow` | Attraction reads `mdFG_global_following` and `mdFG_global_MuskAtomizer` every simulation second. Placeholder stops itself. | Also handles installing/enabling the atomizer while already following, loading, and entering Follow from Guard/Patrol. |
| `mdFG_script_AIGuard` | Global state plus actor-local AI inspection. Placeholder stops itself. | Existing Follow/Forage globals and Guard/Patrol Wander packages identify the command without another global. |
| `mdFG_script_imperfectFight` | Imperfect's local Lua checks at 0.25 simulation seconds. Placeholder stops itself; the local MWScript's repeated StartScript call is removed. | Finds the nearest living actor within 1,000 units, excluding every instance of its own base record. Retains valid Combat packages and replaces dead, disabled, missing, or out-of-worldspace targets. |
| `mdFG_script_RepairModule` | `long pending` increments once per actual script execution, then StopScript. Global Lua transfers a request into saved state; the player script opens native `MerchantRepair` and acknowledges it. | Keeps the existing repair dialogue. Uses **Player** as the service target, matching the MWSE call's default, rather than Gizmo. |
| `mdFG_script_SummonGizmo` | The same counter for the whistle's explicit Player request. Matrix and Imperfect use per-reference MWScript locals and acknowledgements instead. | A stopped global script's `.object` is nil immediately after an actual reload. Matrix/Imperfect also disable or delete themselves, so their local request must retain the source until Lua captures its cell, position, and rotation. |

The three state-driven placeholders have no gameplay behavior to replace or suppress. Their StopScript overrides simply prevent idle global scripts from remaining running, including hooks started by older saves.

### Bridge prototype results

The isolated OpenMW process demonstrated:

- Four successive repair executions remain repeatable after StopScript.
- Multiple StartScript calls before the hook executes coalesce into one execution. This is engine behavior: another StartScript while running does not enqueue a callback. A counter cannot reconstruct invocations the engine never executes. Dialogue requests remain repeatable; a repair window is not duplicated for coalesced starts.
- A stopped script's locals remain readable and writable. A pending repair value of 1 survived a real save, process exit, and reload.
- `SummonGizmo.object` equals Player for the running-session whistle request, but is **nil after reloading its stopped instance**. The stored request and Player destination remain valid for the whistle. Using this bridge for matrix/Imperfect without retaining their references would be unsafe.

OpenMW's [global script implementation](https://github.com/OpenMW/openmw/blob/openmw-0.51.0/apps/openmw/mwscript/globalscripts.cpp) saves stopped instances and reuses their locals when restarting. The [Lua binding](https://github.com/OpenMW/openmw/blob/openmw-0.51.0/apps/openmw/mwlua/mwscriptbindings.cpp) retrieves `.object` without resolving a saved target. These source observations agree with the engine prototype.

## Gameplay and ownership of state

`global.lua` uses the ESP globals as the gameplay interface. Its saved Lua state contains only accepted requests, their immutable destinations, the original reference, UI request IDs, and the fraction of the attraction interval elapsed. Nearby actors, threat reports, and watch subscriptions are rebuilt after load.

`actor.lua` runs AI actions locally. Threat monitoring is enabled only during Guard/Patrol eligibility, checks packages every 0.5 simulation seconds, and expires reports after 1.5 seconds. It examines the whole Combat sequence, including packages below the active package, and Follow/Escort relationships that side with Player. Public combat hit callbacks cover attacks initiated by Player and attacks on Player/allies. No damage is changed or activation suppressed.

Guard/Patrol are recognized by their retained Wander command (distance 0 or 800), `following == 0`, `foraging == 0`, and the original death/form flags. `mdFG_global_new` requests the post-summon greeting and is cleared by that greeting; it does not gate assistance. Forage's distance 1,800 and later Follow/Escort/Travel commands are excluded. Gizmo must be alive and within 3,000 units of Player in the same worldspace. Adding Follow retains current Combat packages. This approximates MWSE's player `inCombat`; exact fleeing and unusual allied-combat behavior still need manual playtesting.

Attraction retains the original 1,024-unit radius, one-second simulation cadence, upgrade globals, and ID rule: `guar` must occur in a creature's record ID without a letter immediately following it. It does not interrupt Combat, and does not replace a Follow package already targeting Player. A Follow targeting someone else is redirected. Collector sampling uses equipped item objects, sets the existing sample global once, and leaves normal activation to the engine.

The retained ESP still handles dialogue, quests, upgrade installation, scaling, foraging/cooldowns, feeding, magicka and soul features, movement abilities, and creation of matrix/Imperfect forms. Their complete in-game regression remains necessary.

### Whistle warnings during dialogue

The OpenMW patch also overrides `mdFG_script_gizmoKey`. The original inventory script checks the dead, matrix, and Imperfect globals every frame before checking `MenuMode` or `OnPCEquip`. Entering matrix form from dialogue therefore repeatedly inserts "Gizmo does not respond while entangled." into the dialogue until it closes. The same ordering also repeats the other unavailable-state warnings during ordinary play.

The override checks `MenuMode` first, then consumes `OnPCEquip` before checking availability. Each actual whistle use produces one warning when Gizmo is unavailable; an idle whistle produces none. The original call prompt and summon result remain in place. The three original local variables retain their names, types, and order for existing saves.

## Summoning and revival

The controller resolves the **placed reference**, `core.getFormId('Fabricant Guar.ESP', 1)`, loading its origin cell or `toddtest` references if needed. It never creates a replacement Gizmo. Summons capture the source destination before allowing source cleanup. Teleportation enables the original reference; ordinary summoning does not reset its inventory or stats.

Matrix/Imperfect handshakes use script-local `omwSummon` values:

| Value | Meaning |
| --- | --- |
| 0 | Idle |
| 1 | Source requests a summon and stays available |
| 5 | Lua accepted and saved the destination; source waits |
| 2 | Lua staged inventory; matrix may execute native Resurrect |
| 3 | Native Resurrect completed; Lua restores inventory |
| 4 | Teleport accepted; source may disable/delete itself |

Lua reads these variable names in lowercase, as required by the 0.51 binding's lookup behavior.

Native non-player Resurrect [clears inventory, stats, and AI runtime data](https://github.com/OpenMW/openmw/blob/openmw-0.51.0/apps/openmw/mwscript/statsextensions.cpp). Revival therefore moves the original inventory to an empty temporary container in `toddtest`, permits native resurrection on the same reference, removes the newly rebuilt base inventory, and returns the staged items. Their instance data, such as condition and enchantment charge, travels with them. The container has a world location so it participates in saving, and is removed after restoration. Saved level, attributes, AI settings, magicka/fatigue, and health base/modifier are restored through the actor-local script; health is filled. Completion acknowledgement survives reloading, and a pending stat-restoration event is safe to resend. Revival clears the mod's death flag and resumes Follow.

Revival requires a gem holding `guar` or `guar_feral`. The original matrix prompt checks soul possession **without consuming the gem**; this effective rule is preserved and rechecked when accepting revival. Ordinary unsummoning does not revive dead Gizmo. The original death flag and matrix-enabled checks still govern access to the revival prompt.

## Compatibility ESP scope

`Fabricant Guar - OpenMW.esp` contains:

- Eight SCPT overrides: the five hooks, the whistle, and the matrix/Imperfect local scripts.
- One empty container base record for inventory staging during resurrection.
- Two existing INFO overrides, with their DIAL context records.
- No new globals, creature changes, placed references, quest edits, or unrelated records.

Two originally suspected dialogue errors were tested before correction:

- `[Augment]`, `2324171041221531644`: OpenMW's dialogue compiler rejected the unterminated Cancel string. The patch closes the quote.
- `Greeting 1`, `474631467945721504`: the original AddItem spelling compiled, but an execution of that exact statement did not award the integral. The corrected statement did. The patch adds the separating space and removes the leading space inside the ID.

The core ESP's SHA-256 remains `9728aeb0d30bcbb01246ac46b86654566ea8daa7e300627205cc33b553500a61`. `tools/build_openmw_patch.py` deterministically rebuilds only the compatibility ESP from core sources.

## Validation performed

Engine: locally installed **OpenMW 0.51.0 development build, revision `1409c532c8`**, LuaJIT/Lua 5.1.4, Windows. API/source inspection used the official `openmw-0.51.0` tag. The development build is not represented as a test of the final release binary.

The final lifecycle suite also passed with `lua num threads = 1`; the deterministic bridge/AI profiles use 0.

Checks use a separate profile under `tools/.cache/engine`, a temporary laboratory plugin, and fresh/saved test games. They do not edit the user's OpenMW profile or existing saves. The laboratory injects some state and requests directly; these checks exercise actual engine APIs and MWScript execution, not every dialogue/button/input path.

| Area | Result and boundary |
| --- | --- |
| Bridge | Repetition, same-frame coalescing, stopped locals, pending save/load, and Player caller behavior verified in engine. |
| Lua | All five modules parse with the installed engine's Lua DLL and load in engine without mod Lua errors. |
| MWScript/dialogue | Retained and overridden scripts compile. Patched result scripts compile. Full engine compilation also finds unrelated existing Bethesda errors in `Museum` and `forged land deed`; these were present in the unpatched baseline and are not modified. |
| Whistle/dialogue regression | The original whistle reproduced repeated warning calls while native Gizmo dialogue was open. The patched script stayed quiet during dialogue and idle play, warned once per injected equip event in matrix/Imperfect/dead states, accepted a repeated use, and opened the native call prompt after dialogue closed. Test-only counters surround the real MessageBox calls; inventory input and prompt-button navigation still need manual testing. |
| Collection | Native activation with collector unequipped leaves sample at 0; equipped activation sets it to 1. Normal activation is not cancelled. |
| Attraction | Enabling the atomizer during Follow produces a native Follow package targeting Player. |
| Guard/Patrol | With the post-summon greeting flag cleared, native rat Combat targeting Player triggers assistance in both Patrol and Guard. Native Combat targeting a follower and an injected public player-hit callback also trigger following. Forage command remains intact during rat combat. Guard monitoring rebuilds after an actual save/load. The previous `new == 1` requirement reproduced the reported failure and was removed. |
| Imperfect | Nearest native target selected; disabling the target causes replacement. Indiscriminate target exclusions and valid package retention are implemented. |
| Repair | Three successive native MerchantRepair opens and cancellations passed. The lifecycle harness supplies a damaged weapon and gold so native list/pricing setup runs. Clicking a repair purchase, insufficient-funds behavior, and keyboard/gamepad navigation remain manual checks. |
| Summoning | Whistle moved the original placed reference from its original exterior to the laboratory. Disabled Gizmo in `toddtest` survived a real save/load and a subsequent matrix summon. Matrix and Imperfect reversion used their own source positions, restored enabled/form flags, and retained inventory. The harness drives matrix requests after the prompt, rather than navigating that prompt. |
| Revival | Real native death, native resurrection, original reference, full health, inventory count/no duplication, and a damaged item's condition passed. An actual save/load during the inventory/resurrection handshake also passed. |
| Installer | XML, every source path, all four engine/texture combinations, Lua imports, manifest entries, patch scope/determinism, and unchanged core checksum are checked by `validate_openmw.py`. Real mod-manager UI installation remains manual. |

### Remaining release acceptance checks

Use `OpenMW compatibility review.md` as the full checklist. In particular, manually test:

1. The final 0.51.0 release binary; full dialogue and prompt navigation; matrix pick-up/drop and its ability; repeat activations and mod-added guar; rotation and exact arrival height in varied interiors/exteriors.
2. Real player-initiated melee/ranged/magic fights, fleeing enemies, allied combat variants, death/removal/target switches, range boundaries, unrelated interiors, combat while loading, and immediate later companion commands.
3. Repair purchases and net gold changes, several damaged weapons/armor, insufficient funds, cancellation from dialogue, and keyboard/gamepad use. The native service uses [OpenMW's own merchant-repair pricing/payment code](https://github.com/OpenMW/openmw/blob/openmw-0.51.0/apps/openmw/mwgui/merchantrepair.cpp); prices were not numerically compared with MWSE.
4. Natural death with/without the matrix unlocked; no-soul rejection and both eligible soul IDs through the actual prompt; repeated full transformations; disabled storage saves outside the harness; all companion inventory item types.
5. The retained quest, upgrade, cooldown, foraging, scaling, feeding, magicka, water-walking/levitation, animation, texture, and sound interactions. Verify paused menus do not advance simulation timers.
6. Fresh FOMOD installations for both engines and both resolutions in a real mod manager.

### Reproducing the checks

Python 3 is sufficient for building and static checks. On Windows, use a Lua 5.1-compatible DLL of matching architecture for syntax checking:

```powershell
python tools/build_openmw_patch.py
python tools/validate_openmw.py --lua-dll 'D:/Games/OpenMW/OpenMW 0.51.0 Dev/lua51.dll'

python tools/create_engine_check.py
python tools/run_openmw.py
# Repeat with --load-savegame pointing to the generated bridge save.

python tools/create_gameplay_check.py
python tools/run_openmw.py

python tools/create_whistle_check.py
python tools/run_openmw.py
# Add --baseline to create_whistle_check.py to reproduce the original failure.

python tools/create_ai_check.py
python tools/run_openmw.py
```

The profile generators default to the local installation paths used for this work; adjust their data paths if reproducing elsewhere. `run_openmw.py --engine <path> --config <directory>` selects another executable/profile and always starts its helper window hidden. The runner checks completion markers and mod/test Lua errors and returns nonzero on failure or timeout, even when the engine itself exits normally. Individual assertions are recorded as `FG TEST PASS` in `openmw.log`. Build/cache output is ignored by Git and is not installed by FOMOD.
