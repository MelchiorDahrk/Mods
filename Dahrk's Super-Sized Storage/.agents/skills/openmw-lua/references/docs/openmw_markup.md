# Package openmw.markup

# Package openmw.markup

API v129

Allows to work with markup languages.

global
menu
local
player
load

## Usage

`local markup = require('openmw.markup')`

## Type `markup`

markup.decodeYaml(inputData)

Convert YAML data to a Lua object

markup.loadYaml(fileName)

Load a YAML file from the VFS to Lua object.

## Type `markup`

### Field(s)

markup.decodeYaml(inputData)

Convert YAML data to a Lua object

### Parameter

-
` #string inputData `:
Data to decode. It has such limitations:

- YAML format of version 1.2 is used.

- Map keys should be scalar values (strings, booleans, numbers).

- YAML tag system is not supported.

- If a scalar is quoted, it is treated like a string.
Otherwise, type deduction works according to YAML 1.2 Core Schema.

- Circular dependencies between YAML nodes are not allowed.

- Lua 5.1 does not have integer numbers - all numeric scalars use a #number type (which use a floating point).

- Integer scalars numbers values are limited by the "int" range. Use floating point notation for larger number in YAML files.

### Return value

#any:
Lua object (can be table or scalar value).

### Usage

`local result = markup.decodeYaml('{ "x": 1 }');
-- prints 1
print(result["x"])`

markup.loadYaml(fileName)

Load a YAML file from the VFS to Lua object.

Conventions are the same as in markup.decodeYaml.

### Parameter

-
` #string fileName `:
YAML file path in the VFS.

### Return value

#any:
Lua object (can be table or scalar value).

### Usage

`-- file contains '{ "x": 1 }' data
local result = markup.loadYaml('test.yaml');
-- prints 1
print(result["x"])`

Package openmw.input

Package openmw.menu
