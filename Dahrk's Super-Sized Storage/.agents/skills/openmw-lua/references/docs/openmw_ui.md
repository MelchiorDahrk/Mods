# Package openmw.ui

# Package openmw.ui

API v129

Controls user interface.

menu
player

## Usage

`local ui = require('openmw.ui')`

## Type `ui`

ui.ALIGNMENT

Alignment values (left to right, top to bottom)

ui.CONSOLE_COLOR

Predefined colors for console output

ui.TYPE

Widget types

ui.content(table)

Converts a given table of tables into an openmw.ui#Content

ui.create(layout, options)

Creates a UI element from the given layout table

ui.layers

Tools for working with layers

ui.printToConsole(msg, color)

Print to the in-game console.

ui.registerSettingsPage(page)

Adds a settings page to main menu setting's Scripts tab.

ui.removeSettingsPage(page)

Removes the settings page

ui.screenSize()

Returns the size of the OpenMW window in pixels as a 2D vector.

ui.setConsoleMode(mode)

Set mode of the in-game console.

ui.setConsoleSelectedObject(obj)

Set selected object for console.

ui.showMessage(msg, options)

Shows given message at the bottom of the screen.

ui.texture(options)

Register a new texture resource.

ui.updateAll()

Update all existing UI elements.

## Type `ALIGNMENT`

ALIGNMENT.Center

ALIGNMENT.End

ALIGNMENT.Start

## Type `CONSOLE_COLOR`

CONSOLE_COLOR.Default

CONSOLE_COLOR.Error

CONSOLE_COLOR.Info

CONSOLE_COLOR.Success

## Type `Content`

Content:__index(name)

Content also acts as a map of names to Layouts

Content:add(layoutOrElement)

Adds the layout at the end of the Content
(same as calling insert with `last index + 1`)

Content:indexOf(layoutOrElement)

Finds the index of the given layout.

Content:insert(index, layoutOrElement)

Puts the layout at given index by shifting all the elements after it

## Type `Element`

Element:destroy()

Destroys the element

Element.layout

Access or replace the element's layout
Note: Is reset to `nil` on `destroy`

Element:update()

Refreshes the rendered element to match the current layout state.

## Type `Layer`

Layer.name

Name of the layer

Layer.size

Size of the layer in pixels

## Type `Layers`

Layers.indexOf(name)

Index of the layer with the given name.

Layers.insertAfter(afterName, name, options)

Creates a layer and inserts it after another layer (shifts indexes of some other layers).

Layers.insertBefore(beforeName, name, options)

Creates a layer and inserts it before another layer (shifts indexes of some other layers).

## Type `Layout`

Layout.content

Optional openmw.ui#Content of children layouts

Layout.events

Optional table of event callbacks

Layout.external

Optional table of external properties

Layout.layer

Optional layout to display in. Only applies for the root widget.
Note: if the #Element isn't attached to anything, it won't be visible!

Layout.name

Optional name of the layout. Allows access by name from Content

Layout.props

Optional table of widget properties

Layout.template

Optional #Template

Layout.type

Type of the widget, one of the values in #TYPE. Must match the type in #Template if both are present

Layout.userData

Arbitrary data for you to use, e. g. when receiving the layout in an event callback

## Type `MouseEvent`

MouseEvent.button

Mouse button which triggered the event.
Matches the arguments of openmw_input#input.isMouseButtonPressed (`nil` for none, 1 for left, 3 for right).

MouseEvent.offset

Position of the mouse cursor relative to the widget

MouseEvent.position

Absolute position of the mouse cursor

## Type `SettingsPageOptions`

SettingsPageOptions.element

The page's UI, which will be attached to the settings tab. The root widget has to have a fixed size. Set the `size` field in `props`, `relativeSize` is ignored.

SettingsPageOptions.name

Name of the page, displayed in the list, used for search

SettingsPageOptions.searchHints

Additional keywords used in search, not displayed anywhere

## Type `TYPE`

TYPE.Container

Automatically wraps around its contents

TYPE.Flex

Aligns widgets in a row or column

TYPE.Image

Displays an image

TYPE.Text

Display text

TYPE.TextEdit

Accepts user text input

TYPE.Widget

Base widget type

TYPE.Window

Can be moved and resized by the user

## Type `Template`

Template.content

Template.props

Template.type

One of the values in #TYPE, serves as the default value for the #Layout

## Type `TextureResourceOptions`

TextureResourceOptions.offset

Offset of this resource in the texture. (0, 0) by default

TextureResourceOptions.path

Path to the texture file. Required

TextureResourceOptions.size

Size of the resource in the texture. (0, 0) by default. 0 means the whole texture size is used.

## Type `ui`

### Field(s)

#ALIGNMENT

ui.ALIGNMENT

Alignment values (left to right, top to bottom)

#CONSOLE_COLOR

ui.CONSOLE_COLOR

Predefined colors for console output

#TYPE

ui.TYPE

Widget types

ui.content(table)

Converts a given table of tables into an openmw.ui#Content

### Parameter

-
` #table table `:

### Return value

#Content:

ui.create(layout, options)

Creates a UI element from the given layout table

### Parameters

-
` #Layout layout `:

-
` #table options `:
Optional table, can take the following options:

- `noWarnUnused` - if set to true this element will never generate warnings about unused properties.

### Return value

#Element:

#Layers

ui.layers

Tools for working with layers

ui.printToConsole(msg, color)

Print to the in-game console.

### Parameters

-
` #string msg `:

-
` openmw.util#Color color `:

ui.registerSettingsPage(page)

Adds a settings page to main menu setting's Scripts tab.

### Parameter

-
` #SettingsPageOptions page `:

ui.removeSettingsPage(page)

Removes the settings page

### Parameter

-
` #SettingsPageOptions page `:
must be the exact same table of options as the one passed to registerSettingsPage

ui.screenSize()

Returns the size of the OpenMW window in pixels as a 2D vector.

### Return value

openmw.util#Vector2:

ui.setConsoleMode(mode)

Set mode of the in-game console.

The mode can be any string, by default is empty.
If not empty, then the console doesn't handle mwscript commands and
instead passes user input to Lua scripts via `onConsoleCommand` engine handler.

### Parameter

-
` #string mode `:

ui.setConsoleSelectedObject(obj)

Set selected object for console.

### Parameter

-
` openmw.core#GameObject obj `:

ui.showMessage(msg, options)

Shows given message at the bottom of the screen.

### Parameters

-
` #string msg `:

-
` #table options `:
An optional table with additional optional arguments. Can contain:

- `showInDialogue` - If true, this message will only be shown in the dialogue window. If false, it will always be shown in a message box.
When omitted, the message will be displayed in the dialogue window if it is open and will be shown at the bottom of the screen otherwise.

### Usage

`local params = {
showInDialogue=false
};
ui.showMessage("Hello world", params)`

ui.texture(options)

Register a new texture resource.

Can be used to manually atlas UI textures.

### Parameter

-
` #TextureResourceOptions options `:

### Return value

#TextureResource:

### Usage

`local ui = require('openmw.ui')
local vector2 = require('openmw.util').vector2
local myAtlas = 'textures/my_atlas.dds' -- a 128x128 atlas
local texture1 = ui.texture { -- texture in the top left corner of the atlas
path = myAtlas,
offset = vector2(0, 0),
size = vector2(64, 64),
}
local texture2 = ui.texture { -- texture in the top right corner of the atlas
path = myAtlas,
offset = vector2(64, 0),
size = vector2(64, 64),
}`

ui.updateAll()

Update all existing UI elements.

Potentially extremely slow, so only call this when necessary, e. g. after overriding a template.

## Type `ALIGNMENT`

Alignment values (details depend on the specific property).

For horizontal alignment the order is left to right, for vertical alignment the order is top to bottom.

### Field(s)

ALIGNMENT.Center

ALIGNMENT.End

ALIGNMENT.Start

## Type `CONSOLE_COLOR`

Predefined colors for console output

### Field(s)

openmw.util#Color

CONSOLE_COLOR.Default

openmw.util#Color

CONSOLE_COLOR.Error

openmw.util#Color

CONSOLE_COLOR.Info

openmw.util#Color

CONSOLE_COLOR.Success

## Type `Content`

Content.

An array-like container, which allows to reference elements by their name.
Implements iterables#List of #Layout or #Element and iterables#Map of #string to #Layout or #Element.

` Content ` is a list of ` #any `.

### Usages

-

`local content = ui.content {
{ name = 'input' },
}
-- bad idea!
-- content[1].name = 'otherInput'
-- do this instead:
content.input = { name = 'otherInput' }`

-

`local content = ui.content {
{ name = 'display' },
{ name = 'submit' },
}
-- allowed, but shifts all the items after it "up" the array
content.display = nil
-- still no holes after this!`

-

`-- iterate over a Content
for i = 1, #content do
print('widget',content[i].name,'at',i)
end`

-

`-- Note: layout names can collide with method names. Because of that you can't use a layout name such as "insert":
local content = ui.content {
{ name = 'insert '}
}
content.insert.content = ui.content {} -- fails here, content.insert is a function!`

### Field(s)

Content:__index(name)

Content also acts as a map of names to Layouts

### Parameter

-
` #string name `:

### Return value

#any:

Content:add(layoutOrElement)

Adds the layout at the end of the Content
(same as calling insert with `last index + 1`)

### Parameter

-
` #any layoutOrElement `:

Content:indexOf(layoutOrElement)

Finds the index of the given layout.

If it is not in the container, returns nil

### Parameter

-
` #any layoutOrElement `:

### Return value

#number, #nil:
index

Content:insert(index, layoutOrElement)

Puts the layout at given index by shifting all the elements after it

### Parameters

-
` #number index `:

-
` #any layoutOrElement `:

## Type `Element`

Element.

An element of the user interface

### Field(s)

Element:destroy()

Destroys the element

#Layout

Element.layout

Access or replace the element's layout
Note: Is reset to `nil` on `destroy`

Element:update()

Refreshes the rendered element to match the current layout state.

Refreshes positions and sizes, but not the layout of the child Elements.

## Type `Layer`

### Field(s)

#string

Layer.name

Name of the layer

openmw.util#Vector2

Layer.size

Size of the layer in pixels

## Type `Layers`

Layers.

Implements iterables#List of #Layer.

` Layers ` is a list of ` #Layer `.

### Usage

`ui.layers.insertAfter('HUD', 'NewLayer', { interactive = true })
local fourthLayer = ui.layers[4]
local windowsIndex = ui.layers.indexOf('Windows')
for i, layer in ipairs(ui.layers) do
print('layer', i, layer.name, layer.size)
end`

### Field(s)

Layers.indexOf(name)

Index of the layer with the given name.

Returns nil if the layer doesn't exist

### Parameter

-
` #string name `:
Name of the layer

### Return value

#number, #nil:
index

Layers.insertAfter(afterName, name, options)

Creates a layer and inserts it after another layer (shifts indexes of some other layers).

### Parameters

-
` #string afterName `:
Name of the layer after which the new layer will be inserted

-
` #string name `:
Name of the new layer

-
` #table options `:
Table with a boolean `interactive` field (default is true). Layers with interactive = false will ignore all mouse interactions.

Layers.insertBefore(beforeName, name, options)

Creates a layer and inserts it before another layer (shifts indexes of some other layers).

### Parameters

-
` #string beforeName `:
Name of the layer before which the new layer will be inserted

-
` #string name `:
Name of the new layer

-
` #table options `:
Table with a boolean `interactive` field (default is true). Layers with interactive = false will ignore all mouse interactions.

## Type `Layout`

Layout

### Field(s)

#Content

Layout.content

Optional openmw.ui#Content of children layouts

#table

Layout.events

Optional table of event callbacks

#table

Layout.external

Optional table of external properties

#string

Layout.layer

Optional layout to display in. Only applies for the root widget.
Note: if the #Element isn't attached to anything, it won't be visible!

#string

Layout.name

Optional name of the layout. Allows access by name from Content

#table

Layout.props

Optional table of widget properties

#Template

Layout.template

Optional #Template

Layout.type

Type of the widget, one of the values in #TYPE. Must match the type in #Template if both are present

Layout.userData

Arbitrary data for you to use, e. g. when receiving the layout in an event callback

## Type `MouseEvent`

Mouse event, passed as an argument to relevant UI events

### Field(s)

#number

MouseEvent.button

Mouse button which triggered the event.
Matches the arguments of openmw_input#input.isMouseButtonPressed (`nil` for none, 1 for left, 3 for right).

openmw.util#Vector2

MouseEvent.offset

Position of the mouse cursor relative to the widget

openmw.util#Vector2

MouseEvent.position

Absolute position of the mouse cursor

## Type `SettingsPageOptions`

Table with settings page options, passed as an argument to ui.registerSettingsPage

### Field(s)

#Element

SettingsPageOptions.element

The page's UI, which will be attached to the settings tab. The root widget has to have a fixed size. Set the `size` field in `props`, `relativeSize` is ignored.

#string

SettingsPageOptions.name

Name of the page, displayed in the list, used for search

#string

SettingsPageOptions.searchHints

Additional keywords used in search, not displayed anywhere

## Type `TYPE`

All available widget types

### Field(s)

TYPE.Container

Automatically wraps around its contents

TYPE.Flex

Aligns widgets in a row or column

TYPE.Image

Displays an image

TYPE.Text

Display text

TYPE.TextEdit

Accepts user text input

TYPE.Widget

Base widget type

TYPE.Window

Can be moved and resized by the user

## Type `Template`

Template

### Field(s)

#Content

Template.content

#table

Template.props

Template.type

One of the values in #TYPE, serves as the default value for the #Layout

## Type `TextureResource`

A texture ready to be used by UI widgets

## Type `TextureResourceOptions`

Table with arguments passed to ui.texture.

### Field(s)

openmw.util#Vector2

TextureResourceOptions.offset

Offset of this resource in the texture. (0, 0) by default

#string

TextureResourceOptions.path

Path to the texture file. Required

openmw.util#Vector2

TextureResourceOptions.size

Size of the resource in the texture. (0, 0) by default. 0 means the whole texture size is used.

Package openmw.types

Package openmw.util
