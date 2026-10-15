# OpenMW support validation

Validated on 14 October 2026. The 1.6.0 implementation adds three optional SSS instance modules with 15 substitutions, installs the existing OAAB web-trap ESP through the FOMOD, and fixes the duplicate Tamriel_Data MWSE keys. The soul-sensitive Spider Daedra Matriarch remains mesh-only in both engine modes. OpenMW also keeps respawning base records and corpses as their original actors.

Packaging was split and revalidated on 15 October 2026. `OpenMW/` and `MWSE/` are independent package roots, each with its own FOMOD, readme, all 30 visual assets, and OAAB patch. Each installer offers its engine's runtime replacements or visual-only mode. The runtime modules, binary assets, and OAAB plugins are unchanged.

## Tested runtime

| Dependency | Build |
| --- | --- |
| OpenMW | 0.51.0 development, revision `1409c532c8f8fcc8c3bb33fe67f2fa8d76d8dc8d`, Lua API 111 |
| Static Switching System | `1.1-dev.10` |
| H3lp Yours3lf | `0.821-dev.59` |

Downloaded framework archives were used only in an isolated validation profile, not copied into the mod or installed into the user's game configuration. Their SHA-256 hashes were:

```text
static_switching_system.zip
4ed210908c8cb829298bde87069e219223dbf83e3bab3a9811d8e02ce802ab14

h3lp_yours3lf.zip
b711bc48f0f49a66fc89387a4d873cb86865b0417da88e4d204a85046f0ba649
```

Runtime content was limited to Morrowind, Tribunal, Bloodmoon, the installed OAAB_Data and Tamriel_Data masters, H3, SSS, the existing OAAB trap patch, and the test harness. The mod's loose creature meshes and animation files were exposed through the test data paths. The test profile used `--replace config`; configuration, logs, shader settings, storage, navmesh cache, and test saves were written under `.validation-cache/smoke/`.

## Passed checks

- All three YAML modules validate against both the local SSS 1.0 reference schema and the downloaded 1.1-dev.10 schema. Counts: OAAB 5, TD 9, vanilla 1. YAML duplicate keys are rejected by the validator.
- Both FOMOD installers pass the cached FOMOD base XSD using .NET XML validation. The upstream base schema's leading whitespace in QName attributes was normalized in the original temporary validation copy for libxml2 compatibility; validation constraints were retained. Options with no files or flags include an empty file list, as the schema requires.
- All **64** runtime/web/creature selection combinations (**32 per engine package**) produce the expected installed file manifests, including the readme, mesh fallbacks, selected runtime files, optional textures, and OAAB ESP. All referenced assets exist within the corresponding package, and no reference framework files enter those manifests.
- Both release archives pass CRC checks, match their package source contents byte for byte, and pass all installer combinations again after extraction into separate directories. Neither archive includes the other engine's runtime files.
- SHA-256 comparison against the pre-split source confirms that all 70 resulting copies of visual assets, runtime files, OAAB plugins, and installer headers are unchanged. Both packages include identical copies of all 30 visual assets and the OAAB plugin.
- The MWSE configs execute in native Lua and pass through the inspected DOR `loadReplacer` implementation. Their effective counts are OAAB 6, TD 9, vanilla 1. TD now retains Dridrea Spawnling and Spider Daedra 01/03 as distinct rules, while excluding Spider Daedra 02.
- An initial vanilla-only OpenMW test creates one sphere from the ordinary centurion and preserves the three vanilla quest variants, including across a save/load cycle.
- The combined OpenMW test creates all **15** approved source creatures, verifies source disabling and the expected destination counts, and verifies that replacement scale `1.25` is retained.
- Six exclusion cases pass: the OAAB respawning parasol spider, TD soul-sensitive matriarch, three vanilla quest centurion variants, and a dead ordinary centurion. Quest centurions retain their own MWScript behavior, which can independently disable them on cell re-entry. The corpse remains dead.
- The combined world is saved through OpenMW's menu API and loaded again. Replacement counts, scales, source disabling, and exclusions remain correct.
- The player leaves and returns to the test cell without creating duplicate replacements.
- A replaced source is deliberately re-enabled after save/load; SSS's saved once-cache suppresses another substitution. The test then disables that source again.
- The final automated runtime run exits normally, logs its pass marker, and contains no engine error entries or Lua failures.
- The complete OpenMW smoke test passes again using the new `OpenMW/` package paths. Its isolated configuration, logs, and saves are under `.validation-cache/package-split-smoke/`.

Final runtime marker:

```text
ARACHNOPHOBIA TEST PASSED: 15 replacements, 6 exclusions, scales, save/load, cell re-entry, and saved once-cache
```

## Repeating the checks

For structural checks, install PyYAML and jsonschema into a development Python environment, then run:

```powershell
python tools/validate_support.py
python tools/validate_support.py --schema "<SSS data>/Scripts/staticSwitcher/schema/replacerSchema.json"
```

The environment used PyYAML 6.0.3 and jsonschema 4.26.0. The local `_Reference` schema is required by this development check but is excluded from release packaging.

For the native runtime test, pass directories containing the executable, all five game masters, and the two framework plugins:

```powershell
.\tools\run_openmw_smoke_test.ps1 `
  -OpenMWDirectory "<OpenMW install>" `
  -MorrowindData "<Data Files with OAAB and TD>" `
  -SssData "<SSS data directory>" `
  -H3Data "<H3 data directory>"
```

This creates a small isolated game, saves and reloads only its test character, and exits automatically. A failure stops the run and points to its logs. Tests and dependency downloads are ignored by Git and excluded from release packaging.

Build both installable archives with `python tools/build_release.py`:

- `dist/Arachnophobia Patch-OpenMW-1.6.0.zip`
- `dist/Arachnophobia Patch-MWSE-1.6.0.zip`

Use `--engine OpenMW` or `--engine MWSE` to build just one. Each archive contains its own visual assets, three creature components, FOMOD files, and player readme. Framework dependencies, references, development documentation, tools, and validation caches are excluded.

After building, run `python tools/validate_support.py --archives` to check both ZIPs and exercise their installers from isolated extracted copies. The original combined archive has been retained only in `.validation-cache/Arachnophobia Patch-1.6.0-combined.zip`.

## Remaining gameplay checks

The automated test exercises runtime replacement and persistence. These checks still require a broader gameplay pass before treating 1.6.0 as fully release-tested:

- Real leveled-list encounters through death, corpse cleanup, and encounter reset. The generated replacement has no native respawn behavior, and disabling an original leveled actor may affect its encounter lifecycle.
- Soul capture and the full Tamriel Rebuilt quest hand-in for the preserved matriarch record, plus representative custom TR quest actors.
- OAAB matron spawning and interactive web traps in an actual location. The existing ESP empties the whole trap script; that behavior is intentional.
- Visual inspection of fallback meshes and animations, crowded cell entry, and competing mesh or actor-modifying SSS modules.
- Existing saves with injured actors or altered inventories. Fresh replacements intentionally do not copy those states.
- Other OpenMW and SSS/H3 builds, including older stable engines.

No changes to the existing replacement NIF/KF/texture assets or plugin binary were needed. Preserve those fallback assets and the documented exclusions while completing gameplay validation.
