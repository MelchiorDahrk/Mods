-- Discovered automatically by the OpenMW edition of Custom Weather Framework.
-- Omitted settings inherit the installed engine defaults.
local function rgb(r, g, b)
    return { r / 255, g / 255, b / 255 }
end

return {
    version = 1,
    region = 'AZ_Region_Thousand Isles',
    preset = {
        Clear = {
            skySunriseColor     = rgb(165, 148, 116),
            skyDayColor         = rgb(130, 156, 148),
            skySunsetColor      = rgb(145, 110,  84),
            skyNightColor       = rgb( 22,  28,  26),

            fogSunriseColor     = rgb(188, 164, 118),
            fogDayColor         = rgb(147, 154, 123),
            fogSunsetColor      = rgb(166, 126,  92),
            fogNightColor       = rgb( 31,  36,  31),

            ambientDayColor     = rgb(110, 118,  99),
            ambientNightColor   = rgb( 46,  54,  49),

            sunDayColor         = rgb(226, 221, 197),
            sunSunsetColor      = rgb(231, 170, 106),

            cloudTexture = 'textures/tx_sky_clear.dds',
        },

        Cloudy = {
            skyDayColor         = rgb(128, 138, 125),
            skySunsetColor      = rgb(126, 107,  92),
            fogDayColor         = rgb(132, 137, 117),
            fogSunsetColor      = rgb(136, 112,  95),
            ambientDayColor     = rgb( 98, 102,  89),
            sunDayColor         = rgb(181, 177, 160),

            cloudTexture = 'textures/tx_sky_cloudy.dds',
        },

        Foggy = {
            skyDayColor         = rgb(140, 154, 132),
            skySunsetColor      = rgb(124, 130, 114),
            skyNightColor       = rgb( 28,  34,  29),

            fogDayColor         = rgb(122, 130, 106),
            fogSunsetColor      = rgb(116, 121, 102),
            fogNightColor       = rgb( 32,  37,  31),

            ambientDayColor     = rgb( 92,  98,  84),
            ambientNightColor   = rgb( 50,  55,  50),

            sunDayColor         = rgb(152, 159, 145),

            cloudTexture = 'textures/tx_sky_foggy.dds',
        },

        Overcast = {
            skyDayColor         = rgb(121, 124, 111),
            skySunsetColor      = rgb(110, 108, 100),
            fogDayColor         = rgb(118, 118, 109),
            fogSunsetColor      = rgb(108, 107, 100),
            ambientDayColor     = rgb( 91,  92,  84),
            ambientNightColor   = rgb( 55,  58,  56),
            sunDayColor         = rgb(152, 149, 137),

            cloudTexture = 'textures/tx_sky_overcast.dds',
        },

        Rain = {
            skyDayColor         = rgb( 94, 100,  93),
            skySunsetColor      = rgb( 84,  88,  82),
            fogDayColor         = rgb( 90,  95,  87),
            fogSunsetColor      = rgb( 82,  86,  79),
            ambientDayColor     = rgb( 80,  85,  78),
            ambientNightColor   = rgb( 47,  52,  50),
            sunDayColor         = rgb(123, 129, 125),

            cloudTexture = 'textures/tx_sky_rainy.dds',
        },

        Thunderstorm = {
            skyDayColor         = rgb( 63,  69,  71),
            skySunsetColor      = rgb( 57,  61,  64),
            skyNightColor       = rgb( 20,  23,  25),

            fogDayColor         = rgb( 67,  72,  70),
            fogSunsetColor      = rgb( 61,  65,  63),
            fogNightColor       = rgb( 22,  26,  27),

            ambientDayColor     = rgb( 60,  64,  62),
            ambientNightColor   = rgb( 42,  46,  47),

            sunDayColor         = rgb(101, 110, 117),

            cloudTexture = 'textures/tx_sky_thunder.dds',
        },
    },
}
