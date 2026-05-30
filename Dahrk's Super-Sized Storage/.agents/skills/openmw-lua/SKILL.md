---
name: openmw-lua
description: Build, review, debug, or explain OpenMW Lua scripts and OpenMW mod scripting structure. Use this skill whenever the user mentions OpenMW Lua, openmw-lua, .omwscripts, OpenMW script packages such as openmw.core/openmw.world/openmw.self/openmw.ui, built-in script interfaces, engine handlers, local/global/player/menu scripts, or asks for Morrowind/OpenMW mod behavior implemented in Lua, even if they do not explicitly ask for a skill.
---

# OpenMW Lua

Use this skill to write or review OpenMW Lua code that matches the current OpenMW Lua scripting model and avoids MWSE habits that do not apply to OpenMW.

## First steps

1. Identify the script context before choosing APIs: `GLOBAL`, `MENU`, `PLAYER`, `LOCAL`, or `LOAD`.
2. Read `references/concepts.md` for sandboxing, script structure, `.omwscripts`, events, save/load, and context rules.
3. Read `references/api-map.md` for package availability and the specific OpenMW docs page to consult.
4. If the task touches UI widgets, setting renderers, AI packages, or built-in interfaces, also use the matching section in `references/api-map.md`.

When writing code, include the script file path and the `.omwscripts` entry when that is useful to make the output installable.

## Core mental model

OpenMW Lua is not MWScript and not MWSE Lua. Scripts run in sandboxes with a limited Lua 5.1-based environment. They interact with the engine by:

- Loading API packages with `require('openmw.package')` or helper libraries with `require('openmw_aux.package')`.
- Returning a table that registers `engineHandlers`, `eventHandlers`, and optionally a public script interface.
- Sending events between scripts or using `openmw.interfaces` to talk to built-in script interfaces.
- Saving script state only through `onSave`; restoring it through `onLoad`.

Pick APIs by authority:

- `openmw.self`: mutate the object the local/player script is attached to.
- `openmw.nearby`: read nearby active cells from a local/player script.
- `openmw.world`: global-script world read/write access.
- `openmw.ui`, `openmw.input`, `openmw.camera`, `openmw.ambient`, `openmw.postprocessing`: player/menu scoped features.
- `openmw.content`: load-script content manipulation before the game fully starts.
- `openmw.types`: type-specific helpers for records, actors, items, inventory, stats, spells, and object behavior.
- `openmw.core`: common engine data, records, game time, object references, cells, magic constants, and shared types.
- `openmw.util`: vectors, transforms, colors, math helpers, readonly helpers.

## Context checks

Before finalizing code, verify these constraints:

- Local scripts can mutate only their own attached object through `openmw.self`; other visible objects are read-only.
- `openmw.nearby` is available only to active local/player scripts. Do not call it from `onSave`, `onLoad`, or inactive handlers.
- Player-only packages and interfaces require a player script, not an arbitrary local script.
- Menu scripts can run before a game is loaded, so avoid assumptions about player/world objects unless the API explicitly supports it.
- Global scripts can affect the world through `openmw.world`, but use the global API shape rather than local `openmw.self` patterns.
- Load scripts use `openmw.content` for content records and should not rely on runtime world state.
- Save data must be serializable. Store ids, primitive values, plain tables, and re-resolvable references rather than closures or engine objects unless the docs say they serialize.

## Code style

Prefer small, explicit modules:

```lua
local core = require('openmw.core')
local self = require('openmw.self')

local function onSave()
    return {
        version = 1,
        enabled = true,
    }
end

local function onLoad(data)
    if data and data.version == 1 then
        -- restore state here
    end
end

return {
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad,
    },
}
```

Use `local` for functions and package imports. Every script instance has a separate environment, but locals are clearer and faster.

Use `scripts/<ModName>/<ScriptName>.lua` or `scripts/<AuthorName>/<ModName>/<ScriptName>.lua`. Avoid `scripts/omw/`, which is reserved for built-in scripts.

## Common output patterns

For a complete mod scripting answer, provide:

- A short explanation of which script context is appropriate and why.
- One or more `.lua` files with paths.
- The corresponding `.omwscripts` lines, for example `PLAYER: scripts/my_mod/player.lua`.
- Any required `openmw.cfg` content entry, usually `content=my_mod.omwscripts`.
- Notes on hot reload with `reloadlua` when useful.

For reviews, focus on context misuse, read/write authority, save/load safety, unavailable packages, UI/player-only mistakes, and MWSE terminology or APIs.

## When uncertain

OpenMW Lua API pages are detailed and versioned. If a function signature, enum, or context is not in `references/api-map.md`, consult the official docs page linked there before inventing an API. Prefer saying that an API needs confirmation over guessing names.

