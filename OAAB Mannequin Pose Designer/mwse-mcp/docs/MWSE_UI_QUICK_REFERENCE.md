# MWSE Custom UI Quick Reference

This is the shortest known-good path for creating and iterating on custom MWSE
UI through mwseMCP. It is based on the installed MWSE 2.1.0 API stubs, the
official [TES3 UI example](https://mwse.github.io/MWSE/guides/tes3ui/), and a
live-tested slider controlling an MGE XE shader.

## Ground these APIs first

Read the version-exact stubs from the Morrowind installation:

| Need | Stub |
|---|---|
| Top-level menu functions | `Data Files/MWSE/core/meta/lib/tes3ui.lua` |
| Element creation, layout, and events | `Data Files/MWSE/core/meta/class/tes3uiElement.lua` |
| Slider widget fields | `Data Files/MWSE/core/meta/class/tes3uiSlider.lua` |
| MGE shader lookup/loading | `Data Files/MWSE/core/meta/class/mgeShadersConfig.lua` |
| MGE shader variables/reload | `Data Files/MWSE/core/meta/class/mgeShaderHandle.lua` |
| UI enums such as events and flow direction | `Data Files/MWSE/core/meta/lib/tes3.lua` |

Useful installed mods are also practical examples. Search under
`Data Files/MWSE/mods/` for `createMenu`, `createSlider`, and
`partScrollBarChanged`.

## Basic menu lifecycle

1. Register namespaced IDs with `tes3ui.registerID`.
2. Refuse to create a duplicate menu, or destroy the old one during reload.
3. Create a top-level `dragFrame` or `fixedFrame` menu.
4. Build its element tree.
5. Register element callbacks.
6. Call `menu:updateLayout()`.
7. Call `tes3ui.enterMenuMode(menuId)` if the menu should receive interaction.
8. On close, destroy the menu and leave menu mode when appropriate.

```lua
local MENU_ID = tes3ui.registerID("AgentGenerated:ExampleMenu")

local function close()
	local menu = tes3ui.findMenu(MENU_ID)
	if menu then
		tes3ui.leaveMenuMode()
		menu:destroy()
	end
end

local function open()
	local existing = tes3ui.findMenu(MENU_ID)
	if existing then
		tes3ui.moveMenuToFront(existing)
		return existing
	end

	local menu = tes3ui.createMenu({
		id = MENU_ID,
		dragFrame = true,
		loadable = false,
	})
	menu.text = "Example"
	menu.width = 380
	menu.height = 150
	menu.minWidth = 380
	menu.minHeight = 150

	-- Add elements and callbacks here.

	menu:updateLayout()
	tes3ui.enterMenuMode(MENU_ID)
	return menu
end
```

Use `fixedFrame = true` for a centered dialog-like window. Fixed-frame menus are
modal by default. Use `dragFrame = true` for movable tool windows.

## Layout model

MWSE UI is a tree of `tes3uiElement` objects. Blocks organize children:

```lua
local contents = menu:createBlock()
contents.flowDirection = tes3.flowDirection.topToBottom
contents.widthProportional = 1.0
contents.autoHeight = true
contents.borderAllSides = 12
```

Common sizing and layout fields:

- `width`, `height`, `minWidth`, `minHeight`
- `widthProportional`, `heightProportional`
- `autoWidth`, `autoHeight`
- `flowDirection`
- `childAlignX`, `childAlignY`
- `borderAllSides`, `borderTop`, `borderBottom`, `borderLeft`, `borderRight`
- `absolutePosAlignX`, `absolutePosAlignY`

After adding, resizing, or moving elements, call `updateLayout()` on the
top-level menu.

## Slider pattern

Native sliders use a zero-based range: `0` through `max`. There is no `min`
parameter. Remap the value yourself when the logical range does not start at
zero.

```lua
local valueLabel = contents:createLabel({
	text = "Value: 65%",
})

local slider = contents:createSlider({
	current = 65,
	max = 100,
	step = 1,
	jump = 10,
})
slider.width = 330

slider:register(tes3.uiEvent.partScrollBarChanged, function(e)
	local value = math.floor(e.source.widget.current + 0.5)
	valueLabel.text = string.format("Value: %d%%", value)
end)
```

Relevant `tes3uiSlider` fields:

- `widget.current`
- `widget.max`
- `widget.step`
- `widget.jump`

To test a callback without dragging the UI:

```lua
slider.widget.current = 80
slider:triggerEvent(tes3.uiEvent.partScrollBarChanged)
```

## Binding a slider to an MGE XE shader

Generated shaders live under:

```text
Data Files/shaders/XEshaders/AgentGenerated/
```

Load them using an extensionless path relative to `XEshaders`:

```lua
local shaderName = "AgentGenerated/Desaturate"
local shader = mge.shaders.find({ name = shaderName })
if not shader then
	shader = mge.shaders.load({ name = shaderName })
end

if not shader then
	error("Could not load shader '" .. shaderName .. "'.")
end

shader.enabled = true
```

Editable shader globals appear as properties on the handle. For a shader
variable named `saturation`:

```lua
slider:register(tes3.uiEvent.partScrollBarChanged, function(e)
	local desaturation = e.source.widget.current / 100.0
	shader.saturation = 1.0 - desaturation
end)
```

Inspect `shader.variables` to verify the variable name and type before binding
UI to it.

## Buttons and element events

```lua
local closeButton = contents:createButton({ text = "Close" })
closeButton:register(tes3.uiEvent.mouseClick, close)
```

UI callbacks are attached to elements. Destroying an element automatically
removes its custom UI event handlers.

## Hot-reload and cleanup

Put substantial UI code in an agent-generated module and reload it with
`mw_reload_module`.

During module execution, destroy an old instance before recreating it:

```lua
local oldMenu = tes3ui.findMenu(MENU_ID)
if oldMenu then
	oldMenu:destroy()
end
```

Expose explicit controls for later evals:

```lua
_G.Agent.modules.exampleUI = {
	open = open,
	close = close,
}
```

Important cleanup boundaries:

- `mw_reload_module` removes tracked engine hooks belonging to that module, but
  it does not automatically destroy UI menus.
- `mw_reset` unregisters tracked engine hooks and wipes `_G.Agent`, but it does
  not currently destroy custom menus or disable loaded shaders.
- Close custom menus and disable experimental shaders explicitly before reset
  when cleanup matters.

## Common failure modes

- Forgetting `menu:updateLayout()` after constructing or changing the tree.
- Creating duplicate menus because `tes3ui.findMenu(id)` was not checked.
- Using un-namespaced IDs and colliding with another mod.
- Treating sliders as if they accept a non-zero `min`.
- Binding the wrong event; sliders use
  `tes3.uiEvent.partScrollBarChanged`.
- Keeping stale element references after a menu is destroyed. Look the menu up
  again, or check `element:isValid()` when lifetime is uncertain.
- Expecting `mw_reset` to remove UI or shader state.
- Loading a generated shader with `.fx` in its name. Use
  `AgentGenerated/Name`, not `AgentGenerated/Name.fx`.

## Live-proven example

The working test module is:

```text
Data Files/MWSE/mods/AgentGenerated/DesaturateUI.lua
```

It creates a draggable slider window, updates the label live, writes directly
to `mgeShaderHandle.saturation`, and supports module reload without duplicate
menus.
