local ui = require('openmw.ui')
local I = require("openmw.interfaces")

local function isWaitRestMode(mode)
    return mode == I.UI.MODE.Rest
end

local function onUiModeChange(data)
    if isWaitRestMode(data.newMode) and not data.oldMode and not data.arg then
        ui.showMessage('Resting and waiting are disabled. You must find a bed.')
        I.UI.setMode()
    end
    return
end

return {
    eventHandlers = {
        UiModeChanged = onUiModeChange
    }
}
