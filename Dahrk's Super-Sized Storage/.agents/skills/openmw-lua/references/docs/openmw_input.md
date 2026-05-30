# Package openmw.input

# Package openmw.input

API v129

Most mods should prefer to use the actions/triggers API over the direct input device methods.

Actions have one value on each frame (resolved just before the `onFrame` engine handler),
while Triggers don't have a value, but can occur multiple times on each frame.
Prefer to use built-in methods of binding actions, such as the inputBinding setting renderer

menu
player

## Usage

`local input = require('openmw.input')
-- Example of Action usage
input.registerAction {
key = 'MyAction',
type = input.ACTION_TYPE.Boolean,
l10n = 'MyLocalizationContext',
name = 'MyAction_name',
description = 'MyAction_full_description',
defaultValue = false,
}
return {
onFrame = function()
local myAction = input.getBooleanActionValue('MyAction')
if (myAction) then print('My action is active!') end
end,
}
-- Example of Trigger usage
input.registerTrigger {
key = 'MyTrigger',
l10n = 'MyLocalizationContext',
name = 'MyTrigger_name',
description = 'MyTrigger_full_description',
}
input.registerTriggerHandler('MyTrigger', async:callback(function() print('MyTrigger') end))`

## Type `input`

input.ACTION

(DEPRECATED, use getBooleanActionValue) Values that can be used with isActionPressed.

input.ACTION_TYPE

Values that can be used in registerAction

input.CONTROLLER_AXIS

Values that can be used with getAxisValue.

input.CONTROLLER_BUTTON

Values that can be passed to onControllerButtonPress/onControllerButtonRelease engine handlers.

input.CONTROL_SWITCH

[Deprecated, moved to types.Player] Values that can be used with getControlSwitch/setControlSwitch.

input.KEY

Key codes.

input.actions

Map of all currently registered actions

input.activateTrigger(key)

Activates the trigger with the given key

input.bindAction(key, callback, dependencies)

Provides a function computing the value of given input action.

input.getAxisValue(axisId)

Get value of an axis of a game controller.

input.getBooleanActionValue(key)

Returns the value of a Boolean action

input.getControlSwitch(key)

[Deprecated, moved to types.Player] Get state of a control switch.

input.getKeyName(code)

Returns a human readable name for the given key code

input.getMouseMoveX()

Horizontal mouse movement during the last frame.

input.getMouseMoveY()

Vertical mouse movement during the last frame.

input.getNumberActionValue(key)

Returns the value of a Number action

input.getRangeActionValue(key)

Returns the value of a Range action

input.isActionPressed(actionId)

(DEPRECATED, use getBooleanActionValue) Input bindings can be changed in-game using Options/Controls menu.

input.isAltPressed()

Is `Alt` key pressed.

input.isControllerButtonPressed(buttonId)

Is a controller button currently pressed.

input.isCtrlPressed()

Is `Ctrl` key pressed.

input.isIdle()

Is the player idle.

input.isKeyPressed(keyCode)

Is a keyboard button currently pressed.

input.isMouseButtonPressed(buttonId)

Is a mouse button currently pressed.

input.isShiftPressed()

Is `Shift` key pressed.

input.isSuperPressed()

Is `Super`/`Win` key pressed.

input.registerAction(info)

Registers a new input action.

input.registerActionHandler(key, callback)

Registers a function to be called whenever the action's value changes

input.registerTrigger(info)

Registers a new input trigger.

input.registerTriggerHandler(key, callback)

Registers a function to be called whenever the trigger activates

input.setControlSwitch(key, value)

[Deprecated, moved to types.Player] Set state of a control switch.

input.triggers

Map of all currently registered triggers

## Type `ACTION`

ACTION.Activate

ACTION.AlwaysRun

ACTION.AutoMove

ACTION.Console

ACTION.CycleSpellLeft

ACTION.CycleSpellRight

ACTION.CycleWeaponLeft

ACTION.CycleWeaponRight

ACTION.GameMenu

ACTION.Inventory

ACTION.Journal

ACTION.Jump

ACTION.MoveBackward

ACTION.MoveForward

ACTION.MoveLeft

ACTION.MoveRight

ACTION.QuickKey1

ACTION.QuickKey10

ACTION.QuickKey2

ACTION.QuickKey3

ACTION.QuickKey4

ACTION.QuickKey5

ACTION.QuickKey6

ACTION.QuickKey7

ACTION.QuickKey8

ACTION.QuickKey9

ACTION.QuickKeysMenu

ACTION.QuickLoad

ACTION.QuickMenu

ACTION.QuickSave

ACTION.Run

ACTION.Screenshot

ACTION.Sneak

ACTION.ToggleDebug

ACTION.ToggleHUD

ACTION.TogglePOV

ACTION.TogglePostProcessorHUD

ACTION.ToggleSpell

ACTION.ToggleWeapon

ACTION.Use

ACTION.ZoomIn

ACTION.ZoomOut

## Type `ACTION_TYPE`

ACTION_TYPE.Boolean

Input action with value of true or false

ACTION_TYPE.Number

Input action with a numeric value

ACTION_TYPE.Range

Input action with a numeric value between 0 and 1 (inclusive)

## Type `ActionInfo`

ActionInfo.defaultValue

initial value of the action

ActionInfo.description

Localization key of the action's description

ActionInfo.key

ActionInfo.l10n

Localization context containing the name and description keys

ActionInfo.name

Localization key of the action's name

ActionInfo.type

## Type `CONTROLLER_AXIS`

CONTROLLER_AXIS.LeftX

Left stick horizontal axis (from -1 to 1)

CONTROLLER_AXIS.LeftY

Left stick vertical axis (from -1 to 1)

CONTROLLER_AXIS.LookLeftRight

(DEPRECATED, use the LookLeftRight action) View direction horizontal axis (RightX by default, can be mapped to another axis in Options/Controls menu)

CONTROLLER_AXIS.LookUpDown

(DEPRECATED, use the LookUpDown action) View direction vertical axis (RightY by default, can be mapped to another axis in Options/Controls menu)

CONTROLLER_AXIS.MoveForwardBackward

(DEPRECATED, use the MoveForwardBackward action) Movement forward/backward (LeftY by default, can be mapped to another axis in Options/Controls menu)

CONTROLLER_AXIS.MoveLeftRight

(DEPRECATED, use the MoveLeftRight action) Side movement (LeftX by default, can be mapped to another axis in Options/Controls menu)

CONTROLLER_AXIS.RightX

Right stick horizontal axis (from -1 to 1)

CONTROLLER_AXIS.RightY

Right stick vertical axis (from -1 to 1)

CONTROLLER_AXIS.TriggerLeft

Left trigger (from 0 to 1)

CONTROLLER_AXIS.TriggerRight

Right trigger (from 0 to 1)

## Type `CONTROLLER_BUTTON`

CONTROLLER_BUTTON.A

CONTROLLER_BUTTON.B

CONTROLLER_BUTTON.Back

CONTROLLER_BUTTON.DPadDown

CONTROLLER_BUTTON.DPadLeft

CONTROLLER_BUTTON.DPadRight

CONTROLLER_BUTTON.DPadUp

CONTROLLER_BUTTON.Guide

CONTROLLER_BUTTON.LeftShoulder

CONTROLLER_BUTTON.LeftStick

CONTROLLER_BUTTON.Misc1

CONTROLLER_BUTTON.Paddle1

CONTROLLER_BUTTON.Paddle2

CONTROLLER_BUTTON.Paddle3

CONTROLLER_BUTTON.Paddle4

CONTROLLER_BUTTON.RightShoulder

CONTROLLER_BUTTON.RightStick

CONTROLLER_BUTTON.Start

CONTROLLER_BUTTON.Touchpad

CONTROLLER_BUTTON.X

CONTROLLER_BUTTON.Y

## Type `CONTROL_SWITCH`

CONTROL_SWITCH.Controls

Ability to move

CONTROL_SWITCH.Fighting

Ability to attack

CONTROL_SWITCH.Jumping

Ability to jump

CONTROL_SWITCH.Looking

Ability to change view direction

CONTROL_SWITCH.Magic

Ability to use magic

CONTROL_SWITCH.VanityMode

Vanity view if the player doesn't touch controls for a long time

CONTROL_SWITCH.ViewMode

Ability to toggle 1st/3rd person view

## Type `KEY`

KEY.A

KEY.Apostrophe

KEY.B

KEY.BackSlash

KEY.Backspace

KEY.C

KEY.CapsLock

KEY.Comma

KEY.D

KEY.Delete

KEY.DownArrow

KEY.E

KEY.End

KEY.Enter

KEY.Equals

KEY.Escape

KEY.F

KEY.F1

KEY.F10

KEY.F11

KEY.F12

KEY.F2

KEY.F3

KEY.F4

KEY.F5

KEY.F6

KEY.F7

KEY.F8

KEY.F9

KEY.G

KEY.H

KEY.Home

KEY.I

KEY.Insert

KEY.J

KEY.K

KEY.L

KEY.LeftAlt

KEY.LeftArrow

KEY.LeftBracket

KEY.LeftCtrl

KEY.LeftShift

KEY.LeftSuper

KEY.M

KEY.Minus

KEY.N

KEY.NP_0

KEY.NP_1

KEY.NP_2

KEY.NP_3

KEY.NP_4

KEY.NP_5

KEY.NP_6

KEY.NP_7

KEY.NP_8

KEY.NP_9

KEY.NP_Delete

KEY.NP_Divide

KEY.NP_Enter

KEY.NP_Minus

KEY.NP_Multiply

KEY.NP_Plus

KEY.NumLock

KEY.O

KEY.P

KEY.PageDown

KEY.PageUp

KEY.Pause

KEY.Period

KEY.PrintScreen

KEY.Q

KEY.R

KEY.RightAlt

KEY.RightArrow

KEY.RightBracket

KEY.RightCtrl

KEY.RightShift

KEY.RightSuper

KEY.S

KEY.ScrollLock

KEY.Semicolon

KEY.Slash

KEY.Space

KEY.T

KEY.Tab

KEY.U

KEY.UpArrow

KEY.V

KEY.W

KEY.X

KEY.Y

KEY.Z

KEY._0

KEY._1

KEY._2

KEY._3

KEY._4

KEY._5

KEY._6

KEY._7

KEY._8

KEY._9

## Type `KeyboardEvent`

KeyboardEvent.code

Key code.

KeyboardEvent.symbol

The pressed symbol (1-symbol string if can be represented or an empty string otherwise).

KeyboardEvent.withAlt

Is `Alt` key pressed.

KeyboardEvent.withCtrl

Is `Control` key pressed.

KeyboardEvent.withShift

Is `Shift` key pressed.

KeyboardEvent.withSuper

Is `Super`/`Win` key pressed.

## Type `TouchEvent`

TouchEvent.device

Device id (there might be multiple touch devices connected). Note: the specific device ids are not guaranteed. Always use previous user input (onTouch... handlers) to get a valid device id (e. g. in your script's settings page).

TouchEvent.finger

Finger id (the device might support multitouch).

TouchEvent.position

Relative position on the touch device (0 to 1 from top left corner),

TouchEvent.pressure

Pressure of the finger.

## Type `TriggerInfo`

TriggerInfo.description

Localization key of the trigger's description

TriggerInfo.key

TriggerInfo.l10n

Localization context containing the name and description keys

TriggerInfo.name

Localization key of the trigger's name

## Type `input`

### Field(s)

#ACTION

input.ACTION

(DEPRECATED, use getBooleanActionValue) Values that can be used with isActionPressed.

#ACTION_TYPE

input.ACTION_TYPE

Values that can be used in registerAction

#CONTROLLER_AXIS

input.CONTROLLER_AXIS

Values that can be used with getAxisValue.

#CONTROLLER_BUTTON

input.CONTROLLER_BUTTON

Values that can be passed to onControllerButtonPress/onControllerButtonRelease engine handlers.

#CONTROL_SWITCH

input.CONTROL_SWITCH

[Deprecated, moved to types.Player] Values that can be used with getControlSwitch/setControlSwitch.

#KEY

input.KEY

Key codes.

#map<#string,#ActionInfo>

input.actions

Map of all currently registered actions

input.activateTrigger(key)

Activates the trigger with the given key

### Parameter

-
` #string key `:

input.bindAction(key, callback, dependencies)

Provides a function computing the value of given input action.

The callback is called once a frame, after the values of dependency actions are resolved.
Throws an error if a cyclic action dependency is detected.

### Parameters

-
` #string key `:

-
` openmw.async#Callback callback `:
returning the new value of the action, and taking as arguments:
frame time in seconds,
value of the function,
value of the first dependency action,
...

-
` #list<#string> dependencies `:

### Usage

` input.bindAction('Activate', async:callback(function(dt, use, sneak, run)
-- while sneaking, only activate things while holding the run binding
return use and (run or not sneak)
end), { 'Sneak', 'Run' })`

input.getAxisValue(axisId)

Get value of an axis of a game controller.

### Parameter

-
` #number axisId `:
Index of a controller axis, one of openmw.input#CONTROLLER_AXIS.

### Return value

#number:
Value in range [-1, 1].

input.getBooleanActionValue(key)

Returns the value of a Boolean action

### Parameter

-
` #string key `:

### Return value

#boolean:

input.getControlSwitch(key)

[Deprecated, moved to types.Player] Get state of a control switch.

I.e. is the player able to move/fight/jump/etc.

### Parameter

-
` #ControlSwitch key `:
Control type (see openmw.input#CONTROL_SWITCH)

### Return value

#boolean:

input.getKeyName(code)

Returns a human readable name for the given key code

### Parameter

-
` #KeyCode code `:
A key code (see openmw.input#KEY)

### Return value

#string:

input.getMouseMoveX()

Horizontal mouse movement during the last frame.

### Return value

#number:

input.getMouseMoveY()

Vertical mouse movement during the last frame.

### Return value

#number:

input.getNumberActionValue(key)

Returns the value of a Number action

### Parameter

-
` #string key `:

### Return value

#number:

input.getRangeActionValue(key)

Returns the value of a Range action

### Parameter

-
` #string key `:

### Return value

#number:

input.isActionPressed(actionId)

(DEPRECATED, use getBooleanActionValue) Input bindings can be changed in-game using Options/Controls menu.

### Parameter

-
` #number actionId `:
One of openmw.input#ACTION

### Return value

#boolean:

input.isAltPressed()

Is `Alt` key pressed.

### Return value

#boolean:

input.isControllerButtonPressed(buttonId)

Is a controller button currently pressed.

### Parameter

-
` #number buttonId `:
Button index (see openmw.input#CONTROLLER_BUTTON)

### Return value

#boolean:

input.isCtrlPressed()

Is `Ctrl` key pressed.

### Return value

#boolean:

input.isIdle()

Is the player idle.

### Return value

#boolean:

input.isKeyPressed(keyCode)

Is a keyboard button currently pressed.

### Parameter

-
` #KeyCode keyCode `:
Key code (see openmw.input#KEY)

### Return value

#boolean:

input.isMouseButtonPressed(buttonId)

Is a mouse button currently pressed.

### Parameter

-
` #number buttonId `:
Button index (1 - left, 2 - middle, 3 - right, 4 - X1, 5 - X2)

### Return value

#boolean:

input.isShiftPressed()

Is `Shift` key pressed.

### Return value

#boolean:

input.isSuperPressed()

Is `Super`/`Win` key pressed.

### Return value

#boolean:

input.registerAction(info)

Registers a new input action.

The key must be unique

### Parameter

-
` #ActionInfo info `:

input.registerActionHandler(key, callback)

Registers a function to be called whenever the action's value changes

### Parameters

-
` #string key `:

-
` openmw.async#Callback callback `:
takes the new action value as the only argument

input.registerTrigger(info)

Registers a new input trigger.

The key must be unique

### Parameter

-
` #TriggerInfo info `:

input.registerTriggerHandler(key, callback)

Registers a function to be called whenever the trigger activates

### Parameters

-
` #string key `:

-
` openmw.async#Callback callback `:
takes the new action value as the only argument

input.setControlSwitch(key, value)

[Deprecated, moved to types.Player] Set state of a control switch.

I.e. forbid or allow the player to move/fight/jump/etc.

### Parameters

-
` #ControlSwitch key `:
Control type (see openmw.input#CONTROL_SWITCH)

-
` #boolean value `:

#map<#string,#TriggerInfo>

input.triggers

Map of all currently registered triggers

## Type `ACTION`

(DEPRECATED, use actions with matching keys)

### Field(s)

#number

ACTION.Activate

#number

ACTION.AlwaysRun

#number

ACTION.AutoMove

#number

ACTION.Console

#number

ACTION.CycleSpellLeft

#number

ACTION.CycleSpellRight

#number

ACTION.CycleWeaponLeft

#number

ACTION.CycleWeaponRight

#number

ACTION.GameMenu

#number

ACTION.Inventory

#number

ACTION.Journal

#number

ACTION.Jump

#number

ACTION.MoveBackward

#number

ACTION.MoveForward

#number

ACTION.MoveLeft

#number

ACTION.MoveRight

#number

ACTION.QuickKey1

#number

ACTION.QuickKey10

#number

ACTION.QuickKey2

#number

ACTION.QuickKey3

#number

ACTION.QuickKey4

#number

ACTION.QuickKey5

#number

ACTION.QuickKey6

#number

ACTION.QuickKey7

#number

ACTION.QuickKey8

#number

ACTION.QuickKey9

#number

ACTION.QuickKeysMenu

#number

ACTION.QuickLoad

#number

ACTION.QuickMenu

#number

ACTION.QuickSave

#number

ACTION.Run

#number

ACTION.Screenshot

#number

ACTION.Sneak

#number

ACTION.ToggleDebug

#number

ACTION.ToggleHUD

#number

ACTION.TogglePOV

#number

ACTION.TogglePostProcessorHUD

#number

ACTION.ToggleSpell

#number

ACTION.ToggleWeapon

#number

ACTION.Use

#number

ACTION.ZoomIn

#number

ACTION.ZoomOut

## Type `ACTION_TYPE`

### Field(s)

#ActionType

ACTION_TYPE.Boolean

Input action with value of true or false

#ActionType

ACTION_TYPE.Number

Input action with a numeric value

#ActionType

ACTION_TYPE.Range

Input action with a numeric value between 0 and 1 (inclusive)

## Type `ActionInfo`

### Field(s)

ActionInfo.defaultValue

initial value of the action

#string

ActionInfo.description

Localization key of the action's description

#string

ActionInfo.key

#string

ActionInfo.l10n

Localization context containing the name and description keys

#string

ActionInfo.name

Localization key of the action's name

#ActionType

ActionInfo.type

## Type `ActionType`

## Type `CONTROLLER_AXIS`

Ids of game controller axises.

Used as an argument in getAxisValue.

### Field(s)

#number

CONTROLLER_AXIS.LeftX

Left stick horizontal axis (from -1 to 1)

#number

CONTROLLER_AXIS.LeftY

Left stick vertical axis (from -1 to 1)

#number

CONTROLLER_AXIS.LookLeftRight

(DEPRECATED, use the LookLeftRight action) View direction horizontal axis (RightX by default, can be mapped to another axis in Options/Controls menu)

#number

CONTROLLER_AXIS.LookUpDown

(DEPRECATED, use the LookUpDown action) View direction vertical axis (RightY by default, can be mapped to another axis in Options/Controls menu)

#number

CONTROLLER_AXIS.MoveForwardBackward

(DEPRECATED, use the MoveForwardBackward action) Movement forward/backward (LeftY by default, can be mapped to another axis in Options/Controls menu)

#number

CONTROLLER_AXIS.MoveLeftRight

(DEPRECATED, use the MoveLeftRight action) Side movement (LeftX by default, can be mapped to another axis in Options/Controls menu)

#number

CONTROLLER_AXIS.RightX

Right stick horizontal axis (from -1 to 1)

#number

CONTROLLER_AXIS.RightY

Right stick vertical axis (from -1 to 1)

#number

CONTROLLER_AXIS.TriggerLeft

Left trigger (from 0 to 1)

#number

CONTROLLER_AXIS.TriggerRight

Right trigger (from 0 to 1)

## Type `CONTROLLER_BUTTON`

### Field(s)

#number

CONTROLLER_BUTTON.A

#number

CONTROLLER_BUTTON.B

#number

CONTROLLER_BUTTON.Back

#number

CONTROLLER_BUTTON.DPadDown

#number

CONTROLLER_BUTTON.DPadLeft

#number

CONTROLLER_BUTTON.DPadRight

#number

CONTROLLER_BUTTON.DPadUp

#number

CONTROLLER_BUTTON.Guide

#number

CONTROLLER_BUTTON.LeftShoulder

#number

CONTROLLER_BUTTON.LeftStick

#number

CONTROLLER_BUTTON.Misc1

#number

CONTROLLER_BUTTON.Paddle1

#number

CONTROLLER_BUTTON.Paddle2

#number

CONTROLLER_BUTTON.Paddle3

#number

CONTROLLER_BUTTON.Paddle4

#number

CONTROLLER_BUTTON.RightShoulder

#number

CONTROLLER_BUTTON.RightStick

#number

CONTROLLER_BUTTON.Start

#number

CONTROLLER_BUTTON.Touchpad

#number

CONTROLLER_BUTTON.X

#number

CONTROLLER_BUTTON.Y

## Type `CONTROL_SWITCH`

### Field(s)

#ControlSwitch

CONTROL_SWITCH.Controls

Ability to move

#ControlSwitch

CONTROL_SWITCH.Fighting

Ability to attack

#ControlSwitch

CONTROL_SWITCH.Jumping

Ability to jump

#ControlSwitch

CONTROL_SWITCH.Looking

Ability to change view direction

#ControlSwitch

CONTROL_SWITCH.Magic

Ability to use magic

#ControlSwitch

CONTROL_SWITCH.VanityMode

Vanity view if the player doesn't touch controls for a long time

#ControlSwitch

CONTROL_SWITCH.ViewMode

Ability to toggle 1st/3rd person view

## Type `ControlSwitch`

String id of a #CONTROL_SWITCH

## Type `KEY`

### Field(s)

#KeyCode

KEY.A

#KeyCode

KEY.Apostrophe

#KeyCode

KEY.B

#KeyCode

KEY.BackSlash

#KeyCode

KEY.Backspace

#KeyCode

KEY.C

#KeyCode

KEY.CapsLock

#KeyCode

KEY.Comma

#KeyCode

KEY.D

#KeyCode

KEY.Delete

#KeyCode

KEY.DownArrow

#KeyCode

KEY.E

#KeyCode

KEY.End

#KeyCode

KEY.Enter

#KeyCode

KEY.Equals

#KeyCode

KEY.Escape

#KeyCode

KEY.F

#KeyCode

KEY.F1

#KeyCode

KEY.F10

#KeyCode

KEY.F11

#KeyCode

KEY.F12

#KeyCode

KEY.F2

#KeyCode

KEY.F3

#KeyCode

KEY.F4

#KeyCode

KEY.F5

#KeyCode

KEY.F6

#KeyCode

KEY.F7

#KeyCode

KEY.F8

#KeyCode

KEY.F9

#KeyCode

KEY.G

#KeyCode

KEY.H

#KeyCode

KEY.Home

#KeyCode

KEY.I

#KeyCode

KEY.Insert

#KeyCode

KEY.J

#KeyCode

KEY.K

#KeyCode

KEY.L

#KeyCode

KEY.LeftAlt

#KeyCode

KEY.LeftArrow

#KeyCode

KEY.LeftBracket

#KeyCode

KEY.LeftCtrl

#KeyCode

KEY.LeftShift

#KeyCode

KEY.LeftSuper

#KeyCode

KEY.M

#KeyCode

KEY.Minus

#KeyCode

KEY.N

#KeyCode

KEY.NP_0

#KeyCode

KEY.NP_1

#KeyCode

KEY.NP_2

#KeyCode

KEY.NP_3

#KeyCode

KEY.NP_4

#KeyCode

KEY.NP_5

#KeyCode

KEY.NP_6

#KeyCode

KEY.NP_7

#KeyCode

KEY.NP_8

#KeyCode

KEY.NP_9

#KeyCode

KEY.NP_Delete

#KeyCode

KEY.NP_Divide

#KeyCode

KEY.NP_Enter

#KeyCode

KEY.NP_Minus

#KeyCode

KEY.NP_Multiply

#KeyCode

KEY.NP_Plus

#KeyCode

KEY.NumLock

#KeyCode

KEY.O

#KeyCode

KEY.P

#KeyCode

KEY.PageDown

#KeyCode

KEY.PageUp

#KeyCode

KEY.Pause

#KeyCode

KEY.Period

#KeyCode

KEY.PrintScreen

#KeyCode

KEY.Q

#KeyCode

KEY.R

#KeyCode

KEY.RightAlt

#KeyCode

KEY.RightArrow

#KeyCode

KEY.RightBracket

#KeyCode

KEY.RightCtrl

#KeyCode

KEY.RightShift

#KeyCode

KEY.RightSuper

#KeyCode

KEY.S

#KeyCode

KEY.ScrollLock

#KeyCode

KEY.Semicolon

#KeyCode

KEY.Slash

#KeyCode

KEY.Space

#KeyCode

KEY.T

#KeyCode

KEY.Tab

#KeyCode

KEY.U

#KeyCode

KEY.UpArrow

#KeyCode

KEY.V

#KeyCode

KEY.W

#KeyCode

KEY.X

#KeyCode

KEY.Y

#KeyCode

KEY.Z

#KeyCode

KEY._0

#KeyCode

KEY._1

#KeyCode

KEY._2

#KeyCode

KEY._3

#KeyCode

KEY._4

#KeyCode

KEY._5

#KeyCode

KEY._6

#KeyCode

KEY._7

#KeyCode

KEY._8

#KeyCode

KEY._9

## Type `KeyCode`

Numeric id of a #KEY

## Type `KeyboardEvent`

The argument of `onKeyPress`/`onKeyRelease` engine handlers.

### Field(s)

#KeyCode

KeyboardEvent.code

Key code.

#string

KeyboardEvent.symbol

The pressed symbol (1-symbol string if can be represented or an empty string otherwise).

#boolean

KeyboardEvent.withAlt

Is `Alt` key pressed.

#boolean

KeyboardEvent.withCtrl

Is `Control` key pressed.

#boolean

KeyboardEvent.withShift

Is `Shift` key pressed.

#boolean

KeyboardEvent.withSuper

Is `Super`/`Win` key pressed.

## Type `TouchEvent`

The argument of onTouchPress/onTouchRelease/onTouchMove engine handlers.

### Field(s)

#number

TouchEvent.device

Device id (there might be multiple touch devices connected). Note: the specific device ids are not guaranteed. Always use previous user input (onTouch... handlers) to get a valid device id (e. g. in your script's settings page).

#number

TouchEvent.finger

Finger id (the device might support multitouch).

openmw.util#Vector2

TouchEvent.position

Relative position on the touch device (0 to 1 from top left corner),

#number

TouchEvent.pressure

Pressure of the finger.

## Type `TriggerInfo`

### Field(s)

#string

TriggerInfo.description

Localization key of the trigger's description

#string

TriggerInfo.key

#string

TriggerInfo.l10n

Localization context containing the name and description keys

#string

TriggerInfo.name

Localization key of the trigger's name

Package openmw.debug

Package openmw.markup
