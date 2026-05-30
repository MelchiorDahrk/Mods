# Events

# Events

API v129

## Actor events

DialogueResponse

This event is sent to the player’s local script when an actor triggers a greeting, topic response, service refusal, or plays a voice line.
It returns a lua table with the following fields:
- ` actor `: The actor that responded.
- ` type `: The type of ` DialogueRecord ` that triggered the event, can be ` "greeting" `, ` "journal" `, ` "persuasion" `, ` "topic" `, or ` "voice" `.
- ` recordId `: The ID of the ` DialogueRecord `.
- ` infoId `: The ID of the ` DialogueRecordInfo ` in question.

` eventHandlers = {
DialogueResponse = function ( e )
local topic = core . dialogue [ e . type ]. records [ e . recordId ];
for _ , info in pairs ( topic . infos ) do
if info . id == e . infoId then
print ( e . actor , 'said' , info . text )
return
end
end
end
}
`

Died

This event is sent to an actor’s local script when that actor dies.

` eventHandlers = {
Died = function ()
print ( 'Alas, ye hardly knew me!' )
end
}
`

StartAIPackage, RemoveAIPackages

Any script can send to any actor (except player, for player will be ignored) events ` StartAIPackage ` and ` RemoveAIPackages `.
The effect is equivalent to calling ` interfaces.AI.startPackage ` or ` interfaces.AI.removePackages ` in a local script on this actor.

Examples:

` actor : sendEvent ( 'StartAIPackage' , { type = 'Combat' , target = self . object })
actor : sendEvent ( 'RemoveAIPackages' , 'Pursue' )
`

UseItem

Any script can send global event ` UseItem ` with arguments ` object `, ` actor `, and optional boolean ` force `.
The actor will use (e.g. equip or consume) the object. The object should be in the actor’s inventory.

Example:

` core . sendGlobalEvent ( 'UseItem' , { object = potion , actor = player , force = true })
`

ModifyStat

Modify the corresponding stat.

` -- Consume 10 magicka
actor : sendEvent ( 'ModifyStat' , { stat = 'magicka' , amount = - 10 })
`

AddVfx

Calls the corresponding method in openmw.animation

` local eventParams = {
model = 'vfx_default' ,
options = {
textureOverride = effect . particle ,
},
}
actor : sendEvent ( 'AddVfx' , eventParams )
`

PlaySound3d

Calls the corresponding function in openw.core on the target. Will use core.sound.playSoundFile3d instead of core.sound.playSound3d if you put file instead of sound in the event data.

BreakInvisibility

Forces the actor to lose all active invisibility effects.

Unequip

Any script can send ` Unequip ` events with the argument ` item ` or ` slot ` to any actor, to make that actor unequip an item.

The following two examples are equivalent, except the ` item ` variant is guaranteed to only unequip the specified item and won’t unequip a different item if the actor’s equipment changed during the same frame:

` local item = Actor . getEquipment ( actor , Actor . EQUIPMENT_SLOT . CarriedLeft )
if item then
actor : sendEvent ( 'Unequip' , { item = item })
end
`

` actor : sendEvent ( 'Unequip' , { slot = Actor . EQUIPMENT_SLOT . CarriedLeft })
`

## Combat events

Hit

Any script can send ` Hit ` events with arguments described in the Combat interface to cause a hit to an actor

Example:

` -- See Combat#AttackInfo
local attack = {
attacker = self ,
weapon = Actor . getEquipment ( self , Actor . EQUIPMENT_SLOT . CarriedRight ),
sourceType = I . Combat . ATTACK_SOURCE_TYPES . Melee ,
strength = 1 ,
type = self . ATTACK_TYPE . Chop ,
damage = {
health = 20 ,
fatigue = 10 ,
},
successful = true ,
}
victim : sendEvent ( 'Hit' , attack )
`

## Item events

ModifyItemCondition

Any script can send ` ModifyItemCondition ` events to global to adjust the condition of an item.

Example:

` local item = Actor . getEquipment ( actor , Actor . EQUIPMENT_SLOT . CarriedLeft )
if item then
-- Reduce condition by 1
-- Note that actor should be included, if applicable, to allow forcibly unequipping items whose condition is reduced to 0
core . sendGlobalEvent ( 'ModifyItemCondition' , { actor = self , item = item , amount = - 1 })
end
`

## UI events

ShowMessage

If sent to a player, shows a message as if a call to ui.showMessage was made.

` player : sendEvent ( 'ShowMessage' , { message = 'Lorem ipsum' })
`

UiModeChanged

Every time UI mode is changed built-in scripts send to player the event ` UiModeChanged ` with arguments ` oldMode, ``newMode ` (same as ` I.UI.getMode() `)
and ` arg ` (for example in the mode ` Book ` the argument is the book the player is reading).

` eventHandlers = {
UiModeChanged = function ( data )
print ( 'UiModeChanged from' , data . oldMode , 'to' , data . newMode , '(' .. tostring ( data . arg ).. ')' )
end
}
`

AddUiMode

Equivalent to ` I.UI.addMode `, but can be sent from another object or global script.

` player : sendEvent ( 'AddUiMode' , { mode = 'Book' , target = book })
`

SetUiMode

Equivalent to ` I.UI.setMode `, but can be sent from another object or global script.

` player : sendEvent ( 'SetUiMode' , { mode = 'Book' , target = book })
`

## World events

Global events that just call the corresponding function in openmw.world .

` -- world.pause(tag)
core . sendGlobalEvent ( 'Pause' , tag )

-- world.unpause(tag)
core . sendGlobalEvent ( 'Unpause' , tag )

-- world.setGameTimeScale(scale)
core . sendGlobalEvent ( 'SetGameTimeScale' , scale )

-- world.setSimulationTimeScale(scale)
core . sendGlobalEvent ( 'SetSimulationTimeScale' , scale )
`

SpawnVfx, PlaySound3d

Calls the corresponding function in openw.core. Note that PlaySound3d will call core.sound.playSoundFile3d instead of core.sound.playSound3d if you put file instead of sound in the event data.

ConsumeItem

Reduces stack size of an item by a given amount, removing the item completely if stack size is reduced to 0 or less.

` core . sendGlobalEvent ( 'ConsumeItem' , { item = foobar , amount = 1 })
`

Lock

Lock a container or door

` core . sendGlobalEvent ( 'Lock' , { target = selected , magnitude = 50 })
`

Unlock

Unlock a container or door

` core . sendGlobalEvent ( 'Unlock' , { target = selected })
`

Engine handlers reference

Iterable types

On this page

- Actor events

- Combat events

- Item events

- UI events

- World events
