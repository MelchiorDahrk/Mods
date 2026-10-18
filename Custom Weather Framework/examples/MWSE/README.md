# MWSE example: Bitter Coast colours

Requires the **MWSE edition of Weather Adjuster**, Morrowind, MWSE and MGE XE.

## Start from all default colours

[default_region.lua](default_region.lua) is a complete editable base: all ten weather types, all 170 stock colour entries and all ten MWSE cloud texture names. Edit its `region`, unique registration `id`, and any `rgb(...)` values. The RGB helper takes components from **0 to 255** and converts them to the API's 0–1 values.

To use it with this example, copy it over `MWSE/mods/cwf_example/weatheradjust/bitter_coast.lua` before installation. The existing `main.lua` registers it through the interop. For your own mod, put the base file wherever you prefer and pass its returned table to `weather.registerRegion(require('your_mod.your_module'))` after obtaining the interop. This base is a data module; it does not register itself.

These are stock Morrowind GOTY INI colours and texture names, including Snow and Blizzard. MGE XE scattering inherits the running engine's defaults because those settings can vary with MGE versions and configuration. An installed weather mod or edited INI can have different defaults; delete individual entries to inherit those values instead. The original teal/pink demonstration remains available in the small example definition.

## Install

1. Install the framework's `00 MWSE` package into **Data Files**.
2. Copy this example's **MWSE** directory into **Data Files**, giving you `Data Files/MWSE/mods/cwf_example/main.lua`.
3. Restart Morrowind and load a game. The example registers its colours when its `main.lua` runs. If the framework is absent, it quietly does nothing.
4. Visit the Bitter Coast and use **Shift+F4** to preview **Clear / Day** (teal) or **Clear / Sunset** (pink). **Ctrl-click** Bitter Coast in Regions to clear any personal assignment that overrides the example.

## Adapt it for your mod

- `MWSE/mods/cwf_example/main.lua` obtains the optional framework interop and registers the table returned by `require`.
- `MWSE/mods/cwf_example/weatheradjust/bitter_coast.lua` contains the region, colours, unique registration ID and priority. This is plain data; `main.lua` registers it.
- Rename `cwf_example` to your mod's namespace, update the `require` path and registration `id`, then change the region and `rgb(...)` colour values. Enter components from **0 to 255**; the helper converts them to the interop's 0–1 format.
- The `weatheradjust` subfolder is just this example's choice. Put the definition anywhere your mod can load it from. The framework does not scan or require a particular consumer folder layout.
- Higher `priority` values override lower priorities for the same region. Equal priorities use the most recent registration. Personal editor assignments take priority over both.

To remove the example, delete only `Data Files/MWSE/mods/cwf_example/` and restart Morrowind. A personal copy you explicitly saved or assigned remains in your settings.
