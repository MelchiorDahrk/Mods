# Custom Weather Framework / Weather Adjuster

Regional weather colours, cloud textures and lighting, based on Hrnchamd's Weather Adjuster 3.0.

Choose the package for your engine:

| Package | Requirements | Installation |
| --- | --- | --- |
| `00 MWSE` | Morrowind, MWSE and MGE XE | Install its contents into Data Files. |
| `00 OpenMW` | OpenMW 0.51 or newer with the Lua weather API | Add this directory as a data directory and enable `Weather Adjuster.omwscripts`. |

Framework scripts install under `MWSE/mods/customweather/` for MWSE or `scripts/customweather/` for OpenMW. Both packages include picker textures under `textures/customweather/`.

The OpenMW edition includes an editor (Shift+F4), preset creation/renaming/deletion, regional assignments, 20-second colour transitions, undo/redo, texture compatibility options, and import/export of Weather Adjuster JSON presets. Installation instructions and engine differences are in [the OpenMW readme](00%20OpenMW/README.md).

Both in-game editors include a VS Code-style colour picker: click a swatch, drag the saturation/brightness square and hue strip, or enter an RGB/hex value. Changes preview live; Done keeps them and Cancel restores them. Each drag is one undo step. Install the included `textures` directory with the scripts.

Both editions can export regional colours as portable `.lua` files. MWSE mods register colours through the interop from any script location; OpenMW discovers installed region files. See [sharing region colours](REGION-MODS.md) for the short authoring and installation workflow. MGE XE scattering and the Morrowind executable's cloud vertex-colour patch are specific to the MWSE edition.

The [example mods](examples/README.md) include an installable Bitter Coast colour mod for each engine, with commented Lua files and setup instructions. Each also includes a complete stock-default region base for editing all weather colours manually.

The optional [MD_Azurian Isles interop](interops/MD_Azurian%20Isles/README.md) provides the Azurian Isles, Thousand Isles and Scabrous Residuum region presets, with MWSE and OpenMW scripts.

Developer checks, including an isolated test in the actual OpenMW engine, are documented in [tests/README.md](tests/README.md).
