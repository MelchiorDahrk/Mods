# Package openmw_aux.ui

# Package openmw_aux.ui

API v129

`openmw_aux.ui` defines utility functions for UI.

Implementation can be found in `resources/vfs/openmw_aux/ui.lua`.

menu
player

## Usage

`local auxUi = require('openmw_aux.ui')`

## Type `ui`

ui.deepDestroy(elementOrLayout)

Recursively destroys all elements in the passed layout or element

ui.deepLayoutCopy(layout)

ui.deepUpdate(elementOrLayout)

Recursively updates all elements in the passed layout or element

## Type `ui`

### Field(s)

ui.deepDestroy(elementOrLayout)

Recursively destroys all elements in the passed layout or element

### Parameter

-
` #any elementOrLayout `:
openmw.ui#Layout or openmw.ui#Element

ui.deepLayoutCopy(layout)

### Parameter

-
` #table layout `:

### Return value

#table:
copied layout

ui.deepUpdate(elementOrLayout)

Recursively updates all elements in the passed layout or element

### Parameter

-
` #any elementOrLayout `:
openmw.ui#Layout or openmw.ui#Element

Package openmw_aux.time

Package openmw_aux.util
