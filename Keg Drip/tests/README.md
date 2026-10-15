Run commands from the repository root.

`lua tests/runtime.lua` runs the MWSE and OpenMW behavior tests with mocked engine APIs. It checks all six keg meshes (common, dunmer, wine, hf, hr, and sky), static/container/activator/miscellaneous kegs, mixed case and mesh separators, the matching effect IDs, rotated and scaled placement, unchanged source references, upright exclusions, continuous dripping without a receiver, downward raycasts and misses, slope alignment, slow puddle growth and the 1.0 cap, returning receivers, duplicate cleanup, save cleanup, cell unload/re-entry, and receiver/keg changes (including moved and removed non-static kegs). The OpenMW mock defers scale changes like the engine does. Lua 5.1+, including LuaJIT, is supported.

`python tests/plugin.py` validates the ESP's record structure, all six drip IDs and mesh paths, their packaged NIF/KF animation assets, the exact `kegPuddle` ID and mesh, and the attached `kegPuddleNoSave` script's source and vanilla bytecode (`DontSaveObject; End`). It also checks that the plugin contains no replacement static records.

For an isolated OpenMW engine test on Windows:

```powershell
.\tests\run_openmw_smoke.ps1 -OpenMWDirectory 'D:\path\to\OpenMW' -MorrowindData 'D:\path\to\Data Files'
```

The harness loads only Morrowind.esm, the packaged mod, and its test fixture. It uses its own configuration, saves, and logs under `.validation-cache/openmw`; it does not change the user's normal configuration or saves. Sound output is disabled. It checks animation playback for all six effects, unchanged original kegs, rotation and scale, tilted exclusions, continuous dripping after receiver removal, real physics raycast placement, puddle growth and the 1.0 cap, save/load, cell unload/re-entry, duplicate cleanup, and effects in the player's exterior cell and an adjacent cell. It also inspects the actual save bytes to ensure no puddle references or scripts were serialized. It exits automatically and fails on any engine Lua error.

`openmw_smoke/KegDripSmoke.esp` defines four test statics for the wine, hf, hr, and sky source models, so they can be tested without editing the production plugin or loading Tamriel Data. The engine test needs the hf, hr, and sky source meshes installed in the supplied Morrowind data directory. Install only `00 Core` and your selected `01` module; the test files are development tools.

Validation performed with Lua 5.2.2 and OpenMW 0.51.0 revision 1409c532c8 (Lua API 111). All packaged NIF/KF files were also read successfully by OpenMW's `niftest`; none were edited.
