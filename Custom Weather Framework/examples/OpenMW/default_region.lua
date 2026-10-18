-- Full stock Morrowind GOTY region preset: 10 weathers, 17 colours each.
-- Edit region (and the MWSE registration id) below, then edit any rgb(...) values.
-- rgb uses ordinary 0..255 red, green and blue components; the API uses 0..1.
-- This is a static stock baseline. Delete entries to inherit your installed defaults.
-- Copy to scripts/weatheradjust/regions/<your_mod>_<region>.lua to activate.
-- Source: OpenMW 0.51 weather records with stock GOTY INI weather fallbacks.

local function rgb(r, g, b)
    return { r / 255, g / 255, b / 255 }
end

return {
    version = 1,
    region = 'Bitter Coast Region', -- Replace with your target region ID.
    preset = {
        Clear = {
            -- Sky: sunrise, day, sunset, night.
            skySunriseColor         = rgb(117, 141, 164),
            skyDayColor             = rgb( 95, 135, 203),
            skySunsetColor          = rgb( 56,  89, 129),
            skyNightColor           = rgb(  9,  10,  11),
            -- Fog: sunrise, day, sunset, night.
            fogSunriseColor         = rgb(255, 189, 157),
            fogDayColor             = rgb(206, 227, 255),
            fogSunsetColor          = rgb(255, 189, 157),
            fogNightColor           = rgb(  9,  10,  11),
            -- Ambient light: sunrise, day, sunset, night.
            ambientSunriseColor     = rgb( 47,  66,  96),
            ambientDayColor         = rgb(137, 140, 160),
            ambientSunsetColor      = rgb( 68,  75,  96),
            ambientNightColor       = rgb( 32,  35,  42),
            -- Sunlight: sunrise, day, sunset, night.
            sunSunriseColor         = rgb(242, 159, 119),
            sunDayColor             = rgb(255, 252, 238),
            sunSunsetColor          = rgb(255, 114,  79),
            sunNightColor           = rgb( 59,  97, 176),
            -- The visible sun disc at sunset.
            sundiscSunsetColor      = rgb(255, 189, 157),
            cloudTexture = 'textures/tx_sky_clear.dds',
        },
        Cloudy = {
            -- Sky: sunrise, day, sunset, night.
            skySunriseColor         = rgb(126, 158, 173),
            skyDayColor             = rgb(117, 160, 215),
            skySunsetColor          = rgb(111, 114, 159),
            skyNightColor           = rgb(  9,  10,  11),
            -- Fog: sunrise, day, sunset, night.
            fogSunriseColor         = rgb(255, 207, 149),
            fogDayColor             = rgb(245, 235, 224),
            fogSunsetColor          = rgb(255, 155, 106),
            fogNightColor           = rgb(  9,  10,  11),
            -- Ambient light: sunrise, day, sunset, night.
            ambientSunriseColor     = rgb( 66,  74,  87),
            ambientDayColor         = rgb(137, 145, 160),
            ambientSunsetColor      = rgb( 71,  80,  92),
            ambientNightColor       = rgb( 32,  39,  54),
            -- Sunlight: sunrise, day, sunset, night.
            sunSunriseColor         = rgb(241, 177,  99),
            sunDayColor             = rgb(255, 236, 221),
            sunSunsetColor          = rgb(255,  89,   0),
            sunNightColor           = rgb( 77,  91, 124),
            -- The visible sun disc at sunset.
            sundiscSunsetColor      = rgb(255, 202, 179),
            cloudTexture = 'textures/tx_sky_cloudy.dds',
        },
        Foggy = {
            -- Sky: sunrise, day, sunset, night.
            skySunriseColor         = rgb(197, 190, 180),
            skyDayColor             = rgb(184, 211, 228),
            skySunsetColor          = rgb(142, 159, 176),
            skyNightColor           = rgb( 18,  23,  28),
            -- Fog: sunrise, day, sunset, night.
            fogSunriseColor         = rgb(173, 164, 148),
            fogDayColor             = rgb(150, 187, 209),
            fogSunsetColor          = rgb(113, 135, 157),
            fogNightColor           = rgb( 19,  24,  29),
            -- Ambient light: sunrise, day, sunset, night.
            ambientSunriseColor     = rgb( 48,  43,  37),
            ambientDayColor         = rgb( 92, 109, 120),
            ambientSunsetColor      = rgb( 29,  53,  76),
            ambientNightColor       = rgb( 28,  33,  39),
            -- Sunlight: sunrise, day, sunset, night.
            sunSunriseColor         = rgb(177, 162, 137),
            sunDayColor             = rgb(111, 131, 151),
            sunSunsetColor          = rgb(125, 157, 189),
            sunNightColor           = rgb( 81, 100, 119),
            -- The visible sun disc at sunset.
            sundiscSunsetColor      = rgb(223, 223, 223),
            cloudTexture = 'textures/tx_sky_foggy.dds',
        },
        Overcast = {
            -- Sky: sunrise, day, sunset, night.
            skySunriseColor         = rgb( 91,  99, 106),
            skyDayColor             = rgb(143, 146, 149),
            skySunsetColor          = rgb(108, 115, 121),
            skyNightColor           = rgb( 19,  22,  25),
            -- Fog: sunrise, day, sunset, night.
            fogSunriseColor         = rgb( 91,  99, 106),
            fogDayColor             = rgb(143, 146, 149),
            fogSunsetColor          = rgb(108, 115, 121),
            fogNightColor           = rgb( 19,  22,  25),
            -- Ambient light: sunrise, day, sunset, night.
            ambientSunriseColor     = rgb( 84,  88,  92),
            ambientDayColor         = rgb( 93,  96, 105),
            ambientSunsetColor      = rgb( 83,  77,  75),
            ambientNightColor       = rgb( 57,  60,  66),
            -- Sunlight: sunrise, day, sunset, night.
            sunSunriseColor         = rgb( 87, 125, 163),
            sunDayColor             = rgb(163, 169, 183),
            sunSunsetColor          = rgb( 85, 103, 157),
            sunNightColor           = rgb( 32,  54, 100),
            -- The visible sun disc at sunset.
            sundiscSunsetColor      = rgb(128, 128, 128),
            cloudTexture = 'textures/tx_sky_overcast.dds',
        },
        Rain = {
            -- Sky: sunrise, day, sunset, night.
            skySunriseColor         = rgb( 71,  74,  75),
            skyDayColor             = rgb(116, 120, 122),
            skySunsetColor          = rgb( 73,  73,  73),
            skyNightColor           = rgb( 24,  25,  26),
            -- Fog: sunrise, day, sunset, night.
            fogSunriseColor         = rgb( 71,  74,  75),
            fogDayColor             = rgb(116, 120, 122),
            fogSunsetColor          = rgb( 73,  73,  73),
            fogNightColor           = rgb( 24,  25,  26),
            -- Ambient light: sunrise, day, sunset, night.
            ambientSunriseColor     = rgb( 97,  90,  88),
            ambientDayColor         = rgb(105, 110, 113),
            ambientSunsetColor      = rgb( 88,  97,  97),
            ambientNightColor       = rgb( 50,  55,  67),
            -- Sunlight: sunrise, day, sunset, night.
            sunSunriseColor         = rgb(131, 122, 120),
            sunDayColor             = rgb(149, 157, 170),
            sunSunsetColor          = rgb(120, 126, 131),
            sunNightColor           = rgb( 50,  62, 101),
            -- The visible sun disc at sunset.
            sundiscSunsetColor      = rgb(128, 128, 128),
            cloudTexture = 'textures/tx_sky_rainy.dds',
        },
        Thunderstorm = {
            -- Sky: sunrise, day, sunset, night.
            skySunriseColor         = rgb( 35,  36,  39),
            skyDayColor             = rgb( 97, 104, 115),
            skySunsetColor          = rgb( 35,  36,  39),
            skyNightColor           = rgb( 19,  20,  22),
            -- Fog: sunrise, day, sunset, night.
            fogSunriseColor         = rgb( 70,  74,  85),
            fogDayColor             = rgb( 97, 104, 115),
            fogSunsetColor          = rgb( 70,  74,  85),
            fogNightColor           = rgb( 19,  20,  22),
            -- Ambient light: sunrise, day, sunset, night.
            ambientSunriseColor     = rgb( 54,  54,  54),
            ambientDayColor         = rgb( 90,  90,  90),
            ambientSunsetColor      = rgb( 54,  54,  54),
            ambientNightColor       = rgb( 49,  51,  54),
            -- Sunlight: sunrise, day, sunset, night.
            sunSunriseColor         = rgb( 91,  99, 122),
            sunDayColor             = rgb(138, 144, 155),
            sunSunsetColor          = rgb( 96, 101, 117),
            sunNightColor           = rgb( 55,  76, 110),
            -- The visible sun disc at sunset.
            sundiscSunsetColor      = rgb(128, 128, 128),
            cloudTexture = 'textures/tx_sky_thunder.dds',
        },
        Ashstorm = {
            -- Sky: sunrise, day, sunset, night.
            skySunriseColor         = rgb( 91,  56,  51),
            skyDayColor             = rgb(124,  73,  58),
            skySunsetColor          = rgb(106,  55,  40),
            skyNightColor           = rgb( 20,  21,  22),
            -- Fog: sunrise, day, sunset, night.
            fogSunriseColor         = rgb( 91,  56,  51),
            fogDayColor             = rgb(124,  73,  58),
            fogSunsetColor          = rgb(106,  55,  40),
            fogNightColor           = rgb( 20,  21,  22),
            -- Ambient light: sunrise, day, sunset, night.
            ambientSunriseColor     = rgb( 54,  42,  37),
            ambientDayColor         = rgb( 75,  49,  41),
            ambientSunsetColor      = rgb( 48,  39,  35),
            ambientNightColor       = rgb( 36,  42,  49),
            -- Sunlight: sunrise, day, sunset, night.
            sunSunriseColor         = rgb(184,  91,  71),
            sunDayColor             = rgb(228, 139, 114),
            sunSunsetColor          = rgb(185,  86,  57),
            sunNightColor           = rgb( 54,  66,  74),
            -- The visible sun disc at sunset.
            sundiscSunsetColor      = rgb(128, 128, 128),
            cloudTexture = 'textures/tx_sky_ashstorm.dds',
        },
        Blight = {
            -- Sky: sunrise, day, sunset, night.
            skySunriseColor         = rgb( 90,  35,  35),
            skyDayColor             = rgb( 90,  35,  35),
            skySunsetColor          = rgb( 92,  33,  33),
            skyNightColor           = rgb( 44,  14,  14),
            -- Fog: sunrise, day, sunset, night.
            fogSunriseColor         = rgb( 90,  35,  35),
            fogDayColor             = rgb(128,  19,  19),
            fogSunsetColor          = rgb( 92,  33,  33),
            fogNightColor           = rgb( 44,  14,  14),
            -- Ambient light: sunrise, day, sunset, night.
            ambientSunriseColor     = rgb( 61,  40,  40),
            ambientDayColor         = rgb( 79,  54,  54),
            ambientSunsetColor      = rgb( 61,  40,  40),
            ambientNightColor       = rgb( 56,  58,  62),
            -- Sunlight: sunrise, day, sunset, night.
            sunSunriseColor         = rgb(180,  78,  78),
            sunDayColor             = rgb(224,  84,  84),
            sunSunsetColor          = rgb(180,  78,  78),
            sunNightColor           = rgb( 61,  91, 143),
            -- The visible sun disc at sunset.
            sundiscSunsetColor      = rgb(128, 128, 128),
            cloudTexture = 'textures/tx_sky_blight.dds',
        },
        Snow = {
            -- Sky: sunrise, day, sunset, night.
            skySunriseColor         = rgb(106,  91,  91),
            skyDayColor             = rgb(153, 158, 166),
            skySunsetColor          = rgb( 96, 115, 134),
            skyNightColor           = rgb( 31,  35,  39),
            -- Fog: sunrise, day, sunset, night.
            fogSunriseColor         = rgb(106,  91,  91),
            fogDayColor             = rgb(153, 158, 166),
            fogSunsetColor          = rgb( 96, 115, 134),
            fogNightColor           = rgb( 31,  35,  39),
            -- Ambient light: sunrise, day, sunset, night.
            ambientSunriseColor     = rgb( 92,  84,  84),
            ambientDayColor         = rgb( 93,  96, 105),
            ambientSunsetColor      = rgb( 70,  79,  87),
            ambientNightColor       = rgb( 49,  58,  68),
            -- Sunlight: sunrise, day, sunset, night.
            sunSunriseColor         = rgb(141, 109, 109),
            sunDayColor             = rgb(163, 169, 183),
            sunSunsetColor          = rgb(101, 121, 141),
            sunNightColor           = rgb( 55,  66,  77),
            -- The visible sun disc at sunset.
            sundiscSunsetColor      = rgb(128, 128, 128),
            cloudTexture = 'textures/tx_bm_sky_snow.dds',
        },
        Blizzard = {
            -- Sky: sunrise, day, sunset, night.
            skySunriseColor         = rgb( 91,  99, 106),
            skyDayColor             = rgb(121, 133, 145),
            skySunsetColor          = rgb(108, 115, 121),
            skyNightColor           = rgb( 27,  29,  31),
            -- Fog: sunrise, day, sunset, night.
            fogSunriseColor         = rgb( 91,  99, 106),
            fogDayColor             = rgb(121, 133, 145),
            fogSunsetColor          = rgb(108, 115, 121),
            fogNightColor           = rgb( 21,  24,  28),
            -- Ambient light: sunrise, day, sunset, night.
            ambientSunriseColor     = rgb( 84,  88,  92),
            ambientDayColor         = rgb( 93,  96, 105),
            ambientSunsetColor      = rgb( 83,  77,  75),
            ambientNightColor       = rgb( 53,  62,  70),
            -- Sunlight: sunrise, day, sunset, night.
            sunSunriseColor         = rgb(114, 128, 146),
            sunDayColor             = rgb(163, 169, 183),
            sunSunsetColor          = rgb(106, 114, 136),
            sunNightColor           = rgb( 57,  66,  74),
            -- The visible sun disc at sunset.
            sundiscSunsetColor      = rgb(128, 128, 128),
            cloudTexture = 'textures/tx_bm_sky_blizzard.dds',
        },
    },
}
