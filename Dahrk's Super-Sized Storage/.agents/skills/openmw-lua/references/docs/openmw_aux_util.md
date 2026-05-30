# Package openmw_aux.util

# Package openmw_aux.util

API v129

`openmw_aux.util` defines utility functions that are implemented in Lua rather than in C++.

Implementation can be found in `resources/vfs/openmw_aux/util.lua`.

global
menu
local

## Usage

`local aux_util = require('openmw_aux.util')`

## Type `util`

util.callEventHandlers(handlers, ...)

Iterates over an array of event handlers, calling each in turn until one returns false.

util.callMultipleEventHandlers(handlers, ...)

Iterates over an array of event handler arrays, passing each to `aux_util.callEventHandlers` until the event is handled.

util.deepToString(value, maxDepth)

Works like `tostring` but also shows the content of tables.

util.findMinScore(array, scoreFn)

Finds the element in the array given the lowest score by `scoreFn`.

util.mapFilter(array, scoreFn)

Computes `scoreFn` for each element of `array` and filters out elements with false and nil results.

util.mapFilterSort(array, scoreFn)

Filters and sorts `array` by the scores calculated by `scoreFn`.

util.shallowCopy(table)

Copies all key-value pairs from the input table to a new table.

## Type `util`

### Field(s)

util.callEventHandlers(handlers, ...)

Iterates over an array of event handlers, calling each in turn until one returns false.

### Parameters

-
` #table handlers `:
An optional array of handlers to invoke

-
` #any ... `:
Arguments to pass to each event handler

### Return value

boolean True if no further handlers should be called

util.callMultipleEventHandlers(handlers, ...)

Iterates over an array of event handler arrays, passing each to `aux_util.callEventHandlers` until the event is handled.

### Parameters

-
` #table handlers `:
An array of event handler arrays

-
` #any ... `:
Arguments to pass to each event handler

### Return value

boolean True if no further handlers should be called

util.deepToString(value, maxDepth)

Works like `tostring` but also shows the content of tables.

### Parameters

-
` #any value `:
The value to convert to a string

-
` #number maxDepth `:
Max depth of table unpacking (optional, 1 by default)

util.findMinScore(array, scoreFn)

Finds the element in the array given the lowest score by `scoreFn`.

### Parameters

-
` #table array `:
Any array

-
` #function scoreFn `:
Function that returns either nil/false or a number for each element of the array

### Return values

-
element The element given the lowest score

-
#number:
score The score given to the chosen element by `scoreFn`

-
#number:
index The index of the chosen element in the array

### Usage

`-- Find the nearest NPC
local nearestNPC, distToNPC = aux_util.findMinScore(
nearby.actors,
function(actor)
return actor.type == types.NPC and (self.position - actor.position):length()
end)`

util.mapFilter(array, scoreFn)

Computes `scoreFn` for each element of `array` and filters out elements with false and nil results.

### Parameters

-
` #table array `:
Any array

-
` #function scoreFn `:
Filter function

### Return values

-
#table:
Output array

-
#table:
Array of the same size with corresponding scores

### Usage

`-- Find all NPCs in `nearby.actors`
local NPCs = aux_util.mapFilter(
nearby.actors,
function(actor) return actor.type == types.NPC end)`

util.mapFilterSort(array, scoreFn)

Filters and sorts `array` by the scores calculated by `scoreFn`.

The same as `aux_util.mapFilter`, but the result is sorted.

### Parameters

-
` #table array `:
Any array

-
` #function scoreFn `:
Filter function

### Return values

-
#table:
Output array

-
#table:
Array of the same size with corresponding scores

### Usage

`-- Find all NPCs in `nearby.actors` and sort them by distances
local NPCs, distances = aux_util.mapFilterSort(
nearby.actors,
function(actor)
return actor.type == types.NPC and (self.position - actor.position):length()
end)`

util.shallowCopy(table)

Copies all key-value pairs from the input table to a new table.

### Parameter

-
` #table table `:
The table to copy

### Return value

#table:
A shallow copy of the input table

Package openmw_aux.ui

AI packages
