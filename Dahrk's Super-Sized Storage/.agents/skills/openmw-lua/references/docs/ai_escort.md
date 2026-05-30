# AI Package Escort

# Escort

API v129

Escort another actor to the given location.

Arguments

name

type

description

type

string [required]

the name of the package (see packages listed below)

cancelOther

boolean [default=true]

whether to cancel all other AI packages

target

GameObject [required]

the actor to follow

destPosition

3d vector [required]

the destination point

destCell

Cell [optional]

the destination cell

duration

number [optional]

duration in game time (will be rounded up to the next hour)

isRepeat

boolean [optional]

Will the package repeat (true or false)

Example

` actor : sendEvent ( 'StartAIPackage' , {
type = 'Escort' ,
target = object . self ,
destPosition = util . vector3 ( x , y , z ),
duration = 3 * time . hour ,
isRepeat = true
})
`

Combat

Follow
