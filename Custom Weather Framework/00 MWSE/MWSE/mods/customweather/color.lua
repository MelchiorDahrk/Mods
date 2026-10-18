-- Engine-independent colour picker math. Keep identical in both editions.
local M = {}

function M.clamp(value)
    return math.max(0, math.min(1, value))
end

function M.toHSV(rgb, previousHue)
    local r, g, b = rgb[1], rgb[2], rgb[3]
    local hi, lo = math.max(r, g, b), math.min(r, g, b)
    local delta, hue = hi - lo, previousHue or 0
    if delta > 0 then
        if hi == r then hue = ((g - b) / delta) % 6
        elseif hi == g then hue = (b - r) / delta + 2
        else hue = (r - g) / delta + 4 end
        hue = hue / 6
    end
    return { hue, hi == 0 and 0 or delta / hi, hi }
end

function M.toRGB(hsv)
    local h, s, v = (hsv[1] % 1) * 6, M.clamp(hsv[2]), M.clamp(hsv[3])
    local sector = math.floor(h)
    local f = h - sector
    local p, q, t = v * (1 - s), v * (1 - s * f), v * (1 - s * (1 - f))
    if sector == 0 then return { v, t, p }
    elseif sector == 1 then return { q, v, p }
    elseif sector == 2 then return { p, v, t }
    elseif sector == 3 then return { p, q, v }
    elseif sector == 4 then return { t, p, v }
    else return { v, p, q } end
end

function M.hex(rgb)
    return string.format('#%02X%02X%02X', math.floor(M.clamp(rgb[1]) * 255 + 0.5),
        math.floor(M.clamp(rgb[2]) * 255 + 0.5), math.floor(M.clamp(rgb[3]) * 255 + 0.5))
end

function M.label(rgb)
    return string.format('rgb(%d, %d, %d)', math.floor(rgb[1] * 255 + 0.5),
        math.floor(rgb[2] * 255 + 0.5), math.floor(rgb[3] * 255 + 0.5))
end

function M.parse(value)
    local hex = value:match('^%s*#(%x%x%x%x%x%x)%s*$')
    if hex then
        return { tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255,
            tonumber(hex:sub(5, 6), 16) / 255 }
    end
    value = value:match('^%s*rgb%((.-)%)%s*$') or value
    local r, g, b = value:match('^%s*([%d%.]+)%s*,%s*([%d%.]+)%s*,%s*([%d%.]+)%s*$')
    local rgb = { tonumber(r), tonumber(g), tonumber(b) }
    for i = 1, 3 do
        if not rgb[i] or rgb[i] ~= rgb[i] or rgb[i] < 0 or rgb[i] > 255 then return nil end
        rgb[i] = rgb[i] / 255
    end
    return rgb
end

return M
