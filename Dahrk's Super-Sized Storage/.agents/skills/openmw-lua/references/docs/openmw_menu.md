# Package openmw.menu

# Package openmw.menu

API v129

Provides interfaces to interact with menu elements.

menu

## Usage

`local menu = require('openmw.menu')`

## Type `menu`

menu.STATE

All possible game states returned by menu.getState

menu.deleteGame(directory, slotName)

Delete a saved game

menu.getAllSaves()

List of all available saves, grouped by directory

menu.getCurrentSaveDir()

Current save directory

menu.getSaves(directory)

All the saves for the given directory

menu.getState()

Current game state

menu.loadGame(directory, slotName)

Load the game from a save slot

menu.newGame()

Start a new game

menu.quit()

Exit the game

menu.saveGame(description, slotName)

Save the game

## Type `STATE`

STATE.Ended

STATE.NoGame

STATE.Running

## Type `SaveInfo`

SaveInfo.contentFiles

SaveInfo.creationTime

Time at which the game was saved, as a timestamp in seconds. Can be passed as the second argument to `os.data`.

SaveInfo.description

SaveInfo.playerLevel

SaveInfo.playerName

SaveInfo.timePlayed

Gameplay time for this saved game. Note: available even with time played turned off

## Type `menu`

### Field(s)

#STATE

menu.STATE

All possible game states returned by menu.getState

menu.deleteGame(directory, slotName)

Delete a saved game

### Parameters

-
` #string directory `:
name of the save directory (e. g. character)

-
` #string slotName `:
name of the save slot

menu.getAllSaves()

List of all available saves, grouped by directory

### Return value

#map<#string,#map<#string,#SaveInfo>>:
map with directory names as keys, returning maps with save filenames as keys

menu.getCurrentSaveDir()

Current save directory

### Return value

#string:

menu.getSaves(directory)

All the saves for the given directory

### Parameter

-
` #string directory `:
name of the save directory (e. g. character)

### Return value

#map<#string,#SaveInfo>:
map with save filenames as keys

menu.getState()

Current game state

### Return value

#STATE:

menu.loadGame(directory, slotName)

Load the game from a save slot

### Parameters

-
` #string directory `:
name of the save directory (e. g. character)

-
` #string slotName `:
name of the save slot

menu.newGame()

Start a new game

menu.quit()

Exit the game

menu.saveGame(description, slotName)

Save the game

### Parameters

-
` #string description `:
human readable description of the save

-
` #string slotName `:
name of the save slot

## Type `STATE`

### Field(s)

STATE.Ended

STATE.NoGame

STATE.Running

## Type `SaveInfo`

### Field(s)

#list<#string>

SaveInfo.contentFiles

#number

SaveInfo.creationTime

Time at which the game was saved, as a timestamp in seconds. Can be passed as the second argument to `os.data`.

#string

SaveInfo.description

#string

SaveInfo.playerLevel

#string

SaveInfo.playerName

#number

SaveInfo.timePlayed

Gameplay time for this saved game. Note: available even with time played turned off

Package openmw.markup

Package openmw.nearby
