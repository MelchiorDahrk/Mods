# Package openmw.world

# Package openmw.world

API v129

Provides an interface to the game world for global scripts.

global

## Usage

`local world = require('openmw.world')`

## Type `world`

world.activeActors

List of currently active actors.

world.advanceTime(hours)

Advance the world time by a certain number of hours.

world.cells

List of all cells

world.createObject(recordId, count)

Create a new instance of the given record.

world.createRecord(record)

Creates a custom record in the world database; string IDs that came from ESM3 content files are lower-cased.

world.getCellById(cellId)

Loads a cell by ID provided

world.getCellByName(cellName)

Loads a named cell

world.getExteriorCell(gridX, gridY, cellOrName)

Loads an exterior cell by grid indices

world.getGameTime()

Game time in seconds.

world.getGameTimeScale()

The scale of game time relative to simulation time.

world.getObjectByFormId(formId)

Return an object by RefNum/FormId.

world.getPausedTags()

The tags that are currently pausing the game.

world.getSimulationTime()

Simulation time in seconds.

world.getSimulationTimeScale()

The scale of simulation time relative to real time.

world.isWorldPaused()

Whether the world is paused.

world.mwscript

Functions related to MWScript (see #MWScriptFunctions).

world.pause(tag)

Pause the game starting from the next frame.

world.players

List of players.

world.setGameTimeScale(ratio)

Set the ratio of game time speed to simulation time speed.

world.setSimulationTimeScale(scale)

Set the simulation time scale.

world.unpause(tag)

Remove the given tag from the list of pause tags.

world.vfx

#VFX: Visual effects

## Type `MWScript`

MWScript.isRunning

Whether the script is currently running

MWScript.object

The object the script is attached to.

MWScript.player

The player the script refers to.

MWScript.recordId

Id of the script

MWScript.variables

Local variables of the script (mutable)

## Type `MWScriptFunctions`

MWScriptFunctions.getGlobalScript(recordId, player)

Returns global mwscript with given recordId.

MWScriptFunctions.getGlobalVariables(player)

Returns mutable global variables.

MWScriptFunctions.getLocalScript(object, player)

Returns local mwscript on `object`.

## Type `VFX`

VFX.remove(vfxId)

Remove all VFX with the given vfxId.

VFX.spawn(model, position, options)

Spawn a VFX at the given location in the world.

## Type `world`

### Field(s)

openmw.core#ObjectList

world.activeActors

List of currently active actors.

world.advanceTime(hours)

Advance the world time by a certain number of hours.

This advances time, weather, and AI, but does not perform other functions associated with the passage of time, e.g., regeneration.

### Parameter

-
` #number hours `:
Number of hours to advance time

#list<openmw.core#Cell>

world.cells

List of all cells

### Usage

`for i, cell in ipairs(world.cells) do print(cell) end`

world.createObject(recordId, count)

Create a new instance of the given record.

After creation the object is in the disabled state. Use :teleport to place to the world or :moveInto to put it into a container or an inventory.
Note that dynamically created creatures, NPCs, and container inventories will not respawn.

### Parameters

-
` #string recordId `:
Record ID. String ids that came from ESM3 content files are lower-cased. If another ID is provided, it must be provided exactly as it is, case sensitive.

-
` #number count `:
(optional, 1 by default) The number of objects in stack

### Return value

openmw.core#GameObject:

### Usages

-

` -- put 100 gold on the ground at the position of `actor`
money = world.createObject('gold_001', 100)
money:teleport(actor.cell.name, actor.position)`

-

`-- put 50 gold into the actor's inventory
money = world.createObject('gold_001', 50)
money:moveInto(types.Actor.inventory(actor))`

-

`-- create the an object for the first generated item
potion = world.createObject('Generated:0x0', 1)`

world.createRecord(record)

Creates a custom record in the world database; string IDs that came from ESM3 content files are lower-cased.

Eventually meant to support all records, but the current
set of supported types is limited to:

- openmw.types#ActivatorRecord,

- openmw.types#ArmorRecord,

- openmw.types#BookRecord,

- openmw.types#ClothingRecord,

- openmw.types#ContainerRecord,

- openmw.types#CreatureRecord,

- openmw.types#DoorRecord,

- openmw.core#Enchantment,

- openmw.types#LightRecord,

- openmw.types#MiscellaneousRecord,

- openmw.types#NpcRecord,

- openmw.types#PotionRecord,

- openmw.types#ProbeRecord,

- openmw.core#Spell,

- openmw.types#StaticRecord,

- openmw.types#WeaponRecord

### Parameter

-
` #any record `:
A record to be registered in the database. Must be one of the supported types. The id field is not used, one will be generated for you.

### Return value

#any:
A new record added to the database. The type is the same as the input's.

world.getCellById(cellId)

Loads a cell by ID provided

### Parameter

-
` #string cellId `:

### Return value

openmw.core#Cell:

world.getCellByName(cellName)

Loads a named cell

### Parameter

-
` #string cellName `:

### Return value

openmw.core#Cell:

world.getExteriorCell(gridX, gridY, cellOrName)

Loads an exterior cell by grid indices

### Parameters

-
` #number gridX `:

-
` #number gridY `:

-
` #any cellOrName `:
(optional) other cell or cell name in the same exterior world space

### Return value

openmw.core#Cell:

world.getGameTime()

Game time in seconds.

### Return value

#number:

world.getGameTimeScale()

The scale of game time relative to simulation time.

### Return value

#number:

world.getObjectByFormId(formId)

Return an object by RefNum/FormId.

Note: the function always returns openmw.core#GameObject and doesn't validate that
the object exists in the game world. If it doesn't exist or not yet loaded to memory),
then `obj:isValid()` will be `false`.

### Parameter

-
` #string formId `:
String returned by `core.getFormId`

### Return value

openmw.core#GameObject:

### Usage

`local obj = world.getObjectByFormId(core.getFormId('Morrowind.esm', 128964))`

world.getPausedTags()

The tags that are currently pausing the game.

### Return value

#table:

world.getSimulationTime()

Simulation time in seconds.

The number of simulation seconds passed in the game world since starting a new game.

### Return value

#number:

world.getSimulationTimeScale()

The scale of simulation time relative to real time.

### Return value

#number:

world.isWorldPaused()

Whether the world is paused.

### Return value

#boolean:

#MWScriptFunctions

world.mwscript

Functions related to MWScript (see #MWScriptFunctions).

world.pause(tag)

Pause the game starting from the next frame.

### Parameter

-
` #string tag `:
(optional, empty string by default) The game will be paused until `unpause` is called with the same tag.

openmw.core#ObjectList

world.players

List of players.

Currently (since multiplayer is not yet implemented) always has one element.

world.setGameTimeScale(ratio)

Set the ratio of game time speed to simulation time speed.

### Parameter

-
` #number ratio `:

world.setSimulationTimeScale(scale)

Set the simulation time scale.

### Parameter

-
` #number scale `:

world.unpause(tag)

Remove the given tag from the list of pause tags.

Resume the game starting from the next frame if the list became empty.

### Parameter

-
` #string tag `:
(optional, empty string by default) Needed to undo `pause` called with this tag.

#VFX

world.vfx

#VFX: Visual effects

## Type `MWScript`

### Usage

`for _, script in ipairs(world.mwscript.getLocalScripts(object)) do
-- print the value of local variable 'something' (0 if there is no such variable)
print(script.variables.something)
-- set the variable 'something' (raises an error if there is no such variable)
script.variables.something = 5
end`

### Field(s)

#boolean

MWScript.isRunning

Whether the script is currently running

openmw.core#GameObject

MWScript.object

The object the script is attached to.

openmw.core#GameObject

MWScript.player

The player the script refers to.

#string

MWScript.recordId

Id of the script

#MWScriptVariables

MWScript.variables

Local variables of the script (mutable)

## Type `MWScriptFunctions`

Functions related to MWScript.

### Field(s)

MWScriptFunctions.getGlobalScript(recordId, player)

Returns global mwscript with given recordId.

Returns `nil` if the script doesn't exist or is not started.
Currently there can be only one instance of each mwscript, but in multiplayer it will be possible to have a separate instance per player.

### Parameters

-
` #string recordId `:

-
` openmw.core#GameObject player `:
(optional) Will be used in multiplayer mode to get the script if there is a separate instance for each player. Currently has no effect.

### Return value

#MWScript, #nil:

MWScriptFunctions.getGlobalVariables(player)

Returns mutable global variables.

In multiplayer, these may be specific to the provided player.

### Parameter

-
` openmw.core#GameObject player `:
(optional) Will be used in multiplayer mode to get the globals if there is a separate instance for each player. Currently has no effect.

### Return value

#MWScriptVariables:

MWScriptFunctions.getLocalScript(object, player)

Returns local mwscript on `object`.

Returns `nil` if the script doesn't exist or is not started.

### Parameters

-
` openmw.core#GameObject object `:

-
` openmw.core#GameObject player `:
(optional) Will be used in multiplayer mode to get the script if there is a separate instance for each player. Currently has no effect.

### Return value

#MWScript, #nil:

## Type `MWScriptVariables`

` MWScriptVariables ` is a map of ` #string ` to ` #number `.

## Type `VFX`

### Field(s)

VFX.remove(vfxId)

Remove all VFX with the given vfxId.

Best invoked through the RemoveVfx global event

### Parameter

-
` #string vfxId `:
the vfxId of the VFX to remove. Passing an empty string removes all VFX that don't have a vfxId (this includes non-scripted VFX!)

### Usage

`-- Remove all VFX with vfxId "myvfx"
core.sendGlobalEvent('RemoveVfx', "myvfx")
`

VFX.spawn(model, position, options)

Spawn a VFX at the given location in the world.

Best invoked through the SpawnVfx global event

### Parameters

-
` #string model `:
string model path (normally taken from a record such as openmw.types#StaticRecord.model or similar)

-
` openmw.util#Vector3 position `:

-
` #table options `:
optional table of parameters. Can contain:

- `mwMagicVfx` - Boolean that if true causes the textureOverride parameter to only affect nodes with the Nif::RC_NiTexturingProperty property set. (default: true).

- `particleTextureOverride` - Name of a particle texture that should override this effect's default texture. (default: "")

- `scale` - A number that scales the size of the vfx (Default: 1)

- `useAmbientLight` - boolean, vfx get a white ambient light attached in Morrowind. If false don't attach this. (default: true)

- `loop` - boolean, if true the effect will loop until removed (default: false).

- `vfxId` - a string ID that can be used to remove the effect later, using VFX.remove. (Default: "").

### Usage

`-- Spawn a sanctuary effect near the player
local effect = core.magic.effects.records[core.magic.EFFECT_TYPE.Sanctuary]
local pos = self.position + util.vector3(0, 100, 0)
local model = types.Static.records[effect.castStatic].model
core.sendGlobalEvent('SpawnVfx', {model = model, position = pos, options = { useAmbientLight = false, vfxId = "myVfx" }})
`

Package openmw.vfs

Auxiliary Packages
