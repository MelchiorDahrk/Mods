# Weather Adjuster checks

Run the Lua tests from the mod's root with Lua 5.1 or LuaJIT:

```sh
lua tests/color_spec.lua
lua tests/openmw_spec.lua
lua tests/editor_spec.lua
lua tests/regionfiles_spec.lua
lua tests/mwse_spec.lua
```

On Windows, OpenMW's existing `lua51.dll` can run all suites through Python without installing another Lua runtime:

```powershell
python tests/run_lua.py --lua-dll 'D:/Games/OpenMW/OpenMW 0.51.0 Dev/lua51.dll'
```

The suites cover all 17 colour mappings, sparse MWSE presets, texture paths and compatibility, validation, JSON/Lua escaping, exact transition completion, interrupted transitions, interiors, load initialization, preview restoration, rename/delete references, failed imports, zero-duration transitions, editor tabs, time and weather controls, invalid preview selections, RGB/hex editing, picker dragging and clamping, Cancel/Escape restoration, undo/redo, key rebinding and sharing. Region mod checks cover OpenMW discovery, duplicate precedence, malformed files, personal overrides, reset, removal, immutable installed presets, portable copies, unsaved versus assigned exports, and MWSE file creation without overwriting. MWSE interop checks cover arbitrary caller locations, optional framework availability, validation, independent data snapshots, priorities, replacement, unregistration, and registration after game load. Folder scanning is explicitly forbidden by the MWSE filesystem mock. Picker checks also cover HSV round trips, achromatic hue preservation, identical assets across editions, and MWSE weather/scattering saving. Rebuild the analytic gradient assets with `python tests/generate_picker_textures.py`. Engine APIs and MWSE's filesystem are mocked for these deterministic tests; the shared data module must remain identical in both packages.

The regression suites also check the MD_Azurian Isles interops against the plugin's `AZ_Region_` record IDs in both editions, automatic application and reset of Thousand Isles colours, and navigation to a current region whose display name sorts onto another page.

Run the real-engine smoke test with a local OpenMW installation and Morrowind's three original master files and BSAs:

```powershell
./tests/run_engine.ps1 `
    -OpenMWDirectory 'D:/Games/OpenMW/OpenMW 0.51.0 Dev' `
    -MorrowindData 'D:/Games/Morrowind/Data Files'
```

It starts OpenMW with an isolated configuration, content list and user-data directory under ignored `tests/.runtime/`. It verifies automatic discovery and application of a separately packaged region Lua file through the real VFS/module loader, then imports a JSON preset through the real markup API and verifies that the personal assignment overrides the installed file. It opens the production editor and checks all four time selections and immediate Rain/Clear changes while the editor pauses the game. It verifies that the date stays unchanged and no weather transition remains queued, then closes the editor and quits. It times out after 90 seconds. It does not load or edit your normal OpenMW profile. Check the printed log directory for diagnostics; the script-requested quit traceback is expected.

Verified with OpenMW **0.51.0**, revision **1409c532c8**. The unit runner uses that installation's LuaJIT 2.1 runtime.
