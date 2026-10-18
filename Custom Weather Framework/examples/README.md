# Region mod examples

For a complete preset to edit by hand, start with [MWSE/default_region.lua](MWSE/default_region.lua) or [OpenMW/default_region.lua](OpenMW/default_region.lua). Each contains all **10 weather types**, all **17 colour fields per weather** (170 RGB entries), and the engine's cloud texture paths, starting from stock Morrowind GOTY values. Edit `region` and the colours directly; no in-game editor or export is needed. These base files sit outside the active example paths until you copy them into your mod.

Colours use `rgb(red, green, blue)` with familiar **0–255** components. For example, `rgb(95, 135, 203)` is the stock clear daytime sky. The helper converts to the framework's 0–1 format. Remove a field if you want it to inherit the user's installed defaults instead of fixing it to a stock value. See each engine's readme for how to activate a base file.

These two small mods give the **Bitter Coast** a teal sky and fog during **Clear / Day** weather, plus a pink sky and fog during **Clear / Sunset**. Other settings inherit the engine defaults. They need no extra textures.

- [MWSE example](MWSE/README.md): a normal mod entry point registers a definition through the interop. The definition lives in this example's own `weatheradjust` folder; you can choose any module location in your mod.
- [OpenMW example](OpenMW/README.md): a region definition is discovered automatically in the example data directory.

Install the example for your engine separately from the framework. The examples are optional and are outside both framework packages.

To see the effect, visit the Bitter Coast (for example, Seyda Neen), open the editor with **Shift+F4**, and choose **Clear**, then **Day** or **Sunset**. If you have a personal assignment for the region, restore the mod colours first: **Ctrl-click** Bitter Coast in MWSE's Regions tab, or click its **Reset** button in OpenMW.

For the full API and packaging guide, see [Share region colours as a mod](../REGION-MODS.md).
