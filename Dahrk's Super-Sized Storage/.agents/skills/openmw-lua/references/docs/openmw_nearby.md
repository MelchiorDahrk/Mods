# Package openmw.nearby

# Package openmw.nearby

API v129

Provides read-only access to the nearest area of the game world.

local

## Usage

`local nearby = require('openmw.nearby')`

## Type `nearby`

nearby.COLLISION_TYPE

Collision types that are used in `castRay`.

nearby.activators

List of nearby activators.

nearby.actors

List of nearby actors.

nearby.asyncCastRenderingRay(callback, from, to, options)

Asynchronously cast a ray from one point to another and find the first visual intersection with anything in the scene.

nearby.castNavigationRay(from, to, options)

Finds a nearest to the ray target position starting from the initial position with resulting curve drawn on the
navigation mesh surface.

nearby.castRay(from, to, options)

Cast a ray from one point to another and return the first collision.

nearby.castRenderingRay(from, to, options)

Cast a ray from one point to another and find the first visual intersection with anything in the scene.

nearby.containers

List of nearby containers.

nearby.doors

List of nearby doors.

nearby.findNearestNavMeshPosition(position, options)

Finds a nearest position on navigation mesh to the given position within given search area.

nearby.findPath(source, destination, options)

Find a path over the navigation mesh from the source to the destination with the given options.

nearby.findRandomPointAroundCircle(position, maxRadius, options)

Returns a random location on the navigation mesh within the reach of the specified location.

nearby.getObjectByFormId(formId)

Return an object by RefNum/FormId.

nearby.items

Everything nearby that is derived from openmw.types#Item.

nearby.players

List of nearby players.

## Type `AgentBounds`

AgentBounds.halfExtents

AgentBounds.shapeType

## Type `AreaCosts`

AreaCosts.door

Value >= 0, used in combination with NAVIGATOR_FLAGS.OpenDoor
(default: 2).

AreaCosts.ground

Value >= 0, used in combination with NAVIGATOR_FLAGS.Walk (default: 1).

AreaCosts.pathgrid

Value >= 0, used in combination with NAVIGATOR_FLAGS.UsePathgrid
(default: 1).

AreaCosts.water

Value >= 0, used in combination with NAVIGATOR_FLAGS.Swim (default: 1).

## Type `COLLISION_SHAPE_TYPE`

COLLISION_SHAPE_TYPE.Aabb

Axis-Aligned Bounding Box is used for NPC and symmetric
Creatures.

COLLISION_SHAPE_TYPE.Cylinder

is used for NPC and symmetric Creatures.

COLLISION_SHAPE_TYPE.RotatingBox

is used for Creatures with big difference in width and
height.

## Type `COLLISION_TYPE`

COLLISION_TYPE.Actor

COLLISION_TYPE.AnyPhysical

World+Door+Actor+HeightMap+Projectile+Water

COLLISION_TYPE.Camera

Objects that should collide only with camera

COLLISION_TYPE.Default

Used by default: World+Door+Actor+HeightMap

COLLISION_TYPE.Door

COLLISION_TYPE.HeightMap

COLLISION_TYPE.Projectile

COLLISION_TYPE.VisualOnly

Objects that were not intended to be part of the physics world

COLLISION_TYPE.Water

COLLISION_TYPE.World

## Type `CastRayOptions`

CastRayOptions.collisionType

Object types to work with (see openmw.nearby#COLLISION_TYPE)

CastRayOptions.ignore

An openmw.core#GameObject or openmw.core#ObjectList to ignore (specify here the source of the ray, or other objects which should not collide)

CastRayOptions.radius

The radius of the ray (zero by default). If not zero then castRay actually casts a sphere with given radius.
NOTE: currently `ignore` is not supported if `radius>0`.

## Type `CastRenderingRayOptions`

CastRenderingRayOptions.ignore

A openmw.core#GameObject or openmw.core#ObjectList to ignore while doing the ray cast

## Type `FIND_PATH_STATUS`

FIND_PATH_STATUS.EndPolygonNotFound

`destination` position is too far from available
navigation mesh. The status may appear when navigation mesh is not fully generated or position is outside of covered
area;

FIND_PATH_STATUS.FindPathOverPolygonsFailed

Path over navigation mesh from `source` to
`destination` does not exist or navigation mesh is not fully generated to provide the path;

FIND_PATH_STATUS.FindStraightPathFailed

Couldn't map path over polygons into world
coordinates.

FIND_PATH_STATUS.InitNavMeshQueryFailed

Couldn't initialize required data due to bad input
or bad navigation mesh data.

FIND_PATH_STATUS.MoveAlongSurfaceFailed

Found path couldn't be smoothed due to imperfect
algorithm implementation or bad navigation mesh data;

FIND_PATH_STATUS.NavMeshNotFound

Provided `agentBounds` don't have corresponding navigation
mesh. For interior cells it means an agent with such `agentBounds` is present on the scene. For exterior cells only
default `agentBounds` is supported;

FIND_PATH_STATUS.PartialPath

Last path point is not a destination but a nearest position
among found;

FIND_PATH_STATUS.StartPolygonNotFound

`source` position is too far from available
navigation mesh. The status may appear when navigation mesh is not fully generated or position is outside of covered
area;

FIND_PATH_STATUS.Success

Path is found.

FIND_PATH_STATUS.TargetPolygonNotFound

adjusted `destination` position is too far from
available navigation mesh. The status may appear when navigation mesh is not fully generated or position is outside
of covered area;

## Type `FindNearestNavMeshPositionOptions`

FindNearestNavMeshPositionOptions.agentBounds

Identifies which navmesh to use.

FindNearestNavMeshPositionOptions.includeFlags

Allowed areas for agent to move, a sum of #NAVIGATOR_FLAGS
values (default: NAVIGATOR_FLAGS.Walk + NAVIGATOR_FLAGS.Swim + NAVIGATOR_FLAGS.OpenDoor
+ NAVIGATOR_FLAGS.UsePathgrid).

FindNearestNavMeshPositionOptions.searchAreaHalfExtents

Defines AABB like area half extents around
given position (default: (1 + 2 * CellGridRadius) * CellSize * (1, 1, 1) where CellGridRadius and depends on cell
type to cover the whole active grid).

## Type `FindPathOptions`

FindPathOptions.agentBounds

identifies which navmesh to use.

FindPathOptions.areaCosts

a table defining relative cost for each type of area.

FindPathOptions.checkpoints

an array of positions to build path over if possible.

FindPathOptions.destinationTolerance

a floating point number representing maximum allowed
distance between destination and a nearest point on the navigation mesh in addition to agent size (default: 1).

FindPathOptions.includeFlags

allowed areas for agent to move, a sum of #NAVIGATOR_FLAGS
values (default: NAVIGATOR_FLAGS.Walk + NAVIGATOR_FLAGS.Swim + NAVIGATOR_FLAGS.OpenDoor
+ NAVIGATOR_FLAGS.UsePathgrid).

## Type `NAVIGATOR_FLAGS`

NAVIGATOR_FLAGS.OpenDoor

Allow agent to open doors on the way.

NAVIGATOR_FLAGS.Swim

Allow agent to swim on the water surface.

NAVIGATOR_FLAGS.UsePathgrid

Allow agent to use predefined pathgrid imported from ESM files.

NAVIGATOR_FLAGS.Walk

Allow agent to walk on the ground area.

## Type `NavMeshOptions`

NavMeshOptions.agentBounds

Identifies which navmesh to use.

NavMeshOptions.includeFlags

Allowed areas for agent to move, a sum of #NAVIGATOR_FLAGS
values (default: NAVIGATOR_FLAGS.Walk + NAVIGATOR_FLAGS.Swim + NAVIGATOR_FLAGS.OpenDoor
+ NAVIGATOR_FLAGS.UsePathgrid).

## Type `RayCastingResult`

RayCastingResult.hit

Is there a collision? (true/false)

RayCastingResult.hitNormal

Normal to the surface in the collision point (nil if no collision)

RayCastingResult.hitObject

The object the ray has collided with (can be nil)

RayCastingResult.hitPos

Position of the collision point (nil if no collision)

## Type `nearby`

### Field(s)

#COLLISION_TYPE

nearby.COLLISION_TYPE

Collision types that are used in `castRay`.

Several types can be combined with openmw_util#util.bitOr.

openmw.core#ObjectList

nearby.activators

List of nearby activators.

openmw.core#ObjectList

nearby.actors

List of nearby actors.

nearby.asyncCastRenderingRay(callback, from, to, options)

Asynchronously cast a ray from one point to another and find the first visual intersection with anything in the scene.

### Parameters

-
` openmw.async#Callback callback `:
The callback to pass the result to (should accept a single argument openmw.nearby#RayCastingResult).

-
` openmw.util#Vector3 from `:
Start point of the ray.

-
` openmw.util#Vector3 to `:
End point of the ray.

-
` #CastRenderingRayOptions options `:
An optional table with additional optional arguments

nearby.castNavigationRay(from, to, options)

Finds a nearest to the ray target position starting from the initial position with resulting curve drawn on the
navigation mesh surface.

### Parameters

-
` openmw.util#Vector3 from `:
Initial ray position.

-
` openmw.util#Vector3 to `:
Target ray position.

-
` #NavMeshOptions options `:
An optional table with additional optional arguments.

### Return value

openmw.util#Vector3, #nil:

### Usages

-

`local position = nearby.castNavigationRay(from, to)`

-

`local position = nearby.castNavigationRay(from, to, {
includeFlags = nearby.NAVIGATOR_FLAGS.Swim,
})`

-

`local position = nearby.castNavigationRay(from, to, {
agentBounds = Actor.getPathfindingAgentBounds(self),
})`

nearby.castRay(from, to, options)

Cast a ray from one point to another and return the first collision.

### Parameters

-
` openmw.util#Vector3 from `:
Start point of the ray.

-
` openmw.util#Vector3 to `:
End point of the ray.

-
` #CastRayOptions options `:
An optional table with additional optional arguments

### Return value

#RayCastingResult:

### Usages

-

`if nearby.castRay(pointA, pointB).hit then print('obstacle between A and B') end`

-

`local res = nearby.castRay(self.position, enemy.position, {ignore=self})
if res.hitObject and res.hitObject ~= enemy then obstacle = res.hitObject end`

-

`local res = nearby.castRay(self.position, targetPos, {
collisionType=nearby.COLLISION_TYPE.HeightMap + nearby.COLLISION_TYPE.Water,
radius = 10,
})`

nearby.castRenderingRay(from, to, options)

Cast a ray from one point to another and find the first visual intersection with anything in the scene.

Unlike `castRay`, `castRenderingRay` can find an intersection with an object without collisions.
To avoid threading issues, `castRenderingRay` can only be used in:
- The `onFrame` engine handler.
- Engine handlers for user input.
- Callbacks provided to openmw.input#registerActionHandler
In other cases, use `asyncCastRenderingRay` instead.

### Parameters

-
` openmw.util#Vector3 from `:
Start point of the ray.

-
` openmw.util#Vector3 to `:
End point of the ray.

-
` #CastRenderingRayOptions options `:
An optional table with additional optional arguments

### Return value

#RayCastingResult:

openmw.core#ObjectList

nearby.containers

List of nearby containers.

openmw.core#ObjectList

nearby.doors

List of nearby doors.

nearby.findNearestNavMeshPosition(position, options)

Finds a nearest position on navigation mesh to the given position within given search area.

### Parameters

-
` openmw.util#Vector3 position `:
Search area center.

-
` #FindNearestNavMeshPositionOptions options `:
An optional table with additional optional arguments.

### Return value

openmw.util#Vector3, #nil:

### Usages

-

`local navMeshPosition = nearby.findNearestNavMeshPosition(position)`

-

`local navMeshPosition = nearby.findNearestNavMeshPosition(position, {
includeFlags = nearby.NAVIGATOR_FLAGS.Swim,
})`

-

`local navMeshPosition = nearby.findNearestNavMeshPosition(position, {
agentBounds = Actor.getPathfindingAgentBounds(self),
})`

-

`local navMeshPosition = nearby.findNearestNavMeshPosition(position, {
searchAreaHalfExtents = util.vector3(1000, 1000, 1000),
includeFlags = nearby.NAVIGATOR_FLAGS.Walk,
})`

nearby.findPath(source, destination, options)

Find a path over the navigation mesh from the source to the destination with the given options.

Result is unstable since navigation
mesh generation is asynchronous.

### Parameters

-
` openmw.util#Vector3 source `:
Initial path position.

-
` openmw.util#Vector3 destination `:
Final path position.

-
` #FindPathOptions options `:
An optional table with additional optional arguments.

### Return values

-
#FIND PATH STATUS:

-
#list<openmw.util#Vector3>:

### Usages

-

`local status, path = nearby.findPath(source, destination)`

-

`local status, path = nearby.findPath(source, destination, {
includeFlags = nearby.NAVIGATOR_FLAGS.Walk + nearby.NAVIGATOR_FLAGS.OpenDoor,
areaCosts = {
door = 1.5,
},
})`

-

`local status, path = nearby.findPath(source, destination, {
agentBounds = Actor.getPathfindingAgentBounds(self),
})`

nearby.findRandomPointAroundCircle(position, maxRadius, options)

Returns a random location on the navigation mesh within the reach of the specified location.

The location is not exactly constrained by the circle, but it limits the area.

### Parameters

-
` openmw.util#Vector3 position `:
Center of the search circle.

-
` #number maxRadius `:
Approximate maximum search distance.

-
` #NavMeshOptions options `:
An optional table with additional optional arguments.

### Return value

openmw.util#Vector3, #nil:

### Usages

-

`local position = nearby.findRandomPointAroundCircle(position, maxRadius)`

-

`local position = nearby.findRandomPointAroundCircle(position, maxRadius, {
includeFlags = nearby.NAVIGATOR_FLAGS.Walk,
})`

-

`local position = nearby.findRandomPointAroundCircle(position, maxRadius, {
agentBounds = Actor.getPathfindingAgentBounds(self),
})`

nearby.getObjectByFormId(formId)

Return an object by RefNum/FormId.

Note: the function always returns openmw.core#GameObject and doesn't validate that
the object exists in the game world. If it doesn't exist or not yet loaded to memory),
then `obj:isValid()` will be `false`.

### Parameter

-
` #string formId `:
String returned by `core.getFormId`

### Return value

openmw.core#GameObject:

### Usage

`local obj = nearby.getObjectByFormId(core.getFormId('Morrowind.esm', 128964))`

openmw.core#ObjectList

nearby.items

Everything nearby that is derived from openmw.types#Item.

openmw.core#ObjectList

nearby.players

List of nearby players.

Currently (since multiplayer is not yet implemented) always has one element.

## Type `AgentBounds`

A table of parameters identifying navmesh

### Field(s)

openmw.util#Vector3

AgentBounds.halfExtents

#COLLISION_SHAPE_TYPE

AgentBounds.shapeType

## Type `AreaCosts`

A table of parameters to specify relative path cost per each area type

### Field(s)

#number

AreaCosts.door

Value >= 0, used in combination with NAVIGATOR_FLAGS.OpenDoor
(default: 2).

#number

AreaCosts.ground

Value >= 0, used in combination with NAVIGATOR_FLAGS.Walk (default: 1).

#number

AreaCosts.pathgrid

Value >= 0, used in combination with NAVIGATOR_FLAGS.UsePathgrid
(default: 1).

#number

AreaCosts.water

Value >= 0, used in combination with NAVIGATOR_FLAGS.Swim (default: 1).

## Type `COLLISION_SHAPE_TYPE`

### Field(s)

#number

COLLISION_SHAPE_TYPE.Aabb

Axis-Aligned Bounding Box is used for NPC and symmetric
Creatures.

#number

COLLISION_SHAPE_TYPE.Cylinder

is used for NPC and symmetric Creatures.

#number

COLLISION_SHAPE_TYPE.RotatingBox

is used for Creatures with big difference in width and
height.

## Type `COLLISION_TYPE`

### Field(s)

#number

COLLISION_TYPE.Actor

#number

COLLISION_TYPE.AnyPhysical

World+Door+Actor+HeightMap+Projectile+Water

#number

COLLISION_TYPE.Camera

Objects that should collide only with camera

#number

COLLISION_TYPE.Default

Used by default: World+Door+Actor+HeightMap

#number

COLLISION_TYPE.Door

#number

COLLISION_TYPE.HeightMap

#number

COLLISION_TYPE.Projectile

#number

COLLISION_TYPE.VisualOnly

Objects that were not intended to be part of the physics world

#number

COLLISION_TYPE.Water

#number

COLLISION_TYPE.World

## Type `CastRayOptions`

A table of parameters for nearby.castRay

### Field(s)

#number

CastRayOptions.collisionType

Object types to work with (see openmw.nearby#COLLISION_TYPE)

#any

CastRayOptions.ignore

An openmw.core#GameObject or openmw.core#ObjectList to ignore (specify here the source of the ray, or other objects which should not collide)

#number

CastRayOptions.radius

The radius of the ray (zero by default). If not zero then castRay actually casts a sphere with given radius.
NOTE: currently `ignore` is not supported if `radius>0`.

## Type `CastRenderingRayOptions`

A table of parameters for nearby.castRenderingRay and nearby.asyncCastRenderingRay

### Field(s)

#any

CastRenderingRayOptions.ignore

A openmw.core#GameObject or openmw.core#ObjectList to ignore while doing the ray cast

## Type `FIND_PATH_STATUS`

### Field(s)

#number

FIND_PATH_STATUS.EndPolygonNotFound

`destination` position is too far from available
navigation mesh. The status may appear when navigation mesh is not fully generated or position is outside of covered
area;

#number

FIND_PATH_STATUS.FindPathOverPolygonsFailed

Path over navigation mesh from `source` to
`destination` does not exist or navigation mesh is not fully generated to provide the path;

#number

FIND_PATH_STATUS.FindStraightPathFailed

Couldn't map path over polygons into world
coordinates.

#number

FIND_PATH_STATUS.InitNavMeshQueryFailed

Couldn't initialize required data due to bad input
or bad navigation mesh data.

#number

FIND_PATH_STATUS.MoveAlongSurfaceFailed

Found path couldn't be smoothed due to imperfect
algorithm implementation or bad navigation mesh data;

#number

FIND_PATH_STATUS.NavMeshNotFound

Provided `agentBounds` don't have corresponding navigation
mesh. For interior cells it means an agent with such `agentBounds` is present on the scene. For exterior cells only
default `agentBounds` is supported;

#number

FIND_PATH_STATUS.PartialPath

Last path point is not a destination but a nearest position
among found;

#number

FIND_PATH_STATUS.StartPolygonNotFound

`source` position is too far from available
navigation mesh. The status may appear when navigation mesh is not fully generated or position is outside of covered
area;

#number

FIND_PATH_STATUS.Success

Path is found.

#number

FIND_PATH_STATUS.TargetPolygonNotFound

adjusted `destination` position is too far from
available navigation mesh. The status may appear when navigation mesh is not fully generated or position is outside
of covered area;

## Type `FindNearestNavMeshPositionOptions`

A table of parameters for nearby.findNearestNavMeshPosition

### Field(s)

#AgentBounds

FindNearestNavMeshPositionOptions.agentBounds

Identifies which navmesh to use.

#number

FindNearestNavMeshPositionOptions.includeFlags

Allowed areas for agent to move, a sum of #NAVIGATOR_FLAGS
values (default: NAVIGATOR_FLAGS.Walk + NAVIGATOR_FLAGS.Swim + NAVIGATOR_FLAGS.OpenDoor
+ NAVIGATOR_FLAGS.UsePathgrid).

openmw.util#Vector3

FindNearestNavMeshPositionOptions.searchAreaHalfExtents

Defines AABB like area half extents around
given position (default: (1 + 2 * CellGridRadius) * CellSize * (1, 1, 1) where CellGridRadius and depends on cell
type to cover the whole active grid).

## Type `FindPathOptions`

A table of parameters for nearby.findPath

### Field(s)

#AgentBounds

FindPathOptions.agentBounds

identifies which navmesh to use.

#AreaCosts

FindPathOptions.areaCosts

a table defining relative cost for each type of area.

#table

FindPathOptions.checkpoints

an array of positions to build path over if possible.

#number

FindPathOptions.destinationTolerance

a floating point number representing maximum allowed
distance between destination and a nearest point on the navigation mesh in addition to agent size (default: 1).

#number

FindPathOptions.includeFlags

allowed areas for agent to move, a sum of #NAVIGATOR_FLAGS
values (default: NAVIGATOR_FLAGS.Walk + NAVIGATOR_FLAGS.Swim + NAVIGATOR_FLAGS.OpenDoor
+ NAVIGATOR_FLAGS.UsePathgrid).

## Type `NAVIGATOR_FLAGS`

### Field(s)

#number

NAVIGATOR_FLAGS.OpenDoor

Allow agent to open doors on the way.

#number

NAVIGATOR_FLAGS.Swim

Allow agent to swim on the water surface.

#number

NAVIGATOR_FLAGS.UsePathgrid

Allow agent to use predefined pathgrid imported from ESM files.

#number

NAVIGATOR_FLAGS.Walk

Allow agent to walk on the ground area.

## Type `NavMeshOptions`

A table of parameters for nearby.findRandomPointAroundCircle and nearby.castNavigationRay

### Field(s)

#AgentBounds

NavMeshOptions.agentBounds

Identifies which navmesh to use.

#number

NavMeshOptions.includeFlags

Allowed areas for agent to move, a sum of #NAVIGATOR_FLAGS
values (default: NAVIGATOR_FLAGS.Walk + NAVIGATOR_FLAGS.Swim + NAVIGATOR_FLAGS.OpenDoor
+ NAVIGATOR_FLAGS.UsePathgrid).

## Type `RayCastingResult`

Result of raycasting

### Field(s)

#boolean

RayCastingResult.hit

Is there a collision? (true/false)

openmw.util#Vector3

RayCastingResult.hitNormal

Normal to the surface in the collision point (nil if no collision)

openmw.core#GameObject

RayCastingResult.hitObject

The object the ray has collided with (can be nil)

openmw.util#Vector3

RayCastingResult.hitPos

Position of the collision point (nil if no collision)

Package openmw.menu

Package openmw.postprocessing
