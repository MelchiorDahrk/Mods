# Interface UI

# Interface UI

API v129

player

## Usage

`require('openmw.interfaces').UI`

## Type `UI`

UI.MODE

All available UI modes.

UI.WINDOW

All windows.

UI.addMode(mode, options)

Add mode to stack without dropping other active modes.

UI.getMode()

Get current mode (nil if all windows are closed), equivalent to `I.UI.modes[#I.UI.modes]`

UI.getWindowsForMode(mode)

Returns windows that can be shown in given mode.

UI.isHudVisible()

Returns if the player HUD is visible or not

UI.isWindowVisible(windowName)

Returns if the given window is visible or not

UI.modes

Stack of currently active modes

UI.registerWindow(windowName, showFn, hideFn)

Register new implementation for the window with given name; overrides previous implementation.

UI.removeMode(mode)

Remove the specified mode from active modes.

UI.setHudVisibility(showHud)

Set whether the UI should be visible.

UI.setMode(mode, options)

Drop all active modes and set mode.

UI.setPauseOnMode(mode, shouldPause)

Set whether the mode should pause the game.

UI.showInteractiveMessage(message, options)

Shows a message as an interactive message box pausing the game, with a single button with the localized text OK.

UI.version

Interface version

## Type `UI`

### Field(s)

#table

UI.MODE

All available UI modes.

Use `view(I.UI.MODE)` in `luap` console mode to see the list.

#table

UI.WINDOW

All windows.

Use `view(I.UI.WINDOW)` in `luap` console mode to see the list.

UI.addMode(mode, options)

Add mode to stack without dropping other active modes.

### Parameters

-
` #string mode `:
New mode

-
` #table options `:
(optional) Table with keys 'windows' and/or 'target' (see example).

### Usages

-

`I.UI.addMode('Journal') -- open journal without dropping active modes.`

-

`-- Open barter with an NPC
I.UI.addMode('Barter', {target = actor})`

UI.getMode()

Get current mode (nil if all windows are closed), equivalent to `I.UI.modes[#I.UI.modes]`

### Return value

#string:

UI.getWindowsForMode(mode)

Returns windows that can be shown in given mode.

### Parameter

-
` #string mode `:

### Return value

#table:

UI.isHudVisible()

Returns if the player HUD is visible or not

### Return value

#boolean:

UI.isWindowVisible(windowName)

Returns if the given window is visible or not

### Parameter

-
` #string windowName `:

### Return value

#boolean:

UI.modes

Stack of currently active modes

UI.registerWindow(windowName, showFn, hideFn)

Register new implementation for the window with given name; overrides previous implementation.

Adding new windows is not supported yet. At the moment it is only possible to override built-in windows.

### Parameters

-
` #string windowName `:

-
` #function showFn `:
Callback that will be called when the window should become visible

-
` #function hideFn `:
Callback that will be called when the window should be hidden

UI.removeMode(mode)

Remove the specified mode from active modes.

### Parameter

-
` #string mode `:
Mode to drop

UI.setHudVisibility(showHud)

Set whether the UI should be visible.

### Parameter

-
` #boolean showHud `:

UI.setMode(mode, options)

Drop all active modes and set mode.

### Parameters

-
` #string mode `:
(optional) New mode

-
` #table options `:
(optional) Table with keys 'windows' and/or 'target' (see example).

### Usages

-

`I.UI.setMode() -- drop all modes`

-

`I.UI.setMode('Interface') -- drop all modes and open interface`

-

`-- Drop all modes, open interface, but show only the map window.
I.UI.setMode('Interface', {windows = {'Map'}})`

UI.setPauseOnMode(mode, shouldPause)

Set whether the mode should pause the game.

### Parameters

-
` #string mode `:
Mode to configure

-
` #boolean shouldPause `:

UI.showInteractiveMessage(message, options)

Shows a message as an interactive message box pausing the game, with a single button with the localized text OK.

### Parameters

-
` #string message `:
Message to display

-
` #table options `:
Options (none yet)

#number

UI.version

Interface version

Interface SkillProgression

UI reference
