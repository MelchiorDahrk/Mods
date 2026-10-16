local I = require('openmw.interfaces')

-- Settings and the stat review preview are available without either integration.
I.Settings.registerPage {
    key = 'DynamicClassImages',
    l10n = 'DynamicClassImages',
    name = 'name',
    description = 'description',
}
I.Settings.registerGroup {
    key = 'SettingsDynamicClassImages',
    page = 'DynamicClassImages',
    l10n = 'DynamicClassImages',
    name = 'artwork',
    permanentStorage = true,
    settings = {
        { key = 'enabled', renderer = 'checkbox', name = 'enabled',
            description = 'enabledDescription', default = true },
    },
}

if I.StatsWindow then
    require('scripts.DynamicClassImages.statsWindow')
end

return require('scripts.DynamicClassImages.statReview')
