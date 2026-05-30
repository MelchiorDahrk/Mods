# Interface GamepadControls

# Interface GamepadControls

API v129

Gamepad control interface

player

## Usage

`require('openmw.interfaces').GamepadControls`

## Type `GamepadControls`

GamepadControls.isControllerMenusEnabled()

Checks if the controller menu option is enabled.

GamepadControls.isGamepadCursorActive()

Checks if the gamepad cursor is active.

GamepadControls.setGamepadCursorActive(value)

Sets if the gamepad cursor is active.

GamepadControls.version

Interface version

## Type `GamepadControls`

### Field(s)

GamepadControls.isControllerMenusEnabled()

Checks if the controller menu option is enabled.

If true, UI is replaced with a more controller appropriate interface.

### Return value

#boolean:

GamepadControls.isGamepadCursorActive()

Checks if the gamepad cursor is active.

If it is active, the left stick can move the cursor, and A will be interpreted as a mouse click.

### Return value

#boolean:

GamepadControls.setGamepadCursorActive(value)

Sets if the gamepad cursor is active.

If it is active, the left stick can move the cursor, and A will be interpreted as a mouse click.

### Parameter

-
` #boolean value `:

#number

GamepadControls.version

Interface version

Interface Crimes

Interface ItemUsage
