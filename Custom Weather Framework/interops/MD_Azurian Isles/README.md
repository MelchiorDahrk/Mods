# MD_Azurian Isles weather interop

Regional weather colours for **MD_Azurian Isles**, using Custom Weather Framework / Weather Adjuster. Install MD_Azurian Isles and the matching framework edition first, then install this interop's files for your engine.

| Region ID | In-game name | Included weather presets |
| --- | --- | --- |
| `AZ_Region_Azurian Isles` | Lyithdonea, Azurian Isles | Clear, Cloudy, Foggy, Rain, Thunderstorm |
| `AZ_Region_Thousand Isles` | Lyithdonea, Thousand Isles | Clear, Cloudy, Foggy, Overcast, Rain, Thunderstorm |
| `AZ_Region_Scabrous Residuum` | Lyithdonea, Scabrous Residuum | Clear, Foggy, Overcast, Thunderstorm, Ashstorm, Blight |

Definitions must target the plugin's record IDs, including `AZ_Region_`; display names and shortened names do not match. The OpenMW Regions list sorts by the in-game name, so these entries appear under **L**. **Show current** jumps to the current region's page.

The supplied RGB values and cloud texture paths are preserved. Omitted colours and weather types inherit the engine's installed defaults. The textures are stock Morrowind clouds; no extra textures are included. The duplicate Thousand Isles definition is included once.

## MWSE

Requires Morrowind, MWSE, MGE XE and the framework's **00 MWSE** package.

1. Copy this interop's **MWSE** directory into **Data Files**. The entry point should be `Data Files/MWSE/mods/az/main.lua`.
2. Restart Morrowind and load a game with MD_Azurian Isles enabled.

The entry point obtains the optional `customweather.interop` API and registers all three definitions from its own `weatheradjust` folder. Registrations use the unique IDs `MD_Azurian Isles:azurian_isles`, `MD_Azurian Isles:thousand_isles` and `MD_Azurian Isles:scabrous_residuum`, all at priority `0`. The framework converts the portable `textures/` paths to MWSE's relative texture names. If the framework is absent, the entry point quietly does nothing.

## OpenMW

Requires MD_Azurian Isles and the framework's **00 OpenMW** package on OpenMW 0.51 or newer with the Lua weather API.

1. Add this **MD_Azurian Isles** interop directory (the directory containing this readme and `scripts/`) as an OpenMW data directory, alongside MD_Azurian Isles and the framework.
2. Keep the framework's **Weather Adjuster.omwscripts** enabled and restart OpenMW.

The framework automatically discovers all three files directly inside `scripts/weatheradjust/regions/`. This interop needs no additional `.omwscripts` or plugin entry. You can also copy that `scripts` folder into MD_Azurian Isles' data directory when bundling the interop with the mod.

## Preview and personal overrides

Visit the corresponding region, open the editor with **Shift+F4**, and preview one of its included weather types and times. Personal region assignments take priority: **Ctrl-click** the region in MWSE's Regions tab, or click its **Reset** button in OpenMW, to restore the interop colours.

To uninstall, remove `Data Files/MWSE/mods/az/` for MWSE, or remove this interop's data directory from OpenMW's configuration, then restart. Personal copies explicitly saved or assigned remain in your settings.
