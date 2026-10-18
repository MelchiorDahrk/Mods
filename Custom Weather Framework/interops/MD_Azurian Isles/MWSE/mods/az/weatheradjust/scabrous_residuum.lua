-- Registered by az/main.lua through the MWSE interop.
-- Omitted settings inherit the installed engine defaults.
local function rgb(r, g, b)
    return { r / 255, g / 255, b / 255 }
end

return {
    version = 1,
    id = 'MD_Azurian Isles:scabrous_residuum',
    priority = 0,
    region = 'AZ_Region_Scabrous Residuum',
    preset = {
        Clear = {
            skySunriseColor     = rgb(162, 151, 162),
            skyDayColor         = rgb(171, 176, 188),
            skySunsetColor      = rgb(144, 118, 139),
            skyNightColor       = rgb( 28,  31,  42),

            fogSunriseColor     = rgb(145, 136, 140),
            fogDayColor         = rgb(139, 144, 152),
            fogSunsetColor      = rgb(126, 110, 124),
            fogNightColor       = rgb( 33,  36,  46),

            ambientDayColor     = rgb(108, 111, 118),
            ambientNightColor   = rgb( 58,  62,  75),

            sunDayColor         = rgb(216, 219, 224),
            sunSunsetColor      = rgb(178, 141, 156),

            cloudTexture = 'textures/tx_sky_clear.dds',
        },

        Foggy = {
            skyDayColor         = rgb(132, 138, 134),
            skySunsetColor      = rgb(118, 123, 119),
            fogDayColor         = rgb(103, 111, 103),
            fogSunsetColor      = rgb( 96, 103,  97),
            fogNightColor       = rgb( 29,  34,  31),
            ambientDayColor     = rgb( 78,  84,  79),
            ambientNightColor   = rgb( 47,  52,  49),
            sunDayColor         = rgb(145, 151, 146),

            cloudTexture = 'textures/tx_sky_foggy.dds',
        },

        Overcast = {
            skyDayColor         = rgb(118, 121, 128),
            skySunsetColor      = rgb(108, 111, 118),
            fogDayColor         = rgb(106, 109, 115),
            fogSunsetColor      = rgb(100, 103, 110),
            ambientDayColor     = rgb( 84,  86,  92),
            ambientNightColor   = rgb( 53,  57,  64),
            sunDayColor         = rgb(149, 153, 162),

            cloudTexture = 'textures/tx_sky_overcast.dds',
        },

        Thunderstorm = {
            skyDayColor         = rgb( 72,  74,  88),
            skySunsetColor      = rgb( 66,  67,  80),
            skyNightColor       = rgb( 21,  23,  31),

            fogDayColor         = rgb( 76,  79,  92),
            fogSunsetColor      = rgb( 69,  72,  84),
            fogNightColor       = rgb( 24,  27,  35),

            ambientDayColor     = rgb( 65,  67,  75),
            ambientNightColor   = rgb( 43,  46,  53),

            sunDayColor         = rgb(111, 117, 131),

            cloudTexture = 'textures/tx_sky_thunder.dds',
        },

        Ashstorm = {
            skyDayColor         = rgb(109,  94,  85),
            skySunsetColor      = rgb(101,  82,  74),
            fogDayColor         = rgb(102,  89,  80),
            fogSunsetColor      = rgb( 95,  82,  74),
            ambientDayColor     = rgb( 72,  61,  57),
            ambientNightColor   = rgb( 45,  42,  44),
            sunDayColor         = rgb(173, 140, 116),

            cloudTexture = 'textures/tx_sky_ashstorm.dds',
        },

        Blight = {
            skyDayColor         = rgb(104,  57,  61),
            skySunsetColor      = rgb( 96,  50,  57),
            skyNightColor       = rgb( 45,  22,  28),

            fogDayColor         = rgb( 92,  73,  63),
            fogSunsetColor      = rgb( 88,  64,  58),
            fogNightColor       = rgb( 39,  24,  24),

            ambientDayColor     = rgb( 76,  58,  58),
            ambientNightColor   = rgb( 50,  42,  47),

            sunDayColor         = rgb(181, 103, 103),
            sunSunsetColor      = rgb(165,  88,  88),

            cloudTexture = 'textures/tx_sky_blight.dds',
        },
    },
}
