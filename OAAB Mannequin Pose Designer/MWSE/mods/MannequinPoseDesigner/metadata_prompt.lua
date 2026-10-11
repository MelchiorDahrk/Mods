local metadata=require("MannequinPoseDesigner.pose_metadata")
local library=require("MannequinPoseDesigner.library")
local textRepeat=require("MannequinPoseDesigner.text_repeat")
local M={}
local menuId="OAAB:MannequinPoseDesigner:Metadata"
function M.close(prompt)
    if not prompt or not prompt.menu then return end
    local menu=prompt.menu; prompt.menu=nil
    menu:destroy(); tes3ui.leaveMenuMode()
end
function M.open(initial,onSave,onClose,options)
    initial=initial or {}; options=options or {}
    if tes3ui.findMenu(menuId) then return end
    local menu=tes3ui.createMenu({id=menuId,fixedFrame=true})
    menu.flowDirection=tes3.flowDirection.topToBottom
    local prompt={menu=menu,inputs={}}
    menu:createLabel({text=options.title or "New pose"}).borderBottom=8
    local nameInput
    local function field(key,label,value,limit,multiline)
        menu:createLabel({text=label}).borderTop=5
        local border=menu:createThinBorder({})
        border.widthProportional=nil; border.heightProportional=nil
        border.autoWidth=false; border.autoHeight=false
        border.width=480; border.height=multiline or 28; border.childAlignY=0.5
        border.minWidth=480; border.maxWidth=480; border.minHeight=border.height; border.maxHeight=border.height
        local input
        if multiline then input=border:createParagraphInput({}); input.text=value or ""
        else input=border:createTextInput({text=value or ""}); input.autoWidth=true; input.height=24 end
        input.borderLeft=5; input.borderRight=5; input.consumeMouseEvents=false
        input.repeatKeys=true
        input.widget.lengthLimit=limit
        if not multiline then input.widget.eraseOnFirstKey=false end
        if multiline then input.widthProportional=1; input.heightProportional=1 end
        prompt.inputs[key]=input
        border:registerAfter(tes3.uiEvent.mouseClick,function() tes3ui.acquireTextInput(input) end)
        return input
    end
    -- Paragraph fields wrap long names/categories instead of hitting the
    -- native single-line input's pixel-width insertion guard.
    nameInput=field("name","Name",initial.name,120,44)
    if options.immutableId then
        menu:createLabel({text="ID: "..(initial.id or "").." (fixed)"}).borderTop=5
    else
        field("id","Stable ID ("..library.maxIdLength.." letters, numbers, underscores or hyphens)",initial.id,library.maxIdLength)
    end
    field("description","Description",initial.description,2000,90)
    field("category","Category",initial.category,80,44)
    local errorLabel=menu:createLabel({text=""}); errorLabel.color={1,0.35,0.35}; errorLabel.wrapText=true; errorLabel.width=480
    local function submit()
        if not prompt.menu then return false end
        local fields={id=options.immutableId and initial.id or prompt.inputs.id.text,
            name=prompt.inputs.name.text,description=prompt.inputs.description.text,category=prompt.inputs.category.text}
        local ok,result=pcall(function()
            fields=metadata.validate(fields)
            if not options.immutableId then
                local file,err=library.idFile(fields.id,options.records); assert(file,err)
            end
            -- Keep fields and the dialog intact when an I/O failure occurs.
            local accepted,err=onSave(fields)
            assert(accepted~=false,err or "Could not save pose")
            return fields
        end)
        if not ok then errorLabel.text=tostring(result); menu:updateLayout(); return false end
        M.close(prompt)
        return false
    end
    local buttons=menu:createBlock({}); buttons.autoWidth=true; buttons.autoHeight=true; buttons.flowDirection=tes3.flowDirection.leftToRight
    buttons:createButton({text=options.button or "Save"}):register(tes3.uiEvent.mouseClick,submit)
    buttons:createButton({text="Cancel"}):register(tes3.uiEvent.mouseClick,function() M.close(prompt) end)
    local function escape(e) if e.data0==tes3.scanCode.escape then M.close(prompt); return false end end
    for key,input in pairs(prompt.inputs) do
        input:registerBefore(tes3.uiEvent.keyPress,escape)
        if key~="description" then input:register(tes3.uiEvent.keyEnter,submit) end
    end
    menu:register(tes3.uiEvent.keyPress,escape)
    local stopRepeat=textRepeat.bind(menu,prompt.inputs)
    menu:register(tes3.uiEvent.destroy,function()
        stopRepeat(); prompt.menu=nil; if onClose then onClose() end
    end)
    menu:updateLayout()
    local function activate(remaining)
        if prompt.menu~=menu then return end
        if tes3ui.menuMode() then tes3ui.acquireTextInput(nameInput); return end
        if remaining==0 then return end
        tes3ui.enterMenuMode(menuId)
        timer.frame.delayOneFrame(function() activate(remaining-1) end)
    end
    timer.frame.delayOneFrame(function() activate(3) end)
    return prompt
end
return M
