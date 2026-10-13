local M={}
local menuId="OAAB:MannequinPoseDesigner:Blend"

function M.close(prompt,accept)
    if not prompt or not prompt.menu then return end
    local menu=prompt.menu
    prompt.accepted=accept==true and prompt.valid==true
    prompt.menu=nil
    menu:destroy()
    tes3ui.leaveMenuMode()
end

function M.open(files,onPreview,onClose)
    if tes3ui.findMenu(menuId) then return end
    local menu=tes3ui.createMenu({id=menuId,fixedFrame=true})
    menu.flowDirection=tes3.flowDirection.topToBottom
    menu.childAlignX=0.5
    local w,h=tes3ui.getViewportSize()
    local width=math.min(320,w-40)
    local listHeight=math.min(100,math.floor(h*0.18))
    local prompt={menu=menu,percent=50}
    local function layout()
        menu:updateLayout()
        local viewportWidth,viewportHeight=tes3ui.getViewportSize()
        -- Position properties need a subsequent layout pass to reach the menu
        -- scene node. Reapply after entering menu mode and preview text changes.
        menu.ignoreLayoutX=true; menu.ignoreLayoutY=true
        menu.positionX=math.floor(viewportWidth/2-menu.width-12)
        menu.positionY=math.min(math.floor(menu.height/2),math.floor(viewportHeight/2-12))
        menu:updateLayout()
    end
    menu:createLabel({text="Blend Poses"}).borderBottom=6
    menu:createLabel({text="Choose a pose in each list."}).borderBottom=4
    local slots={}
    for _,side in ipairs({"a","b"}) do
        local label=side=="a" and "A (0%)" or "B (100%)"
        local heading=menu:createLabel({text=label..": choose a pose"})
        local pane=menu:createVerticalScrollPane({})
        -- Native scroll panes default to proportional sizing. In an auto-sized
        -- menu there is no remaining height to divide, so the list collapses.
        pane.widthProportional=nil; pane.heightProportional=nil
        pane.autoWidth=false; pane.autoHeight=false
        pane.width=width; pane.minWidth=width; pane.maxWidth=width
        pane.height=listHeight; pane.minHeight=listHeight; pane.maxHeight=listHeight
        pane.borderBottom=4
        local content=pane:getContentElement()
        content.flowDirection=tes3.flowDirection.topToBottom
        content.widthProportional=nil; content.heightProportional=nil
        content.autoHeight=true; content.autoWidth=false
        content.width=width-24
        slots[side]={label=label,heading=heading,pane=pane}
    end
    local amount=menu:createLabel({text="Blend: 50%"})
    local slider=menu:createSlider({current=50,max=100,step=1,jump=10})
    slider.width=width
    slider.disabled=true
    local status=menu:createLabel({text=#files==0 and "No poses available." or "0% = A, 100% = B"})
    status.borderTop=4
    status.wrapText=true; status.width=width
    local accept=menu:createButton({text="Use blend"})
    accept.borderTop=6; accept.disabled=true
    local cancel=menu:createButton({text="Cancel"})
    local function preview()
        if not prompt.menu then return end
        prompt.valid=false; accept.disabled=true
        slider.disabled=not (prompt.a and prompt.b)
        amount.text=string.format("Blend: %d%%",prompt.percent)
        if prompt.a and prompt.b then
            local ok,err=onPreview(prompt.a.file,prompt.b.file,prompt.percent/100)
            if not prompt.menu then return end
            prompt.valid=ok==true
            accept.disabled=not prompt.valid
            status.text=ok and "Live preview. Use blend to keep it." or tostring(err or "Could not blend these poses.")
        end
        layout()
    end
    for _,side in ipairs({"a","b"}) do
        local slot=side
        for _,file in ipairs(files) do
            local choice=file
            local button=slots[slot].pane:createButton({text=choice.label})
            button:register(tes3.uiEvent.mouseClick,function()
                if not prompt.menu then return end
                prompt[slot]=choice
                slots[slot].heading.text=slots[slot].label..": "..choice.label
                preview()
            end)
        end
    end
    slider:register("PartScrollBar_changed",function()
        if not prompt.menu or slider.disabled then return end
        prompt.percent=math.max(0,math.min(100,math.floor(slider.widget.current+0.5)))
        preview()
    end)
    accept:register(tes3.uiEvent.mouseClick,function()
        if prompt.valid then M.close(prompt,true) end
    end)
    cancel:register(tes3.uiEvent.mouseClick,function() M.close(prompt) end)
    menu:register(tes3.uiEvent.keyPress,function(e)
        if e.data0==tes3.scanCode.escape then M.close(prompt); return false end
    end)
    menu:register(tes3.uiEvent.destroy,function()
        prompt.menu=nil
        if onClose then onClose(prompt.accepted==true) end
    end)
    menu:updateLayout()
    for _,side in ipairs({"a","b"}) do slots[side].pane.widget:contentsChanged() end
    layout()
    local function activate(remaining)
        if prompt.menu~=menu or tes3ui.menuMode() or remaining==0 then return end
        tes3ui.enterMenuMode(menuId)
        layout()
        timer.frame.delayOneFrame(function() activate(remaining-1) end)
    end
    timer.frame.delayOneFrame(function() activate(3) end)
    return prompt
end
return M
