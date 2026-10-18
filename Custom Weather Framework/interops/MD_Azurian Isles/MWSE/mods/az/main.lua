-- The framework is an optional dependency; region definitions are plain data.
local weather = include('customweather.interop')
if not weather then return end

weather.registerRegion(require('az.weatheradjust.azurian_isles'))
weather.registerRegion(require('az.weatheradjust.thousand_isles'))
weather.registerRegion(require('az.weatheradjust.scabrous_residuum'))
