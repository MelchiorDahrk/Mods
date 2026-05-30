# Interface Settings

# Interface Settings

API v129

global
menu
player

## Usage

`-- In a player script
local storage = require('openmw.storage')
local I = require('openmw.interfaces')
I.Settings.registerPage {
key = 'MyModPage',
l10n = 'MyMod',
name = 'My Mod Name',
description = 'My Mod Description',
}
I.Settings.registerGroup {
key = 'SettingsPlayerMyMod',
page = 'MyModPage',
l10n = 'MyMod',
name = 'My Group Name',
description = 'My Group Description',
permanentStorage = false,
settings = {
{
key = 'Greeting',
renderer = 'textLine',
name = 'Greeting',
description = 'Text to display when the game starts',
default = 'Hello, world!',
},
},
}
local playerSettings = storage.playerSection('SettingsPlayerMyMod')
...
ui.showMessage(playerSettings:get('Greeting'))
-- ...
-- access a setting page registered by a global script
local globalSettings = storage.globalSection('SettingsGlobalMyMod')`

## Type `Settings`

Settings.registerGroup(options)

Settings.registerPage(options)

Settings.registerRenderer(key, renderer)

Settings.updateRendererArgument(groupKey, settingKey, argument)

Settings.version

## Type `GroupOptions`

GroupOptions.description

A key from the localization context (optional, can be `nil`)

GroupOptions.key

A unique key, starts with "Settings" by convention

GroupOptions.l10n

A localization context (an argument of core.l10n)

GroupOptions.name

A key from the localization context

GroupOptions.order

Groups within the same page are sorted by this number, or their key for equal values.
Defaults to 0.

GroupOptions.page

Key of a page which will contain this group

GroupOptions.permanentStorage

Whether the group should be stored in permanent storage, or in the save file

GroupOptions.settings

A iterables#List table of #SettingOptions

## Type `PageOptions`

PageOptions.description

A key from the localization context (optional, can be `nil`)

PageOptions.key

A unique key

PageOptions.l10n

A localization context (an argument of core.l10n)

PageOptions.name

A key from the localization context

## Type `SettingOptions`

SettingOptions.argument

An argument for the renderer

SettingOptions.default

A default value

SettingOptions.description

A key from the localization context (optional, can be `nil`)

SettingOptions.key

A unique key

SettingOptions.name

A key from the localization context

SettingOptions.renderer

A renderer key (see the "Setting Renderers" page)

## Type `Settings`

### Field(s)

Settings.registerGroup(options)

### Parameter

-
` #GroupOptions options `:

### Usage

`I.Settings.registerGroup {
key = 'SettingsTest',
page = 'test',
l10n = 'test',
name = 'Player',
description = 'Player settings group',
permanentStorage = false,
settings = {
{
key = 'Greeting',
default = 'Hi',
renderer = 'textLine',
name = 'Text Input',
description = 'Short text input',
},
{
key = 'Flag',
default = false,
renderer = 'checkbox',
name = 'Flag',
description = 'Flag toggle',
},
}
}`

Settings.registerPage(options)

### Parameter

-
` #PageOptions options `:

### Usage

`I.Settings.registerPage({
key = 'MyModName',
l10n = 'MyModName',
name = 'MyModName',
description = 'MyModDescription',
})---`

Settings.registerRenderer(key, renderer)

### Parameters

-
` #string key `:

-
` #function renderer `:
A renderer function, receives setting's value,
a function to change it and an argument from the setting options

### Usage

`I.Settings.registerRenderer('text', function(value, set, arg)
return {
type = ui.TYPE.TextEdit,
props = {
size = util.vector2(arg and arg.size or 150, 30),
text = value,
textColor = util.color.rgb(1, 1, 1),
textSize = 15,
textAlignV = ui.ALIGNMENT.End,
},
events = {
textChanged = async:callback(function(s) set(s) end),
},
}
end)`

Settings.updateRendererArgument(groupKey, settingKey, argument)

### Parameters

-
` #string groupKey `:
A settings group key

-
` #string settingKey `:
A setting key

-
` argument `:
A renderer argument

#number

Settings.version

## Type `GroupOptions`

### Field(s)

#string

GroupOptions.description

A key from the localization context (optional, can be `nil`)

#string

GroupOptions.key

A unique key, starts with "Settings" by convention

#string

GroupOptions.l10n

A localization context (an argument of core.l10n)

#string

GroupOptions.name

A key from the localization context

#number

GroupOptions.order

Groups within the same page are sorted by this number, or their key for equal values.
Defaults to 0.

#string

GroupOptions.page

Key of a page which will contain this group

#boolean

GroupOptions.permanentStorage

Whether the group should be stored in permanent storage, or in the save file

#list<#SettingOptions>

GroupOptions.settings

A iterables#List table of #SettingOptions

## Type `PageOptions`

### Field(s)

#string

PageOptions.description

A key from the localization context (optional, can be `nil`)

#string

PageOptions.key

A unique key

#string

PageOptions.l10n

A localization context (an argument of core.l10n)

#string

PageOptions.name

A key from the localization context

## Type `SettingOptions`

Table of setting options

### Field(s)

SettingOptions.argument

An argument for the renderer

SettingOptions.default

A default value

#string

SettingOptions.description

A key from the localization context (optional, can be `nil`)

#string

SettingOptions.key

A unique key

#string

SettingOptions.name

A key from the localization context

#string

SettingOptions.renderer

A renderer key (see the "Setting Renderers" page)

Interface MWUI

Interface SkillProgression
