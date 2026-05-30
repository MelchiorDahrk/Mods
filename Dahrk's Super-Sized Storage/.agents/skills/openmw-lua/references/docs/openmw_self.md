# Package openmw.self

# Package openmw.self

API v129

Provides full access to the object the script is attached to.

All fields and function of `GameObject` are also available for `openmw.self`.

local

## Usage

`local self = require('openmw.self')
local types = require('openmw.types')
if self.type == types.Player then -- All fields and functions of `GameObject` are available.
self:sendEvent("something", self.position)
end`

## Type `Self`

Self.controls

Movement controls (only for actors)

Self.enableAI(Self, v)

Enables or disables standard AI (enabled by default).

Self.isActive(Self)

Returns true if the script isActive (the object it is attached to is in an active cell).

Self.object

The object the script is attached to (readonly)

## Type `ATTACK_TYPE`

ATTACK_TYPE.Any

ATTACK_TYPE.Chop

ATTACK_TYPE.NoAttack

ATTACK_TYPE.Slash

ATTACK_TYPE.Thrust

## Type `ActorControls`

ActorControls.jump

If true - initiate a jump

ActorControls.movement

+1 - move forward, -1 - move backward

ActorControls.pitchChange

Look down (radians); if negative - look up

ActorControls.run

true - run, false - walk

ActorControls.sideMovement

+1 - move right, -1 - move left

ActorControls.sneak

If true - sneak

ActorControls.use

Activates the readied weapon/spell according to a provided value. For weapons, keeping this value modified will charge the attack until set to ATTACK_TYPE.NoAttack. If an #ATTACK_TYPE not appropriate for a currently equipped weapon provided - an appropriate #ATTACK_TYPE will be used instead.

ActorControls.yawChange

Turn right (radians); if negative - turn left

## Type `Self`

### Extends openmw.core#GameObject

### Field(s)

#ActorControls

Self.controls

Movement controls (only for actors)

Self.enableAI(Self, v)

Enables or disables standard AI (enabled by default).

### Parameters

-
` Self `:

-
` #boolean v `:

Self.isActive(Self)

Returns true if the script isActive (the object it is attached to is in an active cell).

If it is not active, then `openmw.nearby` can not be used.

### Parameter

-
` Self `:

### Return value

#boolean:

openmw.core#GameObject

Self.object

The object the script is attached to (readonly)

## Type `ATTACK_TYPE`

### Field(s)

#number

ATTACK_TYPE.Any

#number

ATTACK_TYPE.Chop

#number

ATTACK_TYPE.NoAttack

#number

ATTACK_TYPE.Slash

#number

ATTACK_TYPE.Thrust

## Type `ActorControls`

Allows to view and/or modify controls of an actor.

All fields are mutable.

### Field(s)

#boolean

ActorControls.jump

If true - initiate a jump

#number

ActorControls.movement

+1 - move forward, -1 - move backward

#number

ActorControls.pitchChange

Look down (radians); if negative - look up

#boolean

ActorControls.run

true - run, false - walk

#number

ActorControls.sideMovement

+1 - move right, -1 - move left

#boolean

ActorControls.sneak

If true - sneak

#ATTACK_TYPE

ActorControls.use

Activates the readied weapon/spell according to a provided value. For weapons, keeping this value modified will charge the attack until set to ATTACK_TYPE.NoAttack. If an #ATTACK_TYPE not appropriate for a currently equipped weapon provided - an appropriate #ATTACK_TYPE will be used instead.

#number

ActorControls.yawChange

Turn right (radians); if negative - turn left

Package openmw.postprocessing

Package openmw.storage
