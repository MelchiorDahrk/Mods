# Package openmw.camera

# Package openmw.camera

API v129

Controls camera.

player

## Usage

`local camera = require('openmw.camera')`

## Type `camera`

camera.MODE

Camera modes.

camera.allowCharacterDeferredRotation(boolValue)

If set to true then after switching from Preview to ThirdPerson the player character turns to the camera view direction.

camera.getBaseFieldOfView()

Return the base field of view vertical angle in radians

camera.getBaseViewDistance()

Return the base view distance.

camera.getCollisionType()

Get the current camera collision type (see openmw.nearby#COLLISION_TYPE).

camera.getExtraPitch()

Additional summand for the pitch angle that is not affected by player input.

camera.getExtraRoll()

Additional summand for the roll angle that is not affected by player input.

camera.getExtraYaw()

Additional summand for the yaw angle that is not affected by player input.

camera.getFieldOfView()

Return the current field of view vertical angle in radians

camera.getFirstPersonOffset()

The offset between the characters head and the camera in first person mode (3d vector).

camera.getFocalPreferredOffset()

Preferred offset between the tracked position (see `getTrackedPosition`) and the camera focal point (the center of the screen) in third person mode.

camera.getFocalTransitionSpeed()

The current speed coefficient of focal point (the center of the screen in third person mode) smooth transition.

camera.getMode()

Return the current openmw.camera#MODE.

camera.getPitch()

Camera pitch angle (radians) without taking extraPitch into account.

camera.getPosition()

Current position of the camera.

camera.getProjectionOffset()

The offset applied to the cameras projection matrix, in pixels.

camera.getQueuedMode()

Return the mode the camera will switch to after the end of the current animation.

camera.getRoll()

Get the camera roll angle (radians).

camera.getThirdPersonDistance()

The actual distance between the camera and the character in third person mode; can differ from the preferred one if there is an obstacle.

camera.getTrackedPosition()

Current position of the tracked object (the characters head if there is no animation).

camera.getViewDistance()

Return the current view distance.

camera.getViewTransform()

Get the world to local transform for the camera.

camera.getYaw()

Camera yaw angle (radians) without taking extraYaw into account.

camera.instantTransition()

Make instant the current transition of camera focal point and the current deferred rotation (see `allowCharacterDeferredRotation`).

camera.setCollisionType(collisionType)

Set the camera collision type (see openmw.nearby#COLLISION_TYPE).

camera.setExtraPitch(value)

Additional summand for the pitch angle; useful for camera shaking effects.

camera.setExtraRoll(value)

Additional summand for the roll angle; useful for camera shaking effects.

camera.setExtraYaw(value)

Additional summand for the yaw angle; useful for camera shaking effects.

camera.setFieldOfView(fov)

Set the field of view

camera.setFirstPersonOffset(offset)

Set the offset between the characters head and the camera in first person mode (3d vector).

camera.setFocalPreferredOffset(offset)

Set the preferred offset between the tracked position (see `getTrackedPosition`) and the camera focal point (the center of the screen) in third person mode.

camera.setFocalTransitionSpeed(speed)

Set the speed coefficient of focal point (the center of the screen in third person mode) smooth transition.

camera.setMode(mode, force)

Change openmw.camera#MODE; if the second (optional, true by default) argument is set to false, the switching can be delayed (see `getQueuedMode`).

camera.setPitch(value)

Force the pitch angle to the given value (radians); player input on this axis is ignored in this frame.

camera.setPreferredThirdPersonDistance(distance)

Set preferred distance between the camera and the character in third person mode.

camera.setProjectionOffset(offset)

Applies an offset to the cameras projection matrix, measured in pixels.

camera.setRoll(value)

Set the camera roll angle (radians).

camera.setStaticPosition(pos)

Set the camera position; can be used only if camera is in Static mode.

camera.setViewDistance(distance)

Set the view distance.

camera.setYaw(value)

Force the yaw angle to the given value (radians); player input on this axis is ignored in this frame.

camera.showCrosshair(boolValue)

Show/hide the crosshair.

camera.viewportToWorldVector(normalizedScreenPos)

Get a vector from the camera to the world for the given point in the viewport.

camera.worldToViewportVector(worldPos)

Get a vector from the world to the viewport for the given point in the world space.

## Type `MODE`

MODE.FirstPerson

First person mode.

MODE.Preview

Third person mode, but player character doesn't turn to the view direction.

MODE.Static

Camera doesn't track player; player inputs doesn't affect camera; use `setStaticPosition` to move the camera.

MODE.ThirdPerson

Third person mode; player character turns to the view direction.

MODE.Vanity

Similar to Preview; camera slowly moves around the player.

## Type `camera`

### Field(s)

#MODE

camera.MODE

Camera modes.

camera.allowCharacterDeferredRotation(boolValue)

If set to true then after switching from Preview to ThirdPerson the player character turns to the camera view direction.

Otherwise, the camera turns to the character view direction.

### Parameter

-
` #boolean boolValue `:

camera.getBaseFieldOfView()

Return the base field of view vertical angle in radians

### Return value

#number:

camera.getBaseViewDistance()

Return the base view distance.

### Return value

#number:

camera.getCollisionType()

Get the current camera collision type (see openmw.nearby#COLLISION_TYPE).

### Return value

#number:

camera.getExtraPitch()

Additional summand for the pitch angle that is not affected by player input.

Full pitch is `getPitch()+getExtraPitch()`.

### Return value

#number:

camera.getExtraRoll()

Additional summand for the roll angle that is not affected by player input.

Full yaw is `getRoll()+getExtraRoll()`.

### Return value

#number:

camera.getExtraYaw()

Additional summand for the yaw angle that is not affected by player input.

Full yaw is `getYaw()+getExtraYaw()`.

### Return value

#number:

camera.getFieldOfView()

Return the current field of view vertical angle in radians

### Return value

#number:

camera.getFirstPersonOffset()

The offset between the characters head and the camera in first person mode (3d vector).

### Return value

openmw.util#Vector3:

camera.getFocalPreferredOffset()

Preferred offset between the tracked position (see `getTrackedPosition`) and the camera focal point (the center of the screen) in third person mode.

See `setFocalPreferredOffset`.

### Return value

openmw.util#Vector2:

camera.getFocalTransitionSpeed()

The current speed coefficient of focal point (the center of the screen in third person mode) smooth transition.

### Return value

#number:

camera.getMode()

Return the current openmw.camera#MODE.

### Return value

#Mode:

camera.getPitch()

Camera pitch angle (radians) without taking extraPitch into account.

Full pitch is `getPitch()+getExtraPitch()`.

### Return value

#number:

camera.getPosition()

Current position of the camera.

### Return value

openmw.util#Vector3:

camera.getProjectionOffset()

The offset applied to the cameras projection matrix, in pixels.

### Return value

openmw.util#Vector2:

camera.getQueuedMode()

Return the mode the camera will switch to after the end of the current animation.

Can be nil.

### Return value

#Mode:

camera.getRoll()

Get the camera roll angle (radians).

### Return value

#number:

camera.getThirdPersonDistance()

The actual distance between the camera and the character in third person mode; can differ from the preferred one if there is an obstacle.

### Return value

#number:

camera.getTrackedPosition()

Current position of the tracked object (the characters head if there is no animation).

### Return value

openmw.util#Vector3:

camera.getViewDistance()

Return the current view distance.

### Return value

#number:

camera.getViewTransform()

Get the world to local transform for the camera.

### Return value

openmw.util#Transform:

camera.getYaw()

Camera yaw angle (radians) without taking extraYaw into account.

Full yaw is `getYaw()+getExtraYaw()`.

### Return value

#number:

camera.instantTransition()

Make instant the current transition of camera focal point and the current deferred rotation (see `allowCharacterDeferredRotation`).

camera.setCollisionType(collisionType)

Set the camera collision type (see openmw.nearby#COLLISION_TYPE).

### Parameter

-
` #number collisionType `:

camera.setExtraPitch(value)

Additional summand for the pitch angle; useful for camera shaking effects.

Setting extra pitch doesn't block player input.
Full pitch is `getPitch()+getExtraPitch()`.

### Parameter

-
` #number value `:

camera.setExtraRoll(value)

Additional summand for the roll angle; useful for camera shaking effects.

Full roll is `getRoll()+getExtraRoll()`.

### Parameter

-
` #number value `:

camera.setExtraYaw(value)

Additional summand for the yaw angle; useful for camera shaking effects.

Full yaw is `getYaw()+getExtraYaw()`.

### Parameter

-
` #number value `:

camera.setFieldOfView(fov)

Set the field of view

### Parameter

-
` #number fov `:
Field of view vertical angle in radians

camera.setFirstPersonOffset(offset)

Set the offset between the characters head and the camera in first person mode (3d vector).

### Parameter

-
` openmw.util#Vector3 offset `:

camera.setFocalPreferredOffset(offset)

Set the preferred offset between the tracked position (see `getTrackedPosition`) and the camera focal point (the center of the screen) in third person mode.

The offset is a 2d vector (X, Y) where X is horizontal (to the right from the character) and Y component is vertical (upward).
The real offset can differ from the preferred one during smooth transition or if blocked by an obstacle.
Smooth transition happens by default every time the preferred offset changes. Use `instantTransition()` to skip the current transition.

### Parameter

-
` openmw.util#Vector2 offset `:

camera.setFocalTransitionSpeed(speed)

Set the speed coefficient of focal point (the center of the screen in third person mode) smooth transition.

Smooth transition happens by default every time the preferred offset changes. Use `instantTransition()` to skip the current transition.

### Parameter

-
` #number speed `:

camera.setMode(mode, force)

Change openmw.camera#MODE; if the second (optional, true by default) argument is set to false, the switching can be delayed (see `getQueuedMode`).

### Parameters

-
` #Mode mode `:

-
` #boolean force `:

camera.setPitch(value)

Force the pitch angle to the given value (radians); player input on this axis is ignored in this frame.

### Parameter

-
` #number value `:

camera.setPreferredThirdPersonDistance(distance)

Set preferred distance between the camera and the character in third person mode.

### Parameter

-
` #number distance `:

camera.setProjectionOffset(offset)

Applies an offset to the cameras projection matrix, measured in pixels.

Small offsets of up to roughly 2 pixels are safe, large offsets are only for debugging and will cause visual glitches.

### Parameter

-
` openmw.util#Vector2 offset `:

camera.setRoll(value)

Set the camera roll angle (radians).

### Parameter

-
` #number value `:

camera.setStaticPosition(pos)

Set the camera position; can be used only if camera is in Static mode.

### Parameter

-
` openmw.util#Vector3 pos `:

camera.setViewDistance(distance)

Set the view distance.

- Takes effect on the next frame.

### Parameter

-
` #number distance `:
View distance in game units

camera.setYaw(value)

Force the yaw angle to the given value (radians); player input on this axis is ignored in this frame.

### Parameter

-
` #number value `:

camera.showCrosshair(boolValue)

Show/hide the crosshair.

### Parameter

-
` #boolean boolValue `:

camera.viewportToWorldVector(normalizedScreenPos)

Get a vector from the camera to the world for the given point in the viewport.

(0, 0) is the top left corner of the screen.

### Parameter

-
` openmw.util#Vector2 normalizedScreenPos `:

### Return value

openmw.util#Vector3:

camera.worldToViewportVector(worldPos)

Get a vector from the world to the viewport for the given point in the world space.

(0, 0) is the top left corner of the screen.
The z component of the return value holds the distance from the camera to the position, in world space

### Parameter

-
` openmw.util#Vector3 worldPos `:

### Return value

openmw.util#Vector3:

## Type `MODE`

### Field(s)

#Mode

MODE.FirstPerson

First person mode.

#Mode

MODE.Preview

Third person mode, but player character doesn't turn to the view direction.

#Mode

MODE.Static

Camera doesn't track player; player inputs doesn't affect camera; use `setStaticPosition` to move the camera.

#Mode

MODE.ThirdPerson

Third person mode; player character turns to the view direction.

#Mode

MODE.Vanity

Similar to Preview; camera slowly moves around the player.

## Type `Mode`

Camera mode; see openmw.camera#MODE for possible values

Package openmw.async

Package openmw.content
