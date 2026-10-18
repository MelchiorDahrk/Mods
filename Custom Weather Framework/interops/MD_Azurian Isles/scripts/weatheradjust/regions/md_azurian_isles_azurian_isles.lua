-- Discovered automatically by the OpenMW edition of Custom Weather Framework.
-- Omitted settings inherit the installed engine defaults.
local function rgb(r, g, b)
    return { r / 255, g / 255, b / 255 }
end

return {
    version = 1,
    region = 'AZ_Region_Azurian Isles',
    preset = {
        Clear = {
            skySunriseColor     = rgb(154, 182, 206),
            skyDayColor         = rgb( 96, 176, 224),
            skySunsetColor      = rgb(192, 138, 188),
            skyNightColor       = rgb( 24,  36,  60),

            fogSunriseColor     = rgb(255, 214, 184),
            fogDayColor         = rgb(172, 216, 232),
            fogSunsetColor      = rgb(224, 172, 194),
            fogNightColor       = rgb( 30,  44,  69),

            ambientDayColor     = rgb(147, 155, 164),
            ambientNightColor   = rgb( 54,  61,  74),

            sunDayColor         = rgb(255, 244, 228),
            sunSunsetColor      = rgb(255, 167, 124),
            sundiscSunsetColor  = rgb(255, 197, 148),

            cloudTexture = 'textures/tx_sky_clear.dds',
        },

        Cloudy = {
            skyDayColor         = rgb(114, 170, 206),
            skySunsetColor      = rgb(166, 133, 176),
            fogDayColor         = rgb(194, 214, 222),
            fogSunsetColor      = rgb(214, 167, 173),
            ambientDayColor     = rgb(136, 144, 154),
            sunDayColor         = rgb(240, 232, 218),

            cloudTexture = 'textures/tx_sky_cloudy.dds',
        },

        Foggy = {
            skyDayColor         = rgb(176, 205, 214),
            skySunsetColor      = rgb(154, 166, 178),
            skyNightColor       = rgb( 34,  48,  64),

            fogDayColor         = rgb(156, 191, 203),
            fogSunsetColor      = rgb(146, 162, 176),
            fogNightColor       = rgb( 38,  54,  71),

            ambientDayColor     = rgb(118, 130, 140),
            ambientNightColor   = rgb( 51,  58,  67),

            sunDayColor         = rgb(194, 209, 214),

            cloudTexture = 'textures/tx_sky_foggy.dds',
        },

        Rain = {
            skyDayColor         = rgb(104, 122, 138),
            skySunsetColor      = rgb( 96, 109, 122),
            fogDayColor         = rgb(104, 122, 132),
            fogSunsetColor      = rgb( 99, 112, 120),
            ambientDayColor     = rgb( 96, 104, 111),
            ambientNightColor   = rgb( 56,  62,  72),
            sunDayColor         = rgb(147, 162, 175),

            cloudTexture = 'textures/tx_sky_rainy.dds',
        },

        Thunderstorm = {
            skyDayColor         = rgb( 71,  82, 104),
            skySunsetColor      = rgb( 64,  73,  96),
            skyNightColor       = rgb( 22,  27,  38),

            fogDayColor         = rgb( 77,  89, 108),
            fogSunsetColor      = rgb( 72,  81, 100),
            fogNightColor       = rgb( 25,  31,  42),

            ambientDayColor     = rgb( 78,  80,  89),
            ambientNightColor   = rgb( 48,  51,  58),

            sunDayColor         = rgb(133, 142, 160),

            cloudTexture = 'textures/tx_sky_thunder.dds',
        },
    },
}
