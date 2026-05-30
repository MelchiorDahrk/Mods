# Interface AnimationController

# Interface AnimationController

API v129

Animation controller interface

local

## Usages

-

`local anim = require('openmw.animation')
local I = require('openmw.interfaces')

-- play spellcast animation
I.AnimationController.playBlendedAnimation('spellcast', { startkey = 'self start', stopkey = 'self stop', priority = {
[anim.BONE_GROUP.RightArm] = anim.PRIORITY.Weapon,
[anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Weapon,
[anim.BONE_GROUP.Torso] = anim.PRIORITY.Weapon,
[anim.BONE_GROUP.LowerBody] = anim.PRIORITY.WeaponLowerBody
} })
`

-

`-- react to the spellcast release textkey
I.AnimationController.addTextKeyHandler('spellcast', function(groupname, key)
-- Note, Lua is 1-indexed so have to subtract 1 less than the length of 'release'
if key.sub(key, #key - 6) == 'release' then
print('Abra kadabra!')
end
end)
`

-

`-- Add a text key handler that will react to all keys
I.AnimationController.addTextKeyHandler('', function(groupname, key)
if key.sub(key, #key - 2) == 'hit' and not key.sub(key, #key - 7) == ' min hit' then
print('Hit!')
end
end)
`

-

`-- Make a handler that changes player attack speed based on current fatigue
I.AnimationController.addPlayBlendedAnimationHandler(function (groupname, options)
local stop = options.stopkey
if #stop > 10 and stop.sub(stop, #stop - 10) == ' max attack' then
-- This is an attack wind up animation, scale its speed by attack
local fatigue = Actor.stats.dynamic.fatigue(self)
local factor = 1 - fatigue.current / fatigue.base
speed = 1 - factor * 0.8
options.speed = speed
end
end)
`

## Type `AnimationController`

AnimationController.addAnimationEndedHandler(handler)

Add a new animationEnded handler for this actor
If `handler(groupname, info)` returns false, other handlers for
the call will be skipped.

AnimationController.addPlayBlendedAnimationHandler(handler)

Add a new playBlendedAnimation handler for this actor
If `handler(groupname, options)` returns false, other handlers for
the call will be skipped.

AnimationController.addTextKeyHandler(groupname, handler)

Add a new text key handler for this actor
While playing, some animations emit text key events.

AnimationController.playBlendedAnimation(groupname, options)

Make this actor play an animation.

AnimationController.version

Interface version

## Type `AnimationController`

### Field(s)

AnimationController.addAnimationEndedHandler(handler)

Add a new animationEnded handler for this actor
If `handler(groupname, info)` returns false, other handlers for
the call will be skipped.

info is a table that contains information related to
the animation that ended and will contain the following fields:

- `time` - The absolute time in the animation when it was ended

- `completion` - The relative time (0-1) in the animation when it was ended

- `startKey` - The start key of the animation that ended

- `stopKey` - The stop key of the animation that ended

### Parameter

-
` #function handler `:
The handler.

AnimationController.addPlayBlendedAnimationHandler(handler)

Add a new playBlendedAnimation handler for this actor
If `handler(groupname, options)` returns false, other handlers for
the call will be skipped.

### Parameter

-
` #function handler `:
The handler.

AnimationController.addTextKeyHandler(groupname, handler)

Add a new text key handler for this actor
While playing, some animations emit text key events.

Register a handle to listen for all
text key events associated with this actor's animations.
If `handler(groupname, key)` returns false, other handlers for
the call will be skipped.

### Parameters

-
` #string groupname `:
Name of the animation group to listen to keys for. If it is an empty string or nil, all keys will be received

-
` #function handler `:
The handler.

AnimationController.playBlendedAnimation(groupname, options)

Make this actor play an animation.

Makes a call to openmw.animation#playBlended, after invoking handlers added through addPlayBlendedAnimationHandler

### Parameters

-
` #string groupname `:
The animation group to be played

-
` #table options `:
The table of play options that will be passed to openmw.animation#playBlended

#number

AnimationController.version

Interface version

## Type `Package`

AnimationController Package

Interface AI

Interface Camera
