# Interface Crimes

# Interface Crimes

Allows to utilize built-in crime mechanics.

global

## Usage

`require('openmw.interfaces').Crimes`

## Type `Crimes`

Crimes.commitCrime(player, CommitCrimeInputs)

Commits a crime as if done through an in-game action.

Crimes.version

Interface version

## Type `CommitCrimeInputs`

CommitCrimeInputs.arg

The amount to increase the player bounty by if the crime type is theft. Ignored otherwise (optional, defaults to 0)

CommitCrimeInputs.faction

ID of the faction the crime is committed against (optional)

CommitCrimeInputs.type

The type of the crime to commit. See openmw.types#OFFENSE_TYPE_IDS (required)

CommitCrimeInputs.victim

The victim of the crime (optional)

CommitCrimeInputs.victimAware

Whether the victim is aware of the crime (optional, defaults to false)

## Type `CommitCrimeOutputs`

CommitCrimeOutputs.wasCrimeSeen

Whether the crime was seen

## Type `Crimes`

### Field(s)

Crimes.commitCrime(player, CommitCrimeInputs)

Commits a crime as if done through an in-game action.

Can only be used in global context.

### Parameters

-
` openmw.core#GameObject player `:
The player committing the crime

-
` CommitCrimeInputs `:
options A table of parameters describing the committed crime

### Return value

CommitCrimeOutputs A table containing information about the committed crime

#number

Crimes.version

Interface version

## Type `CommitCrimeInputs`

Table with information needed to commit crimes.

### Field(s)

#number

CommitCrimeInputs.arg

The amount to increase the player bounty by if the crime type is theft. Ignored otherwise (optional, defaults to 0)

#string

CommitCrimeInputs.faction

ID of the faction the crime is committed against (optional)

openmw.types#OFFENSE_TYPE_IDS

CommitCrimeInputs.type

The type of the crime to commit. See openmw.types#OFFENSE_TYPE_IDS (required)

openmw.core#GameObject

CommitCrimeInputs.victim

The victim of the crime (optional)

#boolean

CommitCrimeInputs.victimAware

Whether the victim is aware of the crime (optional, defaults to false)

## Type `CommitCrimeOutputs`

Table containing information returned by the engine after committing a crime

### Field(s)

#boolean

CommitCrimeOutputs.wasCrimeSeen

Whether the crime was seen

Interface Controls

Interface GamepadControls
