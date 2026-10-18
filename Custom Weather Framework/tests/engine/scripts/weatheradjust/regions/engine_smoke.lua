-- A separately installed region mod: no .omwscripts entry for this definition.
local definition = {
    version = 1,
    region = 'Bitter Coast Region',
    preset = { Clear = { skyDayColor = { 0.25, 0.5, 0.75 } } },
}
local interop = type(include) == 'function' and include('customweather.interop')
if interop then interop.registerRegion(definition) end
return definition
