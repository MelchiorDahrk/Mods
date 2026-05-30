# Package openmw.types

# Package openmw.types

API v129

Defines functions for specific types of game objects.

global
local
player

## Usage

`local types = require('openmw.types')`

## Type `types`

types.Activator

#Activator functions

types.Actor

Common #Actor functions for Creature, NPC, and Player.

types.Apparatus

#Apparatus functions

types.Armor

#Armor functions

types.Book

#Book functions

types.Clothing

#Clothing functions

types.Container

#Container functions

types.Creature

#Creature functions

types.Door

#Door functions

types.ESM4Activator

Functions for #ESM4Activator objects

types.ESM4Ammunition

Functions for #ESM4Ammunition objects

types.ESM4Armor

Functions for #ESM4Armor objects

types.ESM4Book

Functions for #ESM4Book objects

types.ESM4Clothing

Functions for #ESM4Clothing objects

types.ESM4Door

Functions for #ESM4Door objects

types.ESM4Flora

Functions for #ESM4Flora objects

types.ESM4Ingredient

Functions for #ESM4Ingredient objects

types.ESM4ItemMod

Functions for #ESM4ItemMod objects

types.ESM4Light

Functions for #ESM4Light objects

types.ESM4Miscellaneous

Functions for #ESM4Miscellaneous objects

types.ESM4MovableStatic

Functions for #ESM4MovableStatic objects

types.ESM4Potion

Functions for #ESM4Potion objects

types.ESM4Static

Functions for #ESM4Static objects

types.ESM4StaticCollection

Functions for #ESM4StaticCollection objects

types.ESM4Terminal

Functions for #ESM4Terminal objects

types.ESM4Weapon

Functions for #ESM4Weapon objects

types.Ingredient

#Ingredient functions

types.Item

#Item functions (all items that can be placed to an inventory or container)

types.LevelledCreature

#CreatureLevelledList functions

types.Light

#Light functions

types.Lockable

#LOCKABLE functions

types.Lockpick

#Lockpick functions

types.Miscellaneous

Functions for #Miscellaneous objects

types.NPC

#NPC functions

types.Player

#PLAYER functions

types.Potion

#Potion functions

types.Probe

#Probe functions

types.Repair

#Repair functions

types.Static

Functions for #Static objects

types.Weapon

#Weapon functions

## Type `AIStat`

AIStat.base

The stat's base value.

AIStat.modified

The actor's current ai value (read-only.)

AIStat.modifier

The stat's modifier.

## Type `AIStats`

AIStats.alarm(actor)

Alarm (returns #AIStat)

AIStats.fight(actor)

Fight (returns #AIStat)

AIStats.flee(actor)

Flee (returns #AIStat)

AIStats.hello(actor)

Hello (returns #AIStat)

## Type `Activator`

Activator.createRecordDraft(activator)

Creates an #ActivatorRecord without adding it to the world database.

Activator.objectIsInstance(object)

Whether the object is an Activator.

Activator.record(objectOrRecordId)

Returns the read-only #ActivatorRecord of an activator

Activator.records

A read-only list of all #ActivatorRecords in the world database.

## Type `ActivatorRecord`

ActivatorRecord.id

Record id

ActivatorRecord.model

VFS path to the model

ActivatorRecord.mwscript

MWScript on this activator (can be nil)

ActivatorRecord.name

Human-readable name

## Type `Actor`

Actor.EQUIPMENT_SLOT

Available #EQUIPMENT_SLOT values.

Actor.STANCE

#STANCE

Actor.activeEffects(actor)

Return the active magic effects (#ActorActiveEffects) currently affecting the given actor.

Actor.activeSpells(actor)

Return the active spells (#ActorActiveSpells) currently affecting the given actor.

Actor.canMove(object)

Returns true if the object is an actor and is able to move.

Actor.clearSelectedCastable(actor)

Clears the actor's selected castable (spell or enchanted item)

Actor.getBarterGold(actor)

Get the actor's current barter gold.

Actor.getCapacity(actor)

Get the total weight that the actor can carry.

Actor.getCurrentSpeed(actor)

Current speed.

Actor.getEncumbrance(actor)

Get the total weight of everything the actor is carrying, plus modifications from magic effects.

Actor.getEquipment(actor, slot)

Get equipment.

Actor.getPathfindingAgentBounds(actor)

Agent bounds to be used for pathfinding functions.

Actor.getRunSpeed(actor)

Speed of running.

Actor.getSelectedEnchantedItem(actor)

Get currently selected enchanted item

Actor.getSelectedSpell(actor)

Get currently selected spell

Actor.getStance(actor)

Returns the current stance (whether a weapon/spell is readied), see the list of #STANCE values.

Actor.getWalkSpeed(actor)

Speed of walking.

Actor.hasEquipped(actor, item)

Returns `true` if the item is equipped on the actor.

Actor.inventory(actor)

Actor inventory.

Actor.isDead(actor)

Check if the given actor is dead (health reached 0, so death process started).

Actor.isDeathFinished(actor)

Check if the given actor's death process is finished.

Actor.isInActorsProcessingRange(actor)

Check if given actor is in the actors processing range.

Actor.isOnGround(actor)

Is the actor standing on ground.

Actor.isSwimming(actor)

Is the actor in water.

Actor.objectIsInstance(object)

Whether the object is an actor.

Actor.setBarterGold(actor, amount)

Set the actor's current barter gold.

Actor.setEquipment(actor, equipment)

Set equipment.

Actor.setSelectedEnchantedItem(actor, item)

Set currently selected enchanted item, equipping it if applicable

Actor.setSelectedSpell(actor, spell)

Set selected spell

Actor.setStance(actor, stance)

Sets the current stance (whether a weapon/spell is readied), see the list of #STANCE values.

Actor.spells(actor)

Return the spells (#ActorSpells) of the given actor.

Actor.stats

The actor's stats.

## Type `ActorActiveEffects`

ActorActiveEffects:getEffect(effectId, extraParam)

Get a specific active effect on the actor.

ActorActiveEffects:modify(value, effectId, extraParam)

Permanently modifies the magnitude of an active effect by modifying it by the provided value.

ActorActiveEffects:remove(effectId, extraParam)

Completely removes the active effect from the actor.

ActorActiveEffects:set(value, effectId, extraParam)

(Note that using this function will override and conflict with all other sources of this effect.

## Type `ActorActiveSpells`

ActorActiveSpells:add(options)

Adds a new spell to the list of active spells (only in global scripts or on self).

ActorActiveSpells:isSpellActive(recordOrId)

Get whether any instance of the specific spell is active on the actor.

ActorActiveSpells:remove(id)

Remove an active spell based on active spell ID (see openmw_core#ActiveSpell.activeSpellId).

## Type `ActorSpells`

ActorSpells:add(spellOrId)

Add spell (only in global scripts or on self).

ActorSpells:canUsePower(spellOrId)

If true, the actor has not used this power in the last 24h.

ActorSpells:clear()

Remove all spells (only in global scripts or on self).

ActorSpells:remove(spellOrId)

Remove spell (only in global scripts or on self).

## Type `ActorStats`

ActorStats.ai

ActorStats.attributes

ActorStats.dynamic

ActorStats.level(actor)

Level (returns #LevelStat)

## Type `Apparatus`

Apparatus.TYPE

#ApparatusTYPE

Apparatus.baseType

#Item

Apparatus.objectIsInstance(object)

Whether the object is an Apparatus.

Apparatus.record(objectOrRecordId)

Returns the read-only #ApparatusRecord of an apparatus

Apparatus.records

A read-only list of all #ApparatusRecords in the world database.

## Type `ApparatusRecord`

ApparatusRecord.icon

VFS path to the icon

ApparatusRecord.id

The record ID of the apparatus

ApparatusRecord.model

VFS path to the model

ApparatusRecord.mwscript

MWScript on this apparatus (can be nil)

ApparatusRecord.name

The name of the apparatus

ApparatusRecord.quality

The quality of the apparatus

ApparatusRecord.type

The type of apparatus. See Apparatus.TYPE

ApparatusRecord.value

ApparatusRecord.weight

## Type `ApparatusTYPE`

ApparatusTYPE.Alembic

ApparatusTYPE.Calcinator

ApparatusTYPE.MortarPestle

ApparatusTYPE.Retort

## Type `Armor`

Armor.TYPE

#ArmorTYPE

Armor.baseType

#Item

Armor.createRecordDraft(armor)

Creates an #ArmorRecord without adding it to the world database, for the armor to appear correctly on the body, make sure to use a template as described below.

Armor.objectIsInstance(object)

Whether the object is an Armor.

Armor.record(objectOrRecordId)

Returns the read-only #ArmorRecord of an Armor

Armor.records

A read-only list of all #ArmorRecords in the world database.

## Type `ArmorRecord`

ArmorRecord.baseArmor

The base armor rating of this armor

ArmorRecord.enchant

The enchantment ID of this armor (can be nil)

ArmorRecord.enchantCapacity

ArmorRecord.health

ArmorRecord.icon

VFS path to the icon

ArmorRecord.id

Record id

ArmorRecord.model

VFS path to the model

ArmorRecord.mwscript

MWScript on this armor (can be nil)

ArmorRecord.name

Human-readable name

ArmorRecord.type

See Armor.TYPE

ArmorRecord.value

ArmorRecord.weight

## Type `ArmorTYPE`

ArmorTYPE.Boots

ArmorTYPE.Cuirass

ArmorTYPE.Greaves

ArmorTYPE.Helmet

ArmorTYPE.LBracer

ArmorTYPE.LGauntlet

ArmorTYPE.LPauldron

ArmorTYPE.RBracer

ArmorTYPE.RGauntlet

ArmorTYPE.RPauldron

ArmorTYPE.Shield

## Type `AttributeStat`

AttributeStat.base

The actor's base attribute value.

AttributeStat.damage

The amount the attribute has been damaged.

AttributeStat.modified

The actor's current attribute value (read-only.)

AttributeStat.modifier

The attribute's modifier.

## Type `AttributeStats`

AttributeStats.agility(actor)

Agility (returns #AttributeStat)

AttributeStats.endurance(actor)

Endurance (returns #AttributeStat)

AttributeStats.intelligence(actor)

Intelligence (returns #AttributeStat)

AttributeStats.luck(actor)

Luck (returns #AttributeStat)

AttributeStats.personality(actor)

Personality (returns #AttributeStat)

AttributeStats.speed(actor)

Speed (returns #AttributeStat)

AttributeStats.strength(actor)

Strength (returns #AttributeStat)

AttributeStats.willpower(actor)

Willpower (returns #AttributeStat)

## Type `BirthSignRecord`

BirthSignRecord.description

Birth sign description

BirthSignRecord.id

Birth sign id

BirthSignRecord.name

Birth sign name

BirthSignRecord.spells

A read-only list containing the ids of all spells gained from this sign.

BirthSignRecord.texture

Birth sign texture

## Type `BirthSigns`

BirthSigns.record(recordId)

Returns a read-only #BirthSignRecord

BirthSigns.records

A read-only list of all #BirthSignRecords in the world database.

## Type `Book`

Book.SKILL

DEPRECATED, use openmw.core#Skill

Book.baseType

#Item

Book.createRecordDraft(book)

Creates a #BookRecord without adding it to the world database.

Book.objectIsInstance(object)

Whether the object is a Book.

Book.record(objectOrRecordId)

Returns the read-only #BookRecord of a book

Book.records

A read-only list of all #BookRecords in the world database.

## Type `BookRecord`

BookRecord.enchant

The enchantment ID of this book (can be nil)

BookRecord.enchantCapacity

BookRecord.icon

VFS path to the icon

BookRecord.id

The record ID of the book

BookRecord.isScroll

BookRecord.model

VFS path to the model

BookRecord.mwscript

MWScript on this book (can be nil)

BookRecord.name

Name of the book

BookRecord.skill

The skill that this book teaches. See openmw.core#SKILL

BookRecord.text

The text content of the book

BookRecord.value

BookRecord.weight

## Type `BookSKILL`

BookSKILL.acrobatics

"acrobatics"

BookSKILL.alchemy

"alchemy"

BookSKILL.alteration

"alteration"

BookSKILL.armorer

"armorer"

BookSKILL.athletics

"athletics"

BookSKILL.axe

"axe"

BookSKILL.block

"block"

BookSKILL.bluntWeapon

"bluntweapon"

BookSKILL.conjuration

"conjuration"

BookSKILL.destruction

"destruction"

BookSKILL.enchant

"enchant"

BookSKILL.handToHand

"handtohand"

BookSKILL.heavyArmor

"heavyarmor"

BookSKILL.illusion

"illusion"

BookSKILL.lightArmor

"lightarmor"

BookSKILL.longBlade

"longblade"

BookSKILL.marksman

"marksman"

BookSKILL.mediumArmor

"mediumarmor"

BookSKILL.mercantile

"mercantile"

BookSKILL.mysticism

"mysticism"

BookSKILL.restoration

"restoration"

BookSKILL.security

"security"

BookSKILL.shortBlade

"shortblade"

BookSKILL.sneak

"sneak"

BookSKILL.spear

"spear"

BookSKILL.speechcraft

"speechcraft"

BookSKILL.unarmored

"unarmored"

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

Vanity view if player doesn't touch controls for a long time

CONTROL_SWITCH.ViewMode

Ability to toggle 1st/3rd person view

## Type `ClassRecord`

ClassRecord.attributes

A read-only list containing the specialized attributes of the class.

ClassRecord.description

Class description

ClassRecord.id

Class id

ClassRecord.isPlayable

True if the player can play as this class

ClassRecord.majorSkills

A read-only list containing the major skills of the class.

ClassRecord.minorSkills

A read-only list containing the minor skills of the class.

ClassRecord.name

Class name

ClassRecord.specialization

Class specialization. Either combat, magic, or stealth.

## Type `Classes`

Classes.record(recordId)

Returns a read-only #ClassRecord

Classes.records

A read-only list of all #ClassRecords in the world database, may be indexed by recordId.

## Type `Clothing`

Clothing.TYPE

#ClothingTYPE

Clothing.baseType

#Item

Clothing.createRecordDraft(clothing)

Creates a #ClothingRecord without adding it to the world database, for the clothing to appear correctly on the body, make sure to use a template as described below.

Clothing.objectIsInstance(object)

Whether the object is a Clothing.

Clothing.record(objectOrRecordId)

Returns the read-only #ClothingRecord of a Clothing

Clothing.records

A read-only list of all #ClothingRecords in the world database.

## Type `ClothingRecord`

ClothingRecord.enchant

The enchantment ID of this clothing (can be nil)

ClothingRecord.enchantCapacity

ClothingRecord.icon

VFS path to the icon

ClothingRecord.id

Record id

ClothingRecord.model

VFS path to the model

ClothingRecord.mwscript

MWScript on this clothing (can be nil)

ClothingRecord.name

Name of the clothing

ClothingRecord.type

See Clothing.TYPE

ClothingRecord.value

ClothingRecord.weight

## Type `ClothingTYPE`

ClothingTYPE.Amulet

ClothingTYPE.Belt

ClothingTYPE.LGlove

ClothingTYPE.Pants

ClothingTYPE.RGlove

ClothingTYPE.Ring

ClothingTYPE.Robe

ClothingTYPE.Shirt

ClothingTYPE.Shoes

ClothingTYPE.Skirt

## Type `Container`

Container.baseType

#LOCKABLE

Container.content(object)

Container content.

Container.createRecordDraft(container)

Creates a #ContainerRecord without adding it to the world database.

Container.getCapacity(object)

Returns the capacity of a container

Container.getEncumbrance(object)

Returns the total weight of everything in a container

Container.inventory(object)

Container content (same as `Container.content`, added for consistency with `Actor.inventory`).

Container.objectIsInstance(object)

Whether the object is a Container.

Container.record(objectOrRecordId)

Returns the read-only #ContainerRecord of a container

Container.records

A read-only list of all #ContainerRecords in the world database.

## Type `ContainerRecord`

ContainerRecord.id

Record id

ContainerRecord.isOrganic

Whether items can be placed in the container

ContainerRecord.isRespawning

Whether the container respawns its contents

ContainerRecord.model

VFS path to the model

ContainerRecord.mwscript

MWScript on this container (can be nil)

ContainerRecord.name

Human-readable name

ContainerRecord.weight

capacity of this container

## Type `Creature`

Creature.TYPE

#CreatureTYPE

Creature.baseType

#Actor

Creature.createRecordDraft(creature)

Creates a #CreatureRecord without adding it to the world database.

Creature.objectIsInstance(object)

Whether the object is a creature.

Creature.record(objectOrRecordId)

Returns the read-only #CreatureRecord of a creature

Creature.records

A read-only list of all #CreatureRecords in the world database, may be indexed by recordId.

## Type `CreatureAttack`

CreatureAttack.maxDamage

Maximum attack damage.

CreatureAttack.minDamage

Minimum attack damage.

## Type `CreatureLevelledList`

CreatureLevelledList.objectIsInstance(object)

Whether the object is a CreatureLevelledList.

CreatureLevelledList.record(objectOrRecordId)

Returns the read-only #CreatureLevelledListRecord of a levelled creature

CreatureLevelledList.records

A read-only list of all #CreatureLevelledListRecords in the world database.

## Type `CreatureLevelledListRecord`

CreatureLevelledListRecord.calculateFromAllLevels

Calculate from all levels <= player level, not just the closest below player

CreatureLevelledListRecord.chanceNone

Chance this list won't spawn anything [0-1]

CreatureLevelledListRecord.creatures

CreatureLevelledListRecord.getRandomId(listRecord, MaxLvl)

Picks a random id from the levelled list.

CreatureLevelledListRecord.id

Record id

## Type `CreatureRecord`

CreatureRecord.attack

A table of the 3 randomly selected attacks used by creatures that do not carry weapons. The table consists of 6 numbers split into groups of 2 values corresponding to minimum and maximum damage in that order.

CreatureRecord.baseCreature

Record id of a base creature, which was modified to create this one

CreatureRecord.baseGold

The base barter gold of the creature

CreatureRecord.bloodType

integer representing the blood type of the Creature. Used to generate the correct blood vfx.

CreatureRecord.canFly

whether the creature can fly

CreatureRecord.canSwim

whether the creature can swim

CreatureRecord.canUseWeapons

whether the creature can use weapons and shields

CreatureRecord.canWalk

whether the creature can walk

CreatureRecord.combatSkill

The base combat skill of the creature. This is the skill value used for all skills with a 'combat' specialization

CreatureRecord.id

The record ID of the creature

CreatureRecord.isAutocalc

If true, the actor's stats will be automatically calculated based on level and class.

CreatureRecord.isBiped

whether the creature is a biped

CreatureRecord.isEssential

whether the creature is essential

CreatureRecord.isRespawning

whether the creature respawns after death

CreatureRecord.magicSkill

The base magic skill of the creature. This is the skill value used for all skills with a 'magic' specialization

CreatureRecord.model

VFS path to the creature's model

CreatureRecord.mwscript

MWScript on this creature (can be nil)

CreatureRecord.name

CreatureRecord.primaryFaction

Faction ID of the NPCs default faction. Nil if no faction

CreatureRecord.primaryFactionRank

Faction rank of the NPCs default faction. Nil if no faction

CreatureRecord.servicesOffered

The services of the creature, in a table. Value is if the service is provided or not, and they are indexed by: Spells, Spellmaking, Enchanting, Training, Repair, Barter, Weapon, Armor, Clothing, Books, Ingredients, Picks, Probes, Lights, Apparatus, RepairItems, Misc, Potions, MagicItems, Travel.

CreatureRecord.soulValue

The soul value of the creature record

CreatureRecord.stealthSkill

The base stealth skill of the creature. This is the skill value used for all skills with a 'stealth' specialization

CreatureRecord.travelDestinations

A list of #TravelDestinations for this creature.

CreatureRecord.type

The Creature.TYPE of the creature

## Type `CreatureTYPE`

CreatureTYPE.Creatures

CreatureTYPE.Daedra

CreatureTYPE.Humanoid

CreatureTYPE.Undead

## Type `Door`

Door.STATE

#DoorSTATE

Door.activateDoor(object, openState)

Opens/Closes the door.

Door.baseType

#LOCKABLE

Door.createRecordDraft(door)

Creates a #DoorRecord without adding it to the world database.

Door.destCell(object)

Destination cell (only if a teleport door).

Door.destPosition(object)

Destination (only if a teleport door).

Door.destRotation(object)

Destination rotation (only if a teleport door).

Door.getDoorState(object)

Gets the state of the door.

Door.isClosed(object)

Checks if the door is fully closed.

Door.isOpen(object)

Checks if the door is fully open.

Door.isTeleport(object)

Whether the door is a teleport.

Door.objectIsInstance(object)

Whether the object is a Door.

Door.record(objectOrRecordId)

Returns the read-only #DoorRecord of a door

Door.records

A read-only list of all #DoorRecords in the world database.

## Type `DoorRecord`

DoorRecord.closeSound

The sound id for door closing

DoorRecord.id

Record id

DoorRecord.model

VFS path to the model

DoorRecord.mwscript

MWScript on this door (can be nil)

DoorRecord.name

Human-readable name

DoorRecord.openSound

The sound id for door opening

## Type `DoorSTATE`

DoorSTATE.Closing

The door is in the process of closing.

DoorSTATE.Idle

The door is either closed or open (usually closed).

DoorSTATE.Opening

The door is in the process of opening.

## Type `DynamicStat`

DynamicStat.base

DynamicStat.current

DynamicStat.modifier

## Type `DynamicStats`

DynamicStats.fatigue(actor)

Fatigue (returns #DynamicStat)

DynamicStats.health(actor)

Health (returns #DynamicStat)

DynamicStats.magicka(actor)

Magicka (returns #DynamicStat)

## Type `EQUIPMENT_SLOT`

EQUIPMENT_SLOT.Ammunition

EQUIPMENT_SLOT.Amulet

EQUIPMENT_SLOT.Belt

EQUIPMENT_SLOT.Boots

EQUIPMENT_SLOT.CarriedLeft

EQUIPMENT_SLOT.CarriedRight

EQUIPMENT_SLOT.Cuirass

EQUIPMENT_SLOT.Greaves

EQUIPMENT_SLOT.Helmet

EQUIPMENT_SLOT.LeftGauntlet

EQUIPMENT_SLOT.LeftPauldron

EQUIPMENT_SLOT.LeftRing

EQUIPMENT_SLOT.Pants

EQUIPMENT_SLOT.RightGauntlet

EQUIPMENT_SLOT.RightPauldron

EQUIPMENT_SLOT.RightRing

EQUIPMENT_SLOT.Robe

EQUIPMENT_SLOT.Shirt

EQUIPMENT_SLOT.Skirt

## Type `ESM4Door`

ESM4Door.baseType

#LOCKABLE

ESM4Door.destCell(object)

Destination cell (only if a teleport door).

ESM4Door.destPosition(object)

Destination (only if a teleport door).

ESM4Door.destRotation(object)

Destination rotation (only if a teleport door).

ESM4Door.isTeleport(object)

Whether the door is a teleport.

ESM4Door.objectIsInstance(object)

Whether the object is a ESM4Door.

ESM4Door.record(objectOrRecordId)

Returns the read-only #ESM4DoorRecord of a door

ESM4Door.records

A read-only list of all #ESM4DoorRecords in the world database.

## Type `ESM4DoorRecord`

ESM4DoorRecord.closeSound

FormId of the door closing sound

ESM4DoorRecord.id

Record id

ESM4DoorRecord.model

VFS path to the model

ESM4DoorRecord.name

Human-readable name

ESM4DoorRecord.openSound

FormId of the door opening sound

## Type `ESM4Terminal`

ESM4Terminal.objectIsInstance(object)

Whether the object is a ESM4Terminal.

ESM4Terminal.record(objectOrRecordId)

Returns the read-only #ESM4TerminalRecord of a terminal

ESM4Terminal.records

A read-only list of all #ESM4TerminalRecords in the world database.

## Type `ESM4TerminalRecord`

ESM4TerminalRecord.editorId

Human-readable ID

ESM4TerminalRecord.id

Record id (Form ID)

ESM4TerminalRecord.model

VFS path to the model

ESM4TerminalRecord.name

Human-readable name

ESM4TerminalRecord.resultText

Result text of the terminal record

ESM4TerminalRecord.text

Text body of the terminal record

## Type `GenderedNumber`

GenderedNumber.female

Female value

GenderedNumber.male

Male value

## Type `Ingredient`

Ingredient.baseType

#Item

Ingredient.objectIsInstance(object)

Whether the object is an Ingredient.

Ingredient.record(objectOrRecordId)

Returns the read-only #IngredientRecord of a Ingredient

Ingredient.records

A read-only list of all #IngredientRecords in the world database.

## Type `IngredientRecord`

IngredientRecord.effects

The effects (openmw.core#MagicEffectWithParams) of the ingredient

IngredientRecord.icon

VFS path to the icon

IngredientRecord.id

Record id

IngredientRecord.model

VFS path to the model

IngredientRecord.mwscript

MWScript on this potion (can be nil)

IngredientRecord.name

Human-readable name

IngredientRecord.value

IngredientRecord.weight

## Type `Item`

Item.getEnchantmentCharge(item)

(DEPRECATED, use itemData(item).enchantmentCharge) Get this item's current enchantment charge.

Item.isCarriable(object)

Whether the object is supposed to be carriable.

Item.isRestocking(item)

Checks if the item restocks.

Item.itemData(item)

Set of properties that differentiates one item from another of the same record type; can be used by any script, but only global and self scripts can change values.

Item.objectIsInstance(object)

Whether the object is an item.

Item.setEnchantmentCharge(item, charge)

(DEPRECATED, use itemData(item).enchantmentCharge) Set this item's enchantment charge.

## Type `ItemData`

ItemData.condition

The item's current condition. Time remaining for lights (setting this to `-1` will make it last forever). Uses left for repairs, lockpicks and probes. Current health for weapons and armor.

ItemData.enchantmentCharge

The item's current enchantment charge. Unenchanted items will always return a value of `nil`. Setting this to `nil` will reset the charge of the item.

ItemData.soul

The recordId of the item's current soul. Items without soul will always return a value of `nil`. Setting this to `nil` will remove the soul from the item.

## Type `LOCKABLE`

LOCKABLE.getKeyRecord(object)

Returns the key record of a lockable object(door, container)

LOCKABLE.getLockLevel(object)

Returns the lock level of a lockable object(door, container).

LOCKABLE.getTrapSpell(object)

Returns the trap spell of a lockable object(door, container)

LOCKABLE.isLocked(object)

Returns true if the lockable object is locked, and false if it is not.

LOCKABLE.lock(object, lockLevel)

Sets the lock level level of a lockable object(door, container);Locks if not already locked; Must be used in a global script.

LOCKABLE.objectIsInstance(object)

Whether the object is a Lockable.

LOCKABLE.setKeyRecord(object, miscOrId)

Sets the key of a lockable object(door, container); removes it if empty string is provided.

LOCKABLE.setTrapSpell(object, spellOrId)

Sets the trap spell of a lockable object(door, container); removes it if empty string is provided.

LOCKABLE.unlock(object)

Unlocks the lockable object.

## Type `LevelStat`

LevelStat.current

The actor's current level.

LevelStat.progress

The NPC's level progress.

LevelStat.skillIncreasesForAttribute

The NPC's attribute contributions towards the next level up. Values affect how much each attribute can be increased at level up.

LevelStat.skillIncreasesForSpecialization

The NPC's attribute contributions towards the next level up. Values affect the graphic used on the level up screen.

## Type `LevelledListItem`

LevelledListItem.id

Item id

LevelledListItem.level

The minimum player level at which this item can occur

## Type `Light`

Light.baseType

#Item

Light.createRecordDraft(light)

Creates a #LightRecord without adding it to the world database.

Light.objectIsInstance(object)

Whether the object is a Light.

Light.record(objectOrRecordId)

Returns the read-only #LightRecord of a Light

Light.records

A read-only list of all #LightRecords in the world database.

## Type `LightRecord`

LightRecord.color

LightRecord.duration

LightRecord.icon

VFS path to the icon

LightRecord.id

Record id

LightRecord.isCarriable

True if the light can be carried by actors and appears up in their inventory.

LightRecord.isDynamic

If true, the light will apply to actors and other moving objects

LightRecord.isFire

True if the light acts like a fire.

LightRecord.isFlicker

LightRecord.isFlickerSlow

LightRecord.isNegative

If true, the light will reduce light instead of increasing it.

LightRecord.isOffByDefault

If true, the light will not emit any light or sound while placed in the world. It will still work in the inventory.

LightRecord.isPulse

LightRecord.isPulseSlow

LightRecord.model

VFS path to the model

LightRecord.mwscript

MWScript on this light (can be nil)

LightRecord.name

Human-readable name

LightRecord.radius

LightRecord.sound

VFS path to the sound

LightRecord.value

LightRecord.weight

## Type `Lockpick`

Lockpick.baseType

#Item

Lockpick.objectIsInstance(object)

Whether the object is a Lockpick.

Lockpick.record(objectOrRecordId)

Returns the read-only #LockpickRecord of a lockpick

Lockpick.records

A read-only list of all #LockpickRecords in the world database.

## Type `LockpickRecord`

LockpickRecord.icon

VFS path to the icon

LockpickRecord.id

The record ID of the lockpick

LockpickRecord.maxCondition

The maximum number of uses of this lockpick

LockpickRecord.model

VFS path to the model

LockpickRecord.mwscript

MWScript on this lockpick (can be nil)

LockpickRecord.name

The name of the lockpick

LockpickRecord.quality

The quality of the lockpick

LockpickRecord.value

LockpickRecord.weight

## Type `Miscellaneous`

Miscellaneous.baseType

#Item

Miscellaneous.createRecordDraft(miscellaneous)

Creates a #MiscellaneousRecord without adding it to the world database.

Miscellaneous.getSoul(object)

(DEPRECATED, use itemData(item).soul) Returns the read-only soul of a miscellaneous item

Miscellaneous.objectIsInstance(object)

Whether the object is a Miscellaneous.

Miscellaneous.record(objectOrRecordId)

Returns the read-only #MiscellaneousRecord of a miscellaneous item

Miscellaneous.records

A read-only list of all #MiscellaneousRecords in the world database.

Miscellaneous.setSoul(object, soulId)

(DEPRECATED, use itemData(item).soul) Sets the soul of a miscellaneous item, intended for soul gem objects; Must be used in a global script.

## Type `MiscellaneousRecord`

MiscellaneousRecord.icon

VFS path to the icon

MiscellaneousRecord.id

The record ID of the miscellaneous item

MiscellaneousRecord.isKey

MiscellaneousRecord.model

VFS path to the model

MiscellaneousRecord.mwscript

MWScript on this miscellaneous item (can be nil)

MiscellaneousRecord.name

The name of the miscellaneous item

MiscellaneousRecord.value

MiscellaneousRecord.weight

## Type `NPC`

NPC.baseType

#Actor

NPC.classes

#Classes: Class Data

NPC.clearExpelled(actor, faction)

Clear expelling of NPC from given faction.

NPC.createRecordDraft(npc)

Creates an #NpcRecord without adding it to the world database.

NPC.expel(actor, faction)

Expel NPC from given faction.

NPC.getBaseDisposition(object, player)

Returns the current base disposition of the provided NPC.

NPC.getDisposition(object, player)

Returns the current disposition of the provided NPC.

NPC.getFactionRank(actor, faction)

Get rank of given NPC in given faction.

NPC.getFactionReputation(actor, faction)

Get reputation of given actor in given faction.

NPC.getFactions(actor)

Get all factions in which NPC has a membership.

NPC.isExpelled(actor, faction)

Check if NPC is expelled from given faction.

NPC.isWerewolf(actor)

Whether the NPC or player is in the werewolf form at the moment.

NPC.joinFaction(actor, faction)

Add given actor to given faction.

NPC.leaveFaction(actor, faction)

Remove given actor from given faction.

NPC.modifyBaseDisposition(object, player, value)

Modify the base disposition of the provided NPC by a certain amount (only in global scripts or on self).

NPC.modifyFactionRank(actor, faction, value)

Adjust rank of given NPC in given faction.

NPC.modifyFactionReputation(actor, faction, value)

Adjust reputation of given actor in given faction.

NPC.objectIsInstance(object)

Whether the object is an NPC or a Player.

NPC.races

#Races: Race data

NPC.record(objectOrRecordId)

Returns the read-only #NpcRecord of an NPC

NPC.records

A read-only list of all #NpcRecords in the world database, may be indexed by recordId.

NPC.setBaseDisposition(object, player, value)

Set the base disposition of the provided NPC (only in global scripts or on self).

NPC.setFactionRank(actor, faction, value)

Set rank of given NPC in given faction.

NPC.setFactionReputation(actor, faction, value)

Set reputation of given actor in given faction.

NPC.setWerewolf(actor, werewolf)

Turn an NPC or player into werewolf form or back to normal form.

NPC.stats

## Type `NpcRecord`

NpcRecord.baseDisposition

NPC's starting disposition

NpcRecord.baseGold

The base barter gold of the NPC

NpcRecord.bloodType

integer representing the blood type of the NPC. Used to generate the correct blood vfx.

NpcRecord.class

ID of the NPC's class (e.g. acrobat)

NpcRecord.hair

ID of the hair body part

NpcRecord.head

ID of the head body part

NpcRecord.id

The record ID of the NPC

NpcRecord.isAutocalc

If true, the actor's stats will be automatically calculated based on level and class.

NpcRecord.isEssential

whether the NPC is essential

NpcRecord.isMale

The gender setting of the NPC

NpcRecord.isRespawning

whether the NPC respawns after death

NpcRecord.model

Path to the model associated with this NPC, used for animations.

NpcRecord.mwscript

MWScript on this NPC (can be nil)

NpcRecord.name

NpcRecord.race

NpcRecord.servicesOffered

The services of the NPC, in a table. Value is if the service is provided or not, and they are indexed by: Spells, Spellmaking, Enchanting, Training, Repair, Barter, Weapon, Armor, Clothing, Books, Ingredients, Picks, Probes, Lights, Apparatus, RepairItems, Misc, Potions, MagicItems, Travel.

NpcRecord.travelDestinations

A list of #TravelDestinations for this NPC.

## Type `NpcStats`

NpcStats.reputation

NpcStats.skills

## Type `OFFENSE_TYPE_IDS`

OFFENSE_TYPE_IDS.Assault

OFFENSE_TYPE_IDS.Murder

OFFENSE_TYPE_IDS.Pickpocket

OFFENSE_TYPE_IDS.SleepingInOwnedBed

OFFENSE_TYPE_IDS.Theft

OFFENSE_TYPE_IDS.Trespassing

## Type `PLAYER`

PLAYER.CONTROL_SWITCH

Values that can be used with getControlSwitch/setControlSwitch.

PLAYER.OFFENSE_TYPE

Available #OFFENSE_TYPE_IDS values.

PLAYER.addTopic(player, string)

Adds a topic to the list of ones known by the player, so that it can be used in dialogue with actors who can talk about that topic.

PLAYER.baseType

#NPC

PLAYER.birthSigns

#BirthSigns: Birth Sign Data

PLAYER.getBirthSign(player)

PLAYER.getControlSwitch(player, key)

Get state of a control switch.

PLAYER.getCrimeLevel(player)

Returns the bounty or crime level of the player

PLAYER.isCharGenFinished(player)

Whether the character generation for this player is finished.

PLAYER.isTeleportingEnabled(player)

Whether teleportation for this player is enabled.

PLAYER.journal(player)

Returns #PlayerJournal, which contains the read-only access to journal text data accumulated by the player.

PLAYER.objectIsInstance(object)

Whether the object is a player.

PLAYER.quests(player)

Returns a list containing quests #PLAYERQuest for the specified player, indexed by quest ID.

PLAYER.sendMenuEvent(player, eventName, eventData)

Send an event to menu scripts.

PLAYER.setBirthSign(player, recordOrId)

Can be used only in global scripts.

PLAYER.setControlSwitch(player, key, value)

Set state of a control switch.

PLAYER.setCrimeLevel(player, crimeLevel)

Sets the bounty or crime level of the player, may only be used in global scripts

PLAYER.setTeleportingEnabled(player, state)

Enables or disables teleportation for this player.

## Type `PLAYERQuest`

PLAYERQuest:addJournalEntry(stage, actor)

Sets the quest stage for the given quest, on the given player, and adds the entry to the journal, if there is an entry at the specified stage.

PLAYERQuest.finished

Whether the quest is finished (global and player scripts can change it).

PLAYERQuest.id

The quest id.

PLAYERQuest.stage

The quest stage (global and player scripts can change it). Changing the stage starts the quest if it wasn't started.

PLAYERQuest.started

Whether the quest is started.

## Type `PlayerJournal`

PlayerJournal.journalTextEntries

A read-only list of player's accumulated journal (quest etc.) entries (#PlayerJournalTextEntry elements), ordered from oldest entry to newest.

PlayerJournal.topics

A read-only table of player's accumulated #PlayerJournalTopics, indexed by the topic name.

## Type `PlayerJournalTextEntry`

PlayerJournalTextEntry.day

Number of the day this journal entry was written at.

PlayerJournalTextEntry.dayOfMonth

Number of the day in the month this journal entry was written at.

PlayerJournalTextEntry.id

Identifier for this journal entry line.

PlayerJournalTextEntry.month

Number of the month this journal entry was written at.

PlayerJournalTextEntry.questId

Quest id this journal entry is associated with. Can be nil if there is no quest associated with this entry or if journal quest sorting functionality is not available in game.

PlayerJournalTextEntry.text

Text of this journal entry.

## Type `PlayerJournalTopic`

PlayerJournalTopic.entries

A read-only list of player's accumulated conversation lines (#PlayerJournalTopicEntry) for this topic.

PlayerJournalTopic.id

Topic id. It's a lowercase version of name.

PlayerJournalTopic.name

Topic name. Same as id, but with upper cases preserved.

## Type `PlayerJournalTopicEntry`

PlayerJournalTopicEntry.actor

Name of an NPC who is recorded in the player journal as an origin of this topic line.

PlayerJournalTopicEntry.id

Identifier for this topic line.

PlayerJournalTopicEntry.text

Text of this topic line.

## Type `Potion`

Potion.baseType

#Item

Potion.createRecordDraft(potion)

Creates a #PotionRecord without adding it to the world database.

Potion.objectIsInstance(object)

Whether the object is a Potion.

Potion.record(objectOrRecordId)

Returns the read-only #PotionRecord of a potion

Potion.records

A read-only list of all #PotionRecords in the world database.

## Type `PotionRecord`

PotionRecord.effects

The effects (openmw.core#MagicEffectWithParams) of the potion

PotionRecord.icon

VFS path to the icon

PotionRecord.id

Record id

PotionRecord.isAutocalc

If set, the gold value should be computed based on the effect list rather than read from the value field

PotionRecord.model

VFS path to the model

PotionRecord.mwscript

MWScript on this potion (can be nil)

PotionRecord.name

Human-readable name

PotionRecord.value

PotionRecord.weight

## Type `Probe`

Probe.baseType

#Item

Probe.createRecordDraft(probe)

Creates a #ProbeRecord without adding it to the world database.

Probe.objectIsInstance(object)

Whether the object is a Probe.

Probe.record(objectOrRecordId)

Returns the read-only #ProbeRecord of a probe

Probe.records

A read-only list of all #ProbeRecords in the world database.

## Type `ProbeRecord`

ProbeRecord.icon

VFS path to the icon

ProbeRecord.id

The record ID of the probe

ProbeRecord.maxCondition

The maximum number of uses of this probe

ProbeRecord.model

VFS path to the model

ProbeRecord.mwscript

MWScript on this probe (can be nil)

ProbeRecord.name

The name of the probe

ProbeRecord.quality

The quality of the probe

ProbeRecord.value

ProbeRecord.weight

## Type `RaceRecord`

RaceRecord.attributes

A read-only table of attribute ID to base value

RaceRecord.description

Race description

RaceRecord.height

Height values

RaceRecord.id

Race id

RaceRecord.isBeast

True if this race is a beast race

RaceRecord.isPlayable

True if the player can pick this race in character generation

RaceRecord.name

Race name

RaceRecord.skills

A map of bonus skill points by skill ID

RaceRecord.spells

A read-only list containing the ids of all spells inherent to the race

RaceRecord.weight

Weight values

## Type `Races`

Races.record(recordId)

Returns a read-only #RaceRecord

Races.records

A read-only list of all #RaceRecords in the world database.

## Type `Repair`

Repair.baseType

#Item

Repair.objectIsInstance(object)

Whether the object is a Repair.

Repair.record(objectOrRecordId)

Returns the read-only #RepairRecord of a repair tool

Repair.records

A read-only list of all #RepairRecords in the world database.

## Type `RepairRecord`

RepairRecord.icon

VFS path to the icon

RepairRecord.id

The record ID of the repair tool

RepairRecord.maxCondition

The maximum number of uses of this repair tool

RepairRecord.model

VFS path to the model

RepairRecord.mwscript

MWScript on this repair tool (can be nil)

RepairRecord.name

The name of the repair tool

RepairRecord.quality

The quality of the repair tool

RepairRecord.value

RepairRecord.weight

## Type `ReputationStat`

ReputationStat.current

Current reputation value.

## Type `STANCE`

STANCE.Nothing

Default stance

STANCE.Spell

Magic stance

STANCE.Weapon

Weapon stance

## Type `SkillIncreasesForAttributeStats`

SkillIncreasesForAttributeStats.agility

Number of contributions to agility for the next level up.

SkillIncreasesForAttributeStats.endurance

Number of contributions to endurance for the next level up.

SkillIncreasesForAttributeStats.intelligence

Number of contributions to intelligence for the next level up.

SkillIncreasesForAttributeStats.luck

Number of contributions to luck for the next level up.

SkillIncreasesForAttributeStats.personality

Number of contributions to personality for the next level up.

SkillIncreasesForAttributeStats.speed

Number of contributions to speed for the next level up.

SkillIncreasesForAttributeStats.strength

Number of contributions to strength for the next level up.

SkillIncreasesForAttributeStats.willpower

Number of contributions to willpower for the next level up.

## Type `SkillIncreasesForSpecializationStats`

SkillIncreasesForSpecializationStats.combat

Number of contributions to combat specialization for the next level up.

SkillIncreasesForSpecializationStats.magic

Number of contributions to magic specialization for the next level up.

SkillIncreasesForSpecializationStats.stealth

Number of contributions to stealth specialization for the next level up.

## Type `SkillStat`

SkillStat.base

The NPC's base skill value.

SkillStat.damage

The amount the skill has been damaged.

SkillStat.modified

The NPC's current skill value (read-only.)

SkillStat.modifier

The skill's modifier.

SkillStat.progress

[0-1] The NPC's skill progress.

## Type `SkillStats`

SkillStats.acrobatics(actor)

Acrobatics (returns #SkillStat)

SkillStats.alchemy(actor)

Alchemy (returns #SkillStat)

SkillStats.alteration(actor)

Alteration (returns #SkillStat)

SkillStats.armorer(actor)

Armorer (returns #SkillStat)

SkillStats.athletics(actor)

Athletics (returns #SkillStat)

SkillStats.axe(actor)

Axe (returns #SkillStat)

SkillStats.block(actor)

Block (returns #SkillStat)

SkillStats.bluntweapon(actor)

Blunt Weapon (returns #SkillStat)

SkillStats.conjuration(actor)

Conjuration (returns #SkillStat)

SkillStats.destruction(actor)

Destruction (returns #SkillStat)

SkillStats.enchant(actor)

Enchant (returns #SkillStat)

SkillStats.handtohand(actor)

Hand To Hand (returns #SkillStat)

SkillStats.heavyarmor(actor)

Heavy Armor (returns #SkillStat)

SkillStats.illusion(actor)

Illusion (returns #SkillStat)

SkillStats.lightarmor(actor)

Light Armor (returns #SkillStat)

SkillStats.longblade(actor)

Long Blade (returns #SkillStat)

SkillStats.marksman(actor)

Marksman (returns #SkillStat)

SkillStats.mediumarmor(actor)

Medium Armor (returns #SkillStat)

SkillStats.mercantile(actor)

Mercantile (returns #SkillStat)

SkillStats.mysticism(actor)

Mysticism (returns #SkillStat)

SkillStats.restoration(actor)

Restoration (returns #SkillStat)

SkillStats.security(actor)

Security (returns #SkillStat)

SkillStats.shortblade(actor)

Short Blade (returns #SkillStat)

SkillStats.sneak(actor)

Sneak (returns #SkillStat)

SkillStats.spear(actor)

Spear (returns #SkillStat)

SkillStats.speechcraft(actor)

Speechcraft (returns #SkillStat)

SkillStats.unarmored(actor)

Unarmored (returns #SkillStat)

## Type `Static`

Static.createRecordDraft(static)

Creates a #StaticRecord without adding it to the world database.

Static.objectIsInstance(object)

Whether the object is a Static.

Static.record(objectOrRecordId)

Returns the read-only #StaticRecord of a Static

Static.records

A read-only list of all #StaticRecords in the world database.

## Type `StaticRecord`

StaticRecord.id

Record id

StaticRecord.model

VFS path to the model

## Type `TravelDestination`

TravelDestination.cellId

ID of the Destination cell for this TravelDestination, Can be used with openmw_world#world.getCellById.

TravelDestination.position

Destination position for this TravelDestination.

TravelDestination.rotation

Destination rotation for this TravelDestination.

## Type `Weapon`

Weapon.TYPE

#WeaponTYPE

Weapon.baseType

#Item

Weapon.createRecordDraft(weapon)

Creates a #WeaponRecord without adding it to the world database.

Weapon.objectIsInstance(object)

Whether the object is a Weapon.

Weapon.record(objectOrRecordId)

Returns the read-only #WeaponRecord of a weapon

Weapon.records

A read-only list of all #WeaponRecords in the world database.

## Type `WeaponRecord`

WeaponRecord.chopMaxDamage

WeaponRecord.chopMinDamage

WeaponRecord.enchant

The enchantment ID of this weapon (can be nil)

WeaponRecord.enchantCapacity

WeaponRecord.health

WeaponRecord.icon

VFS path to the icon

WeaponRecord.id

Record id

WeaponRecord.isMagical

WeaponRecord.isSilver

WeaponRecord.model

VFS path to the model

WeaponRecord.mwscript

MWScript on this weapon (can be nil)

WeaponRecord.name

Human-readable name

WeaponRecord.reach

WeaponRecord.slashMaxDamage

WeaponRecord.slashMinDamage

WeaponRecord.speed

WeaponRecord.thrustMaxDamage

WeaponRecord.thrustMinDamage

WeaponRecord.type

See Weapon.TYPE

WeaponRecord.value

WeaponRecord.weight

## Type `WeaponTYPE`

WeaponTYPE.Arrow

WeaponTYPE.AxeOneHand

WeaponTYPE.AxeTwoHand

WeaponTYPE.BluntOneHand

WeaponTYPE.BluntTwoClose

WeaponTYPE.BluntTwoWide

WeaponTYPE.Bolt

WeaponTYPE.LongBladeOneHand

WeaponTYPE.LongBladeTwoHand

WeaponTYPE.MarksmanBow

WeaponTYPE.MarksmanCrossbow

WeaponTYPE.MarksmanThrown

WeaponTYPE.ShortBladeOneHand

WeaponTYPE.SpearTwoWide

## Type `types`

### Field(s)

#Activator

types.Activator

#Activator functions

#Actor

types.Actor

Common #Actor functions for Creature, NPC, and Player.

#Apparatus

types.Apparatus

#Apparatus functions

#Armor

types.Armor

#Armor functions

#Book

types.Book

#Book functions

#Clothing

types.Clothing

#Clothing functions

#Container

types.Container

#Container functions

#Creature

types.Creature

#Creature functions

#Door

types.Door

#Door functions

#ESM4Activator

types.ESM4Activator

Functions for #ESM4Activator objects

#ESM4Ammunition

types.ESM4Ammunition

Functions for #ESM4Ammunition objects

#ESM4Armor

types.ESM4Armor

Functions for #ESM4Armor objects

#ESM4Book

types.ESM4Book

Functions for #ESM4Book objects

#ESM4Clothing

types.ESM4Clothing

Functions for #ESM4Clothing objects

#ESM4Door

types.ESM4Door

Functions for #ESM4Door objects

#ESM4Flora

types.ESM4Flora

Functions for #ESM4Flora objects

#ESM4Ingredient

types.ESM4Ingredient

Functions for #ESM4Ingredient objects

#ESM4ItemMod

types.ESM4ItemMod

Functions for #ESM4ItemMod objects

#ESM4Light

types.ESM4Light

Functions for #ESM4Light objects

#ESM4Miscellaneous

types.ESM4Miscellaneous

Functions for #ESM4Miscellaneous objects

#ESM4MovableStatic

types.ESM4MovableStatic

Functions for #ESM4MovableStatic objects

#ESM4Potion

types.ESM4Potion

Functions for #ESM4Potion objects

#ESM4Static

types.ESM4Static

Functions for #ESM4Static objects

#ESM4StaticCollection

types.ESM4StaticCollection

Functions for #ESM4StaticCollection objects

#ESM4Terminal

types.ESM4Terminal

Functions for #ESM4Terminal objects

#ESM4Weapon

types.ESM4Weapon

Functions for #ESM4Weapon objects

#Ingredient

types.Ingredient

#Ingredient functions

#Item

types.Item

#Item functions (all items that can be placed to an inventory or container)

#CreatureLevelledList

types.LevelledCreature

#CreatureLevelledList functions

#Light

types.Light

#Light functions

#LOCKABLE

types.Lockable

#LOCKABLE functions

#Lockpick

types.Lockpick

#Lockpick functions

#Miscellaneous

types.Miscellaneous

Functions for #Miscellaneous objects

#NPC

types.NPC

#NPC functions

#PLAYER

types.Player

#PLAYER functions

#Potion

types.Potion

#Potion functions

#Probe

types.Probe

#Probe functions

#Repair

types.Repair

#Repair functions

#Static

types.Static

Functions for #Static objects

#Weapon

types.Weapon

#Weapon functions

## Type `AIStat`

Value modification is delayed

### Field(s)

#number

AIStat.base

The stat's base value.

#number

AIStat.modified

The actor's current ai value (read-only.)

#number

AIStat.modifier

The stat's modifier.

## Type `AIStats`

### Field(s)

AIStats.alarm(actor)

Alarm (returns #AIStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#AIStat:

AIStats.fight(actor)

Fight (returns #AIStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#AIStat:

AIStats.flee(actor)

Flee (returns #AIStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#AIStat:

AIStats.hello(actor)

Hello (returns #AIStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#AIStat:

## Type `Activator`

### Field(s)

Activator.createRecordDraft(activator)

Creates an #ActivatorRecord without adding it to the world database.

Use openmw_world#world.createRecord to add the record to the world.

### Parameter

-
` #ActivatorRecord activator `:
A Lua table with the fields of an ActivatorRecord, with an optional field `template` that accepts an #ActivatorRecord as a base.

### Return value

#ActivatorRecord:
A strongly typed Activator record.

Activator.objectIsInstance(object)

Whether the object is an Activator.

### Parameter

-
` openmw.core#GameObject object `:

### Return value

#boolean:

Activator.record(objectOrRecordId)

Returns the read-only #ActivatorRecord of an activator

### Parameter

-
` #any objectOrRecordId `:

### Return value

#ActivatorRecord:

#list<#ActivatorRecord>

Activator.records

A read-only list of all #ActivatorRecords in the world database.

Implements iterables#List of #ActivatorRecord.

### Usages

-

`local record = types.Activator.records['example_recordid']`

-

`local record = types.Activator.records[1]`

## Type `ActivatorRecord`

### Field(s)

#string

ActivatorRecord.id

Record id

#string

ActivatorRecord.model

VFS path to the model

#string

ActivatorRecord.mwscript

MWScript on this activator (can be nil)

#string

ActivatorRecord.name

Human-readable name

## Type `Actor`

Common functions for Creature, NPC, and Player.

### Field(s)

#EQUIPMENT_SLOT

Actor.EQUIPMENT_SLOT

Available #EQUIPMENT_SLOT values.

Used in `Actor.getEquipment(obj)` and `Actor.setEquipment(obj, eqp)`.

#STANCE

Actor.STANCE

#STANCE

Actor.activeEffects(actor)

Return the active magic effects (#ActorActiveEffects) currently affecting the given actor.

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#ActorActiveEffects:

Actor.activeSpells(actor)

Return the active spells (#ActorActiveSpells) currently affecting the given actor.

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#ActorActiveSpells:

Actor.canMove(object)

Returns true if the object is an actor and is able to move.

For dead, paralyzed,
or knocked down actors it returns false.

### Parameter

-
` openmw.core#GameObject object `:

### Return value

#boolean:

Actor.clearSelectedCastable(actor)

Clears the actor's selected castable (spell or enchanted item)

### Parameter

-
` openmw.core#GameObject actor `:

Actor.getBarterGold(actor)

Get the actor's current barter gold.

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#number:

Actor.getCapacity(actor)

Get the total weight that the actor can carry.

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#number:

Actor.getCurrentSpeed(actor)

Current speed.

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#number:

Actor.getEncumbrance(actor)

Get the total weight of everything the actor is carrying, plus modifications from magic effects.

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#number:

Actor.getEquipment(actor, slot)

Get equipment.

Has two overloads:

- With a single argument: returns a table `slot` -> openmw.core#GameObject of currently equipped items.
See #EQUIPMENT_SLOT. Returns empty table if the actor doesn't have equipment slots.

- With two arguments: returns an item equipped to the given slot.

### Parameters

-
` openmw.core#GameObject actor `:

-
` #number slot `:
Optional number of the equipment slot

### Return value

#EquipmentTable, openmw.core#GameObject:

Actor.getPathfindingAgentBounds(actor)

Agent bounds to be used for pathfinding functions.

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#table:
with `shapeType` and `halfExtents`

Actor.getRunSpeed(actor)

Speed of running.

For dead actors it still returns a positive value.

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#number:

Actor.getSelectedEnchantedItem(actor)

Get currently selected enchanted item

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

openmw.core#GameObject, nil enchanted item or nil

Actor.getSelectedSpell(actor)

Get currently selected spell

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

openmw.core#Spell, nil

Actor.getStance(actor)

Returns the current stance (whether a weapon/spell is readied), see the list of #STANCE values.

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#number:

Actor.getWalkSpeed(actor)

Speed of walking.

For dead actors it still returns a positive value.

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#number:

Actor.hasEquipped(actor, item)

Returns `true` if the item is equipped on the actor.

### Parameters

-
` openmw.core#GameObject actor `:

-
` openmw.core#GameObject item `:

### Return value

#boolean:

Actor.inventory(actor)

Actor inventory.

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

openmw.core#Inventory:

Actor.isDead(actor)

Check if the given actor is dead (health reached 0, so death process started).

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#boolean:

Actor.isDeathFinished(actor)

Check if the given actor's death process is finished.

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#boolean:

Actor.isInActorsProcessingRange(actor)

Check if given actor is in the actors processing range.

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#boolean:

Actor.isOnGround(actor)

Is the actor standing on ground.

Can be called only from a local script.

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#boolean:

Actor.isSwimming(actor)

Is the actor in water.

Can be called only from a local script.

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#boolean:

Actor.objectIsInstance(object)

Whether the object is an actor.

### Parameter

-
` openmw.core#GameObject object `:

### Return value

#boolean:

Actor.setBarterGold(actor, amount)

Set the actor's current barter gold.

Available in global and local scripts. Can only be used on self in local scripts.

### Parameters

-
` openmw.core#GameObject actor `:

-
` #number amount `:

Actor.setEquipment(actor, equipment)

Set equipment.

Keys in the table are equipment slots (see #EQUIPMENT_SLOT). Each
value can be either a `GameObject` or recordId. Raises an error if
the actor doesn't have equipment slots and table is not empty. Can be
used only in local scripts and only on self.

### Parameters

-
` openmw.core#GameObject actor `:

-
` #EquipmentTable equipment `:

### Usage

`local self = require('openmw.self')
local Actor = require('openmw.types').Actor
Actor.setEquipment(self, {}) -- unequip all`

Actor.setSelectedEnchantedItem(actor, item)

Set currently selected enchanted item, equipping it if applicable

### Parameters

-
` openmw.core#GameObject actor `:

-
` openmw.core#GameObject item `:
enchanted item

Actor.setSelectedSpell(actor, spell)

Set selected spell

### Parameters

-
` openmw.core#GameObject actor `:

-
` openmw.core#Spell spell `:
Spell (can be nil)

Actor.setStance(actor, stance)

Sets the current stance (whether a weapon/spell is readied), see the list of #STANCE values.

Can be used only in local scripts on self.

### Parameters

-
` openmw.core#GameObject actor `:

-
` #number stance `:

Actor.spells(actor)

Return the spells (#ActorSpells) of the given actor.

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#ActorSpells:

#ActorStats

Actor.stats

The actor's stats.

## Type `ActorActiveEffects`

Read-only list of effects currently affecting the actor.

### Usages

-

`-- print active effects
for _, effect in pairs(Actor.activeEffects(self)) do
print('Active Effect: '..effect.id..', attribute='..tostring(effect.affectedAttribute)..', skill='..tostring(effect.affectedSkill)..', magnitude='..tostring(effect.magnitude))
end`

-

`-- Check for a specific effect
local effect = Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.Telekinesis)
if effect.magnitude ~= 0 then
print(effect.id..', attribute='..tostring(effect.affectedAttribute)..', skill='..tostring(effect.affectedSkill)..', magnitude='..tostring(effect.magnitude))
else
print('No Telekinesis effect')
end`

-

`-- Check for a specific effect targeting a specific attribute.
local effect = Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.FortifyAttribute, 'luck')
if effect.magnitude ~= 0 then
print(effect.id..', attribute='..tostring(effect.affectedAttribute)..', skill='..tostring(effect.affectedSkill)..', magnitude='..tostring(effect.magnitude))
else
print('No Fortify Luck effect')
end`

### Field(s)

ActorActiveEffects:getEffect(effectId, extraParam)

Get a specific active effect on the actor.

### Parameters

-
` #string effectId `:
effect ID

-
` #string extraParam `:
Optional skill or attribute ID

### Return value

openmw.core#ActiveEffect:

ActorActiveEffects:modify(value, effectId, extraParam)

Permanently modifies the magnitude of an active effect by modifying it by the provided value.

Note that some active effect values, such as fortify attribute effects, have no practical effect of their own, and must be paired with explicitly modifying the target stat to have any effect.

### Parameters

-
` #number value `:

-
` #string effectId `:
effect ID

-
` #string extraParam `:
Optional skill or attribute ID

ActorActiveEffects:remove(effectId, extraParam)

Completely removes the active effect from the actor.

### Parameters

-
` #string effectId `:
effect ID

-
` #string extraParam `:
Optional skill or attribute ID

ActorActiveEffects:set(value, effectId, extraParam)

(Note that using this function will override and conflict with all other sources of this effect.

You probably want to use ActorActiveEffects.modify instead, this function is provided for mwscript parity only)
Permanently modifies the magnitude of an active effect to be exactly equal to the provided value.
Note that although the modification is permanent, the magnitude will not stay equal to the value if any active spells with this effects are added/removed.
Also see the notes on ActorActiveEffects.modify

### Parameters

-
` #number value `:

-
` #string effectId `:
effect ID

-
` #string extraParam `:
Optional skill or attribute ID

## Type `ActorActiveSpells`

Read-only list of spells currently affecting the actor.

Can be iterated over for a list of openmw.core#ActiveSpell

### Usages

-

`-- print active spells
for _, spell in pairs(Actor.activeSpells(self)) do
print('Active Spell: '..tostring(spell))
end`

-

`-- Check for a specific spell
if Actor.activeSpells(self):isSpellActive('bound longbow') then
print('Player has bound longbow')
else
print('Player does not have bound longbow')
end`

-

`-- Print all information about active spells
for id, params in pairs(Actor.activeSpells(self)) do
print('active spell '..tostring(id)..':')
print(' name: '..tostring(params.name))
print(' id: '..tostring(params.id))
print(' item: '..tostring(params.item))
print(' caster: '..tostring(params.caster))
print(' effects: '..tostring(params.effects))
for _, effect in pairs(params.effects) do
print(' -> effects['..tostring(effect)..']:')
print(' id: '..tostring(effect.id))
print(' name: '..tostring(effect.name))
print(' affectedSkill: '..tostring(effect.affectedSkill))
print(' affectedAttribute: '..tostring(effect.affectedAttribute))
print(' magnitudeThisFrame: '..tostring(effect.magnitudeThisFrame))
print(' minMagnitude: '..tostring(effect.minMagnitude))
print(' maxMagnitude: '..tostring(effect.maxMagnitude))
print(' duration: '..tostring(effect.duration))
print(' durationLeft: '..tostring(effect.durationLeft))
end
end`

### Field(s)

ActorActiveSpells:add(options)

Adds a new spell to the list of active spells (only in global scripts or on self).

Note that this does not play any related VFX or sounds.
Note that this should not be used to add spells without durations (i.e. abilities, curses, and diseases) as they will expire instantly. Use ActorSpells.add instead.

### Parameter

-
` #table options `:
A table of parameters. Must contain the following required parameters:

- `id` - A string record ID. Valid records are openmw.core#Spell, enchanted #Item, #IngredientRecord, or #PotionRecord.

- `effects` - A list of indexes of the effects to be applied. These indexes must be in range of the record's list of openmw.core#MagicEffectWithParams. Note that for Ingredients, normal ingredient consumption rules will be applied to effects.

And may contain the following optional parameters:

- `name` - The name to show in the list of active effects in the UI. Default: Name of the record identified by the id.

- `ignoreResistances` - If true, resistances will be ignored. Default: false

- `ignoreSpellAbsorption` - If true, spell absorption will not be applied. Default: false.

- `ignoreReflect` - If true, reflects will not be applied. Default: false.

- `caster` - A game object that identifies the caster. Default: nil

- `item` - A game object that identifies the specific enchanted item instance used to cast the spell. Default: nil

- `stackable` - If true, the spell will be able to stack. If false, existing instances of spells with the same id from the same source (where source is caster + item)

- `quiet` - If true, no messages will be printed if the spell is an Ingredient and it had no effect. Always true if the target is not the player.

### Usages

-

`-- Adds the effect of the chameleon spell to the character
Actor.activeSpells(self):add({id = 'chameleon', effects = { 0 }})`

-

`-- Adds the effect of a standard potion of intelligence, without consuming any potions from the character's inventory.
-- Note that stackable = true to let the effect stack like a potion should.
Actor.activeSpells(self):add({id = 'p_fortify_intelligence_s', effects = { 0 }, stackable = true})`

-

`-- Adds the negative effect of Greef twice over, and renames it to Good Greef.
Actor.activeSpells(self):add({id = 'potion_comberry_brandy_01', effects = { 1, 1 }, stackable = true, name = 'Good Greef'})`

-

`-- Has the same effect as if the actor ate a chokeweed. With the same variable effect based on skill / random chance.
Actor.activeSpells(self):add({id = 'ingred_chokeweed_01', effects = { 0 }, stackable = true, name = 'Chokeweed'})
-- Same as above, but uses a different index. Note that if multiple indexes are used, the randomicity is applied separately for each effect.
Actor.activeSpells(self):add({id = 'ingred_chokeweed_01', effects = { 1 }, stackable = true, name = 'Chokeweed'})`

ActorActiveSpells:isSpellActive(recordOrId)

Get whether any instance of the specific spell is active on the actor.

### Parameter

-
` #any recordOrId `:
A record or string record ID. Valid records are openmw.core#Spell, enchanted #Item, #IngredientRecord, or #PotionRecord.

### Return value

true if spell is active, false otherwise

ActorActiveSpells:remove(id)

Remove an active spell based on active spell ID (see openmw_core#ActiveSpell.activeSpellId).

Can only be used in global scripts or on self. Can only be used to remove spells with the temporary flag set (see openmw_core#ActiveSpell.temporary).

### Parameter

-
` #any id `:
Active spell ID.

## Type `ActorSpells`

List of spells (modifications are only allowed in global scripts or on self).

### Usages

-

`-- print available spells
local mySpells = types.Actor.spells(self)
for _, spell in pairs(mySpells) do print(spell.id) end`

-

`-- print available spells (equivalent)
local mySpells = types.Actor.spells(self)
for i = 1, #mySpells do print(mySpells[i].id) end`

-

`-- add ALL spells that exist in the world
local mySpells = types.Actor.spells(self)
for _, spell in pairs(core.magic.spells.records) do
if spell.type == core.magic.SPELL_TYPE.Spell then
mySpells:add(spell)
end
end`

-

`-- add specific spell
types.Actor.spells(self):add('thunder fist')`

-

`-- check specific spell
local mySpells = types.Actor.spells(self)
if mySpells['thunder fist'] then print('I have thunder fist') end`

### Field(s)

ActorSpells:add(spellOrId)

Add spell (only in global scripts or on self).

### Parameter

-
` #any spellOrId `:
openmw.core#Spell or string spell id

ActorSpells:canUsePower(spellOrId)

If true, the actor has not used this power in the last 24h.

Will return true for powers the actor does not have.

### Parameter

-
` #any spellOrId `:
A openmw.core#Spell or string record ID.

ActorSpells:clear()

Remove all spells (only in global scripts or on self).

ActorSpells:remove(spellOrId)

Remove spell (only in global scripts or on self).

### Parameter

-
` #any spellOrId `:
openmw.core#Spell or string spell id

## Type `ActorStats`

### Field(s)

#AIStats

ActorStats.ai

#AttributeStats

ActorStats.attributes

#DynamicStats

ActorStats.dynamic

ActorStats.level(actor)

Level (returns #LevelStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#LevelStat:

## Type `Apparatus`

### Extends #Item

### Field(s)

#ApparatusTYPE

Apparatus.TYPE

#ApparatusTYPE

#Item

Apparatus.baseType

#Item

Apparatus.objectIsInstance(object)

Whether the object is an Apparatus.

### Parameter

-
` openmw.core#GameObject object `:

### Return value

#boolean:

Apparatus.record(objectOrRecordId)

Returns the read-only #ApparatusRecord of an apparatus

### Parameter

-
` #any objectOrRecordId `:

### Return value

#ApparatusRecord:

#list<#ApparatusRecord>

Apparatus.records

A read-only list of all #ApparatusRecords in the world database.

Implements iterables#List of #ApparatusRecord.

### Usages

-

`local record = types.Apparatus.records['example_recordid']`

-

`local record = types.Apparatus.records[1]`

## Type `ApparatusRecord`

### Field(s)

#string

ApparatusRecord.icon

VFS path to the icon

#string

ApparatusRecord.id

The record ID of the apparatus

#string

ApparatusRecord.model

VFS path to the model

#string

ApparatusRecord.mwscript

MWScript on this apparatus (can be nil)

#string

ApparatusRecord.name

The name of the apparatus

#number

ApparatusRecord.quality

The quality of the apparatus

#number

ApparatusRecord.type

The type of apparatus. See Apparatus.TYPE

#number

ApparatusRecord.value

#number

ApparatusRecord.weight

## Type `ApparatusTYPE`

Apparatus.TYPE

### Field(s)

#number

ApparatusTYPE.Alembic

#number

ApparatusTYPE.Calcinator

#number

ApparatusTYPE.MortarPestle

#number

ApparatusTYPE.Retort

## Type `Armor`

### Extends #Item

### Field(s)

#ArmorTYPE

Armor.TYPE

#ArmorTYPE

#Item

Armor.baseType

#Item

Armor.createRecordDraft(armor)

Creates an #ArmorRecord without adding it to the world database, for the armor to appear correctly on the body, make sure to use a template as described below.

Use openmw_world#world.createRecord to add the record to the world.

### Parameter

-
` #ArmorRecord armor `:
A Lua table with the fields of an ArmorRecord, with an additional field `template` that accepts an #ArmorRecord as a base.

### Return value

#ArmorRecord:
A strongly typed Armor record.

### Usage

`local armorTemplate = types.Armor.record('orcish_cuirass')
local armorTable = {name = "Better Orcish Cuirass",template = armorTemplate,baseArmor = armorTemplate.baseArmor + 10}
--This is the new record we want to create, with a record provided as a template.
local recordDraft = types.Armor.createRecordDraft(armorTable)--Need to convert the table into the record draft
local newRecord = world.createRecord(recordDraft)--This creates the actual record
world.createObject(newRecord.id):moveInto(playerActor)--Create an instance of this object, and move it into the player's inventory`

Armor.objectIsInstance(object)

Whether the object is an Armor.

### Parameter

-
` openmw.core#GameObject object `:

### Return value

#boolean:

Armor.record(objectOrRecordId)

Returns the read-only #ArmorRecord of an Armor

### Parameter

-
` #any objectOrRecordId `:

### Return value

#ArmorRecord:

#list<#ArmorRecord>

Armor.records

A read-only list of all #ArmorRecords in the world database.

Implements iterables#List of #ArmorRecord.

### Usages

-

`local record = types.Armor.records['example_recordid']`

-

`local record = types.Armor.records[1]`

## Type `ArmorRecord`

### Field(s)

#number

ArmorRecord.baseArmor

The base armor rating of this armor

#string

ArmorRecord.enchant

The enchantment ID of this armor (can be nil)

#number

ArmorRecord.enchantCapacity

#number

ArmorRecord.health

#string

ArmorRecord.icon

VFS path to the icon

#string

ArmorRecord.id

Record id

#string

ArmorRecord.model

VFS path to the model

#string

ArmorRecord.mwscript

MWScript on this armor (can be nil)

#string

ArmorRecord.name

Human-readable name

#number

ArmorRecord.type

See Armor.TYPE

#number

ArmorRecord.value

#number

ArmorRecord.weight

## Type `ArmorTYPE`

Armor.TYPE

### Field(s)

#number

ArmorTYPE.Boots

#number

ArmorTYPE.Cuirass

#number

ArmorTYPE.Greaves

#number

ArmorTYPE.Helmet

#number

ArmorTYPE.LBracer

#number

ArmorTYPE.LGauntlet

#number

ArmorTYPE.LPauldron

#number

ArmorTYPE.RBracer

#number

ArmorTYPE.RGauntlet

#number

ArmorTYPE.RPauldron

#number

ArmorTYPE.Shield

## Type `AttributeStat`

Value modification is delayed

### Field(s)

#number

AttributeStat.base

The actor's base attribute value.

#number

AttributeStat.damage

The amount the attribute has been damaged.

#number

AttributeStat.modified

The actor's current attribute value (read-only.)

#number

AttributeStat.modifier

The attribute's modifier.

## Type `AttributeStats`

### Field(s)

AttributeStats.agility(actor)

Agility (returns #AttributeStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#AttributeStat:

AttributeStats.endurance(actor)

Endurance (returns #AttributeStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#AttributeStat:

AttributeStats.intelligence(actor)

Intelligence (returns #AttributeStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#AttributeStat:

AttributeStats.luck(actor)

Luck (returns #AttributeStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#AttributeStat:

AttributeStats.personality(actor)

Personality (returns #AttributeStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#AttributeStat:

AttributeStats.speed(actor)

Speed (returns #AttributeStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#AttributeStat:

AttributeStats.strength(actor)

Strength (returns #AttributeStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#AttributeStat:

AttributeStats.willpower(actor)

Willpower (returns #AttributeStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#AttributeStat:

## Type `BirthSignRecord`

Birth sign data record

### Field(s)

#string

BirthSignRecord.description

Birth sign description

#string

BirthSignRecord.id

Birth sign id

#string

BirthSignRecord.name

Birth sign name

#list<#string>

BirthSignRecord.spells

A read-only list containing the ids of all spells gained from this sign.

#string

BirthSignRecord.texture

Birth sign texture

## Type `BirthSigns`

### Field(s)

BirthSigns.record(recordId)

Returns a read-only #BirthSignRecord

### Parameter

-
` #string recordId `:

### Return value

#BirthSignRecord:

#list<#BirthSignRecord>

BirthSigns.records

A read-only list of all #BirthSignRecords in the world database.

Implements iterables#List of #BirthSignRecord.

### Usages

-

`local birthSign = types.Player.birthSigns.records['birthsign id'] -- get by id`

-

`local birthSign = types.Player.birthSigns.records[1] -- get by index`

## Type `Book`

### Extends #Item

### Field(s)

#BookSKILL

Book.SKILL

DEPRECATED, use openmw.core#Skill

#Item

Book.baseType

#Item

Book.createRecordDraft(book)

Creates a #BookRecord without adding it to the world database.

Use openmw_world#world.createRecord to add the record to the world.

### Parameter

-
` #BookRecord book `:
A Lua table with the fields of a BookRecord, with an optional field `template` that accepts a #BookRecord as a base.

### Return value

#BookRecord:
A strongly typed Book record.

Book.objectIsInstance(object)

Whether the object is a Book.

### Parameter

-
` openmw.core#GameObject object `:

### Return value

#boolean:

Book.record(objectOrRecordId)

Returns the read-only #BookRecord of a book

### Parameter

-
` #any objectOrRecordId `:

### Return value

#BookRecord:

#list<#BookRecord>

Book.records

A read-only list of all #BookRecords in the world database.

Implements iterables#List of #BookRecord.

### Usages

-

`local record = types.Book.records['example_recordid']`

-

`local record = types.Book.records[1]`

## Type `BookRecord`

### Field(s)

#string

BookRecord.enchant

The enchantment ID of this book (can be nil)

#number

BookRecord.enchantCapacity

#string

BookRecord.icon

VFS path to the icon

#string

BookRecord.id

The record ID of the book

#boolean

BookRecord.isScroll

#string

BookRecord.model

VFS path to the model

#string

BookRecord.mwscript

MWScript on this book (can be nil)

#string

BookRecord.name

Name of the book

#string

BookRecord.skill

The skill that this book teaches. See openmw.core#SKILL

#string

BookRecord.text

The text content of the book

#number

BookRecord.value

#number

BookRecord.weight

## Type `BookSKILL`

Book.SKILL

### Field(s)

#string

BookSKILL.acrobatics

"acrobatics"

#string

BookSKILL.alchemy

"alchemy"

#string

BookSKILL.alteration

"alteration"

#string

BookSKILL.armorer

"armorer"

#string

BookSKILL.athletics

"athletics"

#string

BookSKILL.axe

"axe"

#string

BookSKILL.block

"block"

#string

BookSKILL.bluntWeapon

"bluntweapon"

#string

BookSKILL.conjuration

"conjuration"

#string

BookSKILL.destruction

"destruction"

#string

BookSKILL.enchant

"enchant"

#string

BookSKILL.handToHand

"handtohand"

#string

BookSKILL.heavyArmor

"heavyarmor"

#string

BookSKILL.illusion

"illusion"

#string

BookSKILL.lightArmor

"lightarmor"

#string

BookSKILL.longBlade

"longblade"

#string

BookSKILL.marksman

"marksman"

#string

BookSKILL.mediumArmor

"mediumarmor"

#string

BookSKILL.mercantile

"mercantile"

#string

BookSKILL.mysticism

"mysticism"

#string

BookSKILL.restoration

"restoration"

#string

BookSKILL.security

"security"

#string

BookSKILL.shortBlade

"shortblade"

#string

BookSKILL.sneak

"sneak"

#string

BookSKILL.spear

"spear"

#string

BookSKILL.speechcraft

"speechcraft"

#string

BookSKILL.unarmored

"unarmored"

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

Vanity view if player doesn't touch controls for a long time

#ControlSwitch

CONTROL_SWITCH.ViewMode

Ability to toggle 1st/3rd person view

## Type `ClassRecord`

Class data record

### Field(s)

#list<#string>

ClassRecord.attributes

A read-only list containing the specialized attributes of the class.

#string

ClassRecord.description

Class description

#string

ClassRecord.id

Class id

#boolean

ClassRecord.isPlayable

True if the player can play as this class

#list<#string>

ClassRecord.majorSkills

A read-only list containing the major skills of the class.

#list<#string>

ClassRecord.minorSkills

A read-only list containing the minor skills of the class.

#string

ClassRecord.name

Class name

#string

ClassRecord.specialization

Class specialization. Either combat, magic, or stealth.

## Type `Classes`

### Field(s)

Classes.record(recordId)

Returns a read-only #ClassRecord

### Parameter

-
` #string recordId `:

### Return value

#ClassRecord:

#list<#ClassRecord>

Classes.records

A read-only list of all #ClassRecords in the world database, may be indexed by recordId.

Implements iterables#List of #ClassRecord.

### Usages

-

`local class = types.NPC.classes.records['class id'] -- get by id`

-

`local class = types.NPC.classes.records[1] -- get by index`

## Type `Clothing`

### Extends #Item

### Field(s)

#ClothingTYPE

Clothing.TYPE

#ClothingTYPE

#Item

Clothing.baseType

#Item

Clothing.createRecordDraft(clothing)

Creates a #ClothingRecord without adding it to the world database, for the clothing to appear correctly on the body, make sure to use a template as described below.

Use openmw_world#world.createRecord to add the record to the world.

### Parameter

-
` #ClothingRecord clothing `:
A Lua table with the fields of a ClothingRecord, with an additional field `template` that accepts a #ClothingRecord as a base.

### Return value

#ClothingRecord:
A strongly typed clothing record.

### Usage

`local clothingTemplate = types.Clothing.record('exquisite_robe_01')
local clothingTable = {name = "Better Exquisite Robe",template = clothingTemplate,enchantCapacity = clothingTemplate.enchantCapacity + 10}
--This is the new record we want to create, with a record provided as a template.
local recordDraft = types.Clothing.createRecordDraft(clothingTable)--Need to convert the table into the record draft
local newRecord = world.createRecord(recordDraft)--This creates the actual record
world.createObject(newRecord.id):moveInto(playerActor)--Create an instance of this object, and move it into the player's inventory`

Clothing.objectIsInstance(object)

Whether the object is a Clothing.

### Parameter

-
` openmw.core#GameObject object `:

### Return value

#boolean:

Clothing.record(objectOrRecordId)

Returns the read-only #ClothingRecord of a Clothing

### Parameter

-
` #any objectOrRecordId `:

### Return value

#ClothingRecord:

#list<#ClothingRecord>

Clothing.records

A read-only list of all #ClothingRecords in the world database.

Implements iterables#List of #ClothingRecord.

### Usages

-

`local record = types.Clothing.records['example_recordid']`

-

`local record = types.Clothing.records[1]`

## Type `ClothingRecord`

### Field(s)

#string

ClothingRecord.enchant

The enchantment ID of this clothing (can be nil)

#number

ClothingRecord.enchantCapacity

#string

ClothingRecord.icon

VFS path to the icon

#string

ClothingRecord.id

Record id

#string

ClothingRecord.model

VFS path to the model

#string

ClothingRecord.mwscript

MWScript on this clothing (can be nil)

#string

ClothingRecord.name

Name of the clothing

#number

ClothingRecord.type

See Clothing.TYPE

#number

ClothingRecord.value

#number

ClothingRecord.weight

## Type `ClothingTYPE`

Clothing.TYPE

### Field(s)

#number

ClothingTYPE.Amulet

#number

ClothingTYPE.Belt

#number

ClothingTYPE.LGlove

#number

ClothingTYPE.Pants

#number

ClothingTYPE.RGlove

#number

ClothingTYPE.Ring

#number

ClothingTYPE.Robe

#number

ClothingTYPE.Shirt

#number

ClothingTYPE.Shoes

#number

ClothingTYPE.Skirt

## Type `Container`

### Extends #LOCKABLE

### Field(s)

#LOCKABLE

Container.baseType

#LOCKABLE

Container.content(object)

Container content.

### Parameter

-
` openmw.core#GameObject object `:

### Return value

openmw.core#Inventory:

Container.createRecordDraft(container)

Creates a #ContainerRecord without adding it to the world database.

Use openmw_world#world.createRecord to add the record to the world.

### Parameter

-
` #ContainerRecord container `:
A Lua table with the fields of a ContainerRecord, with an additional field `template` that accepts a #ContainerRecord as a base.

### Return value

#ContainerRecord:
A strongly typed Container record.

### Usage

`local chestTemplate = types.Container.records['chest_small_01']
local containerTable = {name = "Respawning Treasure Chest", template = chestTemplate, isRespawning = true, weight = 150.0}
local recordDraft = types.Container.createRecordDraft(containerTable)
local newRecord = world.createRecord(recordDraft)
world.createObject(newRecord.id):teleport(playerCell, playerPosition)`

Container.getCapacity(object)

Returns the capacity of a container

### Parameter

-
` openmw.core#GameObject object `:

### Return value

#number:

Container.getEncumbrance(object)

Returns the total weight of everything in a container

### Parameter

-
` openmw.core#GameObject object `:

### Return value

#number:

Container.inventory(object)

Container content (same as `Container.content`, added for consistency with `Actor.inventory`).

### Parameter

-
` openmw.core#GameObject object `:

### Return value

openmw.core#Inventory:

Container.objectIsInstance(object)

Whether the object is a Container.

### Parameter

-
` openmw.core#GameObject object `:

### Return value

#boolean:

Container.record(objectOrRecordId)

Returns the read-only #ContainerRecord of a container

### Parameter

-
` #any objectOrRecordId `:

### Return value

#ContainerRecord:

#list<#ContainerRecord>

Container.records

A read-only list of all #ContainerRecords in the world database.

Implements iterables#List of #ContainerRecord.

### Usages

-

`local record = types.Container.records['example_recordid']`

-

`local record = types.Container.records[1]`

## Type `ContainerRecord`

### Field(s)

#string

ContainerRecord.id

Record id

#boolean

ContainerRecord.isOrganic

Whether items can be placed in the container

#boolean

ContainerRecord.isRespawning

Whether the container respawns its contents

#string

ContainerRecord.model

VFS path to the model

#string

ContainerRecord.mwscript

MWScript on this container (can be nil)

#string

ContainerRecord.name

Human-readable name

#number

ContainerRecord.weight

capacity of this container

## Type `ControlSwitch`

String id of a #CONTROL_SWITCH

## Type `Creature`

### Extends #Actor

### Field(s)

#CreatureTYPE

Creature.TYPE

#CreatureTYPE

#Actor

Creature.baseType

#Actor

Creature.createRecordDraft(creature)

Creates a #CreatureRecord without adding it to the world database.

Use openmw_world#world.createRecord to add the record to the world.

### Parameter

-
` #CreatureRecord creature `:
A Lua table with the fields of a CreatureRecord, with an additional field `template` that accepts a #CreatureRecord as a base.

### Return value

#CreatureRecord:
A strongly typed Creature record.

### Usage

`local creatureTemplate = types.Creature.records['mudcrab']
local creatureTable = {name = "Epic Mudcrab", template = creatureTemplate, soulValue = 500, isEssential = true}
local recordDraft = types.Creature.createRecordDraft(creatureTable)
local newRecord = world.createRecord(recordDraft)
world.createObject(newRecord.id):teleport(playerCell, playerPosition)`

Creature.objectIsInstance(object)

Whether the object is a creature.

### Parameter

-
` openmw.core#GameObject object `:

### Return value

#boolean:

Creature.record(objectOrRecordId)

Returns the read-only #CreatureRecord of a creature

### Parameter

-
` #any objectOrRecordId `:

### Return value

#CreatureRecord:

#list<#CreatureRecord>

Creature.records

A read-only list of all #CreatureRecords in the world database, may be indexed by recordId.

Implements iterables#List of #CreatureRecord.

### Usages

-

`local creature = types.Creature.records['creature id'] -- get by id`

-

`local creature = types.Creature.records[1] -- get by index`

## Type `CreatureAttack`

### Field(s)

#number

CreatureAttack.maxDamage

Maximum attack damage.

#number

CreatureAttack.minDamage

Minimum attack damage.

## Type `CreatureLevelledList`

### Field(s)

CreatureLevelledList.objectIsInstance(object)

Whether the object is a CreatureLevelledList.

### Parameter

-
` openmw.core#GameObject object `:

### Return value

#boolean:

CreatureLevelledList.record(objectOrRecordId)

Returns the read-only #CreatureLevelledListRecord of a levelled creature

### Parameter

-
` #any objectOrRecordId `:

### Return value

#CreatureLevelledListRecord:

#list<#CreatureLevelledListRecord>

CreatureLevelledList.records

A read-only list of all #CreatureLevelledListRecords in the world database.

Implements iterables#List of #CreatureLevelledListRecord.

### Usages

-

`local record = types.CreatureLevelledList.records['example_recordid']`

-

`local record = types.CreatureLevelledList.records[1]`

## Type `CreatureLevelledListRecord`

### Field(s)

#boolean

CreatureLevelledListRecord.calculateFromAllLevels

Calculate from all levels <= player level, not just the closest below player

#number

CreatureLevelledListRecord.chanceNone

Chance this list won't spawn anything [0-1]

#list<#LevelledListItem>

CreatureLevelledListRecord.creatures

CreatureLevelledListRecord.getRandomId(listRecord, MaxLvl)

Picks a random id from the levelled list.

### Parameters

-
` openmw.core#CreatureLevelledListRecord listRecord `:
The list

-
` #number MaxLvl `:
The maximum level to select entries for

### Return value

#string:
An id

#string

CreatureLevelledListRecord.id

Record id

## Type `CreatureRecord`

### Field(s)

#list<#number>

CreatureRecord.attack

A table of the 3 randomly selected attacks used by creatures that do not carry weapons. The table consists of 6 numbers split into groups of 2 values corresponding to minimum and maximum damage in that order.

#string

CreatureRecord.baseCreature

Record id of a base creature, which was modified to create this one

#number

CreatureRecord.baseGold

The base barter gold of the creature

#number

CreatureRecord.bloodType

integer representing the blood type of the Creature. Used to generate the correct blood vfx.

#boolean

CreatureRecord.canFly

whether the creature can fly

#boolean

CreatureRecord.canSwim

whether the creature can swim

#boolean

CreatureRecord.canUseWeapons

whether the creature can use weapons and shields

#boolean

CreatureRecord.canWalk

whether the creature can walk

#number

CreatureRecord.combatSkill

The base combat skill of the creature. This is the skill value used for all skills with a 'combat' specialization

#string

CreatureRecord.id

The record ID of the creature

#boolean

CreatureRecord.isAutocalc

If true, the actor's stats will be automatically calculated based on level and class.

#boolean

CreatureRecord.isBiped

whether the creature is a biped

#boolean

CreatureRecord.isEssential

whether the creature is essential

#boolean

CreatureRecord.isRespawning

whether the creature respawns after death

#number

CreatureRecord.magicSkill

The base magic skill of the creature. This is the skill value used for all skills with a 'magic' specialization

#string

CreatureRecord.model

VFS path to the creature's model

#string

CreatureRecord.mwscript

MWScript on this creature (can be nil)

#string

CreatureRecord.name

#string

CreatureRecord.primaryFaction

Faction ID of the NPCs default faction. Nil if no faction

#number

CreatureRecord.primaryFactionRank

Faction rank of the NPCs default faction. Nil if no faction

#map<#string,#boolean>

CreatureRecord.servicesOffered

The services of the creature, in a table. Value is if the service is provided or not, and they are indexed by: Spells, Spellmaking, Enchanting, Training, Repair, Barter, Weapon, Armor, Clothing, Books, Ingredients, Picks, Probes, Lights, Apparatus, RepairItems, Misc, Potions, MagicItems, Travel.

#number

CreatureRecord.soulValue

The soul value of the creature record

#number

CreatureRecord.stealthSkill

The base stealth skill of the creature. This is the skill value used for all skills with a 'stealth' specialization

#list<#TravelDestination>

CreatureRecord.travelDestinations

A list of #TravelDestinations for this creature.

#number

CreatureRecord.type

The Creature.TYPE of the creature

## Type `CreatureTYPE`

Creature.TYPE

### Field(s)

#number

CreatureTYPE.Creatures

#number

CreatureTYPE.Daedra

#number

CreatureTYPE.Humanoid

#number

CreatureTYPE.Undead

## Type `Door`

### Extends #LOCKABLE

### Field(s)

#DoorSTATE

Door.STATE

#DoorSTATE

### Usage

`local state = types.Door.STATE["Idle"]`

Door.activateDoor(object, openState)

Opens/Closes the door.

Can only be used in global scripts or on self.

### Parameters

-
` openmw.core#GameObject object `:

-
` #boolean openState `:
Optional whether the door should be opened or closed. If not provided, the door will switch to the opposite state.

### Usages

-

`types.Door.activateDoor(doorObject)`

-

`types.Door.activateDoor(doorObject, true)`

-

`types.Door.activateDoor(doorObject, false)`

#LOCKABLE

Door.baseType

#LOCKABLE

Door.createRecordDraft(door)

Creates a #DoorRecord without adding it to the world database.

Use openmw_world#world.createRecord to add the record to the world.

### Parameter

-
` #DoorRecord door `:
A Lua table with the fields of a DoorRecord, with an optional field `template` that accepts a #DoorRecord as a base.

### Return value

#DoorRecord:
A strongly typed Door record.

Door.destCell(object)

Destination cell (only if a teleport door).

### Parameter

-
` openmw.core#GameObject object `:

### Return value

openmw.core#Cell:

Door.destPosition(object)

Destination (only if a teleport door).

### Parameter

-
` openmw.core#GameObject object `:

### Return value

openmw.util#Vector3:

Door.destRotation(object)

Destination rotation (only if a teleport door).

### Parameter

-
` openmw.core#GameObject object `:

### Return value

openmw.util#Transform:

Door.getDoorState(object)

Gets the state of the door.

### Parameter

-
` openmw.core#GameObject object `:

### Return value

#DoorSTATE:

Door.isClosed(object)

Checks if the door is fully closed.

Returns false if the door is currently opening or closing.

### Parameter

-
` openmw.core#GameObject object `:

### Return value

#boolean:

Door.isOpen(object)

Checks if the door is fully open.

Returns false if the door is currently opening or closing.

### Parameter

-
` openmw.core#GameObject object `:

### Return value

#boolean:

Door.isTeleport(object)

Whether the door is a teleport.

### Parameter

-
` openmw.core#GameObject object `:

### Return value

#boolean:

Door.objectIsInstance(object)

Whether the object is a Door.

### Parameter

-
` openmw.core#GameObject object `:

### Return value

#boolean:

Door.record(objectOrRecordId)

Returns the read-only #DoorRecord of a door

### Parameter

-
` #any objectOrRecordId `:

### Return value

#DoorRecord:

#list<#DoorRecord>

Door.records

A read-only list of all #DoorRecords in the world database.

Implements iterables#List of #DoorRecord.

### Usages

-

`local record = types.Door.records['example_recordid']`

-

`local record = types.Door.records[1]`

## Type `DoorRecord`

### Field(s)

#string

DoorRecord.closeSound

The sound id for door closing

#string

DoorRecord.id

Record id

#string

DoorRecord.model

VFS path to the model

#string

DoorRecord.mwscript

MWScript on this door (can be nil)

#string

DoorRecord.name

Human-readable name

#string

DoorRecord.openSound

The sound id for door opening

## Type `DoorSTATE`

Door.STATE

### Field(s)

#number

DoorSTATE.Closing

The door is in the process of closing.

#number

DoorSTATE.Idle

The door is either closed or open (usually closed).

#number

DoorSTATE.Opening

The door is in the process of opening.

## Type `DynamicStat`

Value modification is delayed

### Field(s)

#number

DynamicStat.base

#number

DynamicStat.current

#number

DynamicStat.modifier

## Type `DynamicStats`

### Field(s)

DynamicStats.fatigue(actor)

Fatigue (returns #DynamicStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#DynamicStat:

DynamicStats.health(actor)

Health (returns #DynamicStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#DynamicStat:

DynamicStats.magicka(actor)

Magicka (returns #DynamicStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#DynamicStat:

## Type `EQUIPMENT_SLOT`

### Field(s)

#number

EQUIPMENT_SLOT.Ammunition

#number

EQUIPMENT_SLOT.Amulet

#number

EQUIPMENT_SLOT.Belt

#number

EQUIPMENT_SLOT.Boots

#number

EQUIPMENT_SLOT.CarriedLeft

#number

EQUIPMENT_SLOT.CarriedRight

#number

EQUIPMENT_SLOT.Cuirass

#number

EQUIPMENT_SLOT.Greaves

#number

EQUIPMENT_SLOT.Helmet

#number

EQUIPMENT_SLOT.LeftGauntlet

#number

EQUIPMENT_SLOT.LeftPauldron

#number

EQUIPMENT_SLOT.LeftRing

#number

EQUIPMENT_SLOT.Pants

#number

EQUIPMENT_SLOT.RightGauntlet

#number

EQUIPMENT_SLOT.RightPauldron

#number

EQUIPMENT_SLOT.RightRing

#number

EQUIPMENT_SLOT.Robe

#number

EQUIPMENT_SLOT.Shirt

#number

EQUIPMENT_SLOT.Skirt

## Type `ESM4Activator`

## Type `ESM4Ammunition`

## Type `ESM4Armor`

## Type `ESM4Book`

## Type `ESM4Clothing`

## Type `ESM4Door`

### Extends #LOCKABLE

### Field(s)

#LOCKABLE

ESM4Door.baseType

#LOCKABLE

ESM4Door.destCell(object)

Destination cell (only if a teleport door).

### Parameter

-
` openmw.core#GameObject object `:

### Return value

openmw.core#Cell:

ESM4Door.destPosition(object)

Destination (only if a teleport door).

### Parameter

-
` openmw.core#GameObject object `:

### Return value

openmw.util#Vector3:

ESM4Door.destRotation(object)

Destination rotation (only if a teleport door).

### Parameter

-
` openmw.core#GameObject object `:

### Return value

openmw.util#Transform:

ESM4Door.isTeleport(object)

Whether the door is a teleport.

### Parameter

-
` openmw.core#GameObject object `:

### Return value

#boolean:

ESM4Door.objectIsInstance(object)

Whether the object is a ESM4Door.

### Parameter

-
` openmw.core#GameObject object `:

### Return value

#boolean:

ESM4Door.record(objectOrRecordId)

Returns the read-only #ESM4DoorRecord of a door

### Parameter

-
` #any objectOrRecordId `:

### Return value

#ESM4DoorRecord:

#list<#ESM4DoorRecord>

ESM4Door.records

A read-only list of all #ESM4DoorRecords in the world database.

Implements iterables#List of #ESM4DoorRecord.

### Usages

-

`local record = types.ESM4Door.records['example_recordid']`

-

`local record = types.ESM4Door.records[1]`

## Type `ESM4DoorRecord`

### Field(s)

#string

ESM4DoorRecord.closeSound

FormId of the door closing sound

#string

ESM4DoorRecord.id

Record id

#string

ESM4DoorRecord.model

VFS path to the model

#string

ESM4DoorRecord.name

Human-readable name

#string

ESM4DoorRecord.openSound

FormId of the door opening sound

## Type `ESM4Flora`

## Type `ESM4Ingredient`

## Type `ESM4ItemMod`

## Type `ESM4Light`

## Type `ESM4Miscellaneous`

## Type `ESM4MovableStatic`

## Type `ESM4Potion`

## Type `ESM4Static`

## Type `ESM4StaticCollection`

## Type `ESM4Terminal`

### Field(s)

ESM4Terminal.objectIsInstance(object)

Whether the object is a ESM4Terminal.

### Parameter

-
` openmw.core#GameObject object `:

### Return value

#boolean:

ESM4Terminal.record(objectOrRecordId)

Returns the read-only #ESM4TerminalRecord of a terminal

### Parameter

-
` #any objectOrRecordId `:

### Return value

#ESM4TerminalRecord:

#list<#ESM4TerminalRecord>

ESM4Terminal.records

A read-only list of all #ESM4TerminalRecords in the world database.

Implements iterables#List of #ESM4TerminalRecord.

### Usages

-

`local record = types.ESM4Terminal.records['example_recordid']`

-

`local record = types.ESM4Terminal.records[1]`

## Type `ESM4TerminalRecord`

### Field(s)

#string

ESM4TerminalRecord.editorId

Human-readable ID

#string

ESM4TerminalRecord.id

Record id (Form ID)

#string

ESM4TerminalRecord.model

VFS path to the model

#string

ESM4TerminalRecord.name

Human-readable name

#string

ESM4TerminalRecord.resultText

Result text of the terminal record

#string

ESM4TerminalRecord.text

Text body of the terminal record

## Type `ESM4Weapon`

## Type `EquipmentTable`

Map from values of #EQUIPMENT_SLOT to items openmw.core#GameObjects

` EquipmentTable ` is a map of ` #number ` to ` openmw.core#GameObject `.

## Type `GenderedNumber`

### Field(s)

#number

GenderedNumber.female

Female value

#number

GenderedNumber.male

Male value

## Type `Ingredient`

### Extends #Item

### Field(s)

#Item

Ingredient.baseType

#Item

Ingredient.objectIsInstance(object)

Whether the object is an Ingredient.

### Parameter

-
` openmw.core#GameObject object `:

### Return value

#boolean:

Ingredient.record(objectOrRecordId)

Returns the read-only #IngredientRecord of a Ingredient

### Parameter

-
` #any objectOrRecordId `:

### Return value

#IngredientRecord:

#list<#IngredientRecord>

Ingredient.records

A read-only list of all #IngredientRecords in the world database.

Implements iterables#List of #IngredientRecord.

### Usages

-

`local record = types.Ingredient.records['example_recordid']`

-

`local record = types.Ingredient.records[1]`

## Type `IngredientRecord`

### Field(s)

#list<openmw.core#MagicEffectWithParams>

IngredientRecord.effects

The effects (openmw.core#MagicEffectWithParams) of the ingredient

#string

IngredientRecord.icon

VFS path to the icon

#string

IngredientRecord.id

Record id

#string

IngredientRecord.model

VFS path to the model

#string

IngredientRecord.mwscript

MWScript on this potion (can be nil)

#string

IngredientRecord.name

Human-readable name

#number

IngredientRecord.value

#number

IngredientRecord.weight

## Type `Item`

Functions for items that can be placed to an inventory or container

### Field(s)

Item.getEnchantmentCharge(item)

(DEPRECATED, use itemData(item).enchantmentCharge) Get this item's current enchantment charge.

### Parameter

-
` openmw.core#GameObject item `:

### Return value

#number:
The charge remaining. `nil` if the enchantment has never been used, implying the charge is full. Unenchanted items will always return a value of `nil`.

Item.isCarriable(object)

Whether the object is supposed to be carriable.

It is true for all items except
lights without the Carry flag. Non-carriable lights can still be put into
an inventory with an explicit `object:moveInto` call.

### Parameter

-
` openmw.core#GameObject object `:

### Return value

#boolean:

Item.isRestocking(item)

Checks if the item restocks.

Returns true if the object restocks, and false otherwise.

### Parameter

-
` openmw.core#GameObject item `:

### Return value

#boolean:

Item.itemData(item)

Set of properties that differentiates one item from another of the same record type; can be used by any script, but only global and self scripts can change values.

### Parameter

-
` openmw.core#GameObject item `:

### Return value

#ItemData:

Item.objectIsInstance(object)

Whether the object is an item.

### Parameter

-
` openmw.core#GameObject object `:

### Return value

#boolean:

Item.setEnchantmentCharge(item, charge)

(DEPRECATED, use itemData(item).enchantmentCharge) Set this item's enchantment charge.

### Parameters

-
` openmw.core#GameObject item `:

-
` #number charge `:
Can be `nil` to reset the unused state / full

## Type `ItemData`

### Field(s)

#number

ItemData.condition

The item's current condition. Time remaining for lights (setting this to `-1` will make it last forever). Uses left for repairs, lockpicks and probes. Current health for weapons and armor.

#number

ItemData.enchantmentCharge

The item's current enchantment charge. Unenchanted items will always return a value of `nil`. Setting this to `nil` will reset the charge of the item.

#string

ItemData.soul

The recordId of the item's current soul. Items without soul will always return a value of `nil`. Setting this to `nil` will remove the soul from the item.

## Type `LOCKABLE`

### Field(s)

LOCKABLE.getKeyRecord(object)

Returns the key record of a lockable object(door, container)

### Parameter

-
` openmw.core#GameObject object `:

### Return value

#MiscellaneousRecord:

LOCKABLE.getLockLevel(object)

Returns the lock level of a lockable object(door, container).

Does not determine if an object is locked or not, if an object is locked while this is set above 0, this value will be used if no other value is specified.

### Parameter

-
` openmw.core#GameObject object `:

### Return value

#number:

LOCKABLE.getTrapSpell(object)

Returns the trap spell of a lockable object(door, container)

### Parameter

-
` openmw.core#GameObject object `:

### Return value

openmw.core#Spell:

LOCKABLE.isLocked(object)

Returns true if the lockable object is locked, and false if it is not.

### Parameter

-
` openmw.core#GameObject object `:

### Return value

#boolean:

LOCKABLE.lock(object, lockLevel)

Sets the lock level level of a lockable object(door, container);Locks if not already locked; Must be used in a global script.

### Parameters

-
` openmw.core#GameObject object `:

-
` #number lockLevel `:
Level to lock the object at. Optional, if not specified, then 1 will be used, or the previous level if it was locked before.

LOCKABLE.objectIsInstance(object)

Whether the object is a Lockable.

### Parameter

-
` openmw.core#GameObject object `:

### Return value

#boolean:

LOCKABLE.setKeyRecord(object, miscOrId)

Sets the key of a lockable object(door, container); removes it if empty string is provided.

Must be used in a global script.

### Parameters

-
` openmw.core#GameObject object `:

-
` #any miscOrId `:
#MiscellaneousRecord or string misc item id Record ID of the key to use.

LOCKABLE.setTrapSpell(object, spellOrId)

Sets the trap spell of a lockable object(door, container); removes it if empty string is provided.

Must be used in a global script.

### Parameters

-
` openmw.core#GameObject object `:

-
` #any spellOrId `:
openmw.core#Spell or string spell id Record ID for the trap to use

LOCKABLE.unlock(object)

Unlocks the lockable object.

Does not change the lock level, it can be kept for future use.

### Parameter

-
` openmw.core#GameObject object `:

## Type `LevelStat`

Value modification is delayed

### Field(s)

#number

LevelStat.current

The actor's current level.

#number

LevelStat.progress

The NPC's level progress.

#SkillIncreasesForAttributeStats

LevelStat.skillIncreasesForAttribute

The NPC's attribute contributions towards the next level up. Values affect how much each attribute can be increased at level up.

#SkillIncreasesForSpecializationStats

LevelStat.skillIncreasesForSpecialization

The NPC's attribute contributions towards the next level up. Values affect the graphic used on the level up screen.

## Type `LevelledListItem`

### Field(s)

#string

LevelledListItem.id

Item id

#number

LevelledListItem.level

The minimum player level at which this item can occur

## Type `Light`

### Extends #Item

### Field(s)

#Item

Light.baseType

#Item

Light.createRecordDraft(light)

Creates a #LightRecord without adding it to the world database.

Use openmw_world#world.createRecord to add the record to the world.

### Parameter

-
` #LightRecord light `:
A Lua table with the fields of a LightRecord, with an optional field `template` that accepts a #LightRecord as a base.

### Return value

#LightRecord:
A strongly typed Light record.

Light.objectIsInstance(object)

Whether the object is a Light.

### Parameter

-
` openmw.core#GameObject object `:

### Return value

#boolean:

Light.record(objectOrRecordId)

Returns the read-only #LightRecord of a Light

### Parameter

-
` #any objectOrRecordId `:

### Return value

#LightRecord:

#list<#LightRecord>

Light.records

A read-only list of all #LightRecords in the world database.

Implements iterables#List of #LightRecord.

### Usages

-

`local record = types.Light.records['example_recordid']`

-

`local record = types.Light.records[1]`

## Type `LightRecord`

### Field(s)

openmw.util#Color

LightRecord.color

#number

LightRecord.duration

#string

LightRecord.icon

VFS path to the icon

#string

LightRecord.id

Record id

#boolean

LightRecord.isCarriable

True if the light can be carried by actors and appears up in their inventory.

#boolean

LightRecord.isDynamic

If true, the light will apply to actors and other moving objects

#boolean

LightRecord.isFire

True if the light acts like a fire.

#boolean

LightRecord.isFlicker

#boolean

LightRecord.isFlickerSlow

#boolean

LightRecord.isNegative

If true, the light will reduce light instead of increasing it.

#boolean

LightRecord.isOffByDefault

If true, the light will not emit any light or sound while placed in the world. It will still work in the inventory.

#boolean

LightRecord.isPulse

#boolean

LightRecord.isPulseSlow

#string

LightRecord.model

VFS path to the model

#string

LightRecord.mwscript

MWScript on this light (can be nil)

#string

LightRecord.name

Human-readable name

#number

LightRecord.radius

#string

LightRecord.sound

VFS path to the sound

#number

LightRecord.value

#number

LightRecord.weight

## Type `Lockpick`

### Extends #Item

### Field(s)

#Item

Lockpick.baseType

#Item

Lockpick.objectIsInstance(object)

Whether the object is a Lockpick.

### Parameter

-
` openmw.core#GameObject object `:

### Return value

#boolean:

Lockpick.record(objectOrRecordId)

Returns the read-only #LockpickRecord of a lockpick

### Parameter

-
` #any objectOrRecordId `:

### Return value

#LockpickRecord:

#list<#LockpickRecord>

Lockpick.records

A read-only list of all #LockpickRecords in the world database.

Implements iterables#List of #LockpickRecord.

### Usages

-

`local record = types.Lockpick.records['example_recordid']`

-

`local record = types.Lockpick.records[1]`

## Type `LockpickRecord`

### Field(s)

#string

LockpickRecord.icon

VFS path to the icon

#string

LockpickRecord.id

The record ID of the lockpick

#number

LockpickRecord.maxCondition

The maximum number of uses of this lockpick

#string

LockpickRecord.model

VFS path to the model

#string

LockpickRecord.mwscript

MWScript on this lockpick (can be nil)

#string

LockpickRecord.name

The name of the lockpick

#number

LockpickRecord.quality

The quality of the lockpick

#number

LockpickRecord.value

#number

LockpickRecord.weight

## Type `Miscellaneous`

### Extends #Item

### Field(s)

#Item

Miscellaneous.baseType

#Item

Miscellaneous.createRecordDraft(miscellaneous)

Creates a #MiscellaneousRecord without adding it to the world database.

Use openmw_world#world.createRecord to add the record to the world.

### Parameter

-
` #MiscellaneousRecord miscellaneous `:
A Lua table with the fields of a MiscellaneousRecord, with an optional field `template` that accepts a #MiscellaneousRecord as a base.

### Return value

#MiscellaneousRecord:
A strongly typed Miscellaneous record.

Miscellaneous.getSoul(object)

(DEPRECATED, use itemData(item).soul) Returns the read-only soul of a miscellaneous item

### Parameter

-
` openmw.core#GameObject object `:

### Return value

#string:

Miscellaneous.objectIsInstance(object)

Whether the object is a Miscellaneous.

### Parameter

-
` openmw.core#GameObject object `:

### Return value

#boolean:

Miscellaneous.record(objectOrRecordId)

Returns the read-only #MiscellaneousRecord of a miscellaneous item

### Parameter

-
` #any objectOrRecordId `:

### Return value

#MiscellaneousRecord:

#list<#MiscellaneousRecord>

Miscellaneous.records

A read-only list of all #MiscellaneousRecords in the world database.

Implements iterables#List of #MiscellaneousRecord.

### Usages

-

`local record = types.Miscellaneous.records['example_recordid']`

-

`local record = types.Miscellaneous.records[1]`

Miscellaneous.setSoul(object, soulId)

(DEPRECATED, use itemData(item).soul) Sets the soul of a miscellaneous item, intended for soul gem objects; Must be used in a global script.

### Parameters

-
` openmw.core#GameObject object `:

-
` #string soulId `:
Record ID for the soul of the creature to use

## Type `MiscellaneousRecord`

### Field(s)

#string

MiscellaneousRecord.icon

VFS path to the icon

#string

MiscellaneousRecord.id

The record ID of the miscellaneous item

#boolean

MiscellaneousRecord.isKey

#string

MiscellaneousRecord.model

VFS path to the model

#string

MiscellaneousRecord.mwscript

MWScript on this miscellaneous item (can be nil)

#string

MiscellaneousRecord.name

The name of the miscellaneous item

#number

MiscellaneousRecord.value

#number

MiscellaneousRecord.weight

## Type `NPC`

### Extends #Actor

### Field(s)

#Actor

NPC.baseType

#Actor

#Classes

NPC.classes

#Classes: Class Data

NPC.clearExpelled(actor, faction)

Clear expelling of NPC from given faction.

Throws an exception if there is no such faction.

### Parameters

-
` openmw.core#GameObject actor `:
NPC object

-
` #string faction `:
Faction ID

### Usage

`local NPC = require('openmw.types').NPC;
NPC.clearExpelled(player, "mages guild");`

NPC.createRecordDraft(npc)

Creates an #NpcRecord without adding it to the world database.

Use openmw_world#world.createRecord to add the record to the world.

### Parameter

-
` #NpcRecord npc `:
A Lua table with the fields of an NpcRecord, with an optional field `template` that accepts an #NpcRecord as a base.

### Return value

#NpcRecord:
A strongly typed NPC record.

NPC.expel(actor, faction)

Expel NPC from given faction.

Throws an exception if there is no such faction.
Note: the expelled NPC still keeps their rank and reputation in the faction, they just get an additional flag for the given faction.

### Parameters

-
` openmw.core#GameObject actor `:
NPC object

-
` #string faction `:
Faction ID

### Usage

`local NPC = require('openmw.types').NPC;
NPC.expel(player, "mages guild");`

NPC.getBaseDisposition(object, player)

Returns the current base disposition of the provided NPC.

This is their base disposition, before modifiers such as personality and faction relations are taken into account.

### Parameters

-
` openmw.core#GameObject object `:

-
` openmw.core#GameObject player `:
The player that you want to check the disposition for.

### Return value

#number:

NPC.getDisposition(object, player)

Returns the current disposition of the provided NPC.

This is their derived disposition, after modifiers such as personality and faction relations are taken into account.

### Parameters

-
` openmw.core#GameObject object `:

-
` openmw.core#GameObject player `:
The player that you want to check the disposition for.

### Return value

#number:

NPC.getFactionRank(actor, faction)

Get rank of given NPC in given faction.

Throws an exception if there is no such faction.
Note: this function does not take in account an expelling state.

### Parameters

-
` openmw.core#GameObject actor `:
NPC object

-
` #string faction `:
Faction ID

### Return value

#number:
rank Rank index (from 1), 0 if NPC is not in faction.

### Usage

`local NPC = require('openmw.types').NPC;
print(NPC.getFactionRank(player, "mages guild");`

NPC.getFactionReputation(actor, faction)

Get reputation of given actor in given faction.

Throws an exception if there is no such faction.

### Parameters

-
` openmw.core#GameObject actor `:
NPC object

-
` #string faction `:
Faction ID

### Return value

#number:
reputation Reputation level, 0 if NPC is not in faction.

### Usage

`local NPC = require('openmw.types').NPC;
print(NPC.getFactionReputation(player, "mages guild"));`

NPC.getFactions(actor)

Get all factions in which NPC has a membership.

Note: this function does not take in account an expelling state.

### Parameter

-
` openmw.core#GameObject actor `:
NPC object

### Return value

#list<#string>:
factionIds List of faction IDs.

### Usage

`local NPC = require('openmw.types').NPC;
for _, factionId in pairs(types.NPC.getFactions(actor)) do
print(factionId);
end`

NPC.isExpelled(actor, faction)

Check if NPC is expelled from given faction.

Throws an exception if there is no such faction.

### Parameters

-
` openmw.core#GameObject actor `:
NPC object

-
` #string faction `:
Faction ID

### Return value

#boolean:
isExpelled True if NPC is expelled from the faction.

### Usage

`local NPC = require('openmw.types').NPC;
local result = NPC.isExpelled(player, "mages guild");`

NPC.isWerewolf(actor)

Whether the NPC or player is in the werewolf form at the moment.

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#boolean:

NPC.joinFaction(actor, faction)

Add given actor to given faction.

Throws an exception if there is no such faction or target actor is not player.
Function does nothing if valid target actor is already a member of target faction.

### Parameters

-
` openmw.core#GameObject actor `:
NPC object

-
` #string faction `:
Faction ID

### Usage

`local NPC = require('openmw.types').NPC;
NPC.joinFaction(player, "mages guild");`

NPC.leaveFaction(actor, faction)

Remove given actor from given faction.

Function removes rank data and expelling state, but keeps a reputation in target faction.
Throws an exception if there is no such faction or target actor is not player.
Function does nothing if valid target actor is already not member of target faction.

### Parameters

-
` openmw.core#GameObject actor `:
NPC object

-
` #string faction `:
Faction ID

### Usage

`local NPC = require('openmw.types').NPC;
NPC.leaveFaction(player, "mages guild");`

NPC.modifyBaseDisposition(object, player, value)

Modify the base disposition of the provided NPC by a certain amount (only in global scripts or on self).

### Parameters

-
` openmw.core#GameObject object `:

-
` openmw.core#GameObject player `:
The player that you want to modify the disposition for.

-
` #number value `:
Base disposition modification value

NPC.modifyFactionRank(actor, faction, value)

Adjust rank of given NPC in given faction.

Throws an exception if there is no such faction or actor is not a member of given faction.
For NPCs faction also should be an NPC's primary faction.
Notes:

- If rank should become <= 0 after modification, function set rank to lowest available rank.

- If rank should become > 0 after modification, but target rank does not exist, function set rank to the highest valid rank.

### Parameters

-
` openmw.core#GameObject actor `:
NPC object

-
` #string faction `:
Faction ID

-
` #number value `:
Rank index (from 1) modifier. If rank reaches 0 for player character, he leaves the faction.

### Usage

`local NPC = require('openmw.types').NPC;
NPC.modifyFactionRank(player, "mages guild", 1);`

NPC.modifyFactionReputation(actor, faction, value)

Adjust reputation of given actor in given faction.

Throws an exception if there is no such faction.

### Parameters

-
` openmw.core#GameObject actor `:
NPC object

-
` #string faction `:
Faction ID

-
` #number value `:
Reputation modifier value

### Usage

`local NPC = require('openmw.types').NPC;
NPC.modifyFactionReputation(player, "mages guild", 5);`

NPC.objectIsInstance(object)

Whether the object is an NPC or a Player.

### Parameter

-
` openmw.core#GameObject object `:

### Return value

#boolean:

#Races

NPC.races

#Races: Race data

NPC.record(objectOrRecordId)

Returns the read-only #NpcRecord of an NPC

### Parameter

-
` #any objectOrRecordId `:

### Return value

#NpcRecord:

#list<#NpcRecord>

NPC.records

A read-only list of all #NpcRecords in the world database, may be indexed by recordId.

Implements iterables#List of #NpcRecord.

### Usages

-

`local npc = types.NPC.records['npc id'] -- get by id`

-

`local npc = types.NPC.records[1] -- get by index`

NPC.setBaseDisposition(object, player, value)

Set the base disposition of the provided NPC (only in global scripts or on self).

### Parameters

-
` openmw.core#GameObject object `:

-
` openmw.core#GameObject player `:
The player that you want to set the disposition for.

-
` #number value `:
Base disposition is set to this value

NPC.setFactionRank(actor, faction, value)

Set rank of given NPC in given faction.

Throws an exception if there is no such faction, target rank does not exist or actor is not a member of given faction.
For NPCs faction also should be an NPC's primary faction.

### Parameters

-
` openmw.core#GameObject actor `:
NPC object

-
` #string faction `:
Faction ID

-
` #number value `:
Rank index (from 1).

### Usage

`local NPC = require('openmw.types').NPC;
NPC.setFactionRank(player, "mages guild", 6);`

NPC.setFactionReputation(actor, faction, value)

Set reputation of given actor in given faction.

Throws an exception if there is no such faction.

### Parameters

-
` openmw.core#GameObject actor `:
NPC object

-
` #string faction `:
Faction ID

-
` #number value `:
Reputation value

### Usage

`local NPC = require('openmw.types').NPC;
NPC.setFactionReputation(player, "mages guild", 100);`

NPC.setWerewolf(actor, werewolf)

Turn an NPC or player into werewolf form or back to normal form.

Can only be used in global scripts or on self in local scripts.

### Parameters

-
` openmw.core#GameObject actor `:
The NPC or player to transform

-
` #boolean werewolf `:
True to transform into werewolf, false to transform back to normal

### Usages

-

`-- Transform player into werewolf in a global script
player.type.setWerewolf(player, true)`

-

`-- Transform self back to normal in a local script
self.type.setWerewolf(self, false)`

#NpcStats

NPC.stats

## Type `NpcRecord`

### Field(s)

#number

NpcRecord.baseDisposition

NPC's starting disposition

#number

NpcRecord.baseGold

The base barter gold of the NPC

#number

NpcRecord.bloodType

integer representing the blood type of the NPC. Used to generate the correct blood vfx.

#string

NpcRecord.class

ID of the NPC's class (e.g. acrobat)

#string

NpcRecord.hair

ID of the hair body part

#string

NpcRecord.head

ID of the head body part

#string

NpcRecord.id

The record ID of the NPC

#boolean

NpcRecord.isAutocalc

If true, the actor's stats will be automatically calculated based on level and class.

#boolean

NpcRecord.isEssential

whether the NPC is essential

#boolean

NpcRecord.isMale

The gender setting of the NPC

#boolean

NpcRecord.isRespawning

whether the NPC respawns after death

#string

NpcRecord.model

Path to the model associated with this NPC, used for animations.

#string

NpcRecord.mwscript

MWScript on this NPC (can be nil)

#string

NpcRecord.name

#string

NpcRecord.race

#map<#string,#boolean>

NpcRecord.servicesOffered

The services of the NPC, in a table. Value is if the service is provided or not, and they are indexed by: Spells, Spellmaking, Enchanting, Training, Repair, Barter, Weapon, Armor, Clothing, Books, Ingredients, Picks, Probes, Lights, Apparatus, RepairItems, Misc, Potions, MagicItems, Travel.

#list<#TravelDestination>

NpcRecord.travelDestinations

A list of #TravelDestinations for this NPC.

## Type `NpcStats`

### Extends #ActorStats

### Field(s)

#ReputationStat

NpcStats.reputation

#SkillStats

NpcStats.skills

## Type `OFFENSE_TYPE_IDS`

### Field(s)

#number

OFFENSE_TYPE_IDS.Assault

#number

OFFENSE_TYPE_IDS.Murder

#number

OFFENSE_TYPE_IDS.Pickpocket

#number

OFFENSE_TYPE_IDS.SleepingInOwnedBed

#number

OFFENSE_TYPE_IDS.Theft

#number

OFFENSE_TYPE_IDS.Trespassing

## Type `PLAYER`

### Extends #NPC

### Field(s)

#CONTROL_SWITCH

PLAYER.CONTROL_SWITCH

Values that can be used with getControlSwitch/setControlSwitch.

#OFFENSE_TYPE_IDS

PLAYER.OFFENSE_TYPE

Available #OFFENSE_TYPE_IDS values.

Used in `I.Crimes.commitCrime`.

PLAYER.addTopic(player, string)

Adds a topic to the list of ones known by the player, so that it can be used in dialogue with actors who can talk about that topic.

### Parameters

-
` openmw.core#GameObject player `:

-
` string `:
topicId

### Usages

-

`-- Add topic to the list of known ones, in a player script
self.type.addTopic(self, "Some Work")`

-

`-- Give all players in the current world a specific topic, in a global script
for _, player in ipairs(world.players) do player.type.addTopic(player, "Some Unrelated Work") end`

#NPC

PLAYER.baseType

#NPC

#BirthSigns

PLAYER.birthSigns

#BirthSigns: Birth Sign Data

PLAYER.getBirthSign(player)

### Parameter

-
` openmw.core#GameObject player `:

### Return value

#string:
The player's birth sign

PLAYER.getControlSwitch(player, key)

Get state of a control switch.

I.e. is the player able to move/fight/jump/etc.

### Parameters

-
` openmw.core#GameObject player `:

-
` #ControlSwitch key `:
Control type (see openmw.types#CONTROL_SWITCH)

### Return value

#boolean:

PLAYER.getCrimeLevel(player)

Returns the bounty or crime level of the player

### Parameter

-
` openmw.core#GameObject player `:

### Return value

#number:

PLAYER.isCharGenFinished(player)

Whether the character generation for this player is finished.

### Parameter

-
` openmw.core#GameObject player `:

### Return value

#boolean:

PLAYER.isTeleportingEnabled(player)

Whether teleportation for this player is enabled.

### Parameter

-
` openmw.core#GameObject player `:

### Return value

#boolean:

PLAYER.journal(player)

Returns #PlayerJournal, which contains the read-only access to journal text data accumulated by the player.

Not the same as openmw_core#Dialogue.journal which holds raw game records: with placeholders for dynamic variables and no player-specific info.

### Parameter

-
` openmw.core#GameObject player `:

### Return value

#PlayerJournal:

### Usages

-

`-- Get text of the 1st journal entry player made
local entryText = types.Player.journal(player).journalTextEntries[1].text`

-

`-- Get the number of "my trade" conversation topic lines the player journal accumulated
local num = #types.Player.journal(player).topics["my trade"].entries`

PLAYER.objectIsInstance(object)

Whether the object is a player.

### Parameter

-
` openmw.core#GameObject object `:

### Return value

#boolean:

PLAYER.quests(player)

Returns a list containing quests #PLAYERQuest for the specified player, indexed by quest ID.

### Parameter

-
` openmw.core#GameObject player `:

### Return value

#list<#PLAYERQuest>:

### Usages

-

`-- Get stage of a specific quest
stage = types.Player.quests(player)["ms_fargothring"].stage`

-

`-- Start a new quest, add it to the player's quest list but don't add any journal entries
types.Player.quests(player)["ms_fargothring"].stage = 0`

PLAYER.sendMenuEvent(player, eventName, eventData)

Send an event to menu scripts.

### Parameters

-
` openmw.core#GameObject player `:

-
` #string eventName `:

-
` eventData `:

PLAYER.setBirthSign(player, recordOrId)

Can be used only in global scripts.

Note that this does not update the player's spells.

### Parameters

-
` openmw.core#GameObject player `:

-
` #any recordOrId `:
Record or string ID of the birth sign to assign

PLAYER.setControlSwitch(player, key, value)

Set state of a control switch.

I.e. forbid or allow the player to move/fight/jump/etc.
Can be used only in global or player scripts.

### Parameters

-
` openmw.core#GameObject player `:

-
` #ControlSwitch key `:
Control type (see openmw.types#CONTROL_SWITCH)

-
` #boolean value `:

PLAYER.setCrimeLevel(player, crimeLevel)

Sets the bounty or crime level of the player, may only be used in global scripts

### Parameters

-
` openmw.core#GameObject player `:

-
` #number crimeLevel `:
The requested crime level

PLAYER.setTeleportingEnabled(player, state)

Enables or disables teleportation for this player.

### Parameters

-
` openmw.core#GameObject player `:

-
` #boolean state `:
True to enable teleporting, false to disable.

## Type `PLAYERQuest`

### Field(s)

PLAYERQuest:addJournalEntry(stage, actor)

Sets the quest stage for the given quest, on the given player, and adds the entry to the journal, if there is an entry at the specified stage.

Can only be used in global or player scripts.

### Parameters

-
` #number stage `:
Quest stage

-
` openmw.core#GameObject actor `:
(optional) The actor who is the source of the journal entry, it may be used in journal entries with variables such as `%name(The speaker's name)` or `%race(The speaker's race)`.

#boolean

PLAYERQuest.finished

Whether the quest is finished (global and player scripts can change it).

#string

PLAYERQuest.id

The quest id.

#number

PLAYERQuest.stage

The quest stage (global and player scripts can change it). Changing the stage starts the quest if it wasn't started.

#boolean

PLAYERQuest.started

Whether the quest is started.

## Type `PlayerJournal`

### Field(s)

#list<#PlayerJournalTextEntry>

PlayerJournal.journalTextEntries

A read-only list of player's accumulated journal (quest etc.) entries (#PlayerJournalTextEntry elements), ordered from oldest entry to newest.

Implements iterables#list-iterable of #PlayerJournalTextEntry.

### Usages

-

`-- The `firstQuestName` variable below is likely to be "a1_1_findspymaster" in vanilla MW
local firstQuestName = types.Player.journal(player).journalTextEntries[1].questId`

-

`-- The number of journal entries accumulated in the player journal
local num = #types.Player.journal(player).journalTextEntries`

-

`-- Print all journal entries accumulated in the player journal
for idx, journalEntry in pairs(types.Player.journal(player).journalTextEntries) do
print(idx, journalEntry.text)
end`

#map<#string,#PlayerJournalTopic>

PlayerJournal.topics

A read-only table of player's accumulated #PlayerJournalTopics, indexed by the topic name.

Implements iterables#Map of #PlayerJournalTopic.
Topic name index doesn't have to be lowercase.

### Usages

-

`local record = types.Player.journal(player).topics["my trade"]`

-

`local record = types.Player.journal(player).topics["Vivec"]`

## Type `PlayerJournalTextEntry`

### Field(s)

#number

PlayerJournalTextEntry.day

Number of the day this journal entry was written at.

#number

PlayerJournalTextEntry.dayOfMonth

Number of the day in the month this journal entry was written at.

#string

PlayerJournalTextEntry.id

Identifier for this journal entry line.

Is unique only within the #PlayerJournalTextEntry it belongs to.
Has a counterpart in raw data game dialogue records at openmw_core#DialogueRecordInfo held by openmw_core#Dialogue.journal

#number

PlayerJournalTextEntry.month

Number of the month this journal entry was written at.

#string

PlayerJournalTextEntry.questId

Quest id this journal entry is associated with. Can be nil if there is no quest associated with this entry or if journal quest sorting functionality is not available in game.

#string

PlayerJournalTextEntry.text

Text of this journal entry.

## Type `PlayerJournalTopic`

### Field(s)

#list<#PlayerJournalTopicEntry>

PlayerJournalTopic.entries

A read-only list of player's accumulated conversation lines (#PlayerJournalTopicEntry) for this topic.

Implements iterables#list-iterable of #PlayerJournalTopicEntry.

### Usages

-

`-- First NPC topic line entry in the "Background" topic
local firstBackgroundLine = types.Player.journal(player).topics["Background"].entries[1]`

-

`-- The number of topic entries accumulated in the player journal for "Vivec"
local num = #types.Player.journal(player).topics["vivec"].entries`

-

`-- Print all conversation lines accumulated in the player journal for "Balmora"
for idx, topicEntry in pairs(types.Player.journal(player).topics["balmora"].entries) do
print(idx, topicEntry.text)
end`

#string

PlayerJournalTopic.id

Topic id. It's a lowercase version of name.

#string

PlayerJournalTopic.name

Topic name. Same as id, but with upper cases preserved.

## Type `PlayerJournalTopicEntry`

### Field(s)

#string

PlayerJournalTopicEntry.actor

Name of an NPC who is recorded in the player journal as an origin of this topic line.

#string

PlayerJournalTopicEntry.id

Identifier for this topic line.

Is unique only within the #PlayerJournalTopic it belongs to.
Has a counterpart in raw data game dialogue records at openmw_core#DialogueRecordInfo held by openmw_core#Dialogue.topic

#string

PlayerJournalTopicEntry.text

Text of this topic line.

## Type `Potion`

### Extends #Item

### Field(s)

#Item

Potion.baseType

#Item

Potion.createRecordDraft(potion)

Creates a #PotionRecord without adding it to the world database.

Use openmw_world#world.createRecord to add the record to the world.

### Parameter

-
` #PotionRecord potion `:
A Lua table with the fields of a PotionRecord, with an optional field `template` that accepts a #PotionRecord as a base.

### Return value

#PotionRecord:
A strongly typed Potion record.

Potion.objectIsInstance(object)

Whether the object is a Potion.

### Parameter

-
` openmw.core#GameObject object `:

### Return value

#boolean:

Potion.record(objectOrRecordId)

Returns the read-only #PotionRecord of a potion

### Parameter

-
` #any objectOrRecordId `:

### Return value

#PotionRecord:

#list<#PotionRecord>

Potion.records

A read-only list of all #PotionRecords in the world database.

Implements iterables#List of #PotionRecord.

### Usages

-

`local record = types.Potion.records['example_recordid']`

-

`local record = types.Potion.records[1]`

## Type `PotionRecord`

### Field(s)

#list<openmw.core#MagicEffectWithParams>

PotionRecord.effects

The effects (openmw.core#MagicEffectWithParams) of the potion

#string

PotionRecord.icon

VFS path to the icon

#string

PotionRecord.id

Record id

#boolean

PotionRecord.isAutocalc

If set, the gold value should be computed based on the effect list rather than read from the value field

#string

PotionRecord.model

VFS path to the model

#string

PotionRecord.mwscript

MWScript on this potion (can be nil)

#string

PotionRecord.name

Human-readable name

#number

PotionRecord.value

#number

PotionRecord.weight

## Type `Probe`

### Extends #Item

### Field(s)

#Item

Probe.baseType

#Item

Probe.createRecordDraft(probe)

Creates a #ProbeRecord without adding it to the world database.

Use openmw_world#world.createRecord to add the record to the world.

### Parameter

-
` #ProbeRecord probe `:
A Lua table with the fields of a ProbeRecord, with an optional field `template` that accepts a #ProbeRecord as a base.

### Return value

#ProbeRecord:
A strongly typed Probe record.

Probe.objectIsInstance(object)

Whether the object is a Probe.

### Parameter

-
` openmw.core#GameObject object `:

### Return value

#boolean:

Probe.record(objectOrRecordId)

Returns the read-only #ProbeRecord of a probe

### Parameter

-
` #any objectOrRecordId `:

### Return value

#ProbeRecord:

#list<#ProbeRecord>

Probe.records

A read-only list of all #ProbeRecords in the world database.

Implements iterables#List of #ProbeRecord.

### Usages

-

`local record = types.Probe.records['example_recordid']`

-

`local record = types.Probe.records[1]`

## Type `ProbeRecord`

### Field(s)

#string

ProbeRecord.icon

VFS path to the icon

#string

ProbeRecord.id

The record ID of the probe

#number

ProbeRecord.maxCondition

The maximum number of uses of this probe

#string

ProbeRecord.model

VFS path to the model

#string

ProbeRecord.mwscript

MWScript on this probe (can be nil)

#string

ProbeRecord.name

The name of the probe

#number

ProbeRecord.quality

The quality of the probe

#number

ProbeRecord.value

#number

ProbeRecord.weight

## Type `RaceRecord`

Race data record

### Usage

`-- Get base strength for men
strength = types.NPC.races.records[1].attributes.strength.male`

### Field(s)

#map<#string,#GenderedNumber>

RaceRecord.attributes

A read-only table of attribute ID to base value

#string

RaceRecord.description

Race description

#GenderedNumber

RaceRecord.height

Height values

#string

RaceRecord.id

Race id

#boolean

RaceRecord.isBeast

True if this race is a beast race

#boolean

RaceRecord.isPlayable

True if the player can pick this race in character generation

#string

RaceRecord.name

Race name

#map<#string,#number>

RaceRecord.skills

A map of bonus skill points by skill ID

#list<#string>

RaceRecord.spells

A read-only list containing the ids of all spells inherent to the race

#GenderedNumber

RaceRecord.weight

Weight values

## Type `Races`

### Field(s)

Races.record(recordId)

Returns a read-only #RaceRecord

### Parameter

-
` #string recordId `:

### Return value

#RaceRecord:

#list<#RaceRecord>

Races.records

A read-only list of all #RaceRecords in the world database.

Implements iterables#List of #RaceRecord.

### Usages

-

`local race = types.NPC.races.records['race id'] -- get by id`

-

`local race = types.NPC.races.records[1] -- get by index`

## Type `Repair`

### Extends #Item

### Field(s)

#Item

Repair.baseType

#Item

Repair.objectIsInstance(object)

Whether the object is a Repair.

### Parameter

-
` openmw.core#GameObject object `:

### Return value

#boolean:

Repair.record(objectOrRecordId)

Returns the read-only #RepairRecord of a repair tool

### Parameter

-
` #any objectOrRecordId `:

### Return value

#RepairRecord:

#list<#RepairRecord>

Repair.records

A read-only list of all #RepairRecords in the world database.

Implements iterables#List of #RepairRecord.

### Usages

-

`local record = types.Repair.records['example_recordid']`

-

`local record = types.Repair.records[1]`

## Type `RepairRecord`

### Field(s)

#string

RepairRecord.icon

VFS path to the icon

#string

RepairRecord.id

The record ID of the repair tool

#number

RepairRecord.maxCondition

The maximum number of uses of this repair tool

#string

RepairRecord.model

VFS path to the model

#string

RepairRecord.mwscript

MWScript on this repair tool (can be nil)

#string

RepairRecord.name

The name of the repair tool

#number

RepairRecord.quality

The quality of the repair tool

#number

RepairRecord.value

#number

RepairRecord.weight

## Type `ReputationStat`

Value modification is delayed

### Field(s)

#number

ReputationStat.current

Current reputation value.

## Type `STANCE`

### Field(s)

#number

STANCE.Nothing

Default stance

#number

STANCE.Spell

Magic stance

#number

STANCE.Weapon

Weapon stance

## Type `SkillIncreasesForAttributeStats`

Values affect how much each attribute can be increased at level up, and are all reset to 0 upon level up.

### Field(s)

#number

SkillIncreasesForAttributeStats.agility

Number of contributions to agility for the next level up.

#number

SkillIncreasesForAttributeStats.endurance

Number of contributions to endurance for the next level up.

#number

SkillIncreasesForAttributeStats.intelligence

Number of contributions to intelligence for the next level up.

#number

SkillIncreasesForAttributeStats.luck

Number of contributions to luck for the next level up.

#number

SkillIncreasesForAttributeStats.personality

Number of contributions to personality for the next level up.

#number

SkillIncreasesForAttributeStats.speed

Number of contributions to speed for the next level up.

#number

SkillIncreasesForAttributeStats.strength

Number of contributions to strength for the next level up.

#number

SkillIncreasesForAttributeStats.willpower

Number of contributions to willpower for the next level up.

## Type `SkillIncreasesForSpecializationStats`

Values affect the graphic used on the level up screen, and are all reset to 0 upon level up.

### Field(s)

#number

SkillIncreasesForSpecializationStats.combat

Number of contributions to combat specialization for the next level up.

#number

SkillIncreasesForSpecializationStats.magic

Number of contributions to magic specialization for the next level up.

#number

SkillIncreasesForSpecializationStats.stealth

Number of contributions to stealth specialization for the next level up.

## Type `SkillStat`

Value modification is delayed

### Field(s)

#number

SkillStat.base

The NPC's base skill value.

#number

SkillStat.damage

The amount the skill has been damaged.

#number

SkillStat.modified

The NPC's current skill value (read-only.)

#number

SkillStat.modifier

The skill's modifier.

#number

SkillStat.progress

[0-1] The NPC's skill progress.

## Type `SkillStats`

### Field(s)

SkillStats.acrobatics(actor)

Acrobatics (returns #SkillStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#SkillStat:

SkillStats.alchemy(actor)

Alchemy (returns #SkillStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#SkillStat:

SkillStats.alteration(actor)

Alteration (returns #SkillStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#SkillStat:

SkillStats.armorer(actor)

Armorer (returns #SkillStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#SkillStat:

SkillStats.athletics(actor)

Athletics (returns #SkillStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#SkillStat:

SkillStats.axe(actor)

Axe (returns #SkillStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#SkillStat:

SkillStats.block(actor)

Block (returns #SkillStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#SkillStat:

SkillStats.bluntweapon(actor)

Blunt Weapon (returns #SkillStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#SkillStat:

SkillStats.conjuration(actor)

Conjuration (returns #SkillStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#SkillStat:

SkillStats.destruction(actor)

Destruction (returns #SkillStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#SkillStat:

SkillStats.enchant(actor)

Enchant (returns #SkillStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#SkillStat:

SkillStats.handtohand(actor)

Hand To Hand (returns #SkillStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#SkillStat:

SkillStats.heavyarmor(actor)

Heavy Armor (returns #SkillStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#SkillStat:

SkillStats.illusion(actor)

Illusion (returns #SkillStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#SkillStat:

SkillStats.lightarmor(actor)

Light Armor (returns #SkillStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#SkillStat:

SkillStats.longblade(actor)

Long Blade (returns #SkillStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#SkillStat:

SkillStats.marksman(actor)

Marksman (returns #SkillStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#SkillStat:

SkillStats.mediumarmor(actor)

Medium Armor (returns #SkillStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#SkillStat:

SkillStats.mercantile(actor)

Mercantile (returns #SkillStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#SkillStat:

SkillStats.mysticism(actor)

Mysticism (returns #SkillStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#SkillStat:

SkillStats.restoration(actor)

Restoration (returns #SkillStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#SkillStat:

SkillStats.security(actor)

Security (returns #SkillStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#SkillStat:

SkillStats.shortblade(actor)

Short Blade (returns #SkillStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#SkillStat:

SkillStats.sneak(actor)

Sneak (returns #SkillStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#SkillStat:

SkillStats.spear(actor)

Spear (returns #SkillStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#SkillStat:

SkillStats.speechcraft(actor)

Speechcraft (returns #SkillStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#SkillStat:

SkillStats.unarmored(actor)

Unarmored (returns #SkillStat)

### Parameter

-
` openmw.core#GameObject actor `:

### Return value

#SkillStat:

## Type `Static`

### Field(s)

Static.createRecordDraft(static)

Creates a #StaticRecord without adding it to the world database.

Use openmw_world#world.createRecord to add the record to the world.

### Parameter

-
` #StaticRecord static `:
A Lua table with the fields of a StaticRecord, with an optional field `template` that accepts a #StaticRecord as a base.

### Return value

#StaticRecord:
A strongly typed Static record.

Static.objectIsInstance(object)

Whether the object is a Static.

### Parameter

-
` openmw.core#GameObject object `:

### Return value

#boolean:

Static.record(objectOrRecordId)

Returns the read-only #StaticRecord of a Static

### Parameter

-
` #any objectOrRecordId `:

### Return value

#StaticRecord:

#list<#StaticRecord>

Static.records

A read-only list of all #StaticRecords in the world database.

Implements iterables#List of #StaticRecord.

### Usages

-

`local record = types.Static.records['example_recordid']`

-

`local record = types.Static.records[1]`

## Type `StaticRecord`

### Field(s)

#string

StaticRecord.id

Record id

#string

StaticRecord.model

VFS path to the model

## Type `TravelDestination`

### Field(s)

#string

TravelDestination.cellId

ID of the Destination cell for this TravelDestination, Can be used with openmw_world#world.getCellById.

openmw.util#Vector3

TravelDestination.position

Destination position for this TravelDestination.

openmw.util#Transform

TravelDestination.rotation

Destination rotation for this TravelDestination.

## Type `Weapon`

### Extends #Item

### Field(s)

#WeaponTYPE

Weapon.TYPE

#WeaponTYPE

#Item

Weapon.baseType

#Item

Weapon.createRecordDraft(weapon)

Creates a #WeaponRecord without adding it to the world database.

Use openmw_world#world.createRecord to add the record to the world.

### Parameter

-
` #WeaponRecord weapon `:
A Lua table with the fields of a WeaponRecord, with an optional field `template` that accepts a #WeaponRecord as a base.

### Return value

#WeaponRecord:
A strongly typed Weapon record.

Weapon.objectIsInstance(object)

Whether the object is a Weapon.

### Parameter

-
` openmw.core#GameObject object `:

### Return value

#boolean:

Weapon.record(objectOrRecordId)

Returns the read-only #WeaponRecord of a weapon

### Parameter

-
` #any objectOrRecordId `:

### Return value

#WeaponRecord:

#list<#WeaponRecord>

Weapon.records

A read-only list of all #WeaponRecords in the world database.

Implements iterables#List of #WeaponRecord.

### Usages

-

`local record = types.Weapon.records['example_recordid']`

-

`local record = types.Weapon.records[1]`

## Type `WeaponRecord`

### Field(s)

#number

WeaponRecord.chopMaxDamage

#number

WeaponRecord.chopMinDamage

#string

WeaponRecord.enchant

The enchantment ID of this weapon (can be nil)

#number

WeaponRecord.enchantCapacity

#number

WeaponRecord.health

#string

WeaponRecord.icon

VFS path to the icon

#string

WeaponRecord.id

Record id

#boolean

WeaponRecord.isMagical

#boolean

WeaponRecord.isSilver

#string

WeaponRecord.model

VFS path to the model

#string

WeaponRecord.mwscript

MWScript on this weapon (can be nil)

#string

WeaponRecord.name

Human-readable name

#number

WeaponRecord.reach

#number

WeaponRecord.slashMaxDamage

#number

WeaponRecord.slashMinDamage

#number

WeaponRecord.speed

#number

WeaponRecord.thrustMaxDamage

#number

WeaponRecord.thrustMinDamage

#number

WeaponRecord.type

See Weapon.TYPE

#number

WeaponRecord.value

#number

WeaponRecord.weight

## Type `WeaponTYPE`

Weapon.TYPE

### Field(s)

#number

WeaponTYPE.Arrow

#number

WeaponTYPE.AxeOneHand

#number

WeaponTYPE.AxeTwoHand

#number

WeaponTYPE.BluntOneHand

#number

WeaponTYPE.BluntTwoClose

#number

WeaponTYPE.BluntTwoWide

#number

WeaponTYPE.Bolt

#number

WeaponTYPE.LongBladeOneHand

#number

WeaponTYPE.LongBladeTwoHand

#number

WeaponTYPE.MarksmanBow

#number

WeaponTYPE.MarksmanCrossbow

#number

WeaponTYPE.MarksmanThrown

#number

WeaponTYPE.ShortBladeOneHand

#number

WeaponTYPE.SpearTwoWide

Package openmw.storage

Package openmw.ui
