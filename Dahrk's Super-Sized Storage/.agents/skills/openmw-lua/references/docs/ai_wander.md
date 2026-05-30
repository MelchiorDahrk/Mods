# AI Package Wander

# Wander

API v129

Wander nearby current position.

Arguments

name

type

description

type

string [required]

the name of the package (see packages listed below)

distance

float [default=0]

the actor to follow

duration

number [optional]

duration in game time (will be rounded up to the next hour)

idle

table [optional]

Idle chance values, up to 8

isRepeat

boolean [optional]

Will the package repeat (true or false)

Example

` local idleTable = {
idle2 = 60 ,
idle3 = 50 ,
idle4 = 40 ,
idle5 = 30 ,
idle6 = 20 ,
idle7 = 10 ,
idle8 = 0 ,
idle9 = 25
}
actor : sendEvent ( 'StartAIPackage' , {
type = 'Wander' ,
distance = 5000 ,
duration = 5 * time . hour ,
idle = idleTable ,
isRepeat = true
})
`

Travel

Interfaces
