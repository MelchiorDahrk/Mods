-- A normal MWSE mod entry point. The framework is an optional dependency.
local weather = include('customweather.interop')
if not weather then return end

-- This path belongs to this example mod. Move it and update the require as needed.
weather.registerRegion(require('cwf_example.weatheradjust.bitter_coast'))
