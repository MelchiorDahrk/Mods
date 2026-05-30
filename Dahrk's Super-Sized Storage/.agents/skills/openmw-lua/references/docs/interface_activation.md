# Interface Activation

# Interface Activation

API v129

global

## Usage

`require('openmw.interfaces').Activation`

## Type `Activation`

Activation.addHandlerForObject(obj, handler)

Add a new activation handler for a specific object.

Activation.addHandlerForType(type, handler)

Add a new activation handler for a type of object.

Activation.version

Interface version

## Type `Activation`

### Field(s)

Activation.addHandlerForObject(obj, handler)

Add a new activation handler for a specific object.

If `handler(object, actor)` returns false, other handlers for
the same object (including type handlers) will be skipped.

### Parameters

-
` openmw.core#GameObject obj `:
The object.

-
` #function handler `:
The handler.

Activation.addHandlerForType(type, handler)

Add a new activation handler for a type of object.

If `handler(object, actor)` returns false, other handlers for
the same object (including type handlers) will be skipped.

### Parameters

-
` #any type `:
A type from the `openmw.types` package.

-
` #function handler `:
The handler.

#number

Activation.version

Interface version

Interfaces

Interface AI
