local world = require('openmw.world')

return {
    engineHandlers = {
        onPlayerAdded = function(player)
            local names, seen = {}, {}
            for _, cell in ipairs(world.cells) do
                local name = cell.name
                if not cell.isExterior and name ~= '' and not seen[name:lower()] then
                    seen[name:lower()] = true
                    names[#names + 1] = name
                end
            end
            table.sort(names, function(a, b) return a:lower() < b:lower() end)
            player:sendEvent('UntoDustCells', names)
        end,
    },
}
