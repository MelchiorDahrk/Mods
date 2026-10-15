local I = require('openmw.interfaces')
local picker = require('scripts.UntoDust.cellPicker')

I.Settings.registerRenderer('UntoDustCells', picker.render)
