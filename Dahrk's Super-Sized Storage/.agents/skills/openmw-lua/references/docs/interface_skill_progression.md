# Interface SkillProgression

# Interface SkillProgression

Allows to extend or override built-in skill progression mechanics.

player

## Usage

`local I = require('openmw.interfaces')

-- Make jail time hurt sneak skill instead of benefitting it
I.SkillProgression.addSkillLevelUpHandler(function(skillid, source, options)
if skillid == 'sneak' and source == 'jail' and options.skillIncreaseValue > 0 then
options.skillIncreaseValue = -options.skillIncreaseValue
end
end)

-- Forbid increasing destruction skill past 50
I.SkillProgression.addSkillLevelUpHandler(function(skillid, source, options)
if skillid == 'destruction' and types.NPC.stats.skills.destruction(self).base >= 50 then
return false
end
end)

-- Scale sneak skill progression based on active invisibility effects
I.SkillProgression.addSkillUsedHandler(function(skillid, params)
if skillid == 'sneak' and params.useType == I.SkillProgression.SKILL_USE_TYPES.Sneak_AvoidNotice then
local activeEffects = Actor.activeEffects(self)
local visibility = activeEffects:getEffect(core.magic.EFFECT_TYPE.Chameleon).magnitude / 100
visibility = visibility + activeEffects:getEffect(core.magic.EFFECT_TYPE.Invisibility).magnitude
visibility = 1 - math.min(1, math.max(0, visibility))
local oldSkillGain = params.skillGain
params.skillGain = oldSkillGain * visibility
end
end)
`

## Type `SkillProgression`

SkillProgression.SKILL_INCREASE_SOURCES

#SkillLevelUpSource

SkillProgression.SKILL_USE_TYPES

#SkillUseType

SkillProgression.addSkillLevelUpHandler(handler)

Add new skill level up handler for this actor.

SkillProgression.addSkillUsedHandler(handler)

Add new skillUsed handler for this actor.

SkillProgression.getSkillLevelUpOptions(skillid, source)

Construct a table of skill level up options

SkillProgression.getSkillProgressRequirement(skillid)

Compute the total skill gain required to level up a skill based on its current level, and other modifying factors such as major skills and specialization.

SkillProgression.skillLevelUp(skillid, source)

Trigger a skill level up, activating relevant handlers

SkillProgression.skillUsed(skillid, options)

Trigger a skill use, activating relevant handlers

SkillProgression.version

Interface version

## Type `SkillLevelUpSource`

SkillLevelUpSource.Book

book

SkillLevelUpSource.Jail

jail

SkillLevelUpSource.Trainer

trainer

SkillLevelUpSource.Usage

usage

## Type `SkillUseType`

SkillUseType.Acrobatics_Fall

1

SkillUseType.Acrobatics_Jump

0

SkillUseType.Alchemy_CreatePotion

0

SkillUseType.Alchemy_UseIngredient

1

SkillUseType.Armor_HitByOpponent

0

SkillUseType.Armorer_Repair

0

SkillUseType.Athletics_RunOneSecond

0

SkillUseType.Athletics_SwimOneSecond

1

SkillUseType.Block_Success

0

SkillUseType.Enchant_CastOnStrike

3

SkillUseType.Enchant_CreateMagicItem

2

SkillUseType.Enchant_Recharge

0

SkillUseType.Enchant_UseMagicItem

1

SkillUseType.Mercantile_Bribe

1

SkillUseType.Mercantile_Success

0

SkillUseType.Security_DisarmTrap

0

SkillUseType.Security_PickLock

1

SkillUseType.Sneak_AvoidNotice

0

SkillUseType.Sneak_PickPocket

1

SkillUseType.Speechcraft_Fail

1

SkillUseType.Speechcraft_Success

0

SkillUseType.Spellcast_Success

0

SkillUseType.Weapon_SuccessfulHit

0

## Type `SkillProgression`

### Field(s)

#SkillLevelUpSource

SkillProgression.SKILL_INCREASE_SOURCES

#SkillLevelUpSource

#SkillUseType

SkillProgression.SKILL_USE_TYPES

#SkillUseType

SkillProgression.addSkillLevelUpHandler(handler)

Add new skill level up handler for this actor.

For load order consistency, handlers should be added in the body if your script.
If `handler(skillid, source, options)` returns false, other handlers (including the default skill level up handler)
will be skipped. Where skillid and source are the parameters passed to SkillProgression.skillLevelUp, and options is
a modifiable table of skill level up values, and can be modified to change the behavior of later handlers.
These values are calculated based on vanilla mechanics. Setting any value to nil will cause that mechanic to be skipped. By default it contains these values:

- `skillIncreaseValue` - The numeric amount of skill levels gained. By default this is 1, except when the source is jail in which case it will instead be -1 for all skills except sneak and security.

- `levelUpProgress` - The numeric amount of level up progress gained.

- `levelUpAttribute` - The string identifying the attribute that should receive points from this skill level up.

- `levelUpAttributeIncreaseValue` - The numeric amount of attribute increase points received. This contributes to the amount of each attribute the character receives during a vanilla level up.

- `levelUpSpecialization` - The string identifying the specialization that should receive points from this skill level up.

- `levelUpSpecializationIncreaseValue` - The numeric amount of specialization increase points received. This contributes to the icon displayed at the level up screen during a vanilla level up.

### Parameter

-
` #function handler `:
The handler.

SkillProgression.addSkillUsedHandler(handler)

Add new skillUsed handler for this actor.

For load order consistency, handlers should be added in the body of your script.
If `handler(skillid, options)` returns false, other handlers (including the default skill progress handler)
will be skipped. Where options is a modifiable table of skill progression values, and can be modified to change the behavior of later handlers.
Contains a `skillGain` value as well as a shallow copy of the options passed to SkillProgression.skillUsed.

### Parameter

-
` #function handler `:
The handler.

SkillProgression.getSkillLevelUpOptions(skillid, source)

Construct a table of skill level up options

### Parameters

-
` #string skillid `:
The id of the skill to level up

-
` #SkillLevelUpSource source `:
The source of the skill increase

### Return value

#table:
The options to pass to the skill level up handlers

SkillProgression.getSkillProgressRequirement(skillid)

Compute the total skill gain required to level up a skill based on its current level, and other modifying factors such as major skills and specialization.

### Parameter

-
` #string skillid `:
The id of the skill to compute skill progress requirement for

SkillProgression.skillLevelUp(skillid, source)

Trigger a skill level up, activating relevant handlers

### Parameters

-
` #string skillid `:
The id of the skill to level up.

-
` #SkillLevelUpSource source `:
The source of the skill increase. Note that passing a value of SkillLevelUpSource.Jail will cause a skill decrease for all skills except sneak and security.

SkillProgression.skillUsed(skillid, options)

Trigger a skill use, activating relevant handlers

### Parameters

-
` #string skillid `:
The ID of the skill that was used

-
` options `:
A table of parameters. Must contain one of `skillGain` or `useType`. It's best to always include `useType` if applicable, even if you set `skillGain`, as it may be used
by handlers to make decisions. See the addSkillUsedHandler example at the top of this page.

- `skillGain` - The numeric amount of skill to be gained.

- `useType` - #SkillUseType, A number from 0 to 3 (inclusive) representing the way the skill was used, with each use type having a different skill progression rate. Available use types and its effect is skill specific. See #SkillUseType

And may contain the following optional parameter:

- `scale` - A numeric value used to scale the skill gain. Ignored if the `skillGain` parameter is set.

Note that a copy of this table is passed to skill used handlers, so any parameters passed to this method will also be passed to the handlers. This can be used to provide additional information to
custom handlers when making custom skill progressions.

#number

SkillProgression.version

Interface version

## Type `SkillLevelUpSource`

Table of all existing sources for skill increases.

Any sources not listed below will be treated as equal to Trainer.

### Field(s)

#string

SkillLevelUpSource.Book

book

#string

SkillLevelUpSource.Jail

jail

#string

SkillLevelUpSource.Trainer

trainer

#string

SkillLevelUpSource.Usage

usage

## Type `SkillUseType`

Table of skill use types defined by Morrowind.

Each entry corresponds to an index into the available skill gain values
of a openmw.core#SkillRecord

### Field(s)

#number

SkillUseType.Acrobatics_Fall

1

#number

SkillUseType.Acrobatics_Jump

0

#number

SkillUseType.Alchemy_CreatePotion

0

#number

SkillUseType.Alchemy_UseIngredient

1

#number

SkillUseType.Armor_HitByOpponent

0

#number

SkillUseType.Armorer_Repair

0

#number

SkillUseType.Athletics_RunOneSecond

0

#number

SkillUseType.Athletics_SwimOneSecond

1

#number

SkillUseType.Block_Success

0

#number

SkillUseType.Enchant_CastOnStrike

3

#number

SkillUseType.Enchant_CreateMagicItem

2

#number

SkillUseType.Enchant_Recharge

0

#number

SkillUseType.Enchant_UseMagicItem

1

#number

SkillUseType.Mercantile_Bribe

1

#number

SkillUseType.Mercantile_Success

0

#number

SkillUseType.Security_DisarmTrap

0

#number

SkillUseType.Security_PickLock

1

#number

SkillUseType.Sneak_AvoidNotice

0

#number

SkillUseType.Sneak_PickPocket

1

#number

SkillUseType.Speechcraft_Fail

1

#number

SkillUseType.Speechcraft_Success

0

#number

SkillUseType.Spellcast_Success

0

#number

SkillUseType.Weapon_SuccessfulHit

0

Interface Settings

Interface UI
