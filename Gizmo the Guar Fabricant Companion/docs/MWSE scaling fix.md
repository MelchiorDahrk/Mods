# MWSE size transformation

Updated October 20, 2026. The MWSE module now completes both size transformations, including saves already reporting that transformation is in process. Gizmo shrinks to scale 0.5 and grows to scale 1 at 0.3 scale units per simulation second, taking about 1.67 seconds for a full transition after dialogue closes.

The shared `mdFG_script_gizmo` advances `ModScale` by `0.3 * GetSecondsPassed`, but only after its 0.1-second throttle. Morrowind stores scale changes at two decimal places. At 144 FPS, each attempted change is about 0.00208 and rounds away completely. The script nevertheless consumes the request and leaves `mdFG_global_scale` at 52 (shrinking) or 102 (growing), so dialogue continues to report that work is in progress. The throttle also discards elapsed time between updates. OpenMW executes the shared script without this native scale-rounding limitation.

The two-decimal conversion was verified by read-only inspection of the installed `Morrowind.exe`: the reference vtable's scale setter points to `0x4F0EA0`, which uses the `%.2f` format at `0x7A8B94`. MWSE exposes this setter through the inherited [`scale` property](https://mwse.github.io/MWSE/types/tes3object/#scale); its [implementation](https://github.com/MWSE/MWSE/blob/master/MWSE/TES3Object.cpp) calls the object's native setter.

The MWSE correction accumulates full elapsed simulation time in Lua and writes absolute scale in hundredths only when the displayed size changes. It marks the reference modified for saving, clamps both endpoints, and completes the existing dialogue global. It uses the [`simulate` event](https://mwse.github.io/MWSE/events/simulate/), which pauses in menus, and clears the native script's scale direction through the reference's [`context`](https://mwse.github.io/MWSE/types/tes3scriptContext/). This prevents the old scale loop from competing with the correction while allowing the rest of the shared native controller to run.

Both request states (51/101) and in-process states (52/102) are accepted. Loading resets the transient accumulator and resumes from the reference's saved size. No new persistent Lua fields or save migration are required. An unavailable, disabled, or dead Gizmo retains its request until it can be serviced. Idle states do no reference lookup or scale writes. The shared core ESP and OpenMW files are unchanged.

Validation uses the actual MWSE module and registered callbacks, with a native-script scale fixture whose setter rounds to two decimals. It reproduces the pre-fix stall at 144 FPS, rejects the pre-fix MWSE module, and passes shrinking/growing at 10, 30, 60, 144, and 360 FPS. It also covers old stuck saves in both directions, reloads during both transitions, menu pauses, replacement requests, long frames, exact endpoints, unavailable references, saved modification flags, and no writes after completion. Existing Speed +50, Guard, attraction, and Imperfect checks pass. Packaging, unchanged core checksum, deterministic OpenMW patch, and Lua syntax checks pass. Native in-game visual and collision testing remains unverified.

```powershell
python -B tools/check_mwse_performance.py --iterations 50
python -B tools/validate_openmw.py --lua-dll 'D:/Games/OpenMW/OpenMW 0.51.0 Dev/lua51.dll'
```

Install `01 MWSE/MWSE/mods/FabricantGuar/main.lua` as `Data Files/MWSE/mods/FabricantGuar/main.lua`, then restart Morrowind and load the existing save. A stuck transformation resumes after leaving dialogue; a new game or console reset is unnecessary.
