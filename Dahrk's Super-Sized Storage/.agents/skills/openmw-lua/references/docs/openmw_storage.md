# Package openmw.storage

# Package openmw.storage

API v129

Contains functions to work with permanent Lua storage.

global
menu
local
player
load

## Usage

`local storage = require('openmw.storage')
local myModData = storage.globalSection('MyModExample')
myModData:set("someVariable", 1.0)
myModData:set("anotherVariable", { exampleStr='abc', exampleBool=true })
local async = require('openmw.async')
myModData:subscribe(async:callback(function(section, key)
if key then
print('Value is changed:', key, '=', myModData:get(key))
else
print('All values are changed')
end
end))`

## Type `storage`

storage.LIFE_TIME

Possible #LifeTime values

storage.allGlobalSections()

Get all global sections as a table; can be used by global scripts only.

storage.allPlayerSections()

Get all player sections as a table; can only be used by player and menu scripts.

storage.globalSection(sectionName)

Get a section of the global storage; can be used by any script, but only global scripts can change values.

storage.playerSection(sectionName)

Get a section of the player storage; can only be used by player and menu scripts.

## Type `LifeTime`

LifeTime.GameSession

"1" Data is stored for the whole game session

LifeTime.Persistent

"0" Data is stored for the whole game session and remains on disk after quitting the game

LifeTime.Temporary

"2" Data is stored until script context reset

## Type `StorageSection`

StorageSection:asTable()

Copy all values and return them as a table.

StorageSection:get(key)

Get a value by a string key; if the value is a table it is readonly.

StorageSection:getCopy(key)

Get a value by a string key; if the value is a table it returns a copy.

StorageSection:removeOnExit()

(DEPRECATED, use `setLifeTime(openmw.storage.LIFE_TIME.Temporary)`) Make the whole section temporary: will be removed on exit or when load a save.

StorageSection:reset(values)

Remove all existing values and assign values from given (the arg is optional) table.

StorageSection:set(key, value)

Set a value by a string key; can not be used for global storage from a local script.

StorageSection:setLifeTime(lifeTime)

Set the lifetime of given storage section.

StorageSection:subscribe(callback)

Subscribe to changes in this section.

## Type `storage`

### Field(s)

#LifeTime

storage.LIFE_TIME

Possible #LifeTime values

storage.allGlobalSections()

Get all global sections as a table; can be used by global scripts only.

Note that adding/removing items to the returned table doesn't create or remove sections.

### Return value

#table:

storage.allPlayerSections()

Get all player sections as a table; can only be used by player and menu scripts.

Note that adding/removing items to the returned table doesn't create or remove sections.

### Return value

#table:

storage.globalSection(sectionName)

Get a section of the global storage; can be used by any script, but only global scripts can change values.

Menu scripts can only access it when a game is running.
Creates the section if it doesn't exist.

### Parameter

-
` #string sectionName `:

### Return value

#StorageSection:

storage.playerSection(sectionName)

Get a section of the player storage; can only be used by player and menu scripts.

Creates the section if it doesn't exist.

### Parameter

-
` #string sectionName `:

### Return value

#StorageSection:

## Type `LifeTime`

`storage.LIFE_TIME`

### Field(s)

#number

LifeTime.GameSession

"1" Data is stored for the whole game session

#number

LifeTime.Persistent

"0" Data is stored for the whole game session and remains on disk after quitting the game

#number

LifeTime.Temporary

"2" Data is stored until script context reset

## Type `StorageSection`

A map `key -> value` that represents a storage section.

### Field(s)

StorageSection:asTable()

Copy all values and return them as a table.

### Return value

#table:

StorageSection:get(key)

Get a value by a string key; if the value is a table it is readonly.

### Parameter

-
` #string key `:

### Return value

#any:

StorageSection:getCopy(key)

Get a value by a string key; if the value is a table it returns a copy.

### Parameter

-
` #string key `:

### Return value

#any:

StorageSection:removeOnExit()

(DEPRECATED, use `setLifeTime(openmw.storage.LIFE_TIME.Temporary)`) Make the whole section temporary: will be removed on exit or when load a save.

Temporary sections have the same interface to get/set values, the only difference is they will not
be saved to the permanent storage on exit.
This function can be used for a global storage section from a global script or for a player storage section from a player or menu script.

### Usage

`local storage = require('openmw.storage')
local myModData = storage.globalSection('MyModExample')
myModData:removeOnExit()`

StorageSection:reset(values)

Remove all existing values and assign values from given (the arg is optional) table.

This function can not be used for a global storage section from a local script.
Note: `section:reset()` removes the section.

### Parameter

-
` #table values `:
(optional) New values

StorageSection:set(key, value)

Set a value by a string key; can not be used for global storage from a local script.

### Parameters

-
` #string key `:

-
` #any value `:

StorageSection:setLifeTime(lifeTime)

Set the lifetime of given storage section.

New sections initially have a Persistent lifetime.
This function can be used for a global storage section from a global script or for a player storage section from a player or menu script.

### Parameter

-
` #LifeTime lifeTime `:
Section life time

### Usage

`local storage = require('openmw.storage')
local myModData = storage.globalSection('MyModExample')
myModData:setLifeTime(storage.LIFE_TIME.Temporary)`

StorageSection:subscribe(callback)

Subscribe to changes in this section.

First argument of the callback is the name of the section (so one callback can be used for different sections).
The second argument is the changed key (or `nil` if `reset` was used and all values were changed at the same time)

### Parameter

-
` openmw.async#Callback callback `:

Package openmw.self

Package openmw.types
