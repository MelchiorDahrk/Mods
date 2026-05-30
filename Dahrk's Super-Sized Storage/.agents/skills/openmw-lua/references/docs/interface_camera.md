# Interface Camera

# Interface Camera

API v129

player

## Usage

`require('openmw.interfaces').Camera`

## Type `Camera`

Camera.disableHeadBobbing(tag)

Disable with (optional) tag until the corresponding enable function is called with the same tag.

Camera.disableModeControl(tag)

Disable with (optional) tag until the corresponding enable function is called with the same tag.

Camera.disableStandingPreview(tag)

Disable with (optional) tag until the corresponding enable function is called with the same tag.

Camera.disableThirdPersonOffsetControl(tag)

Disable with (optional) tag until the corresponding enable function is called with the same tag.

Camera.disableZoom(tag)

Disable with (optional) tag until the corresponding enable function is called with the same tag.

Camera.enableHeadBobbing(tag)

Undo disableHeadBobbing

Camera.enableModeControl(tag)

Undo disableModeControl

Camera.enableStandingPreview(tag)

Undo disableStandingPreview

Camera.enableThirdPersonOffsetControl(tag)

Undo disableThirdPersonOffsetControl

Camera.enableZoom(tag)

Undo disableZoom

Camera.getBaseThirdPersonDistance()

Get the base third person distance (without applying angle and speed modifiers).

Camera.getPrimaryMode()

Return the primary mode (MODE.FirstPerson or MODE.ThirdPerson).

Camera.getTargetThirdPersonDistance()

Get the desired third person distance if there would be no obstacles (with angle and speed modifiers)

Camera.isHeadBobbingEnabled()

Whether head bobbing is enabled.

Camera.isModeControlEnabled()

Whether the built-in mode control logic is enabled.

Camera.isStandingPreviewEnabled()

Whether the built-in standing preview logic is enabled.

Camera.isThirdPersonOffsetControlEnabled()

Whether the the third person offset can be changed by the built-in camera script.

Camera.isZoomEnabled()

Whether the built-in zooming is enabled.

Camera.setBaseThirdPersonDistance(value)

Set the base third person distance

Camera.version

Interface version is 1

## Type `Camera`

### Field(s)

Camera.disableHeadBobbing(tag)

Disable with (optional) tag until the corresponding enable function is called with the same tag.

### Parameter

-
` #string tag `:
(optional, empty string by default) Will be disabled until the enabling function is called with the same tag

Camera.disableModeControl(tag)

Disable with (optional) tag until the corresponding enable function is called with the same tag.

### Parameter

-
` #string tag `:
(optional, empty string by default) Will be disabled until the enabling function is called with the same tag

Camera.disableStandingPreview(tag)

Disable with (optional) tag until the corresponding enable function is called with the same tag.

### Parameter

-
` #string tag `:
(optional, empty string by default) Will be disabled until the enabling function is called with the same tag

Camera.disableThirdPersonOffsetControl(tag)

Disable with (optional) tag until the corresponding enable function is called with the same tag.

### Parameter

-
` #string tag `:
(optional, empty string by default) Will be disabled until the enabling function is called with the same tag

Camera.disableZoom(tag)

Disable with (optional) tag until the corresponding enable function is called with the same tag.

### Parameter

-
` #string tag `:
(optional, empty string by default) Will be disabled until the enabling function is called with the same tag

Camera.enableHeadBobbing(tag)

Undo disableHeadBobbing

### Parameter

-
` #string tag `:
(optional, empty string by default)

Camera.enableModeControl(tag)

Undo disableModeControl

### Parameter

-
` #string tag `:
(optional, empty string by default)

Camera.enableStandingPreview(tag)

Undo disableStandingPreview

### Parameter

-
` #string tag `:
(optional, empty string by default)

Camera.enableThirdPersonOffsetControl(tag)

Undo disableThirdPersonOffsetControl

### Parameter

-
` #string tag `:
(optional, empty string by default)

Camera.enableZoom(tag)

Undo disableZoom

### Parameter

-
` #string tag `:
(optional, empty string by default)

Camera.getBaseThirdPersonDistance()

Get the base third person distance (without applying angle and speed modifiers).

### Return value

#number:

Camera.getPrimaryMode()

Return the primary mode (MODE.FirstPerson or MODE.ThirdPerson).

### Return value

#number:
openmw.camera#MODE

Camera.getTargetThirdPersonDistance()

Get the desired third person distance if there would be no obstacles (with angle and speed modifiers)

### Return value

#number:

Camera.isHeadBobbingEnabled()

Whether head bobbing is enabled.

### Return value

#boolean:

Camera.isModeControlEnabled()

Whether the built-in mode control logic is enabled.

### Return value

#boolean:

Camera.isStandingPreviewEnabled()

Whether the built-in standing preview logic is enabled.

### Return value

#boolean:

Camera.isThirdPersonOffsetControlEnabled()

Whether the the third person offset can be changed by the built-in camera script.

### Return value

#boolean:

Camera.isZoomEnabled()

Whether the built-in zooming is enabled.

### Return value

#boolean:

Camera.setBaseThirdPersonDistance(value)

Set the base third person distance

### Parameter

-
` #number value `:

#number

Camera.version

Interface version is 1

Interface AnimationController

Interface Combat
