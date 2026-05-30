# Interface MWUI

# Interface MWUI

API v129

menu
player

## Usage

`require('openmw.interfaces').MWUI`

## Type `MWUI`

MWUI.templates

MWUI.version

Interface version

## Type `Templates`

Templates.borders

Standard rectangular borders

Templates.bordersThick

Standard rectangular borders

Templates.box

Container wrapping the content with borders

Templates.boxSolid

Same as box, but with a solid background

Templates.boxSolidThick

Same as box, but with a solid background

Templates.boxThick

Container wrapping the content with borders

Templates.boxTransparent

Same as box, but with a semi-transparent background

Templates.boxTransparentThick

Same as box, but with a semi-transparent background

Templates.disabled

Shades its children and makes them uninteractible

Templates.horizontalLine

Expanding horizontal line

Templates.horizontalLineThick

Expanding horizontal line

Templates.interval

Standard spacing interval

Templates.padding

Container that adds padding around its content.

Templates.textEditBox

Multiline text input

Templates.textEditLine

Single line text input

Templates.textHeader

Header white colored text

Templates.textNormal

Standard "sand" colored text

Templates.textParagraph

Standard "sand" colored multiline text

Templates.verticalLine

Expanding vertical line

Templates.verticalLineThick

Expanding vertical line

## Type `MWUI`

### Field(s)

#Templates

MWUI.templates

#number

MWUI.version

Interface version

## Type `Templates`

### Usage

`local I = require('openmw.interfaces')
local ui = require('openmw.ui')
local auxUi = require('openmw_aux.ui')
ui.create {
template = I.MWUI.templates.textNormal,
layer = 'Windows',
type = ui.TYPE.Text,
props = {
text = 'Hello, world!',
},
}
-- important to copy here
local myText = auxUi.deepLayoutCopy(I.MWUI.templates.textNormal)
myText.props.textSize = 20
I.MWUI.templates.textNormal = myText
ui.updateAll()`

### Field(s)

openmw.ui#Template

Templates.borders

Standard rectangular borders

openmw.ui#Template

Templates.bordersThick

Standard rectangular borders

openmw.ui#Template

Templates.box

Container wrapping the content with borders

openmw.ui#Template

Templates.boxSolid

Same as box, but with a solid background

openmw.ui#Template

Templates.boxSolidThick

Same as box, but with a solid background

openmw.ui#Template

Templates.boxThick

Container wrapping the content with borders

openmw.ui#Template

Templates.boxTransparent

Same as box, but with a semi-transparent background

openmw.ui#Template

Templates.boxTransparentThick

Same as box, but with a semi-transparent background

openmw.ui#Template

Templates.disabled

Shades its children and makes them uninteractible

openmw.ui#Template

Templates.horizontalLine

Expanding horizontal line

openmw.ui#Template

Templates.horizontalLineThick

Expanding horizontal line

openmw.ui#Template

Templates.interval

Standard spacing interval

openmw.ui#Template

Templates.padding

Container that adds padding around its content.

openmw.ui#Template

Templates.textEditBox

Multiline text input

openmw.ui#Template

Templates.textEditLine

Single line text input

openmw.ui#Template

Templates.textHeader

Header white colored text

openmw.ui#Template

Templates.textNormal

Standard "sand" colored text

openmw.ui#Template

Templates.textParagraph

Standard "sand" colored multiline text

openmw.ui#Template

Templates.verticalLine

Expanding vertical line

openmw.ui#Template

Templates.verticalLineThick

Expanding vertical line

Interface ItemUsage

Interface Settings
