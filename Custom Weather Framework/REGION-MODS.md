# Share region colours as a mod

An exported region file works with **both MWSE and OpenMW**. It contains the region ID and its weather colours, with any exported cloud textures and scattering settings. The recipient needs the matching edition of Weather Adjuster installed and enabled.

## Export

Open the editor with **Shift+F4**.

- **OpenMW:** go to **Regions** and click **Export Lua** beside a region to export its assigned colours. To export your current preview, including unsaved edits, use **Import / Export**, choose the region ID and click **Export region Lua**. Click inside the text box, press **Ctrl+A / Ctrl+C**, and paste into a plain UTF-8 text file at the displayed path. OpenMW's Lua sandbox cannot write arbitrary files.
- **MWSE:** go to **Regions** and select the target region. **Export assigned Lua** exports its assignment; **Export preview Lua** exports the current colours, including unsaved edits. The exporter writes to `Data Files/scripts/weatheradjust/regions/` as a convenient output location, then shows the path. Existing files are preserved; repeated exports add `_2`, `_3`, and so on. Move the result into your mod as described below. MWSE does not load definitions by scanning that output folder.

The preview export includes every weather type and time of day, not just the currently visible colour row. Assigned export ignores unsaved preview edits. Include any referenced textures at their normal `textures/` paths.

The definition's `region` must match the plugin's **record ID**, not its display name. IDs are case-insensitive, but prefixes and spaces matter: for example, `AZ_Region_Thousand Isles` is displayed as `Lyithdonea, Thousand Isles`. OpenMW's Regions tab shows both for the current region; **Show current** finds its row in the list sorted by display name.

## MWSE: load through the interop

See the [complete MWSE example mod](examples/MWSE/README.md) for an entry point, separate definition and installation instructions.

**Your files can live anywhere your mod loads them from.** No folder name or location is prescribed by Weather Adjuster, and the framework does not scan other mods' folders.

For a new mod with one exported region, use the exported file as your mod's `main.lua`:

```text
Data Files/MWSE/mods/MODNAME/main.lua
```

For an existing mod or multiple regions, put the exported files wherever you prefer and require them from your existing scripts. For example:

```text
Data Files/MWSE/mods/MODNAME/
  main.lua
  weatheradjust/
    bitter_coast.lua
    west_gash.lua
```

Your mod's `main.lua` can contain:

```lua
require('MODNAME.weatheradjust.bitter_coast')
require('MODNAME.weatheradjust.west_gash')
```

Each exported file includes an optional interop registration call. It registers when executed, and safely returns its data if the framework is absent. You do not need to copy framework scripts into your mod. Restart Morrowind after installing or removing a region mod.

You can also register a table directly using the normal interop pattern:

```lua
local weather = include('customweather.interop')
local function rgb(r, g, b)
    return { r / 255, g / 255, b / 255 }
end

if weather then
    weather.registerRegion {
        id = 'MODNAME:bitter_coast',
        region = 'Bitter Coast Region',
        preset = {
            Clear = { skyDayColor = rgb(51, 128, 204) },
        },
        priority = 0,
    }
end
```

The examples use `rgb(red, green, blue)` with **0–255** components for manual editing. The helper returns the **0–1** RGB table expected by the interop, so the same format works in both engines.

- `registerRegion(definition)` validates and copies the supplied data, then returns its registration ID. It accepts `region`, `preset`, optional `id`, optional numeric `priority` (default `0`), and optional `version` (currently `1`). Omitted colours inherit the engine defaults.
- An explicit `id` should identify your mod and region. If omitted, the caller's Lua source and region form the ID automatically. Registering the same ID again replaces its previous data.
- Higher priority wins when registrations target the same region. Equal priorities use the most recent registration. Conflicts are logged.
- `unregisterRegion(id)` removes a registration. Registration and removal also update the current region after a game has loaded. Registration before the game loads is applied once engine defaults are available.

The default output directory is only an export destination. Loading and registration never depend on where a consumer mod stores its files.

## OpenMW: package a region definition

See the [complete OpenMW example mod](examples/OpenMW/README.md) for a ready-to-install data directory and commented definition.

OpenMW continues to discover exported files under this layout:

```text
My Region Colours/
  scripts/
    weatheradjust/
      regions/
        my_mod_bitter_coast.lua
```

Use unique filenames containing lowercase letters, numbers, underscores or hyphens, ending in `.lua`. Keep files directly inside `regions/`. Add **My Region Colours** as an OpenMW data directory, then restart OpenMW. Weather Adjuster discovers the files and applies their colours in the appropriate regions, using its normal transitions. Keep the framework's **Weather Adjuster.omwscripts** enabled; region files need no extra ESP, registration code, JSON import or `.omwscripts` entry. The generated MWSE registration call is inactive in OpenMW, where the file returns its data normally.

If multiple OpenMW files target the same region, the last relative file path in alphabetical order wins and the log identifies the conflict. If two mods provide the same path, OpenMW's normal data directory priority chooses the visible file.

## Personal choices and removal

- Personal assignments take priority over registered or discovered region colours. To restore mod colours, click **Reset** beside the region in OpenMW, or **Ctrl-click** the region in MWSE.
- To force engine defaults even when a colour mod is installed, select **default** and assign it to that region.
- Installed presets appear as **[Mod]** entries. Make a copy to edit one. Assigning one creates a personal copy that remains available after the original mod is removed.
- Removing a region mod and restarting removes its automatic settings. The framework does not save installed definitions into personal configuration.
- Region IDs are case insensitive. Colours are RGB triples from **0 to 1**. Weather names and colour keys match the existing Weather Adjuster JSON format. OpenMW retains MGE XE scattering values for sharing but does not apply them.

API references: [OpenMW sandbox and module loading](https://openmw.readthedocs.io/en/stable/reference/lua-scripting/overview.html), [OpenMW virtual filesystem](https://openmw.readthedocs.io/en/latest/reference/lua-scripting/openmw_vfs.html).
