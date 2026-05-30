# Package openmw.util

# Package openmw.util

API v129

Defines utility functions and classes like 3D vectors, that don't depend on the game world.

global
menu
local
player
load

## Usage

`local util = require('openmw.util')`

## Type `util`

util.bitAnd(A, B)

Bitwise And (supports any number of arguments).

util.bitNot(A)

Bitwise inversion.

util.bitOr(A, B)

Bitwise Or (supports any number of arguments).

util.bitXor(A, B)

Bitwise Xor (supports any number of arguments).

util.box(transform)

Creates a new Box from a given transformation.

util.clamp(value, from, to)

Limits given value to the interval [`from`, `to`].

util.color

Methods for creating #Color values from different formats.

util.loadCode(code, table)

Parses Lua code from string and returns as a function.

util.makeReadOnly(table)

Makes a table read only.

util.makeStrictReadOnly(table)

Makes a table read only and overrides `__index` with the strict version that throws an error if the key is not found.

util.normalizeAngle(angle)

Adds `2pi*k` and puts the angle in range `[-pi, pi]`.

util.remap(value, min, max, newMin, newMax)

Remaps the value from one range to another.

util.round(value)

Rounds the given value to the nearest whole number.

util.transform

3D transforms (scale/move/rotate) that can be applied to 3D vectors.

util.vector2(x, y)

Creates a new 2D vector.

util.vector3(x, y, z)

Creates a new 3D vector.

util.vector4(x, y, z, w)

Creates a new 4D vector.

## Type `Box`

Box.center

The center of the box

Box.halfSize

The half sizes of the box along each axis

Box.transform

A transformation which encapsulates the boxes center pointer (translation), half sizes (scale), and rotation.

Box.vertices

Table of the 8 vertices which comprise the box, taking rotation into account

## Type `COLOR`

COLOR.commaString(str)

Creates a Color from comma-separated string (in RGB or RGBA order, spaces are ignored)

COLOR.hex(hex)

Parses a hex color string into a Color.

COLOR.rgb(r, g, b)

Creates a Color from RGB format.

COLOR.rgba(r, g, b, a)

Creates a Color from RGBA format

## Type `Color`

Color.a

Alpha (transparency) component

Color:asHex()

Converts the color into a HEX string.

Color:asRgb()

Returns a Vector3 with RGB components of the Color.

Color:asRgba()

Returns a Vector4 with RGBA components of the Color.

Color.b

Blue component

Color.g

Green component

Color.r

Red component

## Type `TRANSFORM`

TRANSFORM.identity

Empty transform.

TRANSFORM.move(offset)

Movement by given vector.

TRANSFORM.rotate(angle, axis)

Rotation around a vector (counterclockwise if the vector points to us).

TRANSFORM.rotateX(angle)

X-axis rotation (equivalent to `rotate(angle, vector3(-1, 0, 0))`).

TRANSFORM.rotateY(angle)

Y-axis rotation (equivalent to `rotate(angle, vector3(0, -1, 0))`).

TRANSFORM.rotateZ(angle)

Z-axis rotation (equivalent to `rotate(angle, vector3(0, 0, -1))`).

TRANSFORM.scale(scaleX, scaleY, scaleZ)

Scale transform.

## Type `Transform`

Transform:__mul(t)

Combine transforms (will apply in reverse order)

Transform:apply(v)

Apply transform to a vector

Transform:getAnglesXZ()

Get Euler angles for XZ rotation order (pitch and yaw; radians)

Transform:getAnglesZYX()

Get Euler angles for ZYX rotation order (radians)

Transform:getPitch()

Get pitch angle (radians)

Transform:getYaw()

Get yaw angle (radians)

Transform:inverse()

Returns the inverse transform.

## Type `Vector2`

Vector2:__add(v)

Vector2:__div(k)

Vector2:__mul(k)

Vector2:__sub(v)

Vector2:dot(v)

Dot product.

Vector2:ediv(v)

Element-wise division

Vector2:emul(v)

Element-wise multiplication

Vector2:length()

Length of the vector.

Vector2:length2()

Square of the length of the vector.

Vector2:normalize()

Normalizes vector.

Vector2:rotate(angle)

Rotates 2D vector clockwise.

Vector2.x

Vector2.xy01

swizzle support, any combination of fields can be used to construct a new vector including the 0/1 constants

Vector2.y

## Type `Vector3`

Vector3:__add(v)

Vector3:__div(k)

Vector3:__mul(k)

Vector3:__sub(v)

Vector3:__tostring()

Vector3:cross(v)

Cross product.

Vector3:dot(v)

Dot product.

Vector3:ediv(v)

Element-wise division

Vector3:emul(v)

Element-wise multiplication

Vector3:length()

Length of the vector

Vector3:length2()

Square of the length of the vector

Vector3:normalize()

Normalizes vector.

Vector3.x

Vector3.xyz01

swizzle support, any combination of fields can be used to construct a new vector including the 0/1 constants

Vector3.y

Vector3.z

## Type `Vector4`

Vector4:__add(v)

Vector4:__div(k)

Vector4:__mul(k)

Vector4:__sub(v)

Vector4:__tostring()

Vector4:dot(v)

Dot product.

Vector4:ediv(v)

Element-wise division

Vector4:emul(v)

Element-wise multiplication

Vector4:length()

Length of the vector

Vector4:length2()

Square of the length of the vector

Vector4:normalize()

Normalizes vector.

Vector4.w

Vector4.x

Vector4.xyzw01

swizzle support, any combination of fields can be used to construct a new vector including the 0/1 constants

Vector4.y

Vector4.z

## Type `util`

### Field(s)

util.bitAnd(A, B)

Bitwise And (supports any number of arguments).

### Parameters

-
` #number A `:
First argument (integer).

-
` #number B `:
Second argument (integer).

### Return value

#number:
Bitwise And of A and B.

util.bitNot(A)

Bitwise inversion.

### Parameter

-
` #number A `:
Argument (integer).

### Return value

#number:
Bitwise Not of A.

util.bitOr(A, B)

Bitwise Or (supports any number of arguments).

### Parameters

-
` #number A `:
First argument (integer).

-
` #number B `:
Second argument (integer).

### Return value

#number:
Bitwise Or of A and B.

util.bitXor(A, B)

Bitwise Xor (supports any number of arguments).

### Parameters

-
` #number A `:
First argument (integer).

-
` #number B `:
Second argument (integer).

### Return value

#number:
Bitwise Xor of A and B.

util.box(transform)

Creates a new Box from a given transformation.

Boxes are immutable and can not be changed after creation.

### Parameter

-
` #Transform transform `:
A transformation which encapsulates the boxes center pointer (translation), half sizes (scale), and rotation.

### Return value

#Box:

### Usage

`-- Creates a 1x1x1 length box centered at the origin
util.box(util.transform.scale(util.vector3(0.5, 0.5, 0.5)))`

util.clamp(value, from, to)

Limits given value to the interval [`from`, `to`].

### Parameters

-
` #number value `:

-
` #number from `:

-
` #number to `:

### Return value

#number:
min(max(value, from), to)

#COLOR

util.color

Methods for creating #Color values from different formats.

util.loadCode(code, table)

Parses Lua code from string and returns as a function.

### Parameters

-
` #string code `:
Lua code.

-
` #table table `:
Environment to run the code in.

### Return value

#function:
The loaded code.

util.makeReadOnly(table)

Makes a table read only.

### Parameter

-
` #table table `:
Any table.

### Return value

#table:
The same table wrapped with read only userdata.

util.makeStrictReadOnly(table)

Makes a table read only and overrides `__index` with the strict version that throws an error if the key is not found.

### Parameter

-
` #table table `:
Any table.

### Return value

#table:
The same table wrapped with read only userdata.

util.normalizeAngle(angle)

Adds `2pi*k` and puts the angle in range `[-pi, pi]`.

### Parameter

-
` #number angle `:
Angle in radians

### Return value

#number:
Angle in range `[-pi, pi]`

util.remap(value, min, max, newMin, newMax)

Remaps the value from one range to another.

### Parameters

-
` #number value `:

-
` #number min `:

-
` #number max `:

-
` #number newMin `:

-
` #number newMax `:

### Return value

#number:
The remapped value.

### Usage

`local util = require('openmw.util')
local newValue = util.remap(3, 0, 10, 0, 100)
print(newValue) -- prints 30`

util.round(value)

Rounds the given value to the nearest whole number.

### Parameter

-
` #number value `:

### Return value

#number:
The rounded value.

### Usage

`local util = require('openmw.util')
local roundedValue = util.round(3.141592)
print(roundedValue) -- prints 3`

#TRANSFORM

util.transform

3D transforms (scale/move/rotate) that can be applied to 3D vectors.

Several transforms can be combined and applied to a vector using multiplication.
Combined transforms apply in reverse order (from right to left).

### Usage

`local util = require('openmw.util')
local trans = util.transform
local fromActorSpace = trans.move(actor.position) * trans.rotateZ(actor.rotation:getYaw())

-- rotation is applied first, movement is second
local posBehindActor = fromActorSpace * util.vector3(0, -100, 0)

-- equivalent to trans.rotateZ(-actor.rotation:getYaw()) * trans.move(-actor.position)
local toActorSpace = fromActorSpace:inverse()
local relativeTargetPos = toActorSpace * target.position
local deltaAngle = math.atan2(relativeTargetPos.y, relativeTargetPos.x)`

util.vector2(x, y)

Creates a new 2D vector.

Vectors are immutable and can not be changed after creation.

### Parameters

-
` #number x `:

-
` #number y `:

### Return value

#Vector2:

util.vector3(x, y, z)

Creates a new 3D vector.

Vectors are immutable and can not be changed after creation.

### Parameters

-
` #number x `:

-
` #number y `:

-
` #number z `:

### Return value

#Vector3:

util.vector4(x, y, z, w)

Creates a new 4D vector.

Vectors are immutable and can not be changed after creation.

### Parameters

-
` #number x `:

-
` #number y `:

-
` #number z `:

-
` #number w `:

### Return value

#Vector4:

## Type `Box`

Immutable box.

### Field(s)

#Vector3

Box.center

The center of the box

#Vector3

Box.halfSize

The half sizes of the box along each axis

#Transform

Box.transform

A transformation which encapsulates the boxes center pointer (translation), half sizes (scale), and rotation.

#table

Box.vertices

Table of the 8 vertices which comprise the box, taking rotation into account

## Type `COLOR`

Methods for creating #Color values from different formats.

### Field(s)

COLOR.commaString(str)

Creates a Color from comma-separated string (in RGB or RGBA order, spaces are ignored)

### Parameter

-
` #string str `:

### Return value

#Color:

### Usages

-

`local color = util.color.commaString('255,0,0') -- red color`

-

`local color = util.color.commaString('10000,0,0') -- red color (values are still capped at 255)`

-

`local color = util.color.commaString('0, 0, 255, 255') -- blue color, with explicit alpha`

-

`local color = util.color.commaString('0,255,0,128') -- green color, semi-transparent`

COLOR.hex(hex)

Parses a hex color string into a Color.

### Parameter

-
` #string hex `:
A hex color string in RRGGBB format (e. g. "ff0000").

### Return value

#Color:

COLOR.rgb(r, g, b)

Creates a Color from RGB format.

Equivalent to calling util.rgba with a = 1.

### Parameters

-
` #number r `:

-
` #number g `:

-
` #number b `:

### Return value

#Color:

COLOR.rgba(r, g, b, a)

Creates a Color from RGBA format

### Parameters

-
` #number r `:

-
` #number g `:

-
` #number b `:

-
` #number a `:

### Return value

#Color:

## Type `Color`

Color in RGBA format.

All of the component values are in the range [0, 1].

### Field(s)

#number

Color.a

Alpha (transparency) component

Color:asHex()

Converts the color into a HEX string.

### Return value

#string:

Color:asRgb()

Returns a Vector3 with RGB components of the Color.

### Return value

#Vector3:

Color:asRgba()

Returns a Vector4 with RGBA components of the Color.

### Return value

#Vector4:

#number

Color.b

Blue component

#number

Color.g

Green component

#number

Color.r

Red component

## Type `TRANSFORM`

### Field(s)

#Transform

TRANSFORM.identity

Empty transform.

TRANSFORM.move(offset)

Movement by given vector.

### Parameter

-
` #Vector3 offset `:

### Return value

#Transform:

### Usage

`-- Accepts either 3 numbers or a 3D vector
util.transform.move(x, y, z)
util.transform.move(util.vector3(x, y, z))`

TRANSFORM.rotate(angle, axis)

Rotation around a vector (counterclockwise if the vector points to us).

### Parameters

-
` #number angle `:

-
` #Vector3 axis `:

### Return value

#Transform:

TRANSFORM.rotateX(angle)

X-axis rotation (equivalent to `rotate(angle, vector3(-1, 0, 0))`).

### Parameter

-
` #number angle `:

### Return value

#Transform:

TRANSFORM.rotateY(angle)

Y-axis rotation (equivalent to `rotate(angle, vector3(0, -1, 0))`).

### Parameter

-
` #number angle `:

### Return value

#Transform:

TRANSFORM.rotateZ(angle)

Z-axis rotation (equivalent to `rotate(angle, vector3(0, 0, -1))`).

### Parameter

-
` #number angle `:

### Return value

#Transform:

TRANSFORM.scale(scaleX, scaleY, scaleZ)

Scale transform.

### Parameters

-
` #number scaleX `:

-
` #number scaleY `:

-
` #number scaleZ `:

### Return value

#Transform:

### Usage

`-- Accepts either 3 numbers or a 3D vector
util.transform.scale(x, y, z)
util.transform.scale(util.vector3(x, y, z))`

## Type `Transform`

### Field(s)

Transform:__mul(t)

Combine transforms (will apply in reverse order)

### Parameter

-
` #Transform t `:

### Return value

#Transform:

Transform:apply(v)

Apply transform to a vector

### Parameter

-
` #Vector3 v `:

### Return value

#Vector3:

Transform:getAnglesXZ()

Get Euler angles for XZ rotation order (pitch and yaw; radians)

### Return values

-
#number:
pitch (rotation around X axis)

-
#number:
yaw (rotation around Z axis)

Transform:getAnglesZYX()

Get Euler angles for ZYX rotation order (radians)

### Return values

-
#number:
rotation around Z axis (first rotation)

-
#number:
rotation around Y axis (second rotation)

-
#number:
rotation around X axis (third rotation)

Transform:getPitch()

Get pitch angle (radians)

### Return value

#number:

Transform:getYaw()

Get yaw angle (radians)

### Return value

#number:

Transform:inverse()

Returns the inverse transform.

### Return value

#Transform:

## Type `Vector2`

Immutable 2D vector

### Usage

`v = util.vector2(3, 4)
v.x, v.y -- 3.0, 4.0
str(v) -- "(3.0, 4.0)"
v:length() -- 5.0 length
v:length2() -- 25.0 square of the length
v:normalize() -- vector2(3/5, 4/5)
v:rotate(radians) -- rotate counterclockwise (returns rotated vector)
v1:dot(v2) -- dot product (returns a number)
v1 * v2 -- dot product
v1 + v2 -- vector addition
v1 - v2 -- vector subtraction
v1 * x -- multiplication by a number
v1 / x -- division by a number
v1.xx, v1.xyx -- swizzle with standard fields
v1.y1y, v1.x00 -- swizzle with 0/1 constant
v1['0xy'] -- swizzle with 0/1 constant starting with 0 or 1`

### Field(s)

Vector2:__add(v)

### Parameter

-
` #Vector2 v `:

### Return value

#Vector2:
sum of the vectors

Vector2:__div(k)

### Parameter

-
` #number k `:

### Return value

#Vector2:
vector divided by a number

Vector2:__mul(k)

### Parameter

-
` #number k `:

### Return value

#Vector2:
vector multiplied by a number

Vector2:__sub(v)

### Parameter

-
` #Vector2 v `:

### Return value

#Vector2:
difference of the vectors

Vector2:dot(v)

Dot product.

### Parameter

-
` #Vector2 v `:

### Return value

#number:

Vector2:ediv(v)

Element-wise division

### Parameter

-
` #Vector2 v `:

### Return value

#Vector2:

Vector2:emul(v)

Element-wise multiplication

### Parameter

-
` #Vector2 v `:

### Return value

#Vector2:

Vector2:length()

Length of the vector.

### Return value

#number:

Vector2:length2()

Square of the length of the vector.

### Return value

#number:

Vector2:normalize()

Normalizes vector.

It doesn't change the original vector.

### Return values

-
#Vector2:
normalized vector

-
#number:
the length of the original vector

Vector2:rotate(angle)

Rotates 2D vector clockwise.

### Parameter

-
` #number angle `:
Angle in radians

### Return value

#Vector2:
Rotated vector.

#number

Vector2.x

#string

Vector2.xy01

swizzle support, any combination of fields can be used to construct a new vector including the 0/1 constants

#number

Vector2.y

## Type `Vector3`

Immutable 3D vector

### Usage

`v = util.vector3(3, 4, 5)
v.x, v.y, v.z -- 3.0, 4.0, 5.0
str(v) -- "(3.0, 4.0, 4.5)"
v:length() -- length
v:length2() -- square of the length
v:normalize() -- normalized vector
v1:dot(v2) -- dot product (returns a number)
v1 * v2 -- dot product (returns a number)
v1:cross(v2) -- cross product (returns a vector)
v1 ^ v2 -- cross product (returns a vector)
v1 + v2 -- vector addition
v1 - v2 -- vector subtraction
v1 * x -- multiplication by a number
v1 / x -- division by a number
v1.zyz, v1.yx -- swizzle with standard fields
v1.w1y, v1.z0z -- swizzle with 0/1 constant
v1['0xy'] -- swizzle with 0/1 constant starting with 0 or 1`

### Field(s)

Vector3:__add(v)

### Parameter

-
` #Vector3 v `:

### Return value

#Vector3:
sum of the vectors

Vector3:__div(k)

### Parameter

-
` #number k `:

### Return value

#Vector3:
vector divided by a number

Vector3:__mul(k)

### Parameter

-
` #number k `:

### Return value

#Vector3:
vector multiplied by a number

Vector3:__sub(v)

### Parameter

-
` #Vector3 v `:

### Return value

#Vector3:
difference of the vectors

Vector3:__tostring()

### Return value

#string:

Vector3:cross(v)

Cross product.

### Parameter

-
` #Vector3 v `:

### Return value

#Vector3:

Vector3:dot(v)

Dot product.

### Parameter

-
` #Vector3 v `:

### Return value

#number:

Vector3:ediv(v)

Element-wise division

### Parameter

-
` #Vector3 v `:

### Return value

#Vector3:

Vector3:emul(v)

Element-wise multiplication

### Parameter

-
` #Vector3 v `:

### Return value

#Vector3:

Vector3:length()

Length of the vector

### Return value

#number:

Vector3:length2()

Square of the length of the vector

### Return value

#number:

Vector3:normalize()

Normalizes vector.

It doesn't change the original vector.

### Return values

-
#Vector3:
normalized vector

-
#number:
the length of the original vector

#number

Vector3.x

#string

Vector3.xyz01

swizzle support, any combination of fields can be used to construct a new vector including the 0/1 constants

#number

Vector3.y

#number

Vector3.z

## Type `Vector4`

Immutable 4D vector.

### Usage

`v = util.vector4(3, 4, 5, 6)
v.x, v.y, v.z, v.w -- 3.0, 4.0, 5.0, 6.0
str(v) -- "(3.0, 4.0, 5.0, 6.0)"
v:length() -- length
v:length2() -- square of the length
v:normalize() -- normalized vector
v1:dot(v2) -- dot product (returns a number)
v1 * v2 -- dot product (returns a number)
v1 + v2 -- vector addition
v1 - v2 -- vector subtraction
v1 * x -- multiplication by a number
v1 / x -- division by a number
v1.zyz, v1.wwwx -- swizzle with standard fields
v1.w1, v1.z000 -- swizzle with 0/1 constant
v1['000w'] -- swizzle with 0/1 constant starting with 0 or 1`

### Field(s)

Vector4:__add(v)

### Parameter

-
` #Vector4 v `:

### Return value

#Vector4:
sum of the vectors

Vector4:__div(k)

### Parameter

-
` #number k `:

### Return value

#Vector4:
vector divided by a number

Vector4:__mul(k)

### Parameter

-
` #number k `:

### Return value

#Vector4:
vector multiplied by a number

Vector4:__sub(v)

### Parameter

-
` #Vector4 v `:

### Return value

#Vector4:
difference of the vectors

Vector4:__tostring()

### Return value

#string:

Vector4:dot(v)

Dot product.

### Parameter

-
` #Vector4 v `:

### Return value

#number:

Vector4:ediv(v)

Element-wise division

### Parameter

-
` #Vector4 v `:

### Return value

#Vector4:

Vector4:emul(v)

Element-wise multiplication

### Parameter

-
` #Vector4 v `:

### Return value

#Vector4:

Vector4:length()

Length of the vector

### Return value

#number:

Vector4:length2()

Square of the length of the vector

### Return value

#number:

Vector4:normalize()

Normalizes vector.

It doesn't change the original vector.

### Return values

-
#Vector4:
normalized vector

-
#number:
the length of the original vector

#number

Vector4.w

#number

Vector4.x

#string

Vector4.xyzw01

swizzle support, any combination of fields can be used to construct a new vector including the 0/1 constants

#number

Vector4.y

#number

Vector4.z

Package openmw.ui

Package openmw.vfs
