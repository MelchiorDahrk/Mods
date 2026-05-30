# Package openmw.core

# Package openmw.core

API v129

Defines functions and types that are available in local, global, menu, and load scripts.

global
menu
local
player
load

## Usage

`local core = require('openmw.core')`

## Type `core`

core.API_REVISION

The revision of OpenMW's Lua API.

core.contentFiles

#ContentFiles: functions working with the list of currently loaded content files.

core.dialogue

#Dialogue: Dialogue.

core.factions

#Factions: Factions.

core.getFormId(contentFile, index)

Construct FormId string from content file name and the index in the file.

core.getGMST(setting)

Get a game setting with given name (from GMST ESM records or from openmw.cfg).

core.getGameDifficulty()

The game's difficulty setting.

core.getGameTime()

Game time in seconds.

core.getGameTimeScale()

The scale of game time relative to simulation time.

core.getRealFrameDuration()

Frame duration in seconds.

core.getRealTime()

Real time in seconds; starting point is not fixed (can be time since last reboot), use only for measuring intervals.

core.getSimulationTime()

Simulation time in seconds.

core.getSimulationTimeScale()

The scale of simulation time relative to real time.

core.isWorldPaused()

Whether the world is paused.

core.l10n(context, fallbackLocale)

Return l10n formatting function for the given context.

core.land

#Land: Functions for interacting with land data.

core.magic

#Magic: spells and spell effects.

core.mwscripts

#MWScripts: MWScripts.

core.quit()

Terminates the game and quits to the OS.

core.regions

#Regions: Regions.

core.sendGlobalEvent(eventName, eventData)

Send an event to global scripts.

core.sound

#Sound: Sounds and Speech.

core.stats

#Stats: stats.

core.weather

#Weather: Weather.

## Type `ActiveEffect`

ActiveEffect.affectedAttribute

Optional attribute ID

ActiveEffect.affectedSkill

Optional skill ID

ActiveEffect.id

Effect id string

ActiveEffect.magnitude

Current magnitude of the effect. Will be set to 0 when the effect is removed or expires.

ActiveEffect.magnitudeBase

ActiveEffect.magnitudeModifier

ActiveEffect.name

Localized name of the effect

## Type `ActiveSpell`

ActiveSpell.activeSpellId

Uniquely identifies this active spell within the affected actor's list of active spells.

ActiveSpell.affectsBaseValues

If set, this spell affects the base values of affected stats, rather than modifying current values.

ActiveSpell.caster

The caster object, or nil if the spell has no defined caster

ActiveSpell.effects

The active effects (#ActiveSpellEffect) of this spell.

ActiveSpell.fromEquipment

If set, this spell is tied to an equipped item and can only be ended by unequipping the item.

ActiveSpell.id

Record id of the spell or item used to cast the spell

ActiveSpell.item

The enchanted item used to cast the spell, or nil if the spell was not cast from an enchanted item. Note that if the spell was cast for a single-use enchantment such as a scroll, this will be nil.

ActiveSpell.name

The spell or item display name

ActiveSpell.stackable

If set, this spell can be applied multiple times. If not set, the same spell can only be applied once from the same source (where source is determined by caster + item). In vanilla rules, consumables are stackable while spells and enchantments are not.

ActiveSpell.temporary

If set, this spell effect is temporary and should end on its own. Either after a single application or after its duration has run out.

## Type `ActiveSpellEffect`

ActiveSpellEffect.affectedAttribute

Optional attribute ID

ActiveSpellEffect.affectedSkill

Optional skill ID

ActiveSpellEffect.duration

Total duration in seconds of this spell effect, should not be confused with remaining duration. Or nil if the effect is not temporary.

ActiveSpellEffect.durationLeft

Remaining duration in seconds of this spell effect, or nil if the effect is not temporary.

ActiveSpellEffect.id

Magic effect id

ActiveSpellEffect.index

Index of this effect within the original list of #MagicEffectWithParams of the spell/enchantment/potion this effect came from.

ActiveSpellEffect.magnitudeThisFrame

The magnitude of the effect in the current frame. This will be a new random number between minMagnitude and maxMagnitude every frame. Or nil if the effect has no magnitude.

ActiveSpellEffect.maxMagnitude

The maximum magnitude of this effect, or nil if the effect has no magnitude.

ActiveSpellEffect.minMagnitude

The minimum magnitude of this effect, or nil if the effect has no magnitude.

ActiveSpellEffect.name

Localized name of the effect

## Type `Attribute`

Attribute.record(recordId)

Returns a read-only #AttributeRecord

Attribute.records

A read-only list of all #AttributeRecords in the world database, may be indexed by recordId.
Implements iterables#List of #AttributeRecord.

## Type `AttributeRecord`

AttributeRecord.description

Human-readable description

AttributeRecord.icon

VFS path to the icon

AttributeRecord.id

Record id

AttributeRecord.name

Human-readable name

## Type `Cell`

Cell.displayName

Human-readable cell name (takes into account *.cel file localizations). Can be an empty string.

Cell:getAll(type)

Get all objects of given type from the cell; Only available from global scripts.

Cell.gridX

Index of the cell by X (only for exteriors).

Cell.gridY

Index of the cell by Y (only for exteriors).

Cell.hasSky

True if in this cell sky should be rendered.

Cell:hasTag(tag)

Returns true if the cell has given tag.

Cell.hasWater

True if the cell contains water.

Cell.id

Unique record ID of the cell, based on cell name for interiors and the worldspace for exteriors, or the formID of the cell for ESM4 cells.

Cell.isExterior

Whether the cell is an exterior cell. "Exterior" means grid of cells where the player can seamless walk from one cell to another without teleports. QuasiExterior (interior with sky) is not an exterior.

Cell:isInSameSpace(object)

Returns true either if the cell contains the object or if the cell is an exterior and the object is also in an exterior.

Cell.isQuasiExterior

(DEPRECATED, use `hasTag("QuasiExterior")`) Whether the cell is a quasi exterior (like interior but with the sky and the weather).

Cell.name

Name of the cell (can be empty string).

Cell.pathGrid

The cell's #PathGrid if it has one.

Cell.region

Region of the cell (can be nil).

Cell.waterLevel

The water level of the cell. (nil if cell has no water).

Cell.worldSpaceId

Id of the world space (can be nil).

## Type `ContentFiles`

ContentFiles.has(contentFile)

Check if the content file with given name present in the load order.

ContentFiles.indexOf(contentFile)

Return the index of a specific content file in the load order (or `nil` if there is no such content file).

ContentFiles.list

The current load order (list of content file names).

## Type `Dialogue`

Dialogue.CONDITION_OPERATOR

Possible #DialogueConditionOperator values

Dialogue.CONDITION_TYPE

Possible #DialogueConditionType values

Dialogue.greeting

#DialogueRecords functions for greeting read-only records.

Dialogue.journal

#DialogueRecords functions for journal (quest) read-only records.

Dialogue.persuasion

#DialogueRecords functions for persuasion read-only records.

Dialogue.topic

#DialogueRecords functions for topic read-only records.

Dialogue.voice

#DialogueRecords functions for voice read-only records.

## Type `DialogueConditionOperator`

DialogueConditionOperator.Equal

==

DialogueConditionOperator.Greater

DialogueConditionOperator.GreaterEqual

=

DialogueConditionOperator.Less

<

DialogueConditionOperator.LessEqual

<=

DialogueConditionOperator.NotEqual

!=

## Type `DialogueConditionType`

DialogueConditionType.Alarm

The speaker's current alarm

DialogueConditionType.Alarmed

Whether the speaker was alarmed by the player's crime

DialogueConditionType.Attacked

Whether the speaker was attacked

DialogueConditionType.Choice

The choice index

DialogueConditionType.CreatureTarget

Whether the speaker is targeting a creature

DialogueConditionType.Dead

The number of dead actors of the given DialogueInfoCondition.recordId

DialogueConditionType.Detected

Whether the speaker has detected the player

DialogueConditionType.FacReactionHighest

Highest faction reaction from the speaker's primary faction to the player's factions

DialogueConditionType.FacReactionLowest

Lowest faction reaction from the speaker's primary faction to the player's factions

DialogueConditionType.FactionRankDifference

The difference between the player's rank in the speaker's primary faction and the speaker's

DialogueConditionType.Fight

The speaker's current fight

DialogueConditionType.Flee

The speaker's current flee

DialogueConditionType.FriendHit

The number of times the player has hit the speaker follower

DialogueConditionType.Global

A comparison to the DialogueInfoCondition.variableName global variable

DialogueConditionType.HealthPercent

The speaker's health percentage

DialogueConditionType.Hello

The speaker's current hello

DialogueConditionType.Item

The number of copies of DialogueInfoCondition.recordId the player is carrying

DialogueConditionType.Journal

A comparison to the player's DialogueInfoCondition.recordId journal index

DialogueConditionType.Level

The speaker's level

DialogueConditionType.Local

A comparison to the speaker's DialogueInfoCondition.variableName local variable

DialogueConditionType.NotCell

The player's cell name should not start with DialogueInfoCondition.cellName

DialogueConditionType.NotClass

The speaker's class should not match DialogueInfoCondition.recordId

DialogueConditionType.NotFaction

The speaker's faction ID should not match DialogueInfoCondition.recordId

DialogueConditionType.NotId

The speaker's recordId should not match DialogueInfoCondition.recordId

DialogueConditionType.NotLocal

A comparison to the speaker's DialogueInfoCondition.variableName local variable

DialogueConditionType.NotRace

The speaker's race should not match DialogueInfoCondition.recordId

DialogueConditionType.PcAcrobatics

The player's current acrobatics

DialogueConditionType.PcAgility

The player's current agility

DialogueConditionType.PcAlchemy

The player's current alchemy

DialogueConditionType.PcAlteration

The player's current alteration

DialogueConditionType.PcArmorer

The player's current armorer

DialogueConditionType.PcAthletics

The player's current athletics

DialogueConditionType.PcAxe

The player's current axe

DialogueConditionType.PcBlightDisease

Check if the player has a blight disease

DialogueConditionType.PcBlock

The player's current block

DialogueConditionType.PcBluntWeapon

The player's current blunt weapon

DialogueConditionType.PcClothingModifier

Check the combined value of the player's outfit

DialogueConditionType.PcCommonDisease

Check if the player has a common disease

DialogueConditionType.PcConjuration

The player's current conjuration

DialogueConditionType.PcCorprus

Whether the player is affected by the Corprus magic effect

DialogueConditionType.PcCrimeLevel

The player's bounty

DialogueConditionType.PcDestruction

The player's current destruction

DialogueConditionType.PcEnchant

The player's current enchant

DialogueConditionType.PcEndurance

The player's current endurance

DialogueConditionType.PcExpelled

Check whether the player has been expelled from the speaker's primary faction

DialogueConditionType.PcFatigue

The player's current fatigue

DialogueConditionType.PcGender

The player's gender

DialogueConditionType.PcHandToHand

The player's current hand to hand

DialogueConditionType.PcHealth

The player's current health

DialogueConditionType.PcHealthPercent

The player's health percentage

DialogueConditionType.PcHeavyArmor

The player's current heavy armor

DialogueConditionType.PcIllusion

The player's current illusion

DialogueConditionType.PcIntelligence

The player's current intelligence

DialogueConditionType.PcLevel

The player's level

DialogueConditionType.PcLightArmor

The player's current light armor

DialogueConditionType.PcLongBlade

The player's current long blade

DialogueConditionType.PcLuck

The player's current luck

DialogueConditionType.PcMagicka

The player's current magicka

DialogueConditionType.PcMarksman

The player's current marksman

DialogueConditionType.PcMediumArmor

The player's current medium armor

DialogueConditionType.PcMercantile

The player's current mercantile

DialogueConditionType.PcMysticism

The player's current mysticism

DialogueConditionType.PcPersonality

The player's current personality

DialogueConditionType.PcReputation

The player's reputation

DialogueConditionType.PcRestoration

The player's current restoration

DialogueConditionType.PcSecurity

The player's current security

DialogueConditionType.PcShortBlade

The player's current short blade

DialogueConditionType.PcSneak

The player's current sneak

DialogueConditionType.PcSpear

The player's current spear

DialogueConditionType.PcSpeechcraft

The player's current speechcraft

DialogueConditionType.PcSpeed

The player's current speed

DialogueConditionType.PcStrength

The player's current strength

DialogueConditionType.PcUnarmored

The player's current unarmored

DialogueConditionType.PcVampire

Whether the player is affected by the Vampirism magic effect

DialogueConditionType.PcWerewolfKills

The number of werewolves killed by the player

DialogueConditionType.PcWillpower

The player's current willpower

DialogueConditionType.RankRequirement

Check whether the player can advance in the speaker's primary faction

DialogueConditionType.Reputation

The speaker's reputation

DialogueConditionType.SameFaction

Check if the player is a member of the speaker's primary faction

DialogueConditionType.SameGender

Check if the speaker's gender matches the player's

DialogueConditionType.SameRace

Check if the speaker's race matches the player's

DialogueConditionType.ShouldAttack

Whether the speaker would start combat with the player

DialogueConditionType.TalkedToPc

Whether the speaker has talked to the player before

DialogueConditionType.Weather

Checks the scriptId of the weather in the player's cell

DialogueConditionType.Werewolf

Whether the speaker is in werewolf form

## Type `DialogueInfoCondition`

DialogueInfoCondition.cellName

The cell name to compare to

DialogueInfoCondition.operator

The #{#DialogueConditionOperator} to use in the comparison

DialogueInfoCondition.recordId

The record ID to use in the comparison

DialogueInfoCondition.type

The condition's #DialogueConditionType

DialogueInfoCondition.value

The value to compare to

DialogueInfoCondition.variableName

The name of the global or local mwscript variable to compare to

## Type `DialogueRecord`

DialogueRecord.id

Record identifier

DialogueRecord.infos

A read-only list containing all #DialogueRecordInfos for this record, in order.

DialogueRecord.name

Same as id, but with upper cases preserved.

DialogueRecord.questName

Non-nil only for journal records with available value. Holds the quest name for this journal entry. Same info may be available under `infos[1].text` as well, but this variable is made for convenience.

## Type `DialogueRecordInfo`

DialogueRecordInfo.conditions

A read-only list of #DialogueInfoConditions.

DialogueRecordInfo.filterActorClass

Speaker class allowing for this info entry to appear.

DialogueRecordInfo.filterActorDisposition

Minimum speaker disposition allowing for this info entry to appear.

DialogueRecordInfo.filterActorFaction

Faction of which the speaker must be a member for this info entry to appear.

DialogueRecordInfo.filterActorFactionRank

Minimum speaker's rank in their faction allowing for this info entry to appear.

DialogueRecordInfo.filterActorGender

Speaker gender allowing for this info entry to appear: "male" or "female".

DialogueRecordInfo.filterActorId

Speaker ID allowing for this info entry to appear.

DialogueRecordInfo.filterActorRace

Speaker race allowing for this info entry to appear.

DialogueRecordInfo.filterPlayerCell

Cell name prefix of location where the player must be for this info entry to appear.

DialogueRecordInfo.filterPlayerFaction

Faction of which the player must be a member for this info entry to appear.

DialogueRecordInfo.filterPlayerFactionRank

Minimum player's rank in their faction allowing for this info entry to appear.

DialogueRecordInfo.id

Identifier for this info entry. Is unique only within the #DialogueRecord it belongs to.

DialogueRecordInfo.isQuestFinished

True if this info entry has the "Finished" flag checked.

DialogueRecordInfo.isQuestName

True if this info entry has the "Quest Name" flag checked.

DialogueRecordInfo.isQuestRestart

True if this info entry has the "Restart" flag checked.

DialogueRecordInfo.questStage

Quest stage (same as in openmw_types#PLAYERQuest.stage) this info entry is associated with.

DialogueRecordInfo.resultScript

MWScript (full script text) executed when this info is chosen.

DialogueRecordInfo.sound

Sound file path for this info entry.

DialogueRecordInfo.text

Text associated with this info entry.

## Type `DialogueRecords`

DialogueRecords.records

A read-only list of all #DialogueRecords in the world database, may be indexed by recordId, which doesn't have to be lowercase.

## Type `Effects`

Effects.records

Map from #MagicEffectId to #MagicEffect

## Type `Enchantment`

Enchantment.autocalcFlag

(DEPRECATED, use isAutocalc) If set, the casting cost should be computed based on the effect list rather than read from the cost field

Enchantment.charge

Charge capacity. Should not be confused with current charge.

Enchantment.cost

Enchantment.effects

The effects (#MagicEffectWithParams) of the enchantment

Enchantment.id

Enchantment id

Enchantment.isAutocalc

If set, the casting cost should be computed based on the effect list rather than read from the cost field

Enchantment.type

#EnchantmentType

## Type `EnchantmentType`

EnchantmentType.CastOnStrike

Enchantment is cast on strike, if there is enough charge.

EnchantmentType.CastOnUse

Enchantment is cast when used, if there is enough charge.

EnchantmentType.CastOnce

Enchantment can be cast once, destroying the enchanted item.

EnchantmentType.ConstantEffect

Enchantment is always active when equipped.

## Type `Enchantments`

Enchantments.createRecordDraft(enchantment)

Creates an #Enchantment without adding it to the world database.

Enchantments.records

A read-only list of all #Enchantment records in the world database, may be indexed by recordId.

## Type `FactionRank`

FactionRank.attributeValues

Attributes values required to get this rank.

FactionRank.factionReaction

(DEPRECATED) Returns the same as factionReputation.

FactionRank.factionReputation

Required amount of faction reputation to reach this rank.

FactionRank.favouredSkillValue

Secondary skill value required to get this rank.

FactionRank.name

Faction name Rank display name

FactionRank.primarySkillValue

Primary skill value required to get this rank.

## Type `FactionRecord`

FactionRecord.attributes

A read-only list containing IDs of attributes to advance ranks in the faction.

FactionRecord.hidden

If true, the faction won't show in the player's skills menu

FactionRecord.id

Faction id

FactionRecord.name

Faction name

FactionRecord.ranks

A read-only list containing data for all ranks in the faction, in order.

FactionRecord.reactions

A read-only map containing reactions of other factions to this faction.

FactionRecord.skills

A read-only list containing IDs of skills to advance ranks in the faction.

## Type `Factions`

Factions.records

A read-only list of all #FactionRecords in the world database.

## Type `GameObject`

GameObject:activateBy(actor)

Activate the object.

GameObject:addScript(scriptPath, initData)

Add a new local script to the object.

GameObject.cell

The cell where the object currently is. During loading a game and for objects in an inventory or a container `cell` is nil.

GameObject.contentFile

Lowercase file name of the content file that defines this object; nil for dynamically created objects.

GameObject.count

Count (>1 means a stack of objects).

GameObject.enabled

Whether the object is enabled or disabled. Global scripts can set the value. Items in containers or inventories can't be disabled.

GameObject:getBoundingBox()

The axis aligned bounding box in world coordinates.

GameObject.globalVariable

Global Variable associated with this object (read only).

GameObject:hasScript(scriptPath)

Whether a script with given path is attached to this object.

GameObject.id

The unique id of this object (not record id), can be used as a key in a table.

GameObject:isValid()

Does the object still exist and is available.

GameObject:moveInto(dest)

Moves an object into a container or an inventory.

GameObject.owner

Ownership information

GameObject.parentContainer

Container or actor that contains (or has in inventory) this object. It is nil if the object is in a cell.

GameObject.position

Object position.

GameObject.recordId

Returns record ID of the object in lowercase.

GameObject:remove(count)

Removes an object or reduces a stack of objects.

GameObject:removeScript(scriptPath)

Removes script that was attached by `addScript`
Can be called only from a global script.

GameObject.rotation

Object rotation.

GameObject.scale

Object scale.

GameObject:sendEvent(eventName, eventData)

Send a local event to the object.

GameObject:setScale(scale)

Sets the object's scale.

GameObject:split(count)

Splits a stack of items.

GameObject.startingCell

The object's original cell. Returns nil if `cell` of the object is nil.

GameObject.startingPosition

The object original position

GameObject.startingRotation

The object original rotation

GameObject:teleport(cellOrName, position, options)

Moves the object to given cell and position.

GameObject.type

Type of the object (one of the tables from the package openmw.types#types).

## Type `Inventory`

Inventory:countOf(recordId)

The number of items with the given recordId.

Inventory:find(recordId)

Get first item with the given recordId from the inventory.

Inventory:findAll(recordId)

Get all items with the given recordId from the inventory.

Inventory:getAll(type)

Get all items of the given type from the inventory.

Inventory:isResolved()

Checks if the inventory has a resolved item list.

Inventory:resolve()

Will resolve the inventory, filling it with levelled items if applicable, making its contents permanent.

## Type `Land`

Land.getHeightAt(position, cellOrId)

Get the terrain height at a given location.

Land.getTextureAt(position, cellOrId)

Get the terrain texture at a given location.

## Type `MWScriptRecord`

MWScriptRecord.id

MWScript id

MWScriptRecord.text

MWScript content

## Type `MWScripts`

MWScripts.records

A read-only list of all #MWScriptRecords in the world database.

## Type `Magic`

Magic.EFFECT_TYPE

Possible #MagicEffectId values

Magic.ENCHANTMENT_TYPE

Possible #EnchantmentType values

Magic.RANGE

Possible #SpellRange values

Magic.SPELL_TYPE

Possible #SpellType values

Magic.effects

#Effects: Magic Effects

Magic.enchantments

#Enchantments: Enchantments

Magic.spells

#Spells: Spells

## Type `MagicEffect`

MagicEffect.allowsEnchanting

True if the effect is available for enchanting

MagicEffect.allowsSpellmaking

True if the effect is available for spellmaking

MagicEffect.areaSound

Identifier of the sound used for AOE spells

MagicEffect.areaStatic

Identifier of the vfx static used for AOE spells

MagicEffect.baseCost

MagicEffect.bolt

Identifier of the projectile used for ranged spells

MagicEffect.boltSound

Identifier of the projectile sound used for ranged spells

MagicEffect.castSound

Identifier of the sound used for casting

MagicEffect.castStatic

Identifier of the vfx static used for casting

MagicEffect.casterLinked

If set, it is implied the magic effect links back to the caster in some way and should end immediately or never be applied if the caster dies or is not an actor.

MagicEffect.color

MagicEffect.continuousVfx

Whether the magic effect's vfx should loop or not

MagicEffect.description

Localized description of the effect

MagicEffect.harmful

If set, the effect is considered harmful and should elicit a hostile reaction from affected NPCs.

MagicEffect.hasAttribute

True if the effect requires an attribute parameter

MagicEffect.hasDuration

If set, the magic effect has a duration. As an example, divine intervention has no duration while fire damage does.

MagicEffect.hasMagnitude

If set, the magic effect depends on a magnitude. As an example, cure common disease has no magnitude while chameleon does.

MagicEffect.hasSkill

True if the effect requires a skill parameter

MagicEffect.hitSound

Identifier of the sound used on hit

MagicEffect.hitStatic

Identifier of the vfx static used on hit

MagicEffect.icon

Effect Icon Path

MagicEffect.id

Effect ID

MagicEffect.isAppliedOnce

If set, the magic effect is applied fully on cast, rather than being continuously applied over the effect's duration. For example, chameleon is applied once, while fire damage is continuously applied for the duration.

MagicEffect.name

Localized name of the effect

MagicEffect.negativeLight

True if the effect casts negative light

MagicEffect.nonRecastable

If set, this effect cannot be re-applied until it has ended. This is used by bound equipment spells.

MagicEffect.onSelf

True if the effect can be cast on self

MagicEffect.onTarget

True if the effect can be cast on target

MagicEffect.onTouch

True if the effect can be cast on touch

MagicEffect.particle

Identifier of the particle texture

MagicEffect.school

Skill ID that is this effect's school

MagicEffect.speed

Projectile speed

MagicEffect.unreflectable

True if the effect cannot be reflected

## Type `MagicEffectId`

MagicEffectId.AbsorbAttribute

"absorbattribute"

MagicEffectId.AbsorbFatigue

"absorbfatigue"

MagicEffectId.AbsorbHealth

"absorbhealth"

MagicEffectId.AbsorbMagicka

"absorbmagicka"

MagicEffectId.AbsorbSkill

"absorbskill"

MagicEffectId.AlmsiviIntervention

"almsiviintervention"

MagicEffectId.Blind

"blind"

MagicEffectId.BoundBattleAxe

"boundbattleaxe"

MagicEffectId.BoundBoots

"boundboots"

MagicEffectId.BoundCuirass

"boundcuirass"

MagicEffectId.BoundDagger

"bounddagger"

MagicEffectId.BoundGloves

"boundgloves"

MagicEffectId.BoundHelm

"boundhelm"

MagicEffectId.BoundLongbow

"boundlongbow"

MagicEffectId.BoundLongsword

"boundlongsword"

MagicEffectId.BoundMace

"boundmace"

MagicEffectId.BoundShield

"boundshield"

MagicEffectId.BoundSpear

"boundspear"

MagicEffectId.Burden

"burden"

MagicEffectId.CalmCreature

"calmcreature"

MagicEffectId.CalmHumanoid

"calmhumanoid"

MagicEffectId.Chameleon

"chameleon"

MagicEffectId.Charm

"charm"

MagicEffectId.CommandCreature

"commandcreature"

MagicEffectId.CommandHumanoid

"commandhumanoid"

MagicEffectId.Corprus

"corprus"

MagicEffectId.CureBlightDisease

"cureblightdisease"

MagicEffectId.CureCommonDisease

"curecommondisease"

MagicEffectId.CureCorprusDisease

"curecorprusdisease"

MagicEffectId.CureParalyzation

"cureparalyzation"

MagicEffectId.CurePoison

"curepoison"

MagicEffectId.DamageAttribute

"damageattribute"

MagicEffectId.DamageFatigue

"damagefatigue"

MagicEffectId.DamageHealth

"damagehealth"

MagicEffectId.DamageMagicka

"damagemagicka"

MagicEffectId.DamageSkill

"damageskill"

MagicEffectId.DemoralizeCreature

"demoralizecreature"

MagicEffectId.DemoralizeHumanoid

"demoralizehumanoid"

MagicEffectId.DetectAnimal

"detectanimal"

MagicEffectId.DetectEnchantment

"detectenchantment"

MagicEffectId.DetectKey

"detectkey"

MagicEffectId.DisintegrateArmor

"disintegratearmor"

MagicEffectId.DisintegrateWeapon

"disintegrateweapon"

MagicEffectId.Dispel

"dispel"

MagicEffectId.DivineIntervention

"divineintervention"

MagicEffectId.DrainAttribute

"drainattribute"

MagicEffectId.DrainFatigue

"drainfatigue"

MagicEffectId.DrainHealth

"drainhealth"

MagicEffectId.DrainMagicka

"drainmagicka"

MagicEffectId.DrainSkill

"drainskill"

MagicEffectId.ExtraSpell

"extraspell"

MagicEffectId.Feather

"feather"

MagicEffectId.FireDamage

"firedamage"

MagicEffectId.FireShield

"fireshield"

MagicEffectId.FortifyAttack

"fortifyattack"

MagicEffectId.FortifyAttribute

"fortifyattribute"

MagicEffectId.FortifyFatigue

"fortifyfatigue"

MagicEffectId.FortifyHealth

"fortifyhealth"

MagicEffectId.FortifyMagicka

"fortifymagicka"

MagicEffectId.FortifyMaximumMagicka

"fortifymaximummagicka"

MagicEffectId.FortifySkill

"fortifyskill"

MagicEffectId.FrenzyCreature

"frenzycreature"

MagicEffectId.FrenzyHumanoid

"frenzyhumanoid"

MagicEffectId.FrostDamage

"frostdamage"

MagicEffectId.FrostShield

"frostshield"

MagicEffectId.Invisibility

"invisibility"

MagicEffectId.Jump

"jump"

MagicEffectId.Levitate

"levitate"

MagicEffectId.Light

"light"

MagicEffectId.LightningShield

"lightningshield"

MagicEffectId.Lock

"lock"

MagicEffectId.Mark

"mark"

MagicEffectId.NightEye

"nighteye"

MagicEffectId.Open

"open"

MagicEffectId.Paralyze

"paralyze"

MagicEffectId.Poison

"poison"

MagicEffectId.RallyCreature

"rallycreature"

MagicEffectId.RallyHumanoid

"rallyhumanoid"

MagicEffectId.Recall

"recall"

MagicEffectId.Reflect

"reflect"

MagicEffectId.RemoveCurse

"removecurse"

MagicEffectId.ResistBlightDisease

"resistblightdisease"

MagicEffectId.ResistCommonDisease

"resistcommondisease"

MagicEffectId.ResistCorprusDisease

"resistcorprusdisease"

MagicEffectId.ResistFire

"resistfire"

MagicEffectId.ResistFrost

"resistfrost"

MagicEffectId.ResistMagicka

"resistmagicka"

MagicEffectId.ResistNormalWeapons

"resistnormalweapons"

MagicEffectId.ResistParalysis

"resistparalysis"

MagicEffectId.ResistPoison

"resistpoison"

MagicEffectId.ResistShock

"resistshock"

MagicEffectId.RestoreAttribute

"restoreattribute"

MagicEffectId.RestoreFatigue

"restorefatigue"

MagicEffectId.RestoreHealth

"restorehealth"

MagicEffectId.RestoreMagicka

"restoremagicka"

MagicEffectId.RestoreSkill

"restoreskill"

MagicEffectId.Sanctuary

"sanctuary"

MagicEffectId.Shield

"shield"

MagicEffectId.ShockDamage

"shockdamage"

MagicEffectId.Silence

"silence"

MagicEffectId.SlowFall

"slowfall"

MagicEffectId.Soultrap

"soultrap"

MagicEffectId.Sound

"sound"

MagicEffectId.SpellAbsorption

"spellabsorption"

MagicEffectId.StuntedMagicka

"stuntedmagicka"

MagicEffectId.SummonAncestralGhost

"summonancestralghost"

MagicEffectId.SummonBear

"summonbear"

MagicEffectId.SummonBonelord

"summonbonelord"

MagicEffectId.SummonBonewalker

"summonbonewalker"

MagicEffectId.SummonBonewolf

"summonbonewolf"

MagicEffectId.SummonCenturionSphere

"summoncenturionsphere"

MagicEffectId.SummonClannfear

"summonclannfear"

MagicEffectId.SummonCreature04

"summoncreature04"

MagicEffectId.SummonCreature05

"summoncreature05"

MagicEffectId.SummonDaedroth

"summondaedroth"

MagicEffectId.SummonDremora

"summondremora"

MagicEffectId.SummonFabricant

"summonfabricant"

MagicEffectId.SummonFlameAtronach

"summonflameatronach"

MagicEffectId.SummonFrostAtronach

"summonfrostatronach"

MagicEffectId.SummonGoldenSaint

"summongoldensaint"

MagicEffectId.SummonGreaterBonewalker

"summongreaterbonewalker"

MagicEffectId.SummonHunger

"summonhunger"

MagicEffectId.SummonScamp

"summonscamp"

MagicEffectId.SummonSkeletalMinion

"summonskeletalminion"

MagicEffectId.SummonStormAtronach

"summonstormatronach"

MagicEffectId.SummonWingedTwilight

"summonwingedtwilight"

MagicEffectId.SummonWolf

"summonwolf"

MagicEffectId.SunDamage

"sundamage"

MagicEffectId.SwiftSwim

"swiftswim"

MagicEffectId.Telekinesis

"telekinesis"

MagicEffectId.TurnUndead

"turnundead"

MagicEffectId.Vampirism

"vampirism"

MagicEffectId.WaterBreathing

"waterbreathing"

MagicEffectId.WaterWalking

"waterwalking"

MagicEffectId.WeaknessToBlightDisease

"weaknesstoblightdisease"

MagicEffectId.WeaknessToCommonDisease

"weaknesstocommondisease"

MagicEffectId.WeaknessToCorprusDisease

"weaknesstocorprusdisease"

MagicEffectId.WeaknessToFire

"weaknesstofire"

MagicEffectId.WeaknessToFrost

"weaknesstofrost"

MagicEffectId.WeaknessToMagicka

"weaknesstomagicka"

MagicEffectId.WeaknessToNormalWeapons

"weaknesstonormalweapons"

MagicEffectId.WeaknessToPoison

"weaknesstopoison"

MagicEffectId.WeaknessToShock

"weaknesstoshock"

## Type `MagicEffectWithParams`

MagicEffectWithParams.affectedAttribute

Optional attribute ID

MagicEffectWithParams.affectedSkill

Optional skill ID

MagicEffectWithParams.area

MagicEffectWithParams.duration

MagicEffectWithParams.effect

#MagicEffect

MagicEffectWithParams.id

ID of the associated #MagicEffect

MagicEffectWithParams.index

Index of this effect within the original list of #MagicEffectWithParams of the spell/enchantment/potion this effect came from.

MagicEffectWithParams.magnitudeMax

MagicEffectWithParams.magnitudeMin

MagicEffectWithParams.range

## Type `MagicSchoolData`

MagicSchoolData.areaSound

VFS path to the area sound

MagicSchoolData.boltSound

VFS path to the bolt sound

MagicSchoolData.castSound

VFS path to the cast sound

MagicSchoolData.failureSound

VFS path to the failure sound

MagicSchoolData.hitSound

VFS path to the hit sound

MagicSchoolData.name

Human-readable name

## Type `ObjectOwner`

ObjectOwner.factionId

Faction who owns the object (nil if missing). Global and self scripts can set the value.

ObjectOwner.factionRank

Rank required to be allowed to pick up the object (`nil` if any rank is allowed). Global and self scripts can set the value.

ObjectOwner.recordId

NPC who owns the object (nil if missing). Global and self scripts can set the value.

## Type `PathGrid`

PathGrid:getPoints()

Get all points in this path grid.

## Type `PathGridPoint`

PathGridPoint.autoGenerated

True if this node was automatically generated in the editor.

PathGridPoint.connections

A list of points connected to this point.

PathGridPoint.relativePosition

The point's position relative to the cell's origin. An exterior cell's origin is its southwest corner.

## Type `RegionRecord`

RegionRecord.id

Region ID

RegionRecord.mapColor

Editor map color for this region.

RegionRecord.name

Region display name

RegionRecord.sleepList

A leveled creature list used when sleeping outdoors in this region

RegionRecord.sounds

A read-only list of ambient sound references for this region.
Each reference includes a chance and a resolved link to the full sound record.

RegionRecord.weatherProbabilities

A table mapping WeatherRecord.recordIds to their probability (0–100), should sum to 100.
Valid weather ids include:
`"clear"`, `"cloudy"`, `"foggy"`, `"overcast"`, `"rain"`, `"thunderstorm"`, `"ashstorm"`, `"blight"`, `"snow"`, `"blizzard"`

## Type `RegionSoundRef`

RegionSoundRef.chance

Multiplicative percentage used to determine whether to play the sound

RegionSoundRef.soundId

Sound record ID

## Type `Regions`

Regions.records

A read-only list of all #RegionRecords in the world database.

## Type `Skill`

Skill.record(recordId)

Returns a read-only #SkillRecord

Skill.records

A read-only list of all #SkillRecords in the world database, may be indexed by recordId.
Implements iterables#List of #SkillRecord.

## Type `SkillRecord`

SkillRecord.attribute

The id of the skill's governing attribute

SkillRecord.description

Human-readable description

SkillRecord.icon

VFS path to the icon

SkillRecord.id

Record id

SkillRecord.name

Human-readable name

SkillRecord.school

Optional magic school

SkillRecord.skillGain

Table of the 4 possible skill gain values. See SkillProgression#SkillUseType.

SkillRecord.specialization

Skill specialization. Either combat, magic, or stealth.

## Type `Sound`

Sound.isEnabled()

Checks if sound system is enabled (any functions to play sounds are no-ops when it is disabled).

Sound.isSayActive(object)

Check if an animated voiceover is playing

Sound.isSoundFilePlaying(fileName, object)

Check if a sound file is playing on the given object

Sound.isSoundPlaying(soundId, object)

Check if a sound is playing on the given object

Sound.playSound3d(soundId, object, options)

Play a 3D sound, attached to object

In local scripts can be used only on self.

Sound.playSoundFile3d(fileName, object, options)

Play a 3D sound file, attached to object

In local scripts can be used only on self.

Sound.records

List of all #SoundRecords.

Sound.say(fileName, object, text)

Play an animated voiceover.

Sound.stopSay(fileName, object)

Stop an animated voiceover

In local scripts can be used only on self.

Sound.stopSound3d(soundId, object)

Stop a 3D sound, attached to object

In local scripts can be used only on self.

Sound.stopSoundFile3d(fileName, object)

Stop a 3D sound file, attached to object

In local scripts can be used only on self.

## Type `SoundRecord`

SoundRecord.fileName

Normalized path to sound file in VFS

SoundRecord.id

Sound id

SoundRecord.maxRange

Raw maximal range value, from 0 to 255

SoundRecord.minRange

Raw minimal range value, from 0 to 255

SoundRecord.volume

Raw sound volume, from 0 to 255

## Type `Spell`

Spell.alwaysSucceedFlag

If set, the spell should ignore skill checks and always succeed.

Spell.autocalcFlag

(DEPRECATED, use isAutocalc) If set, the casting cost should be computed based on the effect list rather than read from the cost field

Spell.cost

Spell.effects

The effects (#MagicEffectWithParams) of the spell

Spell.id

Spell id

Spell.isAutocalc

If set, the casting cost should be computed based on the effect list rather than read from the cost field

Spell.name

Spell name

Spell.starterSpellFlag

If set, the spell can be selected as a player's starting spell.

Spell.type

#SpellType

## Type `SpellRange`

SpellRange.Self

Applied on self

SpellRange.Target

Ranged spell

SpellRange.Touch

On touch

## Type `SpellType`

SpellType.Ability

Innate ability, always in effect

SpellType.Blight

Blight disease

SpellType.Curse

Curse

SpellType.Disease

Common disease

SpellType.Power

Power, can be used once a day

SpellType.Spell

Normal spell, must be cast and costs mana

## Type `Spells`

Spells.createRecordDraft(spell)

Creates a #Spell without adding it to the world database.

Spells.records

List of all #Spells.

## Type `Stats`

Stats.Attribute

#Attribute functions

Stats.Skill

#Skill functions

## Type `TeleportOptions`

TeleportOptions.onGround

If true, adjust destination position to the ground.

TeleportOptions.rotation

New rotation; if missing, then the current rotation is used.

## Type `TimeOfDayInterpolatorColor`

TimeOfDayInterpolatorColor.day

TimeOfDayInterpolatorColor.night

TimeOfDayInterpolatorColor.sunrise

TimeOfDayInterpolatorColor.sunset

## Type `TimeOfDayInterpolatorFloat`

TimeOfDayInterpolatorFloat.day

TimeOfDayInterpolatorFloat.night

TimeOfDayInterpolatorFloat.sunrise

TimeOfDayInterpolatorFloat.sunset

## Type `Weather`

Weather.changeWeather(regionId, weather)

Change the weather

Weather.getCurrent(cell)

Get the current weather

Weather.getCurrentStormDirection(cell)

Get the current storm direction taking weather transition into account.

Weather.getCurrentSunLightDirection(cell)

Get the current direction of the light of the sun.

Weather.getCurrentSunPercentage(cell)

Get the current sun percentage taking weather transition into account.

Weather.getCurrentSunVisibility(cell)

Get the current sun visibility taking weather transition into account.

Weather.getCurrentWindSpeed(cell)

Get the current wind speed taking weather transition into account.

Weather.getNext(cell)

Get the next weather if any

Weather.getTransition(cell)

Get current weather transition value

Weather.records

List of all #WeatherRecords.

## Type `WeatherRecord`

WeatherRecord.ambientColor

WeatherRecord.ambientLoopSoundID

WeatherRecord.cloudSpeed

WeatherRecord.cloudTexture

WeatherRecord.cloudsMaximumPercent

Affects the speed of weather transitions (0, 1]

WeatherRecord.distantLandFogFactor

WeatherRecord.distantLandFogOffset

WeatherRecord.fogColor

WeatherRecord.glareView

Strength of the sun glare [0, 1]

WeatherRecord.isStorm

Controls whether the weather is considered a storm for animation and movement purposes

WeatherRecord.landFogDepth

WeatherRecord.name

Read-only weather name

WeatherRecord.particleEffect

Will return nil if weather has no particleEffect

WeatherRecord.rainDiameter

The area around the player to spawn rain in

WeatherRecord.rainEffect

Will return nil if weather has no rainEffect

WeatherRecord.rainEntranceSpeed

The number of seconds between rain particle batches being created

WeatherRecord.rainLoopSoundID

WeatherRecord.rainMaxHeight

The maximum height relative to the player to spawn rain at

WeatherRecord.rainMaxRaindrops

The maximum number of rain particle batches to create every rainEntranceSpeed

WeatherRecord.rainMinHeight

The minimum height relative to the player to spawn rain at

WeatherRecord.rainSpeed

The speed at which rain falls

WeatherRecord.recordId

WeatherRecord.scriptId

Read-only ID used in mwscript and dialogue

WeatherRecord.skyColor

WeatherRecord.stormDirection

WeatherRecord.sunColor

WeatherRecord.sunDiscSunsetColor

WeatherRecord.thunderSoundID

A read-only array containing the recordIds of the thunder sounds

WeatherRecord.windSpeed

Affects the angle of falling rain

## Type `core`

### Field(s)

#number

core.API_REVISION

The revision of OpenMW's Lua API.

It is an integer that is incremented every time the API is changed. See the actual value at the top of the page.

#ContentFiles

core.contentFiles

#ContentFiles: functions working with the list of currently loaded content files.

#Dialogue

core.dialogue

#Dialogue: Dialogue.

Not available in load scripts.

#Factions

core.factions

#Factions: Factions.

Not available in load scripts.

core.getFormId(contentFile, index)

Construct FormId string from content file name and the index in the file.

In ESM3 games (e.g. Morrowind) FormIds are used to reference game objects.
In ESM4 games (e.g. Skyrim) FormIds are used both for game objects and as record ids.

### Parameters

-
` #string contentFile `:

-
` #number index `:

### Return value

#string:

### Usages

-

`if obj.recordId == core.getFormId('Skyrim.esm', 0x4d7da) then ... end`

-

`-- In ESM3 content files (e.g. Morrowind) ids are human-readable strings
obj.owner.factionId = 'blades'
-- In ESM4 (e.g. Skyrim) ids should be constructed using `core.getFormId`:
obj.owner.factionId = core.getFormId('Skyrim.esm', 0x72834)`

-

`-- local scripts
local obj = nearby.getObjectByFormId(core.getFormId('Morrowind.esm', 128964))`

-

`-- global scripts
local obj = world.getObjectByFormId(core.getFormId('Morrowind.esm', 128964))`

core.getGMST(setting)

Get a game setting with given name (from GMST ESM records or from openmw.cfg).

Not available in load scripts.

### Parameter

-
` #string setting `:
Setting name

### Return value

#any:

### Usages

-

`local skillBonus = core.getGMST('fMinorSkillBonus') -- get a numeric GMST from ESM data`

-

`local jailFormatString = core.getGMST('sNotifyMessage42') -- get a string GMST from ESM data`

-

`local bloodTextureName = core.getGMST('Blood_Texture_1') -- get a "fallback" parameter value from openmw.cfg (always a string)`

core.getGameDifficulty()

The game's difficulty setting.

### Return value

#number:

core.getGameTime()

Game time in seconds.

Not available in load scripts.

### Return value

#number:

core.getGameTimeScale()

The scale of game time relative to simulation time.

Not available in load scripts.

### Return value

#number:

core.getRealFrameDuration()

Frame duration in seconds.

Not available in global or load scripts.

### Return value

#number:

core.getRealTime()

Real time in seconds; starting point is not fixed (can be time since last reboot), use only for measuring intervals.

For Unix time use `os.time()`. Not available in load scripts.

### Return value

#number:

core.getSimulationTime()

Simulation time in seconds.

The number of simulation seconds passed in the game world since starting a new game. Not available in load scripts.

### Return value

#number:

core.getSimulationTimeScale()

The scale of simulation time relative to real time.

Not available in load scripts.

### Return value

#number:

core.isWorldPaused()

Whether the world is paused.

Not available in load scripts.

### Return value

#boolean:

core.l10n(context, fallbackLocale)

Return l10n formatting function for the given context.

Localisation files (containing the message names and translations) should be stored in
VFS as files of the form `l10n/<ContextName>/<Locale>.yaml`.

See Localisation for details of the localisation file structure.

When calling the l10n formatting function, if no localisation can be found for any of the requested locales then
the message key will be returned instead (and formatted, if possible).
This makes it possible to use the source strings as message identifiers.

If you do not use the source string as a message identifier you should instead make certain to include
a fallback locale with a complete set of messages.

### Parameters

-
` #string context `:
l10n context; recommended to use the name of the mod.

` This must match the <ContextName> directory in the VFS which stores the localisation files.
`

-
` #string fallbackLocale `:
The source locale containing the default messages

` If omitted defaults to "en".
`

### Return value

#function:

### Usages

-

`# DataFiles/l10n/MyMod/en.yaml
good_morning: 'Good morning.'
you_have_arrows: |-
{count, plural,
one {You have one arrow.}
other {You have {count} arrows.}
}`

-

`# DataFiles/l10n/MyMod/de.yaml
good_morning: "Guten Morgen."
you_have_arrows: |-
{count, plural,
one {Du hast ein Pfeil.}
other {Du hast {count} Pfeile.}
}
"Hello {name}!": "Hallo {name}!"`

-

`-- Usage in Lua
local myMsg = core.l10n('MyMod', 'en')
print( myMsg('good_morning') )
print( myMsg('you_have_arrows', {count=5}) )
print( myMsg('Hello {name}!', {name='World'}) )`

#Land

core.land

#Land: Functions for interacting with land data.

Not available in load scripts.

#Magic

core.magic

#Magic: spells and spell effects.

Not available in load scripts.

#MWScript

core.mwscripts

#MWScripts: MWScripts.

Not available in load scripts.

core.quit()

Terminates the game and quits to the OS.

Should be used only for testing purposes. Not available in load scripts.

#Regions

core.regions

#Regions: Regions.

Not available in load scripts.

core.sendGlobalEvent(eventName, eventData)

Send an event to global scripts.

Note: in menu scripts, errors if the game is not running (check openmw.menu#menu.getState.) Not available in load scripts.

### Parameters

-
` #string eventName `:

-
` eventData `:

#Sound

core.sound

#Sound: Sounds and Speech.

Not available in load scripts.

#Stats

core.stats

#Stats: stats.

Not available in load scripts.

#Weather

core.weather

#Weather: Weather.

Not available in load scripts.

## Type `ActiveEffect`

### Field(s)

#string

ActiveEffect.affectedAttribute

Optional attribute ID

#string

ActiveEffect.affectedSkill

Optional skill ID

#string

ActiveEffect.id

Effect id string

#number

ActiveEffect.magnitude

Current magnitude of the effect. Will be set to 0 when the effect is removed or expires.

#number

ActiveEffect.magnitudeBase

#number

ActiveEffect.magnitudeModifier

#string

ActiveEffect.name

Localized name of the effect

## Type `ActiveSpell`

### Field(s)

#string

ActiveSpell.activeSpellId

Uniquely identifies this active spell within the affected actor's list of active spells.

#boolean

ActiveSpell.affectsBaseValues

If set, this spell affects the base values of affected stats, rather than modifying current values.

#GameObject

ActiveSpell.caster

The caster object, or nil if the spell has no defined caster

#list<#ActiveSpellEffect>

ActiveSpell.effects

The active effects (#ActiveSpellEffect) of this spell.

#boolean

ActiveSpell.fromEquipment

If set, this spell is tied to an equipped item and can only be ended by unequipping the item.

#string

ActiveSpell.id

Record id of the spell or item used to cast the spell

#GameObject

ActiveSpell.item

The enchanted item used to cast the spell, or nil if the spell was not cast from an enchanted item. Note that if the spell was cast for a single-use enchantment such as a scroll, this will be nil.

#string

ActiveSpell.name

The spell or item display name

#boolean

ActiveSpell.stackable

If set, this spell can be applied multiple times. If not set, the same spell can only be applied once from the same source (where source is determined by caster + item). In vanilla rules, consumables are stackable while spells and enchantments are not.

#boolean

ActiveSpell.temporary

If set, this spell effect is temporary and should end on its own. Either after a single application or after its duration has run out.

## Type `ActiveSpellEffect`

### Field(s)

#string

ActiveSpellEffect.affectedAttribute

Optional attribute ID

#string

ActiveSpellEffect.affectedSkill

Optional skill ID

#number

ActiveSpellEffect.duration

Total duration in seconds of this spell effect, should not be confused with remaining duration. Or nil if the effect is not temporary.

#number

ActiveSpellEffect.durationLeft

Remaining duration in seconds of this spell effect, or nil if the effect is not temporary.

#string

ActiveSpellEffect.id

Magic effect id

#number

ActiveSpellEffect.index

Index of this effect within the original list of #MagicEffectWithParams of the spell/enchantment/potion this effect came from.

#number

ActiveSpellEffect.magnitudeThisFrame

The magnitude of the effect in the current frame. This will be a new random number between minMagnitude and maxMagnitude every frame. Or nil if the effect has no magnitude.

#number

ActiveSpellEffect.maxMagnitude

The maximum magnitude of this effect, or nil if the effect has no magnitude.

#number

ActiveSpellEffect.minMagnitude

The minimum magnitude of this effect, or nil if the effect has no magnitude.

#string

ActiveSpellEffect.name

Localized name of the effect

## Type `Attribute`

`core.stats.Attribute`

### Usages

-

`local record = core.stats.Attribute.records['example_recordid']`

-

`local record = core.stats.Attribute.records[1]`

### Field(s)

Attribute.record(recordId)

Returns a read-only #AttributeRecord

### Parameter

-
` #string recordId `:

### Return value

#AttributeRecord:

#list<#AttributeRecord>

Attribute.records

A read-only list of all #AttributeRecords in the world database, may be indexed by recordId.
Implements iterables#List of #AttributeRecord.

## Type `AttributeRecord`

### Field(s)

#string

AttributeRecord.description

Human-readable description

#string

AttributeRecord.icon

VFS path to the icon

#string

AttributeRecord.id

Record id

#string

AttributeRecord.name

Human-readable name

## Type `Cell`

A cell of the game world.

### Field(s)

#string

Cell.displayName

Human-readable cell name (takes into account *.cel file localizations). Can be an empty string.

Cell:getAll(type)

Get all objects of given type from the cell; Only available from global scripts.

### Parameter

-
` type `:
(optional) object type (see openmw.types#types)

### Return value

#ObjectList:

### Usage

`local type = require('openmw.types')
local all = cell:getAll()
local weapons = cell:getAll(types.Weapon)`

#number

Cell.gridX

Index of the cell by X (only for exteriors).

#number

Cell.gridY

Index of the cell by Y (only for exteriors).

#boolean

Cell.hasSky

True if in this cell sky should be rendered.

Cell:hasTag(tag)

Returns true if the cell has given tag.

### Parameter

-
` #string tag `:
One of "QuasiExterior", "NoSleep".

### Return value

#boolean:

#boolean

Cell.hasWater

True if the cell contains water.

#string

Cell.id

Unique record ID of the cell, based on cell name for interiors and the worldspace for exteriors, or the formID of the cell for ESM4 cells.

#boolean

Cell.isExterior

Whether the cell is an exterior cell. "Exterior" means grid of cells where the player can seamless walk from one cell to another without teleports. QuasiExterior (interior with sky) is not an exterior.

Cell:isInSameSpace(object)

Returns true either if the cell contains the object or if the cell is an exterior and the object is also in an exterior.

### Parameter

-
` #GameObject object `:

### Return value

#boolean:

### Usage

`if obj1.cell:isInSameSpace(obj2) then
dist = (obj1.position - obj2.position):length()
else
-- the distance can't be calculated because the coordinates are in different spaces
end`

#boolean

Cell.isQuasiExterior

(DEPRECATED, use `hasTag("QuasiExterior")`) Whether the cell is a quasi exterior (like interior but with the sky and the weather).

#string

Cell.name

Name of the cell (can be empty string).

#PathGrid

Cell.pathGrid

The cell's #PathGrid if it has one.

#string

Cell.region

Region of the cell (can be nil).

#number

Cell.waterLevel

The water level of the cell. (nil if cell has no water).

#string

Cell.worldSpaceId

Id of the world space (can be nil).

## Type `ContentFiles`

Functions working with the list of currently loaded content files.

### Field(s)

ContentFiles.has(contentFile)

Check if the content file with given name present in the load order.

### Parameter

-
` #string contentFile `:

### Return value

#boolean:

ContentFiles.indexOf(contentFile)

Return the index of a specific content file in the load order (or `nil` if there is no such content file).

### Parameter

-
` #string contentFile `:

### Return value

#number:

#list<#string>

ContentFiles.list

The current load order (list of content file names).

## Type `Dialogue`

### Field(s)

#DialogueConditionOperator

Dialogue.CONDITION_OPERATOR

Possible #DialogueConditionOperator values

#DialogueConditionType

Dialogue.CONDITION_TYPE

Possible #DialogueConditionType values

Dialogue.greeting

#DialogueRecords functions for greeting read-only records.

### Usages

-

`--print ids of all greeting records
for _, greetingRecord in pairs(core.dialogue.greeting.records) do
print(greetingRecord.id)
end`

-

`--print all NPC lines for "greeting 0"
for idx, greetingInfo in pairs(core.dialogue.greeting.records["greeting 0"].infos) do
print(idx, greetingInfo.text)
end`

Dialogue.journal

#DialogueRecords functions for journal (quest) read-only records.

### Usages

-

`--print the name of the record, which is a capitalized version of its id
print(core.dialogue.journal.records["ms_fargothring"].name) -- MS_FargothRing`

-

`--print ids of all journal records
for _, journalRecord in pairs(core.dialogue.journal.records) do
print(journalRecord.id)
end`

-

`--print quest names for all quests the player has inside a player script
for _, quest in pairs(types.Player.quests(self)) do
print(quest.id, core.dialogue.journal.records[quest.id].questName)
end`

Dialogue.persuasion

#DialogueRecords functions for persuasion read-only records.

### Usages

-

`--print ids of all persuasion records
for _, persuasionRecord in pairs(core.dialogue.persuasion.records) do
print(persuasionRecord.id)
end`

-

`--print all NPC lines for "admire success"
for idx, persuasionInfo in pairs(core.dialogue.persuasion.records["admire success"].infos) do
print(idx, persuasionInfo.text)
end`

Dialogue.topic

#DialogueRecords functions for topic read-only records.

### Usages

-

`--print ids of all topic records
for _, topicRecord in pairs(core.dialogue.topic.records) do
print(topicRecord.id)
end`

-

`--print all NPC lines for "vivec"
for idx, topicInfo in pairs(core.dialogue.topic.records["vivec"].infos) do
print(idx, topicInfo.text)
end`

Dialogue.voice

#DialogueRecords functions for voice read-only records.

### Usages

-

`--print ids of all voice records
for _, voiceRecord in pairs(core.dialogue.voice.records) do
print(voiceRecord.id)
end`

-

`--print all NPC lines & sounds for "flee"
for idx, voiceInfo in pairs(core.dialogue.voice.records["flee"].infos) do
print(idx, voiceInfo.text, voiceInfo.sound)
end`

## Type `DialogueConditionOperator`

`core.dialogue.CONDITION_OPERATOR`

### Field(s)

#number

DialogueConditionOperator.Equal

==

#number

DialogueConditionOperator.Greater

#number

DialogueConditionOperator.GreaterEqual

=

#number

DialogueConditionOperator.Less

<

#number

DialogueConditionOperator.LessEqual

<=

#number

DialogueConditionOperator.NotEqual

!=

## Type `DialogueConditionType`

`core.dialogue.CONDITION_TYPE`

### Field(s)

#number

DialogueConditionType.Alarm

The speaker's current alarm

#number

DialogueConditionType.Alarmed

Whether the speaker was alarmed by the player's crime

#number

DialogueConditionType.Attacked

Whether the speaker was attacked

#number

DialogueConditionType.Choice

The choice index

#number

DialogueConditionType.CreatureTarget

Whether the speaker is targeting a creature

#number

DialogueConditionType.Dead

The number of dead actors of the given DialogueInfoCondition.recordId

#number

DialogueConditionType.Detected

Whether the speaker has detected the player

#number

DialogueConditionType.FacReactionHighest

Highest faction reaction from the speaker's primary faction to the player's factions

#number

DialogueConditionType.FacReactionLowest

Lowest faction reaction from the speaker's primary faction to the player's factions

#number

DialogueConditionType.FactionRankDifference

The difference between the player's rank in the speaker's primary faction and the speaker's

#number

DialogueConditionType.Fight

The speaker's current fight

#number

DialogueConditionType.Flee

The speaker's current flee

#number

DialogueConditionType.FriendHit

The number of times the player has hit the speaker follower

#number

DialogueConditionType.Global

A comparison to the DialogueInfoCondition.variableName global variable

#number

DialogueConditionType.HealthPercent

The speaker's health percentage

#number

DialogueConditionType.Hello

The speaker's current hello

#number

DialogueConditionType.Item

The number of copies of DialogueInfoCondition.recordId the player is carrying

#number

DialogueConditionType.Journal

A comparison to the player's DialogueInfoCondition.recordId journal index

#number

DialogueConditionType.Level

The speaker's level

#number

DialogueConditionType.Local

A comparison to the speaker's DialogueInfoCondition.variableName local variable

#number

DialogueConditionType.NotCell

The player's cell name should not start with DialogueInfoCondition.cellName

#number

DialogueConditionType.NotClass

The speaker's class should not match DialogueInfoCondition.recordId

#number

DialogueConditionType.NotFaction

The speaker's faction ID should not match DialogueInfoCondition.recordId

#number

DialogueConditionType.NotId

The speaker's recordId should not match DialogueInfoCondition.recordId

#number

DialogueConditionType.NotLocal

A comparison to the speaker's DialogueInfoCondition.variableName local variable

#number

DialogueConditionType.NotRace

The speaker's race should not match DialogueInfoCondition.recordId

#number

DialogueConditionType.PcAcrobatics

The player's current acrobatics

#number

DialogueConditionType.PcAgility

The player's current agility

#number

DialogueConditionType.PcAlchemy

The player's current alchemy

#number

DialogueConditionType.PcAlteration

The player's current alteration

#number

DialogueConditionType.PcArmorer

The player's current armorer

#number

DialogueConditionType.PcAthletics

The player's current athletics

#number

DialogueConditionType.PcAxe

The player's current axe

#number

DialogueConditionType.PcBlightDisease

Check if the player has a blight disease

#number

DialogueConditionType.PcBlock

The player's current block

#number

DialogueConditionType.PcBluntWeapon

The player's current blunt weapon

#number

DialogueConditionType.PcClothingModifier

Check the combined value of the player's outfit

#number

DialogueConditionType.PcCommonDisease

Check if the player has a common disease

#number

DialogueConditionType.PcConjuration

The player's current conjuration

#number

DialogueConditionType.PcCorprus

Whether the player is affected by the Corprus magic effect

#number

DialogueConditionType.PcCrimeLevel

The player's bounty

#number

DialogueConditionType.PcDestruction

The player's current destruction

#number

DialogueConditionType.PcEnchant

The player's current enchant

#number

DialogueConditionType.PcEndurance

The player's current endurance

#number

DialogueConditionType.PcExpelled

Check whether the player has been expelled from the speaker's primary faction

#number

DialogueConditionType.PcFatigue

The player's current fatigue

#number

DialogueConditionType.PcGender

The player's gender

#number

DialogueConditionType.PcHandToHand

The player's current hand to hand

#number

DialogueConditionType.PcHealth

The player's current health

#number

DialogueConditionType.PcHealthPercent

The player's health percentage

#number

DialogueConditionType.PcHeavyArmor

The player's current heavy armor

#number

DialogueConditionType.PcIllusion

The player's current illusion

#number

DialogueConditionType.PcIntelligence

The player's current intelligence

#number

DialogueConditionType.PcLevel

The player's level

#number

DialogueConditionType.PcLightArmor

The player's current light armor

#number

DialogueConditionType.PcLongBlade

The player's current long blade

#number

DialogueConditionType.PcLuck

The player's current luck

#number

DialogueConditionType.PcMagicka

The player's current magicka

#number

DialogueConditionType.PcMarksman

The player's current marksman

#number

DialogueConditionType.PcMediumArmor

The player's current medium armor

#number

DialogueConditionType.PcMercantile

The player's current mercantile

#number

DialogueConditionType.PcMysticism

The player's current mysticism

#number

DialogueConditionType.PcPersonality

The player's current personality

#number

DialogueConditionType.PcReputation

The player's reputation

#number

DialogueConditionType.PcRestoration

The player's current restoration

#number

DialogueConditionType.PcSecurity

The player's current security

#number

DialogueConditionType.PcShortBlade

The player's current short blade

#number

DialogueConditionType.PcSneak

The player's current sneak

#number

DialogueConditionType.PcSpear

The player's current spear

#number

DialogueConditionType.PcSpeechcraft

The player's current speechcraft

#number

DialogueConditionType.PcSpeed

The player's current speed

#number

DialogueConditionType.PcStrength

The player's current strength

#number

DialogueConditionType.PcUnarmored

The player's current unarmored

#number

DialogueConditionType.PcVampire

Whether the player is affected by the Vampirism magic effect

#number

DialogueConditionType.PcWerewolfKills

The number of werewolves killed by the player

#number

DialogueConditionType.PcWillpower

The player's current willpower

#number

DialogueConditionType.RankRequirement

Check whether the player can advance in the speaker's primary faction

#number

DialogueConditionType.Reputation

The speaker's reputation

#number

DialogueConditionType.SameFaction

Check if the player is a member of the speaker's primary faction

#number

DialogueConditionType.SameGender

Check if the speaker's gender matches the player's

#number

DialogueConditionType.SameRace

Check if the speaker's race matches the player's

#number

DialogueConditionType.ShouldAttack

Whether the speaker would start combat with the player

#number

DialogueConditionType.TalkedToPc

Whether the speaker has talked to the player before

#number

DialogueConditionType.Weather

Checks the scriptId of the weather in the player's cell

#number

DialogueConditionType.Werewolf

Whether the speaker is in werewolf form

## Type `DialogueInfoCondition`

### Field(s)

#string

DialogueInfoCondition.cellName

The cell name to compare to

#DialogueConditionOperator

DialogueInfoCondition.operator

The #{#DialogueConditionOperator} to use in the comparison

#string

DialogueInfoCondition.recordId

The record ID to use in the comparison

#DialogueConditionType

DialogueInfoCondition.type

The condition's #DialogueConditionType

#number

DialogueInfoCondition.value

The value to compare to

#string

DialogueInfoCondition.variableName

The name of the global or local mwscript variable to compare to

## Type `DialogueRecord`

Depending on which store this read-only dialogue record is from, it may either be a journal, topic, greeting, persuasion or voice.

### Usages

-

`local journalId = core.dialogue.journal.records['A2_4_MiloGone'].id -- "a2_4_milogone"`

-

`local journalName = core.dialogue.journal.records['A2_4_MiloGone'].name -- "A2_4_MiloGone"`

-

`local questName = core.dialogue.journal.records['A2_4_MiloGone'].questName -- "Mehra Milo and the Lost Prophecies"`

### Field(s)

#string

DialogueRecord.id

Record identifier

#list<#DialogueRecordInfo>

DialogueRecord.infos

A read-only list containing all #DialogueRecordInfos for this record, in order.

#string

DialogueRecord.name

Same as id, but with upper cases preserved.

#string

DialogueRecord.questName

Non-nil only for journal records with available value. Holds the quest name for this journal entry. Same info may be available under `infos[1].text` as well, but this variable is made for convenience.

## Type `DialogueRecordInfo`

Holds the read-only data for one of many info entries inside a dialogue record.

Depending on the type of the dialogue record (journal, topic, greeting, persuasion or voice), it could be, for example, a single journal entry or a NPC dialogue line.

### Usages

-

`--Variable `aa` below is "Congratulations, %PCName. You are now %PCName the %NextPCRank." in vanilla MW:
local aa = core.dialogue.topic.records['advancement'].infos[100].text`

-

`--Variable `bb` below is "sound/vo/a/f/fle_af003.mp3" in vanilla MW:
local bb = core.dialogue.voice.records['flee'].infos[149].sound`

### Field(s)

#list<#DialogueInfoCondition>

DialogueRecordInfo.conditions

A read-only list of #DialogueInfoConditions.

Always nil for journal records.

#string

DialogueRecordInfo.filterActorClass

Speaker class allowing for this info entry to appear.

Always nil for journal records. Otherwise the nil value represents no conditions, i.e. no filtering applied using these criteria.

#number

DialogueRecordInfo.filterActorDisposition

Minimum speaker disposition allowing for this info entry to appear.

Always nil for journal records. Otherwise is a nonnegative number, with the zero value representing no conditions, i.e. no filtering applied using these criteria.

#string

DialogueRecordInfo.filterActorFaction

Faction of which the speaker must be a member for this info entry to appear.

Always nil for journal records. Otherwise the nil value represents no conditions, i.e. no filtering applied using these criteria.
Can return an empty string - this means that the actor must not be a member of any faction for this filtering to apply.

#number

DialogueRecordInfo.filterActorFactionRank

Minimum speaker's rank in their faction allowing for this info entry to appear.

Always nil for journal records. Otherwise the nil value represents no conditions, i.e. no filtering applied using these criteria.
Rank index starts from 1, matching the value in openmw_types#NPC.getFactionRank

#string

DialogueRecordInfo.filterActorGender

Speaker gender allowing for this info entry to appear: "male" or "female".

Always nil for journal records. Otherwise the nil value represents no conditions, i.e. no filtering applied using these criteria.

#string

DialogueRecordInfo.filterActorId

Speaker ID allowing for this info entry to appear.

Always nil for journal records. Otherwise the nil value represents no conditions, i.e. no filtering applied using these criteria.

#string

DialogueRecordInfo.filterActorRace

Speaker race allowing for this info entry to appear.

Always nil for journal records. Otherwise the nil value represents no conditions, i.e. no filtering applied using these criteria.

#string

DialogueRecordInfo.filterPlayerCell

Cell name prefix of location where the player must be for this info entry to appear.

Always nil for journal records. Otherwise the nil value represents no conditions, i.e. no filtering applied using these criteria.
"Prefix" means that the cell's name starting with this value shall pass the filtering. For example: `filterPlayerCell` being "Seyda Neen" does apply to the cell "Seyda Neen, Fargoth's House".

#string

DialogueRecordInfo.filterPlayerFaction

Faction of which the player must be a member for this info entry to appear.

Always nil for journal records. Otherwise the nil value represents no conditions, i.e. no filtering applied using these criteria.

#number

DialogueRecordInfo.filterPlayerFactionRank

Minimum player's rank in their faction allowing for this info entry to appear.

Always nil for journal records. Otherwise the nil value represents no conditions, i.e. no filtering applied using these criteria.
Rank index starts from 1, matching the value in openmw_types#NPC.getFactionRank

#string

DialogueRecordInfo.id

Identifier for this info entry. Is unique only within the #DialogueRecord it belongs to.

#boolean

DialogueRecordInfo.isQuestFinished

True if this info entry has the "Finished" flag checked.

Non-nil only for journal records.

#boolean

DialogueRecordInfo.isQuestName

True if this info entry has the "Quest Name" flag checked.

Non-nil only for journal records.
If true, then the #DialogueRecord, to which this info entry belongs, should have this info entry's DialogueRecordInfo.text value available in its DialogueRecord.questName.

#boolean

DialogueRecordInfo.isQuestRestart

True if this info entry has the "Restart" flag checked.

Non-nil only for journal records.

#number

DialogueRecordInfo.questStage

Quest stage (same as in openmw_types#PLAYERQuest.stage) this info entry is associated with.

Non-nil only for journal records.

#string

DialogueRecordInfo.resultScript

MWScript (full script text) executed when this info is chosen.

Always nil for journal records or if there is no value set.

#string

DialogueRecordInfo.sound

Sound file path for this info entry.

Always nil for journal records or if there is no sound set.

#string

DialogueRecordInfo.text

Text associated with this info entry.

## Type `DialogueRecords`

### Field(s)

#list<#DialogueRecord>

DialogueRecords.records

A read-only list of all #DialogueRecords in the world database, may be indexed by recordId, which doesn't have to be lowercase.

Implements iterables#List of #DialogueRecord.

### Usages

-

`local record = core.dialogue.journal.records['ms_fargothring']`

-

`local record = core.dialogue.journal.records['MS_FargothRing']`

-

`local record = core.dialogue.journal.records[1]`

-

`local record = core.dialogue.topic.records[1]`

-

`local record = core.dialogue.topic.records['background']`

-

`local record = core.dialogue.greeting.records[1]`

-

`local record = core.dialogue.greeting.records['greeting 0']`

-

`local record = core.dialogue.persuasion.records[1]`

-

`local record = core.dialogue.persuasion.records['admire success']`

-

`local record = core.dialogue.voice.records[1]`

-

`local record = core.dialogue.voice.records["flee"]`

## Type `Effects`

### Field(s)

#map<#number,#MagicEffect>

Effects.records

Map from #MagicEffectId to #MagicEffect

### Usages

-

`-- Print all harmful effects
for _, effect in pairs(core.magic.effects.records) do
if effect.harmful then
print(effect.name)
end
end`

-

`-- Look up the record of a specific effect and print its icon
local mgef = core.magic.effects.records[core.magic.EFFECT_TYPE.Reflect]
print('Reflect Icon: '..tostring(mgef.icon))`

## Type `Enchantment`

### Usage

`-- Getting the enchantment of an arbitrary item, if it has one
local function getRecord(item)
if item.type and item.type.record then
return item.type.record(item)
end
return nil
end
local function getEnchantment(item)
local record = getRecord(item)
if record and record.enchant then
return core.magic.enchantments.records[record.enchant]
end
return nil
end`

### Field(s)

#boolean

Enchantment.autocalcFlag

(DEPRECATED, use isAutocalc) If set, the casting cost should be computed based on the effect list rather than read from the cost field

#number

Enchantment.charge

Charge capacity. Should not be confused with current charge.

#number

Enchantment.cost

#list<#MagicEffectWithParams>

Enchantment.effects

The effects (#MagicEffectWithParams) of the enchantment

#string

Enchantment.id

Enchantment id

#boolean

Enchantment.isAutocalc

If set, the casting cost should be computed based on the effect list rather than read from the cost field

#number

Enchantment.type

#EnchantmentType

## Type `EnchantmentType`

`core.magic.ENCHANTMENT_TYPE`

### Field(s)

#number

EnchantmentType.CastOnStrike

Enchantment is cast on strike, if there is enough charge.

#number

EnchantmentType.CastOnUse

Enchantment is cast when used, if there is enough charge.

#number

EnchantmentType.CastOnce

Enchantment can be cast once, destroying the enchanted item.

#number

EnchantmentType.ConstantEffect

Enchantment is always active when equipped.

## Type `Enchantments`

### Field(s)

Enchantments.createRecordDraft(enchantment)

Creates an #Enchantment without adding it to the world database.

Use openmw_world#world.createRecord to add the record to the world.

### Parameter

-
` #Enchantment enchantment `:
A Lua table with the fields of an Enchantment, with an optional field `template` that accepts an #Enchantment as a base.

### Return value

#Enchantment:
A strongly typed Enchantment record.

#list<#Enchantment>

Enchantments.records

A read-only list of all #Enchantment records in the world database, may be indexed by recordId.

Implements iterables#List and iterables#Map of #Enchantment.

### Usages

-

`local enchantment = core.magic.enchantments.records['marara's boon'] -- get by id`

-

`local enchantment = core.magic.enchantments.records[1] -- get by index`

-

`-- Print all enchantments with constant effect
for _, ench in pairs(core.magic.enchantments.records) do
if ench.type == core.magic.ENCHANTMENT_TYPE.ConstantEffect then
print(ench.id)
end
end`

## Type `FactionRank`

Faction rank data record

### Field(s)

#list<#number>

FactionRank.attributeValues

Attributes values required to get this rank.

#number

FactionRank.factionReaction

(DEPRECATED) Returns the same as factionReputation.

#number

FactionRank.factionReputation

Required amount of faction reputation to reach this rank.

#number

FactionRank.favouredSkillValue

Secondary skill value required to get this rank.

#string

FactionRank.name

Faction name Rank display name

#number

FactionRank.primarySkillValue

Primary skill value required to get this rank.

## Type `FactionRecord`

Faction data record

### Field(s)

#list<#string>

FactionRecord.attributes

A read-only list containing IDs of attributes to advance ranks in the faction.

#boolean

FactionRecord.hidden

If true, the faction won't show in the player's skills menu

#string

FactionRecord.id

Faction id

#string

FactionRecord.name

Faction name

#list<#FactionRank>

FactionRecord.ranks

A read-only list containing data for all ranks in the faction, in order.

#map<#string,#number>

FactionRecord.reactions

A read-only map containing reactions of other factions to this faction.

#list<#string>

FactionRecord.skills

A read-only list containing IDs of skills to advance ranks in the faction.

## Type `Factions`

### Field(s)

#list<#FactionRecord>

Factions.records

A read-only list of all #FactionRecords in the world database.

### Usages

-

`local record = core.factions.records['example_recordid']`

-

`local record = core.factions.records[1]`

## Type `GameObject`

### Extends #userdata

Any object that exists in the game world and has a specific location.

Player, actors, items, and statics are game objects.

### Field(s)

GameObject:activateBy(actor)

Activate the object.

### Parameter

-
` #GameObject actor `:
The actor who activates the object

### Usage

`local self = require('openmw.self')
object:activateBy(self)`

GameObject:addScript(scriptPath, initData)

Add a new local script to the object.

Can be called only from a global script. Script should be specified in a content
file (omwgame/omwaddon/omwscripts) with a CUSTOM flag. Scripts can not be attached to Statics.

### Parameters

-
` #string scriptPath `:
Path to the script in OpenMW virtual filesystem.

-
` #table initData `:
(optional) Initialization data to be passed to onInit. If missed then Lua initialization data from content files will be used (if exists for this script).

#Cell

GameObject.cell

The cell where the object currently is. During loading a game and for objects in an inventory or a container `cell` is nil.

#string

GameObject.contentFile

Lowercase file name of the content file that defines this object; nil for dynamically created objects.

#number

GameObject.count

Count (>1 means a stack of objects).

#boolean

GameObject.enabled

Whether the object is enabled or disabled. Global scripts can set the value. Items in containers or inventories can't be disabled.

GameObject:getBoundingBox()

The axis aligned bounding box in world coordinates.

### Return value

openmw.util#Box:

#string

GameObject.globalVariable

Global Variable associated with this object (read only).

GameObject:hasScript(scriptPath)

Whether a script with given path is attached to this object.

Can be called only from a global script.

### Parameter

-
` #string scriptPath `:
Path to the script in OpenMW virtual filesystem.

### Return value

#boolean:

#string

GameObject.id

The unique id of this object (not record id), can be used as a key in a table.

GameObject:isValid()

Does the object still exist and is available.

Returns true if the object exists and loaded, and false otherwise. If false, then every
access to the object will raise an error.

### Return value

#boolean:

GameObject:moveInto(dest)

Moves an object into a container or an inventory.

Enables if was disabled.
Can be called only from a global script.

### Parameter

-
` #any dest `:
#Inventory or #GameObject

### Usages

-

`item:moveInto(types.Actor.inventory(actor))`

-

`item:moveInto(types.Container.content(container))`

-

`item:moveInto(container)`

#ObjectOwner

GameObject.owner

Ownership information

#GameObject

GameObject.parentContainer

Container or actor that contains (or has in inventory) this object. It is nil if the object is in a cell.

openmw.util#Vector3

GameObject.position

Object position.

#string

GameObject.recordId

Returns record ID of the object in lowercase.

GameObject:remove(count)

Removes an object or reduces a stack of objects.

Can be called only from a global script.

### Parameter

-
` #number count `:
(optional) the number of items to remove (if not specified then the whole stack)

GameObject:removeScript(scriptPath)

Removes script that was attached by `addScript`
Can be called only from a global script.

### Parameter

-
` #string scriptPath `:
Path to the script in OpenMW virtual filesystem.

openmw.util#Transform

GameObject.rotation

Object rotation.

#number

GameObject.scale

Object scale.

GameObject:sendEvent(eventName, eventData)

Send a local event to the object.

### Parameters

-
` #string eventName `:

-
` eventData `:

GameObject:setScale(scale)

Sets the object's scale.

Can be called only from a global script.

### Parameter

-
` #number scale `:
Scale desired in game.

GameObject:split(count)

Splits a stack of items.

Original stack is reduced by `count`. Returns a new stack with `count` items.
Can be called only from a global script.

### Parameter

-
` #number count `:
The number of items to return.

### Return value

#GameObject:

### Usage

`-- take 50 coins from `money` and put to the container `cont`
money:split(50):moveInto(types.Container.content(cont))`

#Cell

GameObject.startingCell

The object's original cell. Returns nil if `cell` of the object is nil.

openmw.util#Vector3

GameObject.startingPosition

The object original position

openmw.util#Transform

GameObject.startingRotation

The object original rotation

GameObject:teleport(cellOrName, position, options)

Moves the object to given cell and position.

Can be called only from a global script.
The effect is not immediate: the position will be updated only in the next
frame. Can be called only from a global script. Enables object if it was disabled.
Can be used to move objects from an inventory or a container to the world.

### Parameters

-
` #any cellOrName `:
A cell to define the destination worldspace; can be either #Cell, or cell name, or an empty string (empty string means the default exterior worldspace).
If the worldspace has multiple cells (i.e. an exterior), the destination cell is calculated using `position`.

-
` openmw.util#Vector3 position `:
New position.

-
` #TeleportOptions options `:
(optional) Either table #TeleportOptions or openmw.util#Transform rotation.

#any

GameObject.type

Type of the object (one of the tables from the package openmw.types#types).

## Type `Inventory`

Inventory of a player/NPC or a content of a container.

### Field(s)

Inventory:countOf(recordId)

The number of items with the given recordId.

### Parameter

-
` #string recordId `:

### Return value

#number:

Inventory:find(recordId)

Get first item with the given recordId from the inventory.

Returns nil if not found.

### Parameter

-
` #string recordId `:

### Return value

#GameObject:

### Usage

`inventory:find('gold_001')`

Inventory:findAll(recordId)

Get all items with the given recordId from the inventory.

### Parameter

-
` #string recordId `:

### Return value

#ObjectList:

### Usage

`for _, item in ipairs(inventory:findAll('common_shirt_01')) do ... end`

Inventory:getAll(type)

Get all items of the given type from the inventory.

### Parameter

-
` type `:
(optional) items type (see openmw.types#types)

### Return value

#ObjectList:

### Usage

`local types = require('openmw.types')
local self = require('openmw.self')
local playerInventory = types.Actor.inventory(self.object)
local all = playerInventory:getAll()
local weapons = playerInventory:getAll(types.Weapon)`

Inventory:isResolved()

Checks if the inventory has a resolved item list.

### Return value

#boolean:

### Usage

`inventory:isResolved()`

Inventory:resolve()

Will resolve the inventory, filling it with levelled items if applicable, making its contents permanent.

Must be used in a global script.

### Usage

`inventory:resolve()`

## Type `Land`

### Field(s)

Land.getHeightAt(position, cellOrId)

Get the terrain height at a given location.

### Parameters

-
` openmw.util#Vector3 position `:

-
` #any cellOrId `:
cell or cell id in their exterior world space to query

### Return value

#number:

Land.getTextureAt(position, cellOrId)

Get the terrain texture at a given location.

As textures are blended and
multiple textures can be at one specific position the texture whose center is
closest to the position will be returned.

### Parameters

-
` openmw.util#Vector3 position `:

-
` #any cellOrId `:
cell or cell id in their exterior world space to query

### Return values

-
#nil, #string:
Texture path or nil if one isn't defined

-
#nil, #string:
Plugin name or nil if failed to retrieve the texture

## Type `MWScript`

## Type `MWScriptRecord`

MWScript data record

### Field(s)

#string

MWScriptRecord.id

MWScript id

#string

MWScriptRecord.text

MWScript content

## Type `MWScripts`

### Field(s)

#list<#MWScriptRecord>

MWScripts.records

A read-only list of all #MWScriptRecords in the world database.

### Usages

-

`local record = core.mwscripts.records['example_recordid']`

-

`local record = core.mwscripts.records[1]`

## Type `Magic`

### Field(s)

#MagicEffectId

Magic.EFFECT_TYPE

Possible #MagicEffectId values

#EnchantmentType

Magic.ENCHANTMENT_TYPE

Possible #EnchantmentType values

#SpellRange

Magic.RANGE

Possible #SpellRange values

#SpellType

Magic.SPELL_TYPE

Possible #SpellType values

#Effects

Magic.effects

#Effects: Magic Effects

#Enchantments

Magic.enchantments

#Enchantments: Enchantments

#Spells

Magic.spells

#Spells: Spells

## Type `MagicEffect`

### Field(s)

#boolean

MagicEffect.allowsEnchanting

True if the effect is available for enchanting

#boolean

MagicEffect.allowsSpellmaking

True if the effect is available for spellmaking

#string

MagicEffect.areaSound

Identifier of the sound used for AOE spells

#string

MagicEffect.areaStatic

Identifier of the vfx static used for AOE spells

#number

MagicEffect.baseCost

#string

MagicEffect.bolt

Identifier of the projectile used for ranged spells

#string

MagicEffect.boltSound

Identifier of the projectile sound used for ranged spells

#string

MagicEffect.castSound

Identifier of the sound used for casting

#string

MagicEffect.castStatic

Identifier of the vfx static used for casting

#boolean

MagicEffect.casterLinked

If set, it is implied the magic effect links back to the caster in some way and should end immediately or never be applied if the caster dies or is not an actor.

openmw.util#Color

MagicEffect.color

#boolean

MagicEffect.continuousVfx

Whether the magic effect's vfx should loop or not

#string

MagicEffect.description

Localized description of the effect

#boolean

MagicEffect.harmful

If set, the effect is considered harmful and should elicit a hostile reaction from affected NPCs.

#boolean

MagicEffect.hasAttribute

True if the effect requires an attribute parameter

#boolean

MagicEffect.hasDuration

If set, the magic effect has a duration. As an example, divine intervention has no duration while fire damage does.

#boolean

MagicEffect.hasMagnitude

If set, the magic effect depends on a magnitude. As an example, cure common disease has no magnitude while chameleon does.

#boolean

MagicEffect.hasSkill

True if the effect requires a skill parameter

#string

MagicEffect.hitSound

Identifier of the sound used on hit

#string

MagicEffect.hitStatic

Identifier of the vfx static used on hit

#string

MagicEffect.icon

Effect Icon Path

#string

MagicEffect.id

Effect ID

#boolean

MagicEffect.isAppliedOnce

If set, the magic effect is applied fully on cast, rather than being continuously applied over the effect's duration. For example, chameleon is applied once, while fire damage is continuously applied for the duration.

#string

MagicEffect.name

Localized name of the effect

#boolean

MagicEffect.negativeLight

True if the effect casts negative light

#boolean

MagicEffect.nonRecastable

If set, this effect cannot be re-applied until it has ended. This is used by bound equipment spells.

#boolean

MagicEffect.onSelf

True if the effect can be cast on self

#boolean

MagicEffect.onTarget

True if the effect can be cast on target

#boolean

MagicEffect.onTouch

True if the effect can be cast on touch

#string

MagicEffect.particle

Identifier of the particle texture

#string

MagicEffect.school

Skill ID that is this effect's school

#number

MagicEffect.speed

Projectile speed

#boolean

MagicEffect.unreflectable

True if the effect cannot be reflected

## Type `MagicEffectId`

`core.magic.EFFECT_TYPE`

### Field(s)

#number

MagicEffectId.AbsorbAttribute

"absorbattribute"

#number

MagicEffectId.AbsorbFatigue

"absorbfatigue"

#number

MagicEffectId.AbsorbHealth

"absorbhealth"

#number

MagicEffectId.AbsorbMagicka

"absorbmagicka"

#number

MagicEffectId.AbsorbSkill

"absorbskill"

#number

MagicEffectId.AlmsiviIntervention

"almsiviintervention"

#number

MagicEffectId.Blind

"blind"

#number

MagicEffectId.BoundBattleAxe

"boundbattleaxe"

#number

MagicEffectId.BoundBoots

"boundboots"

#number

MagicEffectId.BoundCuirass

"boundcuirass"

#number

MagicEffectId.BoundDagger

"bounddagger"

#number

MagicEffectId.BoundGloves

"boundgloves"

#number

MagicEffectId.BoundHelm

"boundhelm"

#number

MagicEffectId.BoundLongbow

"boundlongbow"

#number

MagicEffectId.BoundLongsword

"boundlongsword"

#number

MagicEffectId.BoundMace

"boundmace"

#number

MagicEffectId.BoundShield

"boundshield"

#number

MagicEffectId.BoundSpear

"boundspear"

#number

MagicEffectId.Burden

"burden"

#number

MagicEffectId.CalmCreature

"calmcreature"

#number

MagicEffectId.CalmHumanoid

"calmhumanoid"

#number

MagicEffectId.Chameleon

"chameleon"

#number

MagicEffectId.Charm

"charm"

#number

MagicEffectId.CommandCreature

"commandcreature"

#number

MagicEffectId.CommandHumanoid

"commandhumanoid"

#number

MagicEffectId.Corprus

"corprus"

#number

MagicEffectId.CureBlightDisease

"cureblightdisease"

#number

MagicEffectId.CureCommonDisease

"curecommondisease"

#number

MagicEffectId.CureCorprusDisease

"curecorprusdisease"

#number

MagicEffectId.CureParalyzation

"cureparalyzation"

#number

MagicEffectId.CurePoison

"curepoison"

#number

MagicEffectId.DamageAttribute

"damageattribute"

#number

MagicEffectId.DamageFatigue

"damagefatigue"

#number

MagicEffectId.DamageHealth

"damagehealth"

#number

MagicEffectId.DamageMagicka

"damagemagicka"

#number

MagicEffectId.DamageSkill

"damageskill"

#number

MagicEffectId.DemoralizeCreature

"demoralizecreature"

#number

MagicEffectId.DemoralizeHumanoid

"demoralizehumanoid"

#number

MagicEffectId.DetectAnimal

"detectanimal"

#number

MagicEffectId.DetectEnchantment

"detectenchantment"

#number

MagicEffectId.DetectKey

"detectkey"

#number

MagicEffectId.DisintegrateArmor

"disintegratearmor"

#number

MagicEffectId.DisintegrateWeapon

"disintegrateweapon"

#number

MagicEffectId.Dispel

"dispel"

#number

MagicEffectId.DivineIntervention

"divineintervention"

#number

MagicEffectId.DrainAttribute

"drainattribute"

#number

MagicEffectId.DrainFatigue

"drainfatigue"

#number

MagicEffectId.DrainHealth

"drainhealth"

#number

MagicEffectId.DrainMagicka

"drainmagicka"

#number

MagicEffectId.DrainSkill

"drainskill"

#number

MagicEffectId.ExtraSpell

"extraspell"

#number

MagicEffectId.Feather

"feather"

#number

MagicEffectId.FireDamage

"firedamage"

#number

MagicEffectId.FireShield

"fireshield"

#number

MagicEffectId.FortifyAttack

"fortifyattack"

#number

MagicEffectId.FortifyAttribute

"fortifyattribute"

#number

MagicEffectId.FortifyFatigue

"fortifyfatigue"

#number

MagicEffectId.FortifyHealth

"fortifyhealth"

#number

MagicEffectId.FortifyMagicka

"fortifymagicka"

#number

MagicEffectId.FortifyMaximumMagicka

"fortifymaximummagicka"

#number

MagicEffectId.FortifySkill

"fortifyskill"

#number

MagicEffectId.FrenzyCreature

"frenzycreature"

#number

MagicEffectId.FrenzyHumanoid

"frenzyhumanoid"

#number

MagicEffectId.FrostDamage

"frostdamage"

#number

MagicEffectId.FrostShield

"frostshield"

#number

MagicEffectId.Invisibility

"invisibility"

#number

MagicEffectId.Jump

"jump"

#number

MagicEffectId.Levitate

"levitate"

#number

MagicEffectId.Light

"light"

#number

MagicEffectId.LightningShield

"lightningshield"

#number

MagicEffectId.Lock

"lock"

#number

MagicEffectId.Mark

"mark"

#number

MagicEffectId.NightEye

"nighteye"

#number

MagicEffectId.Open

"open"

#number

MagicEffectId.Paralyze

"paralyze"

#number

MagicEffectId.Poison

"poison"

#number

MagicEffectId.RallyCreature

"rallycreature"

#number

MagicEffectId.RallyHumanoid

"rallyhumanoid"

#number

MagicEffectId.Recall

"recall"

#number

MagicEffectId.Reflect

"reflect"

#number

MagicEffectId.RemoveCurse

"removecurse"

#number

MagicEffectId.ResistBlightDisease

"resistblightdisease"

#number

MagicEffectId.ResistCommonDisease

"resistcommondisease"

#number

MagicEffectId.ResistCorprusDisease

"resistcorprusdisease"

#number

MagicEffectId.ResistFire

"resistfire"

#number

MagicEffectId.ResistFrost

"resistfrost"

#number

MagicEffectId.ResistMagicka

"resistmagicka"

#number

MagicEffectId.ResistNormalWeapons

"resistnormalweapons"

#number

MagicEffectId.ResistParalysis

"resistparalysis"

#number

MagicEffectId.ResistPoison

"resistpoison"

#number

MagicEffectId.ResistShock

"resistshock"

#number

MagicEffectId.RestoreAttribute

"restoreattribute"

#number

MagicEffectId.RestoreFatigue

"restorefatigue"

#number

MagicEffectId.RestoreHealth

"restorehealth"

#number

MagicEffectId.RestoreMagicka

"restoremagicka"

#number

MagicEffectId.RestoreSkill

"restoreskill"

#number

MagicEffectId.Sanctuary

"sanctuary"

#number

MagicEffectId.Shield

"shield"

#number

MagicEffectId.ShockDamage

"shockdamage"

#number

MagicEffectId.Silence

"silence"

#number

MagicEffectId.SlowFall

"slowfall"

#number

MagicEffectId.Soultrap

"soultrap"

#number

MagicEffectId.Sound

"sound"

#number

MagicEffectId.SpellAbsorption

"spellabsorption"

#number

MagicEffectId.StuntedMagicka

"stuntedmagicka"

#number

MagicEffectId.SummonAncestralGhost

"summonancestralghost"

#number

MagicEffectId.SummonBear

"summonbear"

#number

MagicEffectId.SummonBonelord

"summonbonelord"

#number

MagicEffectId.SummonBonewalker

"summonbonewalker"

#number

MagicEffectId.SummonBonewolf

"summonbonewolf"

#number

MagicEffectId.SummonCenturionSphere

"summoncenturionsphere"

#number

MagicEffectId.SummonClannfear

"summonclannfear"

#number

MagicEffectId.SummonCreature04

"summoncreature04"

#number

MagicEffectId.SummonCreature05

"summoncreature05"

#number

MagicEffectId.SummonDaedroth

"summondaedroth"

#number

MagicEffectId.SummonDremora

"summondremora"

#number

MagicEffectId.SummonFabricant

"summonfabricant"

#number

MagicEffectId.SummonFlameAtronach

"summonflameatronach"

#number

MagicEffectId.SummonFrostAtronach

"summonfrostatronach"

#number

MagicEffectId.SummonGoldenSaint

"summongoldensaint"

#number

MagicEffectId.SummonGreaterBonewalker

"summongreaterbonewalker"

#number

MagicEffectId.SummonHunger

"summonhunger"

#number

MagicEffectId.SummonScamp

"summonscamp"

#number

MagicEffectId.SummonSkeletalMinion

"summonskeletalminion"

#number

MagicEffectId.SummonStormAtronach

"summonstormatronach"

#number

MagicEffectId.SummonWingedTwilight

"summonwingedtwilight"

#number

MagicEffectId.SummonWolf

"summonwolf"

#number

MagicEffectId.SunDamage

"sundamage"

#number

MagicEffectId.SwiftSwim

"swiftswim"

#number

MagicEffectId.Telekinesis

"telekinesis"

#number

MagicEffectId.TurnUndead

"turnundead"

#number

MagicEffectId.Vampirism

"vampirism"

#number

MagicEffectId.WaterBreathing

"waterbreathing"

#number

MagicEffectId.WaterWalking

"waterwalking"

#number

MagicEffectId.WeaknessToBlightDisease

"weaknesstoblightdisease"

#number

MagicEffectId.WeaknessToCommonDisease

"weaknesstocommondisease"

#number

MagicEffectId.WeaknessToCorprusDisease

"weaknesstocorprusdisease"

#number

MagicEffectId.WeaknessToFire

"weaknesstofire"

#number

MagicEffectId.WeaknessToFrost

"weaknesstofrost"

#number

MagicEffectId.WeaknessToMagicka

"weaknesstomagicka"

#number

MagicEffectId.WeaknessToNormalWeapons

"weaknesstonormalweapons"

#number

MagicEffectId.WeaknessToPoison

"weaknesstopoison"

#number

MagicEffectId.WeaknessToShock

"weaknesstoshock"

## Type `MagicEffectWithParams`

### Field(s)

#string

MagicEffectWithParams.affectedAttribute

Optional attribute ID

#string

MagicEffectWithParams.affectedSkill

Optional skill ID

#number

MagicEffectWithParams.area

#number

MagicEffectWithParams.duration

#MagicEffect

MagicEffectWithParams.effect

#MagicEffect

#string

MagicEffectWithParams.id

ID of the associated #MagicEffect

#number

MagicEffectWithParams.index

Index of this effect within the original list of #MagicEffectWithParams of the spell/enchantment/potion this effect came from.

#number

MagicEffectWithParams.magnitudeMax

#number

MagicEffectWithParams.magnitudeMin

#number

MagicEffectWithParams.range

## Type `MagicSchoolData`

### Field(s)

#string

MagicSchoolData.areaSound

VFS path to the area sound

#string

MagicSchoolData.boltSound

VFS path to the bolt sound

#string

MagicSchoolData.castSound

VFS path to the cast sound

#string

MagicSchoolData.failureSound

VFS path to the failure sound

#string

MagicSchoolData.hitSound

VFS path to the hit sound

#string

MagicSchoolData.name

Human-readable name

## Type `ObjectList`

List of GameObjects.

Implements iterables#List of #GameObject

` ObjectList ` is a list of ` #GameObject `.

## Type `ObjectOwner`

Object owner information

### Field(s)

#string

ObjectOwner.factionId

Faction who owns the object (nil if missing). Global and self scripts can set the value.

#number

ObjectOwner.factionRank

Rank required to be allowed to pick up the object (`nil` if any rank is allowed). Global and self scripts can set the value.

#string

ObjectOwner.recordId

NPC who owns the object (nil if missing). Global and self scripts can set the value.

## Type `PathGrid`

A cell's path grid marking traversable paths.

### Field(s)

PathGrid:getPoints()

Get all points in this path grid.

### Return value

#list<#PathGridPoint>:
A list of #PathGridPoints.

## Type `PathGridPoint`

A point in a cell's path grid.

### Field(s)

#boolean

PathGridPoint.autoGenerated

True if this node was automatically generated in the editor.

#list<#PathGridPoint>

PathGridPoint.connections

A list of points connected to this point.

openmw.util#Vector3

PathGridPoint.relativePosition

The point's position relative to the cell's origin. An exterior cell's origin is its southwest corner.

## Type `RegionRecord`

Region data record

### Usage

`print(region.weatherProbabilities["rain"])`

### Field(s)

#string

RegionRecord.id

Region ID

openmw.util#Color

RegionRecord.mapColor

Editor map color for this region.

#string

RegionRecord.name

Region display name

#string

RegionRecord.sleepList

A leveled creature list used when sleeping outdoors in this region

#list<#RegionSoundRef>

RegionRecord.sounds

A read-only list of ambient sound references for this region.
Each reference includes a chance and a resolved link to the full sound record.

#table

RegionRecord.weatherProbabilities

A table mapping WeatherRecord.recordIds to their probability (0–100), should sum to 100.
Valid weather ids include:
`"clear"`, `"cloudy"`, `"foggy"`, `"overcast"`, `"rain"`, `"thunderstorm"`, `"ashstorm"`, `"blight"`, `"snow"`, `"blizzard"`

## Type `RegionSoundRef`

Region sound reference

### Field(s)

#number

RegionSoundRef.chance

Multiplicative percentage used to determine whether to play the sound

#string

RegionSoundRef.soundId

Sound record ID

## Type `Regions`

### Field(s)

#list<#RegionRecord>

Regions.records

A read-only list of all #RegionRecords in the world database.

### Usages

-

`local record = core.regions.records['bitter coast region']`

-

`local record = core.regions.records[1]`

## Type `Skill`

`core.stats.Skill`

### Usages

-

`local record = core.stats.Skill.records['example_recordid']`

-

`local record = core.stats.Skill.records[1]`

### Field(s)

Skill.record(recordId)

Returns a read-only #SkillRecord

### Parameter

-
` #string recordId `:

### Return value

#SkillRecord:

#list<#SkillRecord>

Skill.records

A read-only list of all #SkillRecords in the world database, may be indexed by recordId.
Implements iterables#List of #SkillRecord.

## Type `SkillRecord`

### Field(s)

#string

SkillRecord.attribute

The id of the skill's governing attribute

#string

SkillRecord.description

Human-readable description

#string

SkillRecord.icon

VFS path to the icon

#string

SkillRecord.id

Record id

#string

SkillRecord.name

Human-readable name

#MagicSchoolData

SkillRecord.school

Optional magic school

#table

SkillRecord.skillGain

Table of the 4 possible skill gain values. See SkillProgression#SkillUseType.

#string

SkillRecord.specialization

Skill specialization. Either combat, magic, or stealth.

## Type `Sound`

### Field(s)

Sound.isEnabled()

Checks if sound system is enabled (any functions to play sounds are no-ops when it is disabled).

It can not be enabled or disabled during runtime.

### Return value

#boolean:

### Usage

`local enabled = core.sound.isEnabled();`

Sound.isSayActive(object)

Check if an animated voiceover is playing

### Parameter

-
` #GameObject object `:
Object on which we want to check an animated voiceover

### Return value

#boolean:

### Usage

`local isActive = isSayActive(object);`

Sound.isSoundFilePlaying(fileName, object)

Check if a sound file is playing on the given object

### Parameters

-
` #string fileName `:
Path to sound file in VFS

-
` #GameObject object `:
Object on which we want to check sound

### Return value

#boolean:

### Usage

`local isPlaying = core.sound.isSoundFilePlaying("Sound\\test.mp3", object);`

Sound.isSoundPlaying(soundId, object)

Check if a sound is playing on the given object

### Parameters

-
` #string soundId `:
ID of Sound record to check

-
` #GameObject object `:
Object on which we want to check sound

### Return value

#boolean:

### Usage

`local isPlaying = core.sound.isSoundPlaying("shock bolt", object);`

Sound.playSound3d(soundId, object, options)

Play a 3D sound, attached to object

In local scripts can be used only on self.

### Parameters

-
` #string soundId `:
ID of Sound record to play

-
` #GameObject object `:
Object to which we attach the sound

-
` #table options `:
An optional table with additional optional arguments. Can contain:

- `timeOffset` - a floating point number >= 0, to some time (in second) from beginning of sound file (default: 0);

- `volume` - a floating point number >= 0, to set a sound volume (default: 1);

- `pitch` - a floating point number >= 0, to set a sound pitch (default: 1);

- `loop` - a boolean, to set if sound should be repeated when it ends (default: false);

### Usage

`local params = {
timeOffset=0.1,
volume=0.3,
loop=false,
pitch=1.0
};
core.sound.playSound3d("shock bolt", object, params)`

Sound.playSoundFile3d(fileName, object, options)

Play a 3D sound file, attached to object

In local scripts can be used only on self.

### Parameters

-
` #string fileName `:
Path to sound file in VFS

-
` #GameObject object `:
Object to which we attach the sound

-
` #table options `:
An optional table with additional optional arguments. Can contain:

- `timeOffset` - a floating point number >= 0, to some time (in second) from beginning of sound file (default: 0);

- `volume` - a floating point number >= 0, to set a sound volume (default: 1);

- `pitch` - a floating point number >= 0, to set a sound pitch (default: 1);

- `loop` - a boolean, to set if sound should be repeated when it ends (default: false);

### Usage

`local params = {
timeOffset=0.1,
volume=0.3,
loop=false,
pitch=1.0
};
core.sound.playSoundFile3d("Sound\\test.mp3", object, params)`

#list<#SoundRecord>

Sound.records

List of all #SoundRecords.

### Usages

-

`local sound = core.sound.records['Ashstorm'] -- get by id`

-

`local sound = core.sound.records[1] -- get by index`

-

`-- Print all sound files paths
for _, sound in pairs(core.sound.records) do
print(sound.fileName)
end`

Sound.say(fileName, object, text)

Play an animated voiceover.

In local scripts can be used only on self.

### Parameters

-
` #string fileName `:
Path to sound file in VFS

-
` #GameObject object `:
Object on which we want to play an animated voiceover

-
` #string text `:
Subtitle text (optional)

### Usages

-

`-- play voiceover for object and print messagebox
core.sound.say("Sound\\Vo\\Misc\\voice.mp3", object, "Subtitle text")`

-

`-- play voiceover for object, without messagebox
core.sound.say("Sound\\Vo\\Misc\\voice.mp3", object)`

Sound.stopSay(fileName, object)

Stop an animated voiceover

In local scripts can be used only on self.

### Parameters

-
` #string fileName `:
Path to sound file in VFS

-
` #GameObject object `:
Object on which we want to stop an animated voiceover

### Usage

`core.sound.stopSay(object);`

Sound.stopSound3d(soundId, object)

Stop a 3D sound, attached to object

In local scripts can be used only on self.

### Parameters

-
` #string soundId `:
ID of Sound record to stop

-
` #GameObject object `:
Object on which we want to stop sound

### Usage

`core.sound.stopSound("shock bolt", object);`

Sound.stopSoundFile3d(fileName, object)

Stop a 3D sound file, attached to object

In local scripts can be used only on self.

### Parameters

-
` #string fileName `:
Path to sound file in VFS

-
` #GameObject object `:
Object on which we want to stop sound

### Usage

`core.sound.stopSoundFile("Sound\\test.mp3", object);`

## Type `SoundRecord`

### Field(s)

#string

SoundRecord.fileName

Normalized path to sound file in VFS

#string

SoundRecord.id

Sound id

#number

SoundRecord.maxRange

Raw maximal range value, from 0 to 255

#number

SoundRecord.minRange

Raw minimal range value, from 0 to 255

#number

SoundRecord.volume

Raw sound volume, from 0 to 255

## Type `Spell`

### Field(s)

#boolean

Spell.alwaysSucceedFlag

If set, the spell should ignore skill checks and always succeed.

#boolean

Spell.autocalcFlag

(DEPRECATED, use isAutocalc) If set, the casting cost should be computed based on the effect list rather than read from the cost field

#number

Spell.cost

#list<#MagicEffectWithParams>

Spell.effects

The effects (#MagicEffectWithParams) of the spell

#string

Spell.id

Spell id

#boolean

Spell.isAutocalc

If set, the casting cost should be computed based on the effect list rather than read from the cost field

#string

Spell.name

Spell name

#boolean

Spell.starterSpellFlag

If set, the spell can be selected as a player's starting spell.

#number

Spell.type

#SpellType

## Type `SpellRange`

`core.magic.RANGE`

### Field(s)

#number

SpellRange.Self

Applied on self

#number

SpellRange.Target

Ranged spell

#number

SpellRange.Touch

On touch

## Type `SpellType`

`core.magic.SPELL_TYPE`

### Field(s)

#number

SpellType.Ability

Innate ability, always in effect

#number

SpellType.Blight

Blight disease

#number

SpellType.Curse

Curse

#number

SpellType.Disease

Common disease

#number

SpellType.Power

Power, can be used once a day

#number

SpellType.Spell

Normal spell, must be cast and costs mana

## Type `Spells`

### Field(s)

Spells.createRecordDraft(spell)

Creates a #Spell without adding it to the world database.

Use openmw_world#world.createRecord to add the record to the world.

### Parameter

-
` #Spell spell `:
A Lua table with the fields of a Spell, with an optional field `template` that accepts a #Spell as a base.

### Return value

#Spell:
A strongly typed Spell record.

#list<#Spell>

Spells.records

List of all #Spells.

### Usages

-

`local spell = core.magic.spells.records['thunder fist'] -- get by id`

-

`local spell = core.magic.spells.records[1] -- get by index`

-

`-- Print all powers
for _, spell in pairs(core.magic.spells.records) do
if spell.type == core.magic.SPELL_TYPE.Power then
print(spell.name)
end
end`

## Type `Stats`

### Field(s)

#Attribute

Stats.Attribute

#Attribute functions

#Skill

Stats.Skill

#Skill functions

## Type `TeleportOptions`

Either a table with options or a openmw.util#Vector3 rotation.

### Field(s)

#boolean

TeleportOptions.onGround

If true, adjust destination position to the ground.

openmw.util#Transform

TeleportOptions.rotation

New rotation; if missing, then the current rotation is used.

## Type `TimeOfDayInterpolatorColor`

Interpolates colors for weathers based on time of day

### Field(s)

openmw.util#Color

TimeOfDayInterpolatorColor.day

openmw.util#Color

TimeOfDayInterpolatorColor.night

openmw.util#Color

TimeOfDayInterpolatorColor.sunrise

openmw.util#Color

TimeOfDayInterpolatorColor.sunset

## Type `TimeOfDayInterpolatorFloat`

Interpolates numbers for weathers based on time of day

### Field(s)

#number

TimeOfDayInterpolatorFloat.day

#number

TimeOfDayInterpolatorFloat.night

#number

TimeOfDayInterpolatorFloat.sunrise

#number

TimeOfDayInterpolatorFloat.sunset

## Type `Weather`

### Field(s)

Weather.changeWeather(regionId, weather)

Change the weather

### Parameters

-
` #string regionId `:

-
` #WeatherRecord weather `:
The weather to change to

Weather.getCurrent(cell)

Get the current weather

### Parameter

-
` #Cell cell `:
The cell to get the current weather for

### Return value

#WeatherRecord:
Can be nil if the cell is inactive or has no weather

Weather.getCurrentStormDirection(cell)

Get the current storm direction taking weather transition into account.

### Parameter

-
` #Cell cell `:
The cell to get the storm direction for

### Return value

openmw.util#Vector3:
Can be nil if the cell is inactive or has no weather

Weather.getCurrentSunLightDirection(cell)

Get the current direction of the light of the sun.

### Parameter

-
` #Cell cell `:
The cell to get the sun direction for

### Return value

openmw.util#Vector4:
Can be nil if the cell is inactive

Weather.getCurrentSunPercentage(cell)

Get the current sun percentage taking weather transition into account.

### Parameter

-
` #Cell cell `:
The cell to get the sun percentage for

### Return value

#number:
Can be nil if the cell is inactive or has no weather

Weather.getCurrentSunVisibility(cell)

Get the current sun visibility taking weather transition into account.

### Parameter

-
` #Cell cell `:
The cell to get the sun visibility for

### Return value

#number:
Can be nil if the cell is inactive or has no weather

Weather.getCurrentWindSpeed(cell)

Get the current wind speed taking weather transition into account.

### Parameter

-
` #Cell cell `:
The cell to get the wind speed for

### Return value

#number:
Can be nil if the cell is inactive or has no weather

Weather.getNext(cell)

Get the next weather if any

### Parameter

-
` #Cell cell `:
The cell to get the next weather for

### Return value

#WeatherRecord:
Can be nil

Weather.getTransition(cell)

Get current weather transition value

### Parameter

-
` #Cell cell `:
The cell to get the transition value for

### Return value

#number:
Can be nil if the cell is inactive or has no weather

#list<#WeatherRecord>

Weather.records

List of all #WeatherRecords.

### Usages

-

`local weather = core.weather.records['Cloudy'] -- get by id`

-

`local weather = core.weather.records[1] -- get by index`

-

`-- Print all storms
for _, weather in pairs(core.weather.records) do
if weather.isStorm then
print(weather.name)
end
end`

## Type `WeatherRecord`

Weather data

### Field(s)

#TimeOfDayInterpolatorColor

WeatherRecord.ambientColor

#string

WeatherRecord.ambientLoopSoundID

#number

WeatherRecord.cloudSpeed

#string

WeatherRecord.cloudTexture

#number

WeatherRecord.cloudsMaximumPercent

Affects the speed of weather transitions (0, 1]

#number

WeatherRecord.distantLandFogFactor

#number

WeatherRecord.distantLandFogOffset

#TimeOfDayInterpolatorColor

WeatherRecord.fogColor

#number

WeatherRecord.glareView

Strength of the sun glare [0, 1]

#boolean

WeatherRecord.isStorm

Controls whether the weather is considered a storm for animation and movement purposes

#TimeOfDayInterpolatorFloat

WeatherRecord.landFogDepth

#string

WeatherRecord.name

Read-only weather name

#string

WeatherRecord.particleEffect

Will return nil if weather has no particleEffect

#number

WeatherRecord.rainDiameter

The area around the player to spawn rain in

#string

WeatherRecord.rainEffect

Will return nil if weather has no rainEffect

#number

WeatherRecord.rainEntranceSpeed

The number of seconds between rain particle batches being created

#string

WeatherRecord.rainLoopSoundID

#number

WeatherRecord.rainMaxHeight

The maximum height relative to the player to spawn rain at

#number

WeatherRecord.rainMaxRaindrops

The maximum number of rain particle batches to create every rainEntranceSpeed

#number

WeatherRecord.rainMinHeight

The minimum height relative to the player to spawn rain at

#number

WeatherRecord.rainSpeed

The speed at which rain falls

#string

WeatherRecord.recordId

#number

WeatherRecord.scriptId

Read-only ID used in mwscript and dialogue

#TimeOfDayInterpolatorColor

WeatherRecord.skyColor

openmw.util#Vector3

WeatherRecord.stormDirection

#TimeOfDayInterpolatorColor

WeatherRecord.sunColor

openmw.util#Color

WeatherRecord.sunDiscSunsetColor

#table

WeatherRecord.thunderSoundID

A read-only array containing the recordIds of the thunder sounds

#number

WeatherRecord.windSpeed

Affects the angle of falling rain

Package openmw.content

Package openmw.debug
