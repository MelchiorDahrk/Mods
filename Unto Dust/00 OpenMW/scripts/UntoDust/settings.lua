local I = require('openmw.interfaces')
local storage = require('openmw.storage')

I.Settings.registerPage {
    key = 'UntoDust',
    l10n = 'UntoDust',
    name = 'PageName',
    description = 'PageDescription',
}

I.Settings.registerGroup {
    key = 'SettingsUntoDust',
    page = 'UntoDust',
    l10n = 'UntoDust',
    name = 'GroupName',
    permanentStorage = true,
    settings = {
        {
            key = 'density',
            renderer = 'number',
            name = 'DensityName',
            description = 'DensityDescription',
            default = 32,
            argument = { min = 0, max = 100, integer = true },
        },
        {
            key = 'whitelist',
            renderer = 'UntoDustCells',
            -- The picker places its heading above its contents. Native setting
            -- labels sit beside the editor, which crowds multi-row controls.
            name = 'PickerSettingName',
            default = {},
            argument = { key = 'whitelist' },
        },
        {
            key = 'blacklist',
            renderer = 'UntoDustCells',
            name = 'PickerSettingName',
            default = {},
            argument = { key = 'blacklist' },
        },
    },
}

return storage.playerSection('SettingsUntoDust')
