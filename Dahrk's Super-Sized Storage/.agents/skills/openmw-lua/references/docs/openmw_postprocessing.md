# Package openmw.postprocessing

# Package openmw.postprocessing

API v129

Provides an interface to postprocessing shaders.

player

## Usage

`local postprocessing = require('openmw.postprocessing')`

## Type `postprocessing`

postprocessing.getChain()

Returns the ordered list of active shaders.

postprocessing.load(name)

Load a shader and return its handle.

## Type `Shader`

Shader.author

Author of the shader

Shader.description

Description of the shader

Shader:disable()

Deactivate the shader.

Shader:enable(position)

Enable the shader.

Shader:isEnabled()

Check if the shader is enabled.

Shader.name

Name of the shader

Shader:setBool(name, value)

Set a non static bool shader variable.

Shader:setFloat(name, value)

Set a non static float shader variable.

Shader:setFloatArray(name, array)

Set a non static float array shader variable.

Shader:setInt(name, value)

Set a non static integer shader variable.

Shader:setIntArray(name, array)

Set a non static integer array shader variable.

Shader:setVector2(name, value)

Set a non static Vector2 shader variable.

Shader:setVector2Array(name, array)

Set a non static Vector2 array shader variable.

Shader:setVector3(name, value)

Set a non static Vector3 shader variable.

Shader:setVector3Array(name, array)

Set a non static Vector3 array shader variable.

Shader:setVector4(name, value)

Set a non static Vector4 shader variable.

Shader:setVector4Array(name, array)

Set a non static Vector4 array shader variable.

Shader.version

Version of the shader

## Type `postprocessing`

### Field(s)

postprocessing.getChain()

Returns the ordered list of active shaders.

Active shaders may change between frames.

### Return value

#list<#Shader>:
list The currently active shaders, in order

postprocessing.load(name)

Load a shader and return its handle.

### Parameter

-
` #string name `:
Name of the shader without its extension

### Return value

#Shader:

### Usage

`-- If the shader exists and compiles, the shader will still be off by default.
-- It must be enabled to see its effect.
local vignetteShader = postprocessing.load('vignette')`

## Type `Shader`

### Field(s)

#string

Shader.author

Author of the shader

#string

Shader.description

Description of the shader

Shader:disable()

Deactivate the shader.

Has no effect if the shader is already deactivated or does not exist.
Will not apply until the next frame.

### Usage

`local vignetteShader = shader.postprocessing('vignette')
vignetteShader:disable() -- shader will be toggled off`

Shader:enable(position)

Enable the shader.

Has no effect if the shader is already enabled or does
not exist. Will not apply until the next frame.

### Parameter

-
` #number position `:
optional position to place the shader. If left out the shader will be inserted at the end of the chain.

### Usage

`-- Load shader
local vignetteShader = postprocessing.load('vignette')
-- Toggle shader on
vignetteShader:enable()`

Shader:isEnabled()

Check if the shader is enabled.

### Return value

#boolean:
True if shader is enabled and was compiled successfully.

### Usage

`local vignetteShader = shader.postprocessing('vignette')
vignetteShader:enable() -- shader will be toggled on`

#string

Shader.name

Name of the shader

Shader:setBool(name, value)

Set a non static bool shader variable.

### Parameters

-
` #string name `:
Name of uniform

-
` #boolean value `:
Value of uniform.

Shader:setFloat(name, value)

Set a non static float shader variable.

### Parameters

-
` #string name `:
Name of uniform

-
` #number value `:
Value of uniform.

Shader:setFloatArray(name, array)

Set a non static float array shader variable.

### Parameters

-
` #string name `:
Name of uniform

-
` #table array `:
Contains equal number of #number elements as the uniform array.

Shader:setInt(name, value)

Set a non static integer shader variable.

### Parameters

-
` #string name `:
Name of uniform

-
` #number value `:
Value of uniform.

Shader:setIntArray(name, array)

Set a non static integer array shader variable.

### Parameters

-
` #string name `:
Name of uniform

-
` #table array `:
Contains equal number of #number elements as the uniform array.

Shader:setVector2(name, value)

Set a non static Vector2 shader variable.

### Parameters

-
` #string name `:
Name of uniform

-
` openmw.util#Vector2 value `:
Value of uniform.

Shader:setVector2Array(name, array)

Set a non static Vector2 array shader variable.

### Parameters

-
` #string name `:
Name of uniform

-
` #table array `:
Contains equal number of openmw.util#Vector2 elements as the uniform array.

Shader:setVector3(name, value)

Set a non static Vector3 shader variable.

### Parameters

-
` #string name `:
Name of uniform

-
` openmw.util#Vector3 value `:
Value of uniform.

Shader:setVector3Array(name, array)

Set a non static Vector3 array shader variable.

### Parameters

-
` #string name `:
Name of uniform

-
` #table array `:
Contains equal number of openmw.util#Vector3 elements as the uniform array.

Shader:setVector4(name, value)

Set a non static Vector4 shader variable.

### Parameters

-
` #string name `:
Name of uniform

-
` openmw.util#Vector4 value `:
Value of uniform.

Shader:setVector4Array(name, array)

Set a non static Vector4 array shader variable.

### Parameters

-
` #string name `:
Name of uniform

-
` #table array `:
Contains equal number of openmw.util#Vector4 elements as the uniform array.

### Usage

`-- Setting an array
local shader = postprocessing.load('godrays')
-- Toggle shader on
shader:enable()
-- Set new array uniform which was defined with length 2
shader:setVector4Array('myArray', { util.vector4(1,0,0,1), util.vector4(1,0,1,1) })`

#string

Shader.version

Version of the shader

Package openmw.nearby

Package openmw.self
