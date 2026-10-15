local menu = require 'openmw.menu'
local pending = false
local frames = 0
return {
  eventHandlers = { ArachnophobiaSave = function()
    print('ARACHNOPHOBIA TEST: saving isolated test game')
    menu.saveGame('Arachnophobia validation', 'arachnophobia-test.omwsave')
    pending = true
  end },
  engineHandlers = { onFrame = function()
    if pending then
      frames = frames + 1
      if frames == 90 then
        print('ARACHNOPHOBIA TEST: loading isolated test game')
        local directory = menu.getCurrentSaveDir()
        local newest, newestTime = nil, -1
        for slot, info in pairs(menu.getSaves(directory)) do
          if info.description == 'Arachnophobia validation' and info.creationTime > newestTime then
            newest, newestTime = slot, info.creationTime
          end
        end
        assert(newest, 'isolated test save was not found')
        menu.loadGame(directory, newest)
        pending = false
      end
    end
  end }
}
