local menu = require('openmw.menu')
local storage = require('openmw.storage')
local lists = require('scripts.UntoDust.cellLists')
local pending = false
local frames = 0

return {
    eventHandlers = {
        UntoDustSmokeDensity = function(data)
            -- Native Settings writes this same persistent section from menus.
            storage.playerSection('SettingsUntoDust'):set('density', data.value)
        end,
        UntoDustSmokeLists = function(data)
            local settings = storage.playerSection('SettingsUntoDust')
            settings:set('whitelist', lists.read(data.whitelist))
            settings:set('blacklist', lists.read(data.blacklist))
        end,
        UntoDustSmokeSave = function()
            menu.saveGame('Unto Dust smoke test', 'unto-dust-smoke.omwsave')
            pending = true
            frames = 0
        end,
    },
    engineHandlers = {
        onFrame = function()
            if not pending then return end
            frames = frames + 1
            if frames < 90 then return end
            local directory = menu.getCurrentSaveDir()
            local newest, newestTime = nil, -1
            for slot, info in pairs(menu.getSaves(directory)) do
                if info.description == 'Unto Dust smoke test' and info.creationTime > newestTime then
                    newest, newestTime = slot, info.creationTime
                end
            end
            assert(newest, 'UNTO DUST SMOKE FAILED: isolated save missing')
            print('UNTO DUST SMOKE: reloading isolated save')
            menu.loadGame(directory, newest)
            pending = false
        end,
    },
}
