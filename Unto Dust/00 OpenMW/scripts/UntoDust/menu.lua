local I = require('openmw.interfaces')
local picker = require('scripts.UntoDust.cellPicker')

I.Settings.registerRenderer('UntoDustCells', picker.render)

return {
    engineHandlers = {
        onFrame = picker.onFrame,
        onMouseWheel = picker.onMouseWheel,
    },
}
