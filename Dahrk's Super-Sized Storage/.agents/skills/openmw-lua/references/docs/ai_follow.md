# AI Package Follow

# Follow

API v129

Follow another actor.

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

destCell

Cell [optional]

the destination cell

duration

number [optional]

duration in game time (will be rounded up to the next hour)

destPosition

3d vector [optional]

the destination point

isRepeat

boolean [optional]

Will the package repeat (true or false)

Escort

Pursue
