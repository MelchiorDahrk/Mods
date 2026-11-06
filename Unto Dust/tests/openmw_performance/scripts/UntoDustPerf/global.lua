local core = require('openmw.core')
local world = require('openmw.world')
local util = require('openmw.util')
-- Includes same-state transitions and both directions of dust on/off changes.
local route = {
    { 'Samarys Ancestral Tomb', -2272, 992, 352 },
    { 'Andrano Ancestral Tomb', 1376, 7552, 14624 },
    { "Balmora, Caius Cosades' House", 163, -228, 192 },
    { 'Andrano Ancestral Tomb', 1376, 7552, 14624 },
    { '', -17000, -58000, 1000 },
    { 'Andrano Ancestral Tomb', 1376, 7552, 14624 },
}
local previous, started, samples, index = nil, nil, {}, 0
return { engineHandlers = { onUpdate = function()
    local player = world.players[1]
    if not player then return end
    local now = core.getRealTime()
    started = started or now
    if previous and index > 0 then samples[#samples + 1] = (now - previous) * 1000 end
    previous = now
    -- First circuit warms cell/assets caches; retain it separately in output.
    if now - started < (index == 0 and 3 or 1) then return end
    if index > 0 then
        local encoded = {}
        for i, value in ipairs(samples) do encoded[i] = string.format('%.3f', value) end
        print('DUST_PERF|' .. index .. '|' .. ((index - 1) % #route + 1) .. '|' .. table.concat(encoded, ','))
    end
    index = index + 1
    if index > #route * 6 then
        print('DUST_PERF_DONE')
        core.quit()
        return
    end
    samples, started = {}, now
    local target = route[(index - 1) % #route + 1]
    player:teleport(target[1], util.vector3(target[2], target[3], target[4]), {
        rotation = util.transform.rotateZ(-math.pi / 2),
    })
end } }
