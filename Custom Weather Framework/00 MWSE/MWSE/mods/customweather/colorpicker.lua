local color = require('customweather.color')
local M = {}

function M.create(params)
    local parent, hsv = params.parent, color.toHSV(params.initial)
    local width, height = 352, 224
    parent:destroyChildren()
    parent:createLabel { text = params.label }
    local header = parent:createBlock {}
    header.flowDirection = tes3.flowDirection.leftToRight
    header.autoHeight, header.widthProportional = true, 1
    local swatch = header:createRect { color = params.initial }
    swatch.width, swatch.height, swatch.borderRight = 40, 24, 12
    local readout = header:createLabel { text = '' }
    local controls = parent:createBlock {}
    controls.flowDirection = tes3.flowDirection.leftToRight
    controls.autoHeight, controls.widthProportional, controls.borderTop = true, 1, 8
    local plane = controls:createRect { id = 'Hrn:WeatherAdjust.PickerSV', color = { 1, 0, 0 } }
    plane.width, plane.height = width, height
    local function image(owner, name, w, h, sourceW, sourceH)
        local node = owner:createImage { path = 'textures\\customweather\\' .. name .. '.dds' }
        node.width, node.height = w, h
        node.imageScaleX, node.imageScaleY = w / sourceW, h / sourceH
        node.consumeMouseEvents = false
        node.absolutePosAlignX, node.absolutePosAlignY = 0, 0
        return node
    end
    image(plane, 'sv', width, height, 256, 256)
    local marker = image(plane, 'cursor', 16, 16, 16, 16)
    marker.ignoreLayoutX, marker.ignoreLayoutY = true, true
    local hue = image(controls, 'hue', 28, height, 16, 256)
    hue.absolutePosAlignX, hue.absolutePosAlignY = nil, nil
    hue.borderLeft, hue.consumeMouseEvents = 12, true
    local hueMarker = hue:createRect { color = { 0, 0, 0 } }
    hueMarker.width, hueMarker.height = 28, 4
    hueMarker.ignoreLayoutX, hueMarker.ignoreLayoutY = true, true
    hueMarker.consumeMouseEvents = false
    local inner = hueMarker:createRect { color = { 1, 1, 1 } }
    inner.width, inner.height, inner.borderLeft, inner.borderTop = 26, 2, 1, 1
    inner.consumeMouseEvents = false
    local hint = parent:createLabel { text = 'Saturation / brightness                         Hue' }
    hint.borderTop = 6
    local entry = parent:createThinBorder {}
    entry.width, entry.autoHeight, entry.borderTop = 400, true, 10
    local input = entry:createTextInput { text = color.hex(params.initial) }
    input.width, input.autoHeight = 390, true
    entry:register(tes3.uiEvent.mouseClick, function() tes3ui.acquireTextInput(input) end)
    local function redraw()
        local rgb = color.toRGB(hsv)
        plane.color = color.toRGB { hsv[1], 1, 1 }
        swatch.color = rgb
        readout.text = color.label(rgb) .. '  ' .. color.hex(rgb)
        marker.positionX, marker.positionY = hsv[2] * (width - 1) - 8, (1 - hsv[3]) * (height - 1) - 8
        hueMarker.positionX, hueMarker.positionY = 0, hsv[1] * (height - 1) - 2
        input.text = color.hex(rgb)
        parent:getTopLevelMenu():updateLayout()
        return rgb
    end
    local function update() params.onUpdate(redraw()) end
    local function bind(node, isHue)
        local dragging
        local function move(e)
            if not dragging then return end
            if isHue then hsv[1] = color.clamp(e.relativeY / (height - 1))
            else hsv[2], hsv[3] = color.clamp(e.relativeX / (width - 1)), 1 - color.clamp(e.relativeY / (height - 1)) end
            update()
        end
        node:register(tes3.uiEvent.mouseDown, function(e)
            params.onBegin()
            dragging = true
            tes3ui.captureMouseDrag(true)
            move(e)
        end)
        node:register(tes3.uiEvent.mouseStillPressed, move)
        node:register(tes3.uiEvent.mouseRelease, function(e)
            move(e)
            dragging = false
            tes3ui.captureMouseDrag(false)
        end)
    end
    bind(plane, false); bind(hue, true)
    local buttons = parent:createBlock {}
    buttons.flowDirection = tes3.flowDirection.leftToRight
    buttons.autoHeight, buttons.widthProportional, buttons.borderTop = true, 1, 8
    local function button(label, callback)
        buttons:createButton { text = label }:register(tes3.uiEvent.mouseClick, callback)
    end
    local function apply()
        local rgb = color.parse(input.text)
        if not rgb then
            tes3.messageBox { message = 'Enter #RRGGBB or RGB values such as 38, 166, 191.' }
            return
        end
        params.onBegin()
        hsv = color.toHSV(rgb, hsv[1]); update()
    end
    input:register(tes3.uiEvent.keyEnter, apply)
    button('Apply', apply)
    local function finish(cancel)
        tes3ui.captureMouseDrag(false)
        tes3ui.acquireTextInput(nil)
        params.onFinish(cancel)
    end
    button('Done', function() finish(false) end)
    button('Cancel', function() finish(true) end)
    redraw()
end

return M
