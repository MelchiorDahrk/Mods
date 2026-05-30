# Interface AI

# Interface AI

API v129

Basic AI interface

local

## Usage

`require('openmw.interfaces').AI`

## Type `AI`

AI.filterPackages(filterCallback)

Iterate over all packages starting from the active one and remove those where `filterCallback` returns false.

AI.forEachPackage(callback)

Iterate over all packages and run `callback` for each starting from the active one.

AI.getActivePackage()

Return the currently active AI package (or `nil` if there are no AI packages).

AI.getActiveTarget(packageType)

Return the target of the active package if the package has given type

AI.getTargets(packageType)

Get a list of targets from all packages of the given type.

AI.isFleeing()

Return whether the actor is fleeing.

AI.removePackages(packageType)

Remove packages of given type (remove all packages if the type is not specified).

AI.startPackage(options)

Start a new AI package.

AI.version

Interface version

## Type `Package`

Package.destPosition

Destination point of the AI package.

Package.distance

Distance value (can be nil).

Package.duration

Duration value (can be nil).

Package.idle

Idle value (can be nil).

Package.isRepeat

Should this package be repeated (true or false).

Package.sideWithTarget

Whether to help the target in combat (true or false).

Package.target

Target (usually an actor) of the AI package (can be nil).

Package.type

Type of the AI package.

## Type `AI`

### Field(s)

AI.filterPackages(filterCallback)

Iterate over all packages starting from the active one and remove those where `filterCallback` returns false.

### Parameter

-
` #function filterCallback `:

AI.forEachPackage(callback)

Iterate over all packages and run `callback` for each starting from the active one.

The same as `filterPackage`, but without removal.

### Parameter

-
` #function callback `:

AI.getActivePackage()

Return the currently active AI package (or `nil` if there are no AI packages).

### Return value

#Package:

AI.getActiveTarget(packageType)

Return the target of the active package if the package has given type

### Parameter

-
` #string packageType `:
The expected type of the active package

### Return value

openmw.core#GameObject:
The target (can be nil if the package has no target or has another type)

AI.getTargets(packageType)

Get a list of targets from all packages of the given type.

### Parameter

-
` #string packageType `:

### Return value

#list<openmw.core#GameObject>:

AI.isFleeing()

Return whether the actor is fleeing.

### Return value

#boolean:

AI.removePackages(packageType)

Remove packages of given type (remove all packages if the type is not specified).

### Parameter

-
` #string packageType `:
(optional) The type of packages to remove.

AI.startPackage(options)

Start a new AI package.

### Parameter

-
` #table options `:
See the "AI packages" page.

#number

AI.version

Interface version

## Type `Package`

AI Package

### Field(s)

openmw.util#Vector3

Package.destPosition

Destination point of the AI package.

#number

Package.distance

Distance value (can be nil).

#number

Package.duration

Duration value (can be nil).

#table

Package.idle

Idle value (can be nil).

#boolean

Package.isRepeat

Should this package be repeated (true or false).

#boolean

Package.sideWithTarget

Whether to help the target in combat (true or false).

openmw.core#GameObject

Package.target

Target (usually an actor) of the AI package (can be nil).

#string

Package.type

Type of the AI package.

Interface Activation

Interface AnimationController
