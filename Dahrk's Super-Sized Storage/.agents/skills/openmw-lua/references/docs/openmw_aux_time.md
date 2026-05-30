# Package openmw_aux.time

# Package openmw_aux.time

API v129

`openmw_aux.time` defines utility functions for timers.

Implementation can be found in `resources/vfs/openmw_aux/time.lua`.

global
menu
local

## Usage

`local time = require('openmw_aux.time')`

## Type `time`

time.GameTime

time.SimulationTime

time.day

time.hour

time.minute

time.newGameTimer(delay, callback, arg, callbackArg)

Alias of async:newSimulationTimer ; call callback(arg) in `delay` game seconds.

time.newSimulationTimer(delay, callback, arg, callbackArg)

Alias of async:newSimulationTimer ; call callback(arg) in `delay` simulation seconds.

time.registerTimerCallback(name, func, fn)

Alias of async:registerTimerCallback ; register a function as a timer callback.

time.runRepeatedly(fn, period, options)

Run given function repeatedly.

time.second

## Type `time`

### Field(s)

#string

time.GameTime

#string

time.SimulationTime

time.day

#number

time.hour

#number

time.minute

time.newGameTimer(delay, callback, arg, callbackArg)

Alias of async:newSimulationTimer ; call callback(arg) in `delay` game seconds.

Callback must be registered in advance.

### Parameters

-
` #number delay `:

-
` openmw.async#TimerCallback callback `:
A callback returned by `registerTimerCallback`

-
` arg `:
An argument for `callback`; can be `nil`.

-
` callbackArg `:

time.newSimulationTimer(delay, callback, arg, callbackArg)

Alias of async:newSimulationTimer ; call callback(arg) in `delay` simulation seconds.

Callback must be registered in advance.

### Parameters

-
` #number delay `:

-
` openmw.async#TimerCallback callback `:
A callback returned by `registerTimerCallback`

-
` arg `:
An argument for `callback`; can be `nil`.

-
` callbackArg `:

time.registerTimerCallback(name, func, fn)

Alias of async:registerTimerCallback ; register a function as a timer callback.

### Parameters

-
` #string name `:

-
` #function func `:

-
` fn `:

### Return value

openmw.async#TimerCallback:

time.runRepeatedly(fn, period, options)

Run given function repeatedly.

Note that loading a save stops the evaluation. If it should always work, call it during the initialization of the script (i.e. not in a handler)

### Parameters

-
` #function fn `:
the function that should be called

-
` #number period `:
interval

-
` #table options `:
additional options `initialDelay` and `type`.
`initialDelay` - delay before the first call. If missed then the delay is a random number in range [0, N]. Randomization is used for performance reasons -- to prevent all scripts from doing time consuming operations at the same time.
`type` - either `time.SimulationTime` (by default, timer uses simulation time) or `time.GameTime` (timer uses game time).

### Return value

#function:
a function without arguments that can be used to stop the periodical evaluation.

### Usages

-

`local stopFn = time.runRepeatedly(function() print('Test') end,
5 * time.second) -- print 'Test' every 5 seconds
stopFn() -- stop printing 'Test'
time.runRepeatedly( -- print 'Test' every 5 minutes with initial 30 second delay
function() print('Test2') end, 5 * time.minute,
{ initialDelay = 30 * time.second })`

-

`local timeBeforeMidnight = time.day - core.getGameTime() % time.day
time.runRepeatedly(doSomething, time.day, {
initialDelay = timeBeforeMidnight,
type = time.GameTime,
}) -- call `doSomething` at the end of every game day.`

#number

time.second

Package openmw_aux.calendar

Package openmw_aux.ui
