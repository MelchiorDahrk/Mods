local menu = require('openmw.menu')
local frames
return {
    eventHandlers = { KegDripSmokeSave = function()
        menu.saveGame('Keg Drip validation', 'keg-drip-test.omwsave')
        frames = 0
    end },
    engineHandlers = { onFrame = function()
        if not frames then return end
        frames = frames + 1
        if frames < 90 then return end
        local directory = menu.getCurrentSaveDir()
        local newest, newestTime = nil, -1
        for slot, info in pairs(menu.getSaves(directory)) do
            if info.description == 'Keg Drip validation' and info.creationTime > newestTime then
                newest, newestTime = slot, info.creationTime
            end
        end
        assert(newest, 'KEG DRIP TEST FAILED: save was not found')
        menu.loadGame(directory, newest)
        frames = nil
    end },
}
