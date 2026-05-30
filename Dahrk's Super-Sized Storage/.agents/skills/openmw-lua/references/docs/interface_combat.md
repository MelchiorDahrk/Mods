# Interface Combat

# Interface Combat

API v129

Basic combat interface

## Usage

`local I = require('openmw.interfaces')

I.Combat.addOnHitHandler(function(attack)
-- Adds fatigue loss when hit by draining fatigue when taking health damage
if attack.damage.health and not attack.damage.fatigue then
local strengthFactor = Actor.stats.attributes.strength(self).modified / 100 * 0.66
local enduranceFactor = Actor.stats.attributes.endurance(self).modified / 100 * 0.34
local factor = 1 - math.min(strengthFactor + enduranceFactor, 1)
if factor > 0 then
attack.damage.fatigue = attack.damage.health * factor
end
end
end)`

## Type `Combat`

Combat.ATTACK_SOURCE_TYPES

#AttackSourceType

Combat.ATTACK_TYPES

#AttackType

Combat.addOnHitHandler(handler)

Add new onHit handler for this actor
If `handler(attack)` returns false, other handlers for
the call will be skipped.

Combat.adjustDamageForArmor(Damage, actor)

Calculates the character's armor rating and adjusts damage accordingly.

Combat.adjustDamageForDifficulty(attack, defendant)

Calculates a difficulty multiplier based on the current difficulty settings
and adjusts damage accordingly.

Combat.applyArmor(attack)

Applies this character's armor to the attack.

Combat.getArmorRating(actor)

Computes this character's armor rating.

Combat.getArmorSkill(item)

Computes this item's armor skill.

Combat.getEffectiveArmorRating(item, actor)

Computes the effective armor rating of a single piece of openmw.types#Armor, adjusted for skill and item condition

Combat.getSkillAdjustedArmorRating(item, actor)

Computes the armor rating of a single piece of openmw.types#Armor, adjusted for skill
Note that this interface function is read by the engine to update the UI.

Combat.onHit(attackInfo)

Hit this actor.

Combat.pickRandomArmor(actor)

Picks a random armor slot and returns the item equipped in that slot.

Combat.spawnBloodEffect(position)

Spawns a random blood effect at the given position

Combat.version

Interface version

## Type `AttackInfo`

AttackInfo.ammo

(Optional) Ammo record ID

AttackInfo.attacker

(Optional) Attacking actor

AttackInfo.damage

A table mapping a stat name (health, fatigue, or magicka) to a number. For example, {health = 50, fatigue = 10} will cause 50 damage to health and 10 to fatigue (before adjusting for armor and difficulty). This field is ignored for failed attacks.

AttackInfo.hitPos

(Optional) Where on the victim the attack is landing. Used to spawn blood effects. Blood effects are skipped if nil.

AttackInfo.sourceType

What class of attack this is.

AttackInfo.strength

A number between 0 and 1 representing the attack strength. This field is ignored for failed attacks.

AttackInfo.successful

Whether the attack was successful or not.

AttackInfo.type

(Optional) Attack variant if applicable. For melee attacks this represents chop vs thrust vs slash. For unarmed creatures this implies which of its 3 possible attacks were used. For other attacks this field can be ignored.

AttackInfo.weapon

(Optional) Attacking weapon

## Type `AttackSourceType`

AttackSourceType.Magic

AttackSourceType.Melee

AttackSourceType.Ranged

AttackSourceType.Unspecified

## Type `AttackType`

AttackType.Chop

AttackType.Slash

AttackType.Thrust

## Type `Combat`

### Field(s)

#AttackSourceType

Combat.ATTACK_SOURCE_TYPES

#AttackSourceType

#AttackType

Combat.ATTACK_TYPES

#AttackType

Combat.addOnHitHandler(handler)

Add new onHit handler for this actor
If `handler(attack)` returns false, other handlers for
the call will be skipped.

Where attack is the same #AttackInfo passed to #Combat.onHit

### Parameter

-
` #function handler `:
The handler.

Combat.adjustDamageForArmor(Damage, actor)

Calculates the character's armor rating and adjusts damage accordingly.

Note that this function only adjusts the number, use #Combat.applyArmor
to include other side effects.

### Parameters

-
` #number Damage `:
The numeric damage to adjust

-
` openmw.core#GameObject actor `:
(Optional) The actor to calculate the armor rating for. Defaults to self.

### Return value

#number:
Damage adjusted for armor

Combat.adjustDamageForDifficulty(attack, defendant)

Calculates a difficulty multiplier based on the current difficulty settings
and adjusts damage accordingly.

Has no effect if both this actor and the
attacker are NPCs, or if both are Players.

### Parameters

-
` #Attack attack `:
The attack to adjust

-
` openmw.core#GameObject defendant `:
(Optional) The defendant to make the difficulty adjustment for. Defaults to self.

Combat.applyArmor(attack)

Applies this character's armor to the attack.

Adjusts damage, reduces item
condition accordingly, progresses armor skill, and plays the armor appropriate
hit sound.

### Parameter

-
` #Attack attack `:

Combat.getArmorRating(actor)

Computes this character's armor rating.

Note that this interface function is read by the engine to update the UI.
This function can still be overridden same as any other interface, but must not call any functions or interfaces that modify anything.

### Parameter

-
` openmw.core#GameObject actor `:
(Optional) The actor to calculate the armor rating for. Defaults to self.

### Return value

#number:

Combat.getArmorSkill(item)

Computes this item's armor skill.

You can override this to return any skill you wish (including non-armor skills, if you so wish).
Note that this interface function is read by the engine to update the UI.
This function can still be overridden same as any other interface, but must not call any functions or interfaces that modify anything.

### Parameter

-
` openmw.core#GameObject item `:
The item

### Return value

#string:
The armor skill identifier, or unarmored if the item was nil or not an instance of openmw.types#Armor. Can return nil if unimplemented.

Combat.getEffectiveArmorRating(item, actor)

Computes the effective armor rating of a single piece of openmw.types#Armor, adjusted for skill and item condition

### Parameters

-
` openmw.core#GameObject item `:
The item

-
` openmw.core#GameObject actor `:
(Optional) The actor, defaults to self

### Return value

#number:

Combat.getSkillAdjustedArmorRating(item, actor)

Computes the armor rating of a single piece of openmw.types#Armor, adjusted for skill
Note that this interface function is read by the engine to update the UI.

This function can still be overridden same as any other interface, but must not call any functions or interfaces that modify anything.

### Parameters

-
` openmw.core#GameObject item `:
The item

-
` openmw.core#GameObject actor `:
(Optional) The actor, defaults to self

### Return value

#number:

Combat.onHit(attackInfo)

Hit this actor.

Normally called as Hit event from the attacking actor, with the same parameters.

### Parameter

-
` #AttackInfo attackInfo `:

Combat.pickRandomArmor(actor)

Picks a random armor slot and returns the item equipped in that slot.

Used to pick which armor to damage / skill to increase when hit during combat.

### Parameter

-
` openmw.core#GameObject actor `:
(Optional) The actor to pick armor from, defaults to self

### Return value

openmw.core#GameObject:
The armor equipped in the chosen slot. nil if nothing was equipped in that slot.

Combat.spawnBloodEffect(position)

Spawns a random blood effect at the given position

### Parameter

-
` openmw.util#Vector3 position `:

#number

Combat.version

Interface version

## Type `Attack`

## Type `AttackInfo`

### Field(s)

#string

AttackInfo.ammo

(Optional) Ammo record ID

openmw.types#Actor

AttackInfo.attacker

(Optional) Attacking actor

#table

AttackInfo.damage

A table mapping a stat name (health, fatigue, or magicka) to a number. For example, {health = 50, fatigue = 10} will cause 50 damage to health and 10 to fatigue (before adjusting for armor and difficulty). This field is ignored for failed attacks.

openmw.util#Vector3

AttackInfo.hitPos

(Optional) Where on the victim the attack is landing. Used to spawn blood effects. Blood effects are skipped if nil.

#AttackSourceType

AttackInfo.sourceType

What class of attack this is.

#number

AttackInfo.strength

A number between 0 and 1 representing the attack strength. This field is ignored for failed attacks.

#boolean

AttackInfo.successful

Whether the attack was successful or not.

#AttackType

AttackInfo.type

(Optional) Attack variant if applicable. For melee attacks this represents chop vs thrust vs slash. For unarmed creatures this implies which of its 3 possible attacks were used. For other attacks this field can be ignored.

openmw.types#Weapon

AttackInfo.weapon

(Optional) Attacking weapon

## Type `AttackSourceType`

Table of possible attack source types

### Field(s)

#string

AttackSourceType.Magic

#string

AttackSourceType.Melee

#string

AttackSourceType.Ranged

#string

AttackSourceType.Unspecified

## Type `AttackType`

Table of possible attack types

### Field(s)

#number

AttackType.Chop

#number

AttackType.Slash

#number

AttackType.Thrust

Interface Camera

Interface Controls
