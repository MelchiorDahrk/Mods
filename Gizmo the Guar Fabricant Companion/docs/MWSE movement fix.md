# MWSE following movement

Updated October 20, 2026. During Follow, Gizmo's Speed attribute is always Player's current Speed +50. For example, Player Speed 40 gives Gizmo Speed 90; Player Speed 80 gives Gizmo Speed 130. It tracks both increases and decreases, including player attribute effects, with no distance multiplier or cap at 100.

Gizmo's creature record starts at Speed 20. The shared native `mdFG_script_gizmo` controller sets Speed to 40 within 300 units of Player and to Player's Speed attribute multiplied by 1.5 between 300 and 900 units. It also contains a combat cap of 100. The October 18 correction only changed calculated movement through `calcMoveSpeed`; it never changed the Speed attribute. That correction did not implement the requested attribute behavior and has been removed.

The MWSE module synchronizes Gizmo's base and current Speed when the Follow hook runs, when Guard switches to Follow, and when a following save loads. It also handles `scriptExecuted`, filtered to `mdfg_script_gizmo`, so each execution of the native controller finishes with the correct +50 value. This ordering prevents the native distance rules and combat cap from overwriting the correction. Unchanged values do not trigger another statistic write.

The Follow command global is authoritative, including before the AI target initializes at recruitment and while combat interrupts Follow. Guard/Patrol/Forage with Follow turned off, dead or disabled Gizmo, and other actors are not synchronized. The correction changes Speed only; it does not clear paralysis, change encumbrance, force movement, or replace AI packages. OpenMW and the shared core ESP are unchanged.

The API and script filter were checked against the installed MWSE metadata and the upstream [scriptExecuted documentation](https://mwse.github.io/MWSE/events/scriptExecuted/), [script-filter implementation](https://github.com/MWSE/MWSE/blob/master/MWSE/LuaScriptExecutedEvent.cpp), and [statistic API](https://mwse.github.io/MWSE/apis/tes3/#tes3setstatistic). `tes3.setStatistic` sets both base and current values with `limit=false`, allowing Speed above 100.

Validation: the executable Lua API fixture reproduces the reported initial Speed 20 failure with the October 18 module and passes with this correction. It checks recruitment before AI target initialization, old native Speed writes at distances from 100 to 1200, player Speed changes (including 0 and 250), the combat cap, no redundant writes, script filtering, non-Follow commands, dead/disabled/missing actors, Guard entering Follow, and reload. Existing Guard, attraction, and Imperfect checks also pass. Packaging, core checksum, deterministic OpenMW patch, and Lua syntax checks pass. These are fixture/static checks; native Morrowind animation, terrain/pathfinding, and mod-list playtesting remain unverified.

```powershell
python -B tools/check_mwse_performance.py
python -B tools/validate_openmw.py --lua-dll 'D:/Games/OpenMW/OpenMW 0.51.0 Dev/lua51.dll'
```

Install the updated `01 MWSE/MWSE/mods/FabricantGuar/main.lua` as `Data Files/MWSE/mods/FabricantGuar/main.lua`, then restart Morrowind. No new game or console stat reset is required.
