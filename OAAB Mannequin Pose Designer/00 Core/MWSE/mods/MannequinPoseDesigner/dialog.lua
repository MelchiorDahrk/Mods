-- Shared lifecycle for editor command menus.
local M={}
function M.close(prompt)
    if not prompt or not prompt.menu then return end
    local menu=prompt.menu
    prompt.menu=nil
    menu:destroy()
    tes3ui.leaveMenuMode()
end
function M.create(id)
    if tes3ui.findMenu(id) then return end
    local menu=tes3ui.createMenu({id=id,fixedFrame=true})
    menu.flowDirection=tes3.flowDirection.topToBottom
    menu.childAlignX=0.5
    return {menu=menu}
end
function M.activate(prompt,id,onClose)
    local menu=prompt.menu
    menu:register(tes3.uiEvent.keyPress,function(e)
        if e.data0==tes3.scanCode.escape then M.close(prompt); return false end
    end)
    menu:register(tes3.uiEvent.destroy,function()
        prompt.menu=nil
        if onClose then onClose() end
    end)
    menu:updateLayout()
    local function activate(remaining)
        if prompt.menu~=menu or tes3ui.menuMode() or remaining==0 then return end
        tes3ui.enterMenuMode(id)
        timer.frame.delayOneFrame(function() activate(remaining-1) end)
    end
    timer.frame.delayOneFrame(function() activate(3) end)
end
return M
