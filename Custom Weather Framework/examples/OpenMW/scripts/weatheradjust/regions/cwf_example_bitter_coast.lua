-- Discovered by the OpenMW framework; no registration or extra content file needed.
-- Edit these RGB components directly as 0..255 values.
local function rgb(r, g, b)
    return { r / 255, g / 255, b / 255 }
end

return {
    version = 1,
    region = 'Bitter Coast Region',
    preset = {
        Clear = {
            -- Teal daytime sky and fog.
            skyDayColor = rgb(38, 166, 191),
            fogDayColor = rgb(64, 153, 166),
            -- Pink sunset sky and fog.
            skySunsetColor = rgb(191, 64, 102),
            fogSunsetColor = rgb(166, 77, 102),
        },
    },
}
