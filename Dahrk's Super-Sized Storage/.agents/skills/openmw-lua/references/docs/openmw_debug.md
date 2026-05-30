# Package openmw.debug

# Package openmw.debug

API v129

Provides an interface to the engine debug utils.

player

## Usage

`local debug = require('openmw.debug')`

## Type `Debug`

Debug.NAV_MESH_RENDER_MODE

Navigation mesh rendering mode values

Debug.RENDER_MODE

Rendering mode values

Debug.isAIEnabled()

Is AI enabled

Debug.isCollisionEnabled()

Is player collision enabled

Debug.isGodMode()

Is god mode enabled

Debug.isMWScriptEnabled()

Is MWScripts enabled

Debug.reloadLua()

Reloads all Lua scripts

Debug.setNavMeshRenderMode(value)

Sets navigation mesh rendering mode

Debug.setShaderHotReloadEnabled(value)

Enable/disable automatic reload of modified shaders

Debug.toggleAI()

Toggles AI

Debug.toggleCollision()

Toggles collisions

Debug.toggleGodMode()

Toggles god mode

Debug.toggleMWScript()

Toggles MWScripts

Debug.toggleRenderMode(value)

Toggles rendering mode

Debug.triggerShaderReload()

To reload modified shaders

## Type `NAV_MESH_RENDER_MODE`

NAV_MESH_RENDER_MODE.AreaType

NAV_MESH_RENDER_MODE.UpdateFrequency

## Type `RENDER_MODE`

RENDER_MODE.ActorsPaths

RENDER_MODE.CollisionDebug

RENDER_MODE.NavMesh

RENDER_MODE.Pathgrid

RENDER_MODE.RecastMesh

RENDER_MODE.Scene

RENDER_MODE.Water

RENDER_MODE.Wireframe

## Type `Debug`

### Field(s)

#NAV_MESH_RENDER_MODE

Debug.NAV_MESH_RENDER_MODE

Navigation mesh rendering mode values

#RENDER_MODE

Debug.RENDER_MODE

Rendering mode values

Debug.isAIEnabled()

Is AI enabled

### Return value

#boolean:

Debug.isCollisionEnabled()

Is player collision enabled

### Return value

#boolean:

Debug.isGodMode()

Is god mode enabled

### Return value

#boolean:

Debug.isMWScriptEnabled()

Is MWScripts enabled

### Return value

#boolean:

Debug.reloadLua()

Reloads all Lua scripts

Debug.setNavMeshRenderMode(value)

Sets navigation mesh rendering mode

### Parameter

-
` #NAV MESH RENDER_MODE value `:

Debug.setShaderHotReloadEnabled(value)

Enable/disable automatic reload of modified shaders

### Parameter

-
` #boolean value `:

Debug.toggleAI()

Toggles AI

Debug.toggleCollision()

Toggles collisions

Debug.toggleGodMode()

Toggles god mode

Debug.toggleMWScript()

Toggles MWScripts

Debug.toggleRenderMode(value)

Toggles rendering mode

### Parameter

-
` #RENDER_MODE value `:

Debug.triggerShaderReload()

To reload modified shaders

## Type `NAV_MESH_RENDER_MODE`

Navigation mesh rendering modes

### Field(s)

#number

NAV_MESH_RENDER_MODE.AreaType

#number

NAV_MESH_RENDER_MODE.UpdateFrequency

## Type `RENDER_MODE`

Rendering modes

### Field(s)

#number

RENDER_MODE.ActorsPaths

#number

RENDER_MODE.CollisionDebug

#number

RENDER_MODE.NavMesh

#number

RENDER_MODE.Pathgrid

#number

RENDER_MODE.RecastMesh

#number

RENDER_MODE.Scene

#number

RENDER_MODE.Water

#number

RENDER_MODE.Wireframe

Package openmw.core

Package openmw.input
