# Package openmw.async

# Package openmw.async

API v129

Contains timers and coroutine utilities.

All functions require
the package itself as a first argument.

global
menu
local
player
load

## Usage

`local async = require('openmw.async')`

## Type `async`

async:callback(func)

Wraps a Lua function with a `Callback` object that can be used in async API calls.

async:newGameTimer(delay, callback, arg)

Calls callback(arg) in `delay` game seconds.

async:newSimulationTimer(delay, callback, arg)

Calls callback(arg) in `delay` simulation seconds.

async:newUnsavableGameTimer(delay, func)

Calls `func()` in `delay` game seconds.

async:newUnsavableSimulationTimer(delay, func)

Calls `func()` in `delay` simulation seconds.

async:registerTimerCallback(name, func)

Register a function as a timer callback.

## Type `async`

### Field(s)

async:callback(func)

Wraps a Lua function with a `Callback` object that can be used in async API calls.

### Parameter

-
` #function func `:

### Return value

#Callback:

async:newGameTimer(delay, callback, arg)

Calls callback(arg) in `delay` game seconds.

The callback must be registered in advance.

### Parameters

-
` #number delay `:

-
` #TimerCallback callback `:
A callback returned by `registerTimerCallback`

-
` arg `:
An argument for `callback`; can be `nil`.

async:newSimulationTimer(delay, callback, arg)

Calls callback(arg) in `delay` simulation seconds.

The callback must be registered in advance.

### Parameters

-
` #number delay `:

-
` #TimerCallback callback `:
A callback returned by `registerTimerCallback`

-
` arg `:
An argument for `callback`; can be `nil`.

async:newUnsavableGameTimer(delay, func)

Calls `func()` in `delay` game seconds.

The timer will be lost if the game is saved and loaded.

### Parameters

-
` #number delay `:

-
` #function func `:

async:newUnsavableSimulationTimer(delay, func)

Calls `func()` in `delay` simulation seconds.

The timer will be lost if the game is saved and loaded.

### Parameters

-
` #number delay `:

-
` #function func `:

async:registerTimerCallback(name, func)

Register a function as a timer callback.

### Parameters

-
` #string name `:

-
` #function func `:

### Return value

#TimerCallback:

## Type `Callback`

## Type `TimerCallback`

Package openmw.animation

Package openmw.camera
