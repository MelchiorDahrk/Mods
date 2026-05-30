# AI Package Combat

# Combat

API v129

Attack another actor.

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

the actor to attack

Examples

` -- from local script add package to self
local AI = require ( 'openmw.interfaces' ). AI
AI . startPackage ({ type = 'Combat' , target = anotherActor })

-- via event to any actor
actor : sendEvent ( 'StartAIPackage' , { type = 'Combat' , target = anotherActor })
`

AI packages

Escort
