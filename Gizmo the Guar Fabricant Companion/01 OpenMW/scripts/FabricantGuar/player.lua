local core = require('openmw.core')
local I = require('openmw.interfaces')
local self = require('openmw.self')
local ui = require('openmw.ui')

local repairRequest
local lastRepair = 0

local function acknowledge(id)
    core.sendGlobalEvent('FGRepairAccepted', { id = id })
end

return {
    engineHandlers = {
        onSave = function() return { lastRepair = lastRepair, repairRequest = repairRequest } end,
        onLoad = function(data)
            lastRepair = data and data.lastRepair or 0
            repairRequest = data and data.repairRequest
        end,
        onFrame = function()
            if not repairRequest then return end
            local id = repairRequest
            repairRequest = nil
            -- Replacing dialogue here avoids Goodbye/dialogue teardown closing
            -- the repair window. The MWSE no-argument service uses Player.
            local ok, err = pcall(I.UI.setMode, 'MerchantRepair', { target = self.object })
            if ok then
                lastRepair = id
                acknowledge(id)
            else
                ui.showMessage('[Gizmo repair service could not open. See openmw.log.]')
                print('Fabricant Guar MerchantRepair: ' .. tostring(err))
            end
        end,
    },
    eventHandlers = {
        FGMessage = function(message) ui.showMessage(message) end,
        FGRepair = function(data)
            if data.id <= lastRepair then acknowledge(data.id)
            else repairRequest = data.id end
        end,
    },
}
