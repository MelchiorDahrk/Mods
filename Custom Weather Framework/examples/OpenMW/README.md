# OpenMW example: Bitter Coast colours

Requires the **OpenMW edition of Weather Adjuster** and OpenMW 0.51 or newer with the Lua weather API.

## Start from all default colours

[default_region.lua](default_region.lua) is a complete editable base: all ten weather types, all 170 stock colour entries and all ten OpenMW cloud texture paths. Edit its `region` and any `rgb(...)` values. The RGB helper takes components from **0 to 255** and converts them to the API's 0–1 values.

Copy the edited file over `scripts/weatheradjust/regions/cwf_example_bitter_coast.lua` to replace this example's teal/pink demonstration. For your own mod, copy it to `scripts/weatheradjust/regions/<your_mod>_<region>.lua` in that mod's data directory, then restart OpenMW. The base file at the root of this example is not automatically discovered there.

The values were checked against OpenMW 0.51's actual weather records in an isolated game configured with stock Morrowind GOTY INI weather settings, including Ashstorm, Blight, Snow and Blizzard. The colours are the same stock RGB values as the MWSE base; cloud texture paths use OpenMW's resolved names. Your imported INI or other weather mods may have different defaults. Delete individual entries to inherit your installed defaults instead of using a fixed stock value.

## Install

1. Add the framework's `00 OpenMW` directory as a data directory and enable **Weather Adjuster.omwscripts**.
2. Add this **examples/OpenMW** directory as another data directory in the OpenMW launcher. You can instead copy its `scripts` folder into your own region mod's data directory.
3. Restart OpenMW and load a game. The framework discovers `scripts/weatheradjust/regions/cwf_example_bitter_coast.lua`. This example needs no extra content entry or `.omwscripts` file.
4. Visit the Bitter Coast and use **Shift+F4** to preview **Clear / Day** (teal) or **Clear / Sunset** (pink). Click **Reset** beside Bitter Coast in Regions to clear any personal assignment that overrides the example.

## Adapt it for your mod

Edit `scripts/weatheradjust/regions/cwf_example_bitter_coast.lua` to change the region or `rgb(...)` colours. Enter components from **0 to 255**; the helper converts them to the framework's 0–1 format. Omitted settings inherit the engine defaults. Give the file a unique name for your mod, using lowercase letters, numbers, underscores or hyphens, and keep it directly inside `scripts/weatheradjust/regions/`.

When multiple files target the same region, the last relative file path alphabetically wins. Personal editor assignments take priority.

To remove the example, remove its data directory from OpenMW's configuration (or remove just its definition file if copied into another mod), then restart OpenMW. A personal copy you explicitly saved or assigned remains in your settings.
