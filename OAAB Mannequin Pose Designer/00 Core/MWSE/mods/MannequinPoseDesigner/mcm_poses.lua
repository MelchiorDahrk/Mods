local library=require("MannequinPoseDesigner.library")
local catalog=require("MannequinPoseDesigner.catalog")
local metadata=require("MannequinPoseDesigner.pose_metadata")
local textRepeat=require("MannequinPoseDesigner.text_repeat")
local M={}

local function block(parent,horizontal)
    local value=parent:createBlock({})
    value.flowDirection=horizontal and tes3.flowDirection.leftToRight or tes3.flowDirection.topToBottom
    value.autoHeight=true
    value.widthProportional=1
    return value
end
local function label(parent,text)
    local value=parent:createLabel({text=text})
    value.wrapText=true; value.widthProportional=1; value.autoWidth=false; value.autoHeight=true
    return value
end
local function button(parent,text,callback)
    local value=parent:createButton({text=text})
    value:register(tes3.uiEvent.mouseClick,callback)
    return value
end

function M.create(page)
    local root=page.elements.subcomponentsContainer
    -- The browser has its own expanding scroll pane. Paragraph inputs in the
    -- editor stay outside it, as native paragraph editing requires noScroll.
    for _,value in ipairs({page.elements.outerContainer.parent,page.elements.outerContainer,
        page.elements.innerContainer,root}) do
        value.autoHeight=false; value.heightProportional=1
    end
    local state={alive=true,generation=0}
    local browse,edit
    local stopRepeat
    local function clear()
        state.generation=state.generation+1
        if stopRepeat then stopRepeat(); stopRepeat=nil end
        -- Release native focus before destroying its input widget.
        tes3ui.acquireTextInput(nil)
        root:destroyChildren()
    end
    root:register(tes3.uiEvent.destroy,function()
        state.alive=false
        if stopRepeat then stopRepeat(); stopRepeat=nil end
    end)
    local function layout() root:getTopLevelMenu():updateLayout() end
    local function errorText(parent,text)
        local value=label(parent,text); value.color={1,0.35,0.35}; return value
    end
    edit=function(pose)
        if not state.alive or state.confirming or not pose.editable then return end
        clear()
        label(root,"Edit Metadata")
        label(root,"ID: "..pose.id.." (fixed)")
        local fields=catalog.fields(pose)
        local inputs={}
        local function field(key,title,limit,height)
            label(root,title).borderTop=4
            local border=root:createThinBorder({})
            border.widthProportional=1; border.autoHeight=false
            border.height=height; border.minHeight=height; border.maxHeight=height
            local input=border:createParagraphInput({})
            input.widthProportional=1; input.heightProportional=1
            input.borderLeft=5; input.borderRight=5; input.text=fields[key]
            input.widget.lengthLimit=limit; input.repeatKeys=true
            border:registerAfter(tes3.uiEvent.mouseClick,function() tes3ui.acquireTextInput(input) end)
            inputs[key]=input
        end
        field("name","Name",120,44)
        field("description","Description",2000,90)
        field("category","Category",80,44)
        local problem=errorText(root,"")
        local actions=block(root,true)
        button(actions,"Save Metadata",function()
            if not state.alive then return end
            local ok,err=pcall(function()
                local value=metadata.validate({id=fields.id,name=inputs.name.text,
                    description=inputs.description.text,category=inputs.category.text})
                library.updateMetadata(pose.file,value)
            end)
            if not ok then problem.text=tostring(err); layout(); return end
            browse()
        end)
        button(actions,"Cancel",function() if state.alive then browse() end end)
        stopRepeat=textRepeat.bind(root,inputs)
        layout()
        tes3ui.acquireTextInput(inputs.name)
    end
    browse=function()
        if not state.alive then return end
        clear()
        local generation=state.generation
        local reload
        local problem=errorText(root,"")
        local pane=root:createVerticalScrollPane({})
        pane.widthProportional=1; pane.heightProportional=1; pane.autoHeight=false
        local content=pane:getContentElement()
        content.flowDirection=tes3.flowDirection.topToBottom
        content.widthProportional=1; content.heightProportional=nil; content.autoHeight=true
        local records={}
        local function draw()
            content:destroyChildren()
            local poses=catalog.filter(records)
            if #poses==0 then label(content,"No poses available.") end
            for _,pose in ipairs(poses) do
                local row=block(content)
                row.borderBottom=10
                label(row,pose.name.." | "..(pose.isOAABData and "OAAB_Data (read-only)" or pose.editable and "Custom" or "Registered (read-only)"))
                label(row,"ID: "..pose.id)
                label(row,pose.file..(pose.duplicateId and " (duplicate ID; kept separately)" or ""))
                if pose.editable then
                    local actions=block(row,true)
                    button(actions,"Edit Metadata",function() edit(pose) end)
                    button(actions,"Delete",function()
                        if not state.alive or state.confirming then return end
                        state.confirming=true
                        tes3ui.acquireTextInput(nil)
                        local answered=false
                        local function finish(remove)
                            if answered then return end; answered=true; state.confirming=false
                            -- Changing tabs or closing the MCM invalidates this confirmation.
                            if not state.alive or state.generation~=generation then return end
                            if remove then
                                local ok,err=pcall(library.remove,pose.file)
                                reload()
                                if not ok then problem.text="Could not delete pose: "..tostring(err); layout() end
                            end
                        end
                        tes3ui.showMessageMenu({
                            message='Delete "'..pose.name..'"?\nThis permanently removes its pose files. Mannequins using this pose will return to Relaxed.',
                            cancels=true,leaveMenuMode=false,
                            cancelCallback=function() finish(false) end,
                            buttons={{text="Delete",callback=function() finish(true) end}},
                        })
                    end)
                end
            end
            layout(); pane.widget:contentsChanged()
        end
        reload=function()
            library.invalidate()
            local ok,result=pcall(catalog.list)
            if ok then records=result; problem.text=""
            else records={}; problem.text="Could not list poses: "..tostring(result) end
            draw()
        end
        reload()
    end
    browse()
end

return M
