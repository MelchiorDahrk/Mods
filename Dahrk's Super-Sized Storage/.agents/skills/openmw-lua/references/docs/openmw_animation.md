# Package openmw.animation

# Package openmw.animation

API v129

Defines functions that allow control of character animations.

Note that for some methods, such as openmw.animation#playBlended you should use the associated methods on the
AnimationController interface rather than invoking this API directly.

local

## Usage

`local anim = require('openmw.animation')`

## Type `animation`

animation.BLEND_MASK

Possible #BlendMask values

animation.BONE_GROUP

Possible #BoneGroup values

animation.PRIORITY

Possible #Priority values

animation.addVfx(actor, model, options)

Plays a VFX on the actor.

animation.cancel(actor, groupName)

Cancels and removes the animation group from the list of active animations.

animation.clearAnimationQueue(actor, clearScripted)

Clears all animations currently in the animation queue.

animation.getActiveGroup(actor, boneGroup)

Get the current active animation for a bone group

animation.getCompletion(actor, groupName)

Returns the completion of the animation, or nil if the animation group is not active.

animation.getCurrentTime(actor, groupName)

Get the current absolute time of the given animation group if it is playing, or -1 if it is not playing.

animation.getLoopCount(actor, groupName)

Returns the remaining number of loops, not counting the current loop, or nil if the animation group is not active.

animation.getSpeed(actor, groupName)

Get the current playback speed of an animation group, or nil if the animation group is not active.

animation.getTextKeyTime(actor, text)

Get the absolute position within the animation track of the given text key

animation.hasAnimation(actor)

Check if the object has an animation object or not

animation.hasBone(actor, boneName)

Check if the actor's skeleton has the given bone or not

animation.hasGroup(actor, groupName)

Check if the actor's animation has the given animation group or not.

animation.isLoopingAnimation(actor, groupName)

Check whether the animation is a looping animation or not.

animation.isPlaying(actor, groupName)

Check if the given animation group is currently playing

animation.playBlended(actor, groupName, options)

Play an animation directly.

animation.playQueued(actor, groupName, options)

Acts as a slightly extended version of MWScript's LoopGroup.

animation.removeAllVfx(actor)

Removes all vfx from the actor.

animation.removeVfx(actor, vfxId)

Removes a specific VFX.

animation.setLoopingEnabled(actor, groupName, enabled)

Enables or disables looping for the given animation group.

animation.setSpeed(actor, groupName, speed)

Modifies the playback speed of an animation group.

animation.skipAnimationThisFrame(actor)

Skips animations for one frame, equivalent to mwscript's SkipAnim.

## Type `BlendMask`

BlendMask.All

"15" All bones

BlendMask.LeftArm

"4" All bones from 'Bip01 L Clavicle' and out

BlendMask.LowerBody

"1" All bones from 'Bip01 pelvis' and below

BlendMask.RightArm

"8" All bones from 'Bip01 R Clavicle' and out

BlendMask.Torso

"2" All bones from 'Bip01 Spine1' and up, excluding arms

BlendMask.UpperBody

"14" All bones from 'Bip01 Spine1' and up, including arms

## Type `BoneGroup`

BoneGroup.LeftArm

"3" All bones from 'Bip01 L Clavicle' and out

BoneGroup.LowerBody

"1" All bones from 'Bip01 pelvis' and below

BoneGroup.RightArm

"4" All bones from 'Bip01 R Clavicle' and out

BoneGroup.Torso

"2" All bones from 'Bip01 Spine1' and up, excluding arms

## Type `Priority`

Priority.Block

"8"

Priority.Death

"12"

Priority.Default

"0"

Priority.Hit

"6"

Priority.Jump

"4"

Priority.Knockdown

"9"

Priority.Movement

"5"

Priority.Scripted

"13" Special priority used by scripted animations. When any animation with this priority is present, all animations without this priority are paused.

Priority.SneakIdleLowerBody

"2"

Priority.Storm

"11"

Priority.SwimIdle

"3"

Priority.Torch

"10"

Priority.Weapon

"7"

Priority.WeaponLowerBody

"1"

## Type `animation`

### Field(s)

#BlendMask

animation.BLEND_MASK

Possible #BlendMask values

#BoneGroup

animation.BONE_GROUP

Possible #BoneGroup values

#Priority

animation.PRIORITY

Possible #Priority values

animation.addVfx(actor, model, options)

Plays a VFX on the actor.

Can only be used on self. Can also be evoked by sending an AddVfx event to the target actor.

### Parameters

-
` openmw.core#GameObject actor `:

-
` #string model `:
path (normally taken from a record such as openmw.types#StaticRecord.model or similar)

-
` #table options `:
optional table of parameters. Can contain:

- `loop` - boolean, if true the effect will loop until removed (default: false).

- `boneName` - name of the bone to attach the vfx to. (default: "")

- `particleTextureOverride` - name of the particle texture to use. (default: "")

- `vfxId` - a string ID that can be used to remove the effect later, using #removeVfx, and to avoid duplicate effects. The default value of "" can have duplicates. To avoid interaction with the engine, use unique identifiers unrelated to magic effect IDs. The engine uses this identifier to add and remove magic effects based on what effects are active on the actor. If this is set equal to the openmw.core#MagicEffectId identifier of the magic effect being added, for example core.magic.EFFECT_TYPE.FireDamage, then the engine will remove it once the fire damage effect on the actor reaches 0. (Default: "").

- `useAmbientLight` - boolean, vfx get a white ambient light attached in Morrowind. If false don't attach this. (default: true)

### Usages

-

`local mgef = core.magic.effects.records[myEffectName]
anim.addVfx(self, 'VFX_Hands', {boneName = 'Bip01 L Hand', particleTextureOverride = mgef.particle, loop = mgef.continuousVfx, vfxId = mgef.id..'_myuniquenamehere'})
-- later:
anim.removeVfx(self, mgef.id..'_myuniquenamehere')
`

-

`-- Add vfx to another actor using an event
local mgef = core.magic.effects.records[myEffectName]
target:sendEvent('AddVfx', {
model = types.Static.record(mgef.hitStatic).model,
options = {
vfxId = mgef.id,
particleTextureOverride = mgef.particle,
loop = false,
}
})
`

animation.cancel(actor, groupName)

Cancels and removes the animation group from the list of active animations.

Can only be used on self.

### Parameters

-
` openmw.core#GameObject actor `:

-
` #string groupName `:

animation.clearAnimationQueue(actor, clearScripted)

Clears all animations currently in the animation queue.

This affects animations played by mwscript, openmw.animation#playQueued, and ai packages, but does not affect animations played using openmw.animation#playBlended.
Can only be used on self.

### Parameters

-
` openmw.core#GameObject actor `:

-
` #boolean clearScripted `:
whether to keep animation with priority Scripted or not.

animation.getActiveGroup(actor, boneGroup)

Get the current active animation for a bone group

### Parameters

-
` openmw.core#GameObject actor `:

-
` #number boneGroup `:
Bone group enum, see openmw.animation#BONE_GROUP

### Return value

#string:

animation.getCompletion(actor, groupName)

Returns the completion of the animation, or nil if the animation group is not active.

### Parameters

-
` openmw.core#GameObject actor `:

-
` #string groupName `:

### Return value

#number, #nil:

animation.getCurrentTime(actor, groupName)

Get the current absolute time of the given animation group if it is playing, or -1 if it is not playing.

### Parameters

-
` openmw.core#GameObject actor `:

-
` #string groupName `:

### Return value

#number:

animation.getLoopCount(actor, groupName)

Returns the remaining number of loops, not counting the current loop, or nil if the animation group is not active.

### Parameters

-
` openmw.core#GameObject actor `:

-
` #string groupName `:

### Return value

#number, #nil:

animation.getSpeed(actor, groupName)

Get the current playback speed of an animation group, or nil if the animation group is not active.

### Parameters

-
` openmw.core#GameObject actor `:

-
` #string groupName `:

### Return value

#number, #nil:

animation.getTextKeyTime(actor, text)

Get the absolute position within the animation track of the given text key

### Parameters

-
` openmw.core#GameObject actor `:

-
` #string text `:
key

### Return value

#number:

animation.hasAnimation(actor)

Check if the object has an animation object or not

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#boolean:

animation.hasBone(actor, boneName)

Check if the actor's skeleton has the given bone or not

### Parameters

-
` openmw.core#GameObject actor `:

-
` #string boneName `:

### Return value

#boolean:

animation.hasGroup(actor, groupName)

Check if the actor's animation has the given animation group or not.

### Parameters

-
` openmw.core#GameObject actor `:

-
` #string groupName `:

### Return value

#boolean:

animation.isLoopingAnimation(actor, groupName)

Check whether the animation is a looping animation or not.

This is determined by a combination
of groupName, some of which are hardcoded to be looping, and the presence of loop start/stop keys.
The groupNames that are hardcoded as looping are the following, as well as per-weapon-type suffixed variants of each.
"walkforward", "walkback", "walkleft", "walkright", "swimwalkforward", "swimwalkback", "swimwalkleft", "swimwalkright",
"runforward", "runback", "runleft", "runright", "swimrunforward", "swimrunback", "swimrunleft", "swimrunright",
"sneakforward", "sneakback", "sneakleft", "sneakright", "turnleft", "turnright", "swimturnleft", "swimturnright",
"spellturnleft", "spellturnright", "torch", "idle", "idle2", "idle3", "idle4", "idle5", "idle6", "idle7", "idle8",
"idle9", "idlesneak", "idlestorm", "idleswim", "jump", "inventoryhandtohand", "inventoryweapononehand",
"inventoryweapontwohand", "inventoryweapontwowide"

### Parameters

-
` openmw.core#GameObject actor `:

-
` #string groupName `:

### Return value

#boolean:

animation.isPlaying(actor, groupName)

Check if the given animation group is currently playing

### Parameters

-
` openmw.core#GameObject actor `:

-
` #string groupName `:

### Return value

#boolean:

animation.playBlended(actor, groupName, options)

Play an animation directly.

You probably want to use the AnimationController interface, which will trigger relevant handlers,
instead of calling this directly. Note that the still hardcoded character controller may at any time and for any reason alter
or cancel currently playing animations, so making your own calls to this function either directly or through the AnimationController
interface may be of limited utility. For now, use openmw.animation#playQueued to script your own animations.
Can only be used on self.

### Parameters

-
` openmw.core#GameObject actor `:

-
` #string groupName `:

-
` #table options `:
A table of play options. Can contain:

- `loops` - a number >= 0, the number of times the animation should loop after the first play (default: 0).

- `priority` - Either a single #Priority value that will be assigned to all bone groups. Or a table mapping bone groups to its priority (default: PRIORITY.Default).

- `blendMask` - A mask of which bone groups to include in the animation (Default: BLEND_MASK.All).

- `autoDisable` - If true, the animation will be immediately removed upon finishing, which means information will not be possible to query once completed. (Default: true)

- `speed` - a floating point number >= 0, the speed at which the animation should play (default: 1)

- `startKey` - the animation key at which the animation should start (default: "start")

- `stopKey` - the animation key at which the animation should end (default: "stop")

- `startPoint` - a floating point number 0 <= value <= 1, starting completion of the animation (default: 0)

- `forceLoop` - a boolean, to set if the animation should loop even if it's not a looping animation (default: false)

animation.playQueued(actor, groupName, options)

Acts as a slightly extended version of MWScript's LoopGroup.

Plays this animation exclusively
until it ends, or the queue is cleared using #clearAnimationQueue. Use #clearAnimationQueue and the `startkey` option
to imitate the behavior of LoopGroup's play modes.
Can only be used on self.

### Parameters

-
` openmw.core#GameObject actor `:

-
` #string groupName `:

-
` #table options `:
A table of play options. Can contain:

- `loops` - a number >= 0, the number of times the animation should loop after the first play (default: infinite).

- `speed` - a floating point number >= 0, the speed at which the animation should play (default: 1);

- `startKey` - the animation key at which the animation should start (default: "start")

- `stopKey` - the animation key at which the animation should end (default: "stop")

- `forceLoop` - a boolean, to set if the animation should loop even if it's not a looping animation (default: false)

### Usages

-

`-- Play death1 without waiting. Equivalent to playgroup, death1, 1
anim.clearAnimationQueue(self, false)
anim.playQueued(self, 'death1')
`

-

`-- Play an animation group with custom start/stop keys
anim.clearAnimationQueue(self, false)
anim.playQueued(self, 'spellcast', { startKey = 'self start', stopKey = 'self stop' })
`

animation.removeAllVfx(actor)

Removes all vfx from the actor.

Can only be used on self.

### Parameter

-
` openmw.core#GameObject actor `:

animation.removeVfx(actor, vfxId)

Removes a specific VFX.

Can only be used on self.

### Parameters

-
` openmw.core#GameObject actor `:

-
` #string vfxId `:
a string ID that uniquely identifies the VFX to remove

animation.setLoopingEnabled(actor, groupName, enabled)

Enables or disables looping for the given animation group.

Looping is enabled by default.
Can only be used on self.

### Parameters

-
` openmw.core#GameObject actor `:

-
` #string groupName `:

-
` #boolean enabled `:

animation.setSpeed(actor, groupName, speed)

Modifies the playback speed of an animation group.

Note that this is not sticky and only affects the speed until the currently playing sequence ends.
Can only be used on self.

### Parameters

-
` openmw.core#GameObject actor `:

-
` #string groupName `:

-
` #number speed `:
The new animation speed, where speed=1 is normal speed.

animation.skipAnimationThisFrame(actor)

Skips animations for one frame, equivalent to mwscript's SkipAnim.

Can only be used on self.

### Parameter

-
` openmw.core#GameObject actor `:

## Type `BlendMask`

`animation.BLEND_MASK`

### Field(s)

#number

BlendMask.All

"15" All bones

#number

BlendMask.LeftArm

"4" All bones from 'Bip01 L Clavicle' and out

#number

BlendMask.LowerBody

"1" All bones from 'Bip01 pelvis' and below

#number

BlendMask.RightArm

"8" All bones from 'Bip01 R Clavicle' and out

#number

BlendMask.Torso

"2" All bones from 'Bip01 Spine1' and up, excluding arms

#number

BlendMask.UpperBody

"14" All bones from 'Bip01 Spine1' and up, including arms

## Type `BoneGroup`

`animation.BONE_GROUP`

### Field(s)

#number

BoneGroup.LeftArm

"3" All bones from 'Bip01 L Clavicle' and out

#number

BoneGroup.LowerBody

"1" All bones from 'Bip01 pelvis' and below

#number

BoneGroup.RightArm

"4" All bones from 'Bip01 R Clavicle' and out

#number

BoneGroup.Torso

"2" All bones from 'Bip01 Spine1' and up, excluding arms

## Type `Priority`

`animation.PRIORITY`

### Field(s)

#number

Priority.Block

"8"

#number

Priority.Death

"12"

#number

Priority.Default

"0"

#number

Priority.Hit

"6"

#number

Priority.Jump

"4"

#number

Priority.Knockdown

"9"

#number

Priority.Movement

"5"

#number

Priority.Scripted

"13" Special priority used by scripted animations. When any animation with this priority is present, all animations without this priority are paused.

#number

Priority.SneakIdleLowerBody

"2"

#number

Priority.Storm

"11"

#number

Priority.SwimIdle

"3"

#number

Priority.Torch

"10"

#number

Priority.Weapon

"7"

#number

Priority.WeaponLowerBody

"1"

Package openmw.ambient

Package openmw.async
