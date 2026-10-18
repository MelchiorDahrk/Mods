# MWSE following movement

Fixed October 18, 2026. This addresses Gizmo's movement, rather than frame rate.

The shared native `mdFG_script_gizmo` controller sets Speed to 40 and clears forced running within 300 units of Player. Between 300 and 900 units it sets Speed to Player's Speed attribute multiplied by 1.5, but does not force running there. `ForceRun` only executes after the 900-unit teleport fallback. Attribute matching alone does not ensure that a creature keeps pace with the player's calculated movement speed.

The MWSE module now handles `calcMoveSpeed`, filtered to `mdfg_gizmo`. While Gizmo's current AI package follows Player, his calculated movement speed has a floor equal to Player's calculated movement speed; beyond 300 units the floor is 1.5 times that speed. Faster existing movement is retained. The callback changes only the current speed calculation, with no saved attribute writes, new timers, or AI package replacement.

Combat, non-Follow commands, Follow targeting other actors, death, disabled references, immobilization, overencumbrance, and zero-speed calculations retain their native behavior. OpenMW and the shared core ESP are unchanged.

The API and object filter were checked against the installed MWSE metadata and the upstream [movement event documentation](https://mwse.github.io/MWSE/events/calcMoveSpeed/), [event implementation](https://github.com/MWSE/MWSE/blob/master/MWSE/LuaCalcMovementSpeedEvent.cpp), and [calculated player movement property](https://mwse.github.io/MWSE/types/tes3mobilePlayer/#movespeed).

Validation: the executable Lua API fixture failed the nearby-following regression with the previous module and passes with the correction. It covers walking/running speed inputs, catch-up, retaining faster movement, command/target exclusions, combat, immobilization, overencumbrance, death/disable, unrelated actors, reload, and unchanged Speed attributes. Existing Guard, attraction, and Imperfect checks also pass. Packaging, core checksum, deterministic OpenMW patch, and Lua syntax checks pass. These are fixture/static checks; native Morrowind animation, terrain/pathfinding, and mod-list playtesting remain unverified.

```powershell
python -B tools/check_mwse_performance.py
python -B tools/validate_openmw.py --lua-dll 'D:/Games/OpenMW/OpenMW 0.51.0 Dev/lua51.dll'
```

Install the updated `01 MWSE/MWSE/mods/FabricantGuar/main.lua` as `Data Files/MWSE/mods/FabricantGuar/main.lua`, then restart Morrowind. No new game or console stat reset is required.
