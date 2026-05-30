# Package openmw.content

# Package openmw.content

API v129

Allows for manipulation of the data loaded from content files while the game is first started.

Records can be created and deleted using this package as if a content file had done so.

load

## Usage

`local content = require('openmw.content')`

## Type `content`

content.RANGE

openmw.core#SpellRange: Magic ranges

content.activators

#ActivatorContent: Activator manipulation.

content.books

#BookContent: Book manipulation.

content.doors

#DoorContent: Door manipulation.

content.enchantments

#EnchantmentContent: Enchantment manipulation.

content.gameSettings

#GMSTContent: GMST manipulation.

content.globals

#GlobalContent: Global variable manipulation.

content.ingredients

#IngredientContent: Ingredient manipulation.

content.lights

#LightContent: Light manipulation.

content.magicEffects

#MagicEffectContent: Magic effect manipulation.

content.miscs

#MiscContent: Misc manipulation.

content.potions

#PotionContent: Potion manipulation.

content.probes

#ProbeContent: Probe manipulation.

content.sounds

#SoundContent: Sound manipulation.

content.spells

#SpellContent: Spell manipulation.

content.statics

#StaticContent: Static manipulation.

## Type `ActivatorContent`

ActivatorContent.records

A mutable list of all openmw.types#ActivatorRecords.

## Type `BookContent`

BookContent.records

A mutable list of all openmw.types#BookRecords.

## Type `DoorContent`

DoorContent.records

A mutable list of all openmw.types#DoorRecords.

## Type `EnchantmentContent`

EnchantmentContent.TYPE

openmw.core#EnchantmentType: Enchantment types

EnchantmentContent.records

A mutable list of all openmw.core#Enchantments.

## Type `GMSTContent`

GMSTContent.getFallbacks()

Returns a table containing all fallback values defined in `openmw.cfg`.

GMSTContent.records

A mutable list of all game settings.

## Type `GlobalContent`

GlobalContent.records

A mutable list of all global mwscript variables.

## Type `IngredientContent`

IngredientContent.records

A mutable list of all openmw.types#IngredientRecords.

## Type `LightContent`

LightContent.records

A mutable list of all openmw.types#LightRecords.

## Type `MagicEffectContent`

MagicEffectContent.records

A mutable list of all openmw.core#MagicEffects.

## Type `MiscContent`

MiscContent.records

A mutable list of all openmw.types#MiscellaneousRecords.

## Type `PotionContent`

PotionContent.records

A mutable list of all openmw.types#PotionRecords.

## Type `ProbeContent`

ProbeContent.records

A mutable list of all openmw.types#ProbeRecords.

## Type `SoundContent`

SoundContent.records

A mutable list of all openmw.core#SoundRecords.

## Type `SpellContent`

SpellContent.TYPE

openmw.core#SpellType: Spell types

SpellContent.records

A mutable list of all openmw.core#Spells.

## Type `StaticContent`

StaticContent.records

A mutable list of all openmw.types#StaticRecords.

## Type `content`

### Field(s)

openmw.core#SpellRange

content.RANGE

openmw.core#SpellRange: Magic ranges

#ActivatorContent

content.activators

#ActivatorContent: Activator manipulation.

#BookContent

content.books

#BookContent: Book manipulation.

#DoorContent

content.doors

#DoorContent: Door manipulation.

#EnchantmentContent

content.enchantments

#EnchantmentContent: Enchantment manipulation.

#GMSTContent

content.gameSettings

#GMSTContent: GMST manipulation.

#GlobalContent

content.globals

#GlobalContent: Global variable manipulation.

#IngredientContent

content.ingredients

#IngredientContent: Ingredient manipulation.

#LightContent

content.lights

#LightContent: Light manipulation.

#MagicEffectContent

content.magicEffects

#MagicEffectContent: Magic effect manipulation.

#MiscContent

content.miscs

#MiscContent: Misc manipulation.

#PotionContent

content.potions

#PotionContent: Potion manipulation.

#ProbeContent

content.probes

#ProbeContent: Probe manipulation.

#SoundContent

content.sounds

#SoundContent: Sound manipulation.

#SpellContent

content.spells

#SpellContent: Spell manipulation.

#StaticContent

content.statics

#StaticContent: Static manipulation.

## Type `ActivatorContent`

### Field(s)

#list<openmw.types#ActivatorRecord>

ActivatorContent.records

A mutable list of all openmw.types#ActivatorRecords.

### Usage

`content.activators.records.MyActivator = { mwscript = 'float', model = 'meshes/w/w_chitin_arrow.nif', name = 'Quest marker' }`

## Type `BookContent`

### Field(s)

#list<openmw.types#BookRecord>

BookContent.records

A mutable list of all openmw.types#BookRecords.

### Usage

`content.books.records.MyBook = { template = content.books.records['bk_lustyargonianmaid'], text = content.books.records['bk_BoethiahPillowBook'].text }`

## Type `DoorContent`

### Field(s)

#list<openmw.types#DoorRecord>

DoorContent.records

A mutable list of all openmw.types#DoorRecords.

### Usage

`content.doors.records.MyDoor = { template = content.doors.records['door_dwrv_double00'], mwscript = 'blockedDoor', name = 'Overly Heavy Dwemer Door' }`

## Type `EnchantmentContent`

### Field(s)

openmw.core#EnchantmentType

EnchantmentContent.TYPE

openmw.core#EnchantmentType: Enchantment types

#list<openmw.core#Enchantment>

EnchantmentContent.records

A mutable list of all openmw.core#Enchantments.

### Usage

`content.enchantments.records.MyEnchantment = { type = content.enchantments.TYPE.CastOnUse, charge = 1, cost = 1, effects = { { id = 'FortifySkill', affectedSkill = 'enchant', duration = 5, magnitudeMin = 50, magnitudeMax = 100 } } }`

## Type `GMSTContent`

### Field(s)

GMSTContent.getFallbacks()

Returns a table containing all fallback values defined in `openmw.cfg`.

### Return value

#table:

#map<#string,#any>

GMSTContent.records

A mutable list of all game settings.

### Usage

`content.gameSettings.records.fJumpAcrobaticsBase = 1024`

## Type `GlobalContent`

### Field(s)

#map<#string,#number>

GlobalContent.records

A mutable list of all global mwscript variables.

### Usage

`content.globals.records.MyVariable = 42`

## Type `IngredientContent`

### Field(s)

#list<openmw.types#IngredientRecord>

IngredientContent.records

A mutable list of all openmw.types#IngredientRecords.

Note that ingredient effects only have the `id`, `affectedAttribute`, and `affectedSkill` properties.

### Usage

`content.ingredients.records.MyIngredient = { template = content.ingredients.records['ingred_ectoplasm_01'], name = 'Soylent', effects = { { id = 'vampirism' } } }`

## Type `LightContent`

### Field(s)

#list<openmw.types#LightRecord>

LightContent.records

A mutable list of all openmw.types#LightRecords.

### Usage

`content.lights.records.MyLight = { template = content.lights.records['torch'], duration = -1, name = 'Infinite Torch' }`

## Type `MagicEffectContent`

### Field(s)

#list<openmw.core#MagicEffect>

MagicEffectContent.records

A mutable list of all openmw.core#MagicEffects.

### Usage

`content.magicEffects.records.MyMagicEffect = { template = content.magicEffects.records['summonscamp'], name = 'Summon Nothing' }`

## Type `MiscContent`

### Field(s)

#list<openmw.types#MiscellaneousRecord>

MiscContent.records

A mutable list of all openmw.types#MiscellaneousRecords.

### Usage

`content.miscs.records.MyMisc = { template = content.miscs.records['gold_001'], mwscript = 'BILL_MarksSpiritSummon', weight = 5 }`

## Type `PotionContent`

### Field(s)

#list<openmw.types#PotionRecord>

PotionContent.records

A mutable list of all openmw.types#PotionRecords.

### Usage

`content.potions.records.MyPotion = { template = content.potions.records['p_dispel_s'], name = 'Too Strong', effects = { { id = 'FireDamage', duration = 10, range = content.RANGE.Self, magnitudeMin = 100 } } }`

## Type `ProbeContent`

### Field(s)

#list<openmw.types#ProbeRecord>

ProbeContent.records

A mutable list of all openmw.types#ProbeRecords.

### Usage

`content.probes.records.MyProbe = { template = content.probes.records['probe_bent'], quality = 5, name = 'Alien Probe' }`

## Type `SoundContent`

### Field(s)

#list<openmw.core#SoundRecord>

SoundContent.records

A mutable list of all openmw.core#SoundRecords.

### Usage

`content.sounds.records.MySound = { template = content.sounds.records['MournDayAmb'], fileName = 'sound/fx/funny.wav' }`

## Type `SpellContent`

### Field(s)

openmw.core#SpellType

SpellContent.TYPE

openmw.core#SpellType: Spell types

#list<openmw.core#Spell>

SpellContent.records

A mutable list of all openmw.core#Spells.

### Usage

`content.spells.records.MySpell = { name = 'Enchantment?', type = content.spells.TYPE.Spell, cost = 1000, starterSpellFlag = true, isAutocalc = true, effects = { { id = 'FortifyAttribute', affectedAttribute = 'intelligence', duration = 5, magnitudeMin = 5, magnitudeMax = 10 } } }`

## Type `StaticContent`

### Field(s)

#list<openmw.types#StaticRecord>

StaticContent.records

A mutable list of all openmw.types#StaticRecords.

### Usage

`content.statics.records.MyStatic = { model = 'meshes/b/B_N_Wood Elf_M_Head_02.nif' }`

Package openmw.camera

Package openmw.core
