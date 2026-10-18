# Weather Adjuster — OpenMW

Requires **OpenMW 0.51 or newer**, including the Lua weather API. Older releases and development builds without `core.weather.records` cannot run this edition. No ESP, MWSE, MGE XE or DLL is needed.

## Installation

1. Add this `00 OpenMW` directory to OpenMW's data directories, or copy its contents into a dedicated mod directory and add that directory.
2. Enable **Weather Adjuster.omwscripts** in the launcher's Content Files list.
3. Load a game and press **Shift+F4** while the other menus are closed.

For manual configuration, add these lines to your `openmw.cfg`, changing the data path to your installation:

```ini
data="D:/Mods/Custom Weather Framework/00 OpenMW"
content=Weather Adjuster.omwscripts
```

Keep the `scripts` and `textures` directories alongside the `.omwscripts` file. If a mod manager installs numbered subpackages, select `00 OpenMW` for OpenMW.

## Editor

- **Colours:** choose one of the ten weather types and a time of day. The weather arrows immediately change the current region's weather, including while the editor is open. Preview weather reapplies the selected weather. The time buttons set the actual game clock to Sunrise (07:00), Day (13:00), Sunset (19:00), or Night (01:00), keeping the same date. Click a colour swatch to open the colour picker. Drag across the large square for saturation and brightness, or along the rainbow strip for hue; the game previews changes immediately. The picker also accepts `#RRGGBB` or `rgb(38, 166, 191)` with Apply. Done keeps the edit; Cancel or Escape restores the colour and undo history from before opening the picker. The RGB fields beside each swatch still accept components from 0 to 255 with Apply. Sunset also exposes the sun disc colour. Cloud texture paths are relative to Data Files, for example `textures/tx_sky_clear.dds`.
- **Presets:** enter a unique name and Create copy to save the current preview. Custom presets can be saved, renamed and deleted. The default preset always comes from the engine's initial weather settings and cannot be overwritten.
- **Regions:** regions sort by their in-game display names. The heading shows the current name and record ID; **Show current** jumps to its page. Assign connects the selected preset to a region. Reset removes your assignment and restores installed region colours, or default weather if none are installed. Assign the default preset explicitly to use engine defaults. Selecting the preset button previews that region's assignment. **Export Lua** exports its assigned colours as an installable region definition.
- **Import / Export:** **Export region Lua** exports the current preview, including unsaved edits, for the chosen region ID. Copy the text and save it as a UTF-8 `.lua` file at the displayed path under `scripts/weatheradjust/regions/`. Package that folder with a mod; its colours load automatically when the framework is enabled and OpenMW restarts. You can also export JSON for copying, or import a complete personal configuration. Import replaces personal presets, assignments and options; installed mod definitions stay installed. Invalid data is rejected before any saved configuration changes.
- **Options:** change the editor shortcut, toggle region messages or texture overrides, and set transition duration from 0 to 300 simulation seconds. Zero makes regional changes immediate. Enabling the texture compatibility option restores the initial textures once, then leaves textures under engine/other-mod control.

Apply previews changes; Save preset writes them to the selected custom preset. Undo and Redo keep up to 50 edits. Switching presets or closing the editor discards unsaved edits. Closing restores the current region's assigned preset. The chosen game time and weather remain in effect when the editor closes.

Colours interpolate over 20 simulation seconds when walking between assigned regions, including when crossing another boundary before the first transition finishes. Loading a game, teleporting, or returning from an interior applies the destination immediately. Ordinary interiors suspend regional interpolation. Sky-bearing interiors with a region use that region's assignment. OpenMW continues to control weather probabilities and its own transitions between weather types. Cloud textures switch at the end of a regional colour transition.

## Existing MWSE presets and sharing

For automatic region mods, use **Export Lua** and follow [Share region colours as a mod](../REGION-MODS.md). These files work with both engines. Installed presets are marked **[Mod]**; use **Create copy** to edit them. Assigning one creates a personal copy. Personal assignments override installed files, and JSON backups contain personal settings only. Removing an installed region mod and restarting removes its automatic settings.

Place the original **Weather Adjuster.json** at `MWSE/config/Weather Adjuster.json` under an active OpenMW data directory, then use **Import MWSE file**. Alternatively, paste its JSON into the Import / Export text box. Referenced cloud textures must also be installed in an active data directory.

The preset format retains the MWSE colour keys and RGB values from 0 to 1. Region IDs are matched without case sensitivity. Missing colours and weather types inherit the engine defaults. For example, this configuration makes clear daytime skies green in the Bitter Coast:

```json
{
  "presets": {
    "Green skies": {
      "Clear": {
        "skyDayColor": [0.0, 1.0, 0.0]
      }
    }
  },
  "regions": {
    "Bitter Coast Region": "Green skies"
  }
}
```

Presets, assignments and options are shared across saves and persist in OpenMW's global Lua storage (`HrnWeatherAdjuster`). The editor shortcut uses player storage (`HrnWeatherAdjusterEditor`). MWSE key codes are not imported; choose the OpenMW shortcut in Options. Use Export JSON for a portable backup. OpenMW scripts cannot write arbitrary JSON files, so copy the exported text into a file with Ctrl+A / Ctrl+C.

## Engine differences and compatibility

- The 17 colour settings per weather cover sky, fog, ambient and sun at sunrise/day/sunset/night, plus the sunset sun disc. These use OpenMW's native weather records and interpolation.
- MGE XE outscatter, inscatter and skylight settings are retained in imported/exported presets but have no effect in OpenMW. The MGE XE atmosphere and OpenMW renderer have different appearances.
- The MWSE cloud vertex-colour executable patch does not apply to OpenMW. Cloud shading follows OpenMW and any installed sky/shader mods.
- Both editions use a saturation/brightness square, hue strip, live swatch, and RGB/hex entry. Each drag is one undo step. OpenMW supports JSON backups and portable region Lua exports.
- Mods that change the same weather record colours at runtime can overwrite each other's settings. The texture compatibility option only suppresses this mod's texture changes.
- OpenMW's weather API queues transitions while menus pause the game. Weather previews complete them with a 0.0036-second game-time advance through `world.advanceTime`; that engine API also updates AI packages, so nearby NPCs may reposition. Time buttons set the hour directly and do not use this time advance.
- Disabling the content file stops this mod's Lua scripts. Restart OpenMW to clear any weather-record edits still held by the running engine. Persistent presets remain available if the mod is enabled again.

Original Weather Adjuster 3.0 by **Hrnchamd**. The MWSE package remains separate and also supports portable region Lua files.

API references: [weather records](https://openmw.readthedocs.io/en/openmw-0.51.0/reference/lua-scripting/openmw_core.html#type-weatherrecord), [storage](https://openmw.readthedocs.io/en/latest/reference/lua-scripting/openmw_storage.html), and [configuration directories](https://openmw.readthedocs.io/en/latest/reference/modding/paths.html#custom-configuration-directories).
