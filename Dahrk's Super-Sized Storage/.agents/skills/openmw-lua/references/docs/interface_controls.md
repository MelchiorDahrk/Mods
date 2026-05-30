# Interface Controls

# Interface Controls

API v129

player

## Usage

`require('openmw.interfaces').Controls`

## Type `Controls`

Controls.overrideCombatControls(value)

When set to true then the controls "attack", "toggle spell", "toggle weapon" are not processed and can be handled by another script.

Controls.overrideMovementControls(value)

When set to true then the movement controls including jump and sneak are not processed and can be handled by another script.

Controls.overrideUiControls(value)

When set to true then the controls "open inventory", "open journal" and so on are not processed and can be handled by another script.

Controls.version

Interface version

## Type `Controls`

### Field(s)

Controls.overrideCombatControls(value)

When set to true then the controls "attack", "toggle spell", "toggle weapon" are not processed and can be handled by another script.

If combat should be disallowed completely, consider to use `types.Player.setControlSwitch` instead.

### Parameter

-
` #boolean value `:

Controls.overrideMovementControls(value)

When set to true then the movement controls including jump and sneak are not processed and can be handled by another script.

If movement should be disallowed completely, consider to use `types.Player.setControlSwitch` instead.

### Parameter

-
` #boolean value `:

Controls.overrideUiControls(value)

When set to true then the controls "open inventory", "open journal" and so on are not processed and can be handled by another script.

### Parameter

-
` #boolean value `:

#number

Controls.version

Interface version

Interface Combat

Interface Crimes
