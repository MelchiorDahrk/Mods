# OpenMW support feasibility and implementation plan

Assessment date: 14 October 2026. Scope: investigation and planning; no runtime mod files have been changed and no OpenMW gameplay test has been performed.

Implementation update: the modules, installer, documentation, and MWSE mapping fix are now implemented. Automated OpenMW runtime checks have passed; see `OPENMW_VALIDATION.md` for the tested builds, evidence, and remaining gameplay checks. The assessment below records the original investigation.

Packaging update (15 October 2026): the current source layout has separate, self-contained `OpenMW/` and `MWSE/` package roots and release archives. Both include their own visuals, OAAB patch, installer, and readme. The shared installer and proposed paths described below are historical; see `Arachnophobia Patch.txt` and `OPENMW_VALIDATION.md` for the current build and validation instructions.

## Recommendation

**Proceed with an optional OpenMW runtime replacement component using SSS instance modules.** The inspected framework supports matching creature record IDs and replacing active instances with existing creature records. This fits the mod's DOR rules without requiring a new replacement framework or individual worldspace patches.

Keep the existing loose meshes, animation files, web textures, and OAAB script patch. They cover quest creatures, corpses, excluded respawning creatures, unlisted variants, and the interval before SSS processes an actor. The existing FOMOD already offers an "OpenMW or Vanilla" option, so visual support is partly present; the new work adds runtime creature substitution and clearer installation choices.

This is feasible as a conservative port. It should not be advertised as preserving every original creature's gameplay behavior: replacement creates a new actor with a different record, inventory, stats, soul identity, and scripts. Full preservation of those properties and native respawning would need additional work outside a straightforward SSS YAML conversion.

## Evidence from this workspace

- Three DOR configuration files declare **17 intended substitutions**: 6 OAAB, 10 Tamriel_Data, and 1 vanilla.
- Tamriel_Data repeats the key `objectToReplace6` four times. Lua keeps the last value, leaving **7 effective TD entries**, or **14 effective substitutions overall**. The discarded entries are Dridrea Spawnling and Spider Daedra variants 01 and 02. Treat these as mapping decisions to review, not an instruction to enable all of them automatically.
- All 17 source IDs and their proposed destination records exist across the inspected local Morrowind, OAAB_Data, and Tamriel_Data masters. This verifies these local versions only.
- The visual packages contain 12 replacement NIFs, 6 KF animation files, and 12 web textures.
- `01 OAAB_Data Creature Replacement Patch/ArachnophobiaPatch_OAAB.ESP` exists. Its only non-header record is `AB_WebTrap_s`, replaced with an empty script. It disables the trap's entire scripted behavior, including spawning spiderlings. Its masters are Morrowind, Tribunal, Bloodmoon, and OAAB_Data.
- The FOMOD installs meshes, textures, and the selected MWSE folders, but **does not install the OAAB ESP**.
- Local SSS documentation identifies its snapshot as 1.0 and describes `instances`, `object_type`, anchored `record_id`, `is_dead`, `is_respawning`, `once`, and `replace`.
- SSS's inspected instance implementation disables the source after successfully creating a replacement, then copies placement and scale. It does not transfer the old actor's runtime state.
- SSS processes active objects in batches of four per update. An SSS module alone cannot guarantee that a source spider never appears before its replacement is processed.

The read-only master inspection used:

- `D:/Games/Morrowind/Data Files/Morrowind.esm`
- `D:/Games/Morrowind/Repositories/OAAB_Data/00 Core/OAAB_Data.esm`
- `D:/Games/Morrowind/Repositories/TamrielDataMain/00 Data Files/Tamriel_Data.esm`
- `D:/Games/Morrowind/Data Files/Tamriel_Data.esm`
- `D:/Games/Morrowind/Data Files/TR_Mainland.esm`

## Important limits and default exclusions

### Quest and soul identity

Use exact record IDs rather than patterns matching any ID or mesh containing "spider". The local TR master contains 14 custom creatures using the affected meshes, all outside the current DOR allowlist. Examples include `TR_m2_SpiderAkamoraM`, `TR_m4_TJ_SpiderDae_M`, and `TR_m4_TJ_SpiderMT`. Several have quest scripts; others have no attached script, so checking for an attached script alone would not establish safety. Preserve these actors and use the loose mesh fallback.

There is also a concrete exception inside the intended DOR mappings: `TR_m3_Tyn_MG06_3` and `TR_m3_Tyn_MG06_4` check for a soul gem containing **`T_Dae_Cre_SpiderDae_02`**. Turning that creature into a dremora would change its soul identity and remove that route to satisfying the quest. **Exclude variant 02 from SSS replacement by default**, even though it appears in the DOR source. Its existing replacement mesh can hide the spider while preserving the required creature record.

The vanilla quest variants `centurion_spider_tga1`, `centurion_spider_tga2`, and `centurion_spider_nchur` also stay outside the runtime allowlist. Exact matching of `centurion_spider` preserves this boundary.

### Respawning and existing actor state

OpenMW documents that dynamically created creatures do not respawn normally. SSS uses `world.createObject`, so this restriction applies even if the destination record has a respawn flag. See the [OpenMW 0.49 world API](https://openmw.readthedocs.io/en/openmw-0.49.0/reference/lua-scripting/openmw_world.html#world-createobject).

Use `is_respawning: false` for the initial release. `AB_Fau_SpiderParasol` has the respawn flag in the inspected OAAB master; preserve its original actor and use the mudcrab mesh. Test leveled-list respawning separately: the base-record flag does not establish what happens when a leveled reference resets and generates another actor.

Use `is_dead: false` so installing the component on an existing save does not turn corpses into living replacements. Injured actors and actors with altered inventories can still lose state on replacement. Start validation with a fresh game, then document the results of testing a copy of an existing save.

Use rule-level `once: true`. Do not use `once: per_cell` for this permanent substitution. Keep module filenames stable, and explain that removing or editing YAML does not undo changes already saved. The local SSS persistence documentation explicitly describes this limitation.

### Dependencies and version support

Require an SSS build with the inspected instance-rule features and its H3lp Yours3lf dependency. FlexTag is unnecessary for this design. Users enable `H3lp Yours3lf.esp` and `Static Switching System.esp`; our YAML modules are discovered automatically under `scripts/staticSwitcher/data/`. See the [SSS author documentation](https://dreamweave-mp.github.io/S3ctors-S3cret-St4sh/static_switching_system/).

As checked on the assessment date, the author's site offers **1.1-dev.10** as a development build and labels stable availability as unverified/not released. The workspace snapshot and downloadable build therefore must not be treated as interchangeable. Pin an actual tested SSS/H3 pair and record its release or commit. Establish the minimum OpenMW version through the first prototype; the site's "any version" label is not sufficient evidence to promise compatibility. OpenMW 0.49 already provides creation of existing creature records, while its custom-record creation API does not support Creature records. The proposed instance port does not need to create new base records.

## Proposed mapping inventory

These retain the intended DOR destinations, with two conservative exceptions. Apply the live/non-respawning guards to every runtime row.

| Package | Source record | Destination | Initial treatment |
| --- | --- | --- | --- |
| Vanilla | `centurion_spider` | `centurion_sphere` | Runtime |
| OAAB | `AB_Fau_SpiderBlackBby` | `scrib` | Runtime |
| OAAB | `AB_Fau_SpiderParasolBby` | `scrib` | Runtime |
| OAAB | `AB_Fau_SpiderBlack` | `rat` | Runtime |
| OAAB | `AB_Fau_SpiderParasol` | `rat` | Mesh fallback; respawning |
| OAAB | `AB_Fau_SpiderBlackLrg` | `rat` | Runtime; review matron spawning script |
| OAAB | `AB_Fau_SpiderParasolLrg` | `nix-hound` | Runtime; review matron spawning script |
| TD | `T_Glb_Fau_LrgSpider_03` | `scrib` | Runtime |
| TD | `T_Glb_Fau_LrgSpider_01` | `rat` | Runtime |
| TD | `T_Glb_Fau_LrgSpider_02` | `nix-hound` | Runtime |
| TD | `T_Dae_Cre_Drid_01` | `daedroth` | Runtime |
| TD | `T_Dae_Cre_DridBs_01` | `golden saint` | Runtime |
| TD | `T_Dae_Cre_DridGr_01` | `golden saint` | Runtime |
| TD | `T_Dae_Cre_DridLs_01` | `clannfear` | Runtime; currently discarded in Lua |
| TD | `T_Dae_Cre_SpiderDae_01` | `T_Dae_Cre_DremCyr_01` | Runtime; currently discarded in Lua |
| TD | `T_Dae_Cre_SpiderDae_02` | `T_Dae_Cre_DremLorCyr_01` | Mesh fallback; quest soul requirement |
| TD | `T_Dae_Cre_SpiderDae_03` | `T_Dae_Cre_DremKynr_01` | Runtime |

This yields **15 initial runtime substitutions** against the inspected masters, with the excluded records still visually covered. A winning record override that changes a respawn flag may reduce the runtime set further. Do not expand to newly found TD summon variants or TR custom records without auditing their behavior.

## Implementation sequence

### 1. Prove one replacement and pin dependencies

In a separate OpenMW test configuration, enable the fallback assets, a selected SSS build, and H3lp Yours3lf. Start with the vanilla centurion rule:

```yaml
log_name: "Arachnophobia Patch - Vanilla"
instances:
  - conditions:
      - object_type: Creature
      - record_id: "^centurion_spider$"
      - is_dead: false
      - is_respawning: false
    once: true
    actions:
      - replace:
          centurion_sphere: 1
```

Validate this against the schema shipped with the pinned build. Confirm discovery in the log, exactly one sphere, source disabling, placement/rotation/scale, combat, death, save/load, and cell re-entry. Confirm a quest centurion variant is untouched by the rule and renders as the scarab fallback. Record OpenMW, SSS, and H3 versions.

**Gate:** if basic replacement or persistence fails, resolve the build/API mismatch before converting the other packages. If a dependable downloadable build is unavailable, retain visual-only OpenMW support until one can be pinned.

### 2. Add package modules and preserve fallback coverage

Add these proposed files beside each package's existing `Meshes` and `MWSE` folders:

```text
01 OAAB_Data Creature Replacement Patch/
  OpenMW/scripts/staticSwitcher/data/arachnophobia_oaab.yaml
02 Tamriel_Data Creature Replacement Patch/
  OpenMW/scripts/staticSwitcher/data/arachnophobia_tamriel_data.yaml
03 Vanilla Spider Centurions Replacement Patch/
  OpenMW/scripts/staticSwitcher/data/arachnophobia_vanilla.yaml
```

Use one explicit rule per approved mapping, lowercase anchored source IDs, a single destination at chance `1`, and rule-level `once: true`. Omit `delete`; normal successful replacement already disables the original. No broad name/mesh matching, custom generated creature records, or tag dependencies are needed.

For the first release, omit the two excluded rows from runtime YAML and explain each exclusion in comments. Keep the mesh/KF bundles installed for selected creature packages in every engine mode. Keep web replacement independent of the runtime framework.

The OAAB matron records carry `AB_SpiderBlackSpawn_s` and `AB_SpiderParasolSpawn_s`. Their replacements intentionally stop using those spawning scripts, as the intended DOR swaps do. Verify no residual spiderlings, duplicate replacements, or enabled source matrons remain. Keep the existing web-trap ESP as a base-script override; do not try to replace script-record resolution with an SSS object rule.

### 3. Update packaging and documentation

- Split engine selection into **MGE XE/MWSE**, **OpenMW with SSS**, and **visual replacements only**.
- Install selected `OpenMW/scripts` folders to `scripts` for the SSS option, selected MWSE folders for MWSE, and existing mesh/texture packages as appropriate.
- Add an explicit file install for `ArachnophobiaPatch_OAAB.ESP` whenever OAAB support is selected. Explain its DLC/OAAB masters and require it enabled after OAAB_Data.
- Keep SSS and H3 as external dependencies rather than shipping `_Reference` framework files. Exclude `_Reference` and this planning document from the release archive.
- Update the readme and FOMOD descriptions with tested dependency versions, manual `data=` setup, content activation, the two fallback exceptions, and save persistence limitations. YAML requires no additional content entry for our mod beyond the existing OAAB ESP when applicable.
- Address the duplicate TD Lua keys separately: give approved entries unique keys and deliberately preserve the soul-sensitive variant as mesh-only. This changes the currently effective MWSE mappings, so validate it as a separate correctness fix instead of silently copying the bug into YAML.

### 4. Validate before release

| Test | Required result |
| --- | --- |
| Each engine/package selection, plus all-off and combined installs | Correct file set; no unselected engine scripts; OAAB ESP installed only with OAAB |
| Individual runtime mappings | Exactly one expected destination at the source placement and scale |
| Save/load and repeated cell re-entry | No duplicate actors or repeated swaps |
| Dead sources and an existing save with damaged actors | Corpses stay dead; state-loss behavior is understood and documented |
| Direct respawning OAAB parasol spider | Original record and native respawn behavior retained under the mudcrab mesh |
| Leveled-list encounter, kill, cleanup, and reset | A newly generated encounter is processed correctly; no permanent encounter loss or accumulating sources |
| OAAB matron and web trap | Reviewed spawn behavior; no visible spiders; empty trap script wins as intended |
| `T_Dae_Cre_SpiderDae_02` soul capture and quest hand-in | Original soul accepted by the inspected TR quest scripts |
| TR custom creatures and vanilla quest centurions | Original records/scripts preserved; fallback geometry and animations work |
| Busy cell entry and `PlaceAtPC`/`PlaceAtMe` spawns | No spider appears before processing; fallback assets provide coverage |
| Mesh-only mode, SSS missing, and overlapping asset replacers | Visual fallback works with correct data priority; limitations are clear |

Validate XML and YAML/schema structure, inspect the installed file tree for each FOMOD combination, and review OpenMW logs for invalid IDs and rejected rules. Check another actor-modifying SSS module for ordering conflicts because multiple rules may match the same original actor.

If a leveled-list or persistence test fails, narrow runtime coverage and retain the visual fallback for that case. If preserving runtime state or replacing respawning/quest actors becomes a requirement, plan a dedicated Lua lifecycle system or carefully scoped record patches as a separate phase.

## Completion criteria

Release the OpenMW SSS option when the three modules validate, approved mappings pass gameplay tests, the soul-sensitive and respawning exclusions behave correctly, mesh/KF fallbacks work in OpenMW, and installer output includes the OAAB ESP. Document the exact tested dependency versions and keep the framework optional for visual-only installs.

Current confidence: **high for the basic replacement mechanism and packaging approach; provisional for gameplay compatibility until the prototype and regression matrix run.**
