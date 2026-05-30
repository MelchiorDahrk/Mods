# OpenMW Lua Concepts

Sources checked:

- references/docs/overview.md
- references/docs/api.md
- references/docs/engine_handlers.md
- references/docs/events.md
- references/docs/iterables.md

## Language and sandbox

OpenMW uses Lua 5.1 with selected Lua 5.2 and 5.3 features. Scripts run in separate sandboxes and do not have general OS access. Standard libraries are limited; `require` can load standard libraries, built-in OpenMW packages, and Lua source files from data folders. DLLs and precompiled Lua files are prohibited.

Use Teal only when the user asks for typed declarations or typed OpenMW Lua work.

## Script types

- Global scripts are always active, are listed in `.omwscripts`, and can use global APIs such as `openmw.world`.
- Menu scripts run even before a game is loaded and are suitable for main-menu and save-management work.
- Local scripts are attached to game objects and are active only when their object is in an active cell. They can mutate only the attached object.
- Player scripts are local scripts attached to a player. They can use player-only UI, camera, input, ambient, and postprocessing APIs.
- Load scripts run while content files are being loaded and can use `openmw.content`.

## .omwscripts format

Each line has flags and a VFS path:

```text
GLOBAL: scripts/my_mod/global.lua
MENU: scripts/my_mod/menu.lua
PLAYER: scripts/my_mod/player.lua
NPC, CREATURE: scripts/my_mod/actor.lua
CONTAINER, CUSTOM: scripts/my_mod/container.lua
LOAD: scripts/my_mod/load.lua
```

Common flags include `GLOBAL`, `MENU`, `CUSTOM`, `PLAYER`, `LOAD`, and object type flags such as `ACTIVATOR`, `ARMOR`, `BOOK`, `CLOTHING`, `CONTAINER`, `CREATURE`, `DOOR`, `INGREDIENT`, `LIGHT`, `MISC_ITEM`, `NPC`, `POTION`, `WEAPON`, `APPARATUS`, `LOCKPICK`, `PROBE`, and `REPAIR`.

Enable an `.omwscripts` file through `openmw.cfg` like other content:

```text
data=path/to/my_lua_mod
content=my_lua_mod.omwscripts
```

## Script structure

Scripts return a table. All sections are optional:

```lua
return {
    interfaceName = 'MyInterface',
    interface = {
        somePublicFunction = somePublicFunction,
    },
    eventHandlers = {
        MyEvent = myEventHandler,
    },
    engineHandlers = {
        onInit = onInit,
        onUpdate = onUpdate,
        onSave = onSave,
        onLoad = onLoad,
    },
}
```

`engineHandlers` are called by the engine. `eventHandlers` receive script events. Interfaces expose functions or data to other scripts.

## Engine handlers

Universal or broad handlers include `onInit`, `onUpdate`, `onSave`, `onLoad`, and `onInterfaceOverride`.

Global-only handlers include `onNewGame`, `onPlayerAdded`, `onObjectActive`, `onActorActive`, `onItemActive`, `onActivate`, and `onNewExterior`.

Local-only handlers include `onActive`, `onInactive`, `onTeleported`, `onActivated`, and `onConsume`.

Menu/player handlers include `onFrame`, `onKeyPress`, `onKeyRelease`, controller button handlers, and input-related handlers.

Important save/load rule: `onSave` can be called for inactive objects, and `onLoad` runs while the object is inactive. Avoid `openmw.nearby` in both.

## Events

Use events for script-to-script communication. Local scripts, global scripts, and objects can send events depending on context and API. For built-in event names and payloads, consult the Events page.

When designing custom events, keep names stable and payloads serializable or simple. Document expected fields near the sender and receiver.

## Iterables

Some OpenMW APIs return iterable collections rather than plain Lua arrays. Check the Iterables page for supported operations before assuming `#`, numeric indexing, or mutation.

## Hot reload and console

The in-game console command `reloadlua` reloads `.omwscripts` and unpacked `.lua` files. It restarts scripts using save/load handlers. Scripts packed in BSA archives and `.omwaddon` script definitions require a restart.

Lua console modes include player, global, selected-object local, and menu contexts.

