local log=require("MannequinPoseDesigner.logger")
local library=require("MannequinPoseDesigner.library")
local catalog=require("MannequinPoseDesigner.catalog")
local preview=require("MannequinPoseDesigner.preview")
local metadataPrompt=require("MannequinPoseDesigner.metadata_prompt")
local textRepeat=require("MannequinPoseDesigner.text_repeat")
local M={}
local menuId="OAAB:MannequinPoseDesigner:Library"
local active
local function identity(file) return file and file:lower():gsub("\\","/") end
local function thinButton(parent,text)
    local value=parent:createButton({text=text})
    value.contentPath="menu_thin_border.nif"
    value.borderAllSides=0; value.paddingAllSides=1
    value.autoWidth=true; value.autoHeight=true
    return value
end
function M.close()
    local state=active
    if not state then return end
    active=nil; state.generation=state.generation+1
    if state.prompt then metadataPrompt.close(state.prompt); state.prompt=nil end
    if state.menu then local menu=state.menu; state.menu=nil; menu:destroy() end
    tes3ui.leaveMenuMode()
end
local function reference(state)
    if not state.handle:valid() then return end
    local ref=state.handle:getObject()
    if ref and not ref.deleted and state.api.canPose(ref) then return ref end
end
function M.open(ref,api,entries,options)
    if active or tes3ui.findMenu(menuId) then return false end
    options=options or {}
    local selectActive=options.page==nil
    local state={handle=tes3.makeSafeObjectHandle(ref),api=api,records=catalog.list(entries),
        source=options.source or "All poses",category=options.category,search=options.search or "",
        sort=options.sort or "Name A-Z",page=options.page or 1,generation=0,
        selected=options.selected or api.getSelectedFile(ref) or "oaab/k/mann_relax.nif",previews={}}
    local menu=tes3ui.createMenu({id=menuId,fixedFrame=true})
    active=state; state.menu=menu
    menu.flowDirection=tes3.flowDirection.topToBottom
    local w,h=tes3ui.getViewportSize()
    local width=math.min(1240,w-40)
    local categoryWidth=math.min(240,math.floor(width/3))
    local gridWidth=width-categoryWidth-20
    local columns=width>=1180 and 4 or width>=850 and 3 or 2
    local rows=h>=850 and 2 or 1
    local pageSize=columns*rows
    local cardWidth=math.floor(gridWidth/columns)-12
    local previewHeight=math.max(56,math.min(210,math.floor((h-400)/rows)-55))
    menu:createLabel({text="Mannequin Pose Library"}).borderBottom=8
    local status=menu:createLabel({text=""}); status.width=width; status.autoWidth=false; status.wrapText=true
    local function errorText(err)
        status.text=tostring(err); status.color={1,0.35,0.35}; menu:updateLayout()
        log("[OAAB Pose Library] %s",tostring(err))
    end
    local function guarded(fn)
        return function()
            if active~=state or not state.menu then return end
            if not reference(state) then M.close(); return end
            local ok,err=pcall(fn)
            if not ok and state.menu then errorText(err) end
        end
    end
    local function button(parent,text,fn)
        local value=thinButton(parent,text); value:register(tes3.uiEvent.mouseClick,guarded(fn)); return value
    end
    local function margin(element,side)
        local value=element[side]
        return value and value>=0 and value or math.max(0,element.borderAllSides or 0)
    end
    local function nameButton(parent,text,fn,buttonWidth)
        local value=button(parent,text:gsub("%s+"," "),fn)
        value.widthProportional=nil; value.heightProportional=nil
        value.autoWidth=true; value.autoHeight=true; value.wrapText=false
        -- Measure the native button, including its text padding, in the game font.
        local function fits(candidate)
            value.text=candidate; menu:updateLayout()
            return value.width<=buttonWidth
        end
        local full=value.text
        if not fits(full) then
            -- Keep UTF-8 characters intact when shortening portable metadata names.
            local endings={[0]=0}
            for ending in full:gmatch(".[\128-\191]*()") do endings[#endings+1]=ending-1 end
            local low,high=0,#endings
            while low<high do
                local middle=math.floor((low+high+1)/2)
                if fits(full:sub(1,endings[middle]).."...") then low=middle else high=middle-1 end
            end
            value.text=full:sub(1,endings[low]):gsub("%s+$","").."..."
        end
        value.autoWidth=false; value.width=buttonWidth; value.minWidth=buttonWidth; value.maxWidth=buttonWidth
        return value
    end
    local function block(parent,flow,blockWidth)
        local value=parent:createBlock({})
        value.flowDirection=flow
        value.widthProportional=nil; value.heightProportional=nil
        value.autoWidth=false; value.autoHeight=true
        value.width=blockWidth; value.minWidth=blockWidth; value.maxWidth=blockWidth; value.minHeight=0
        return value
    end
    local function row(parent,rowWidth)
        return block(parent,tes3.flowDirection.leftToRight,rowWidth or width)
    end
    local function fixedPane(parent,paneWidth,paneHeight)
        local pane=parent:createVerticalScrollPane({})
        pane.widthProportional=nil; pane.heightProportional=nil
        pane.autoWidth=false; pane.autoHeight=false
        pane.width=paneWidth; pane.minWidth=paneWidth; pane.maxWidth=paneWidth
        pane.height=paneHeight; pane.minHeight=paneHeight; pane.maxHeight=paneHeight
        local content=pane:getContentElement()
        content.flowDirection=tes3.flowDirection.topToBottom
        content.widthProportional=nil; content.heightProportional=nil
        content.autoWidth=false; content.autoHeight=true
        content.width=paneWidth-24
        return pane,content
    end
    local toolbar=row(menu)
    local searchBorder=toolbar:createThinBorder({}); searchBorder.width=math.min(400,width-230); searchBorder.height=28
    local search=searchBorder:createTextInput({text=state.search,placeholderText="Search poses"})
    search.autoWidth=true; search.height=24; search.borderLeft=5; search.widget.lengthLimit=160; search.widget.eraseOnFirstKey=false
    search.repeatKeys=true
    searchBorder:registerAfter(tes3.uiEvent.mouseClick,function() tes3ui.acquireTextInput(search) end)
    local redraw,details,refresh
    local function searchNow()
        local value=search.widget:getIsPlaceholding() and "" or search.text
        if value==state.search then return end
        state.search=value; state.page=1; redraw()
    end
    search:registerAfter(tes3.uiEvent.textUpdated,guarded(searchNow))
    search:registerAfter(tes3.uiEvent.textCleared,guarded(function()
        if state.search=="" then return end
        state.search=""; state.page=1; redraw()
    end))
    local sorts={"Name A-Z","Name Z-A","ID","Category"}
    local sortButton
    sortButton=button(toolbar,state.sort,function()
        local index=1; for i,value in ipairs(sorts) do if value==state.sort then index=i end end
        state.sort=sorts[index%#sorts+1]; sortButton.text=state.sort; redraw()
    end)
    local sourceRow=row(menu)
    for _,value in ipairs({"All poses","OAAB_Data","Custom"}) do
        local source=value
        button(sourceRow,source,function() state.source=source; state.page=1; redraw() end)
    end
    local body=row(menu)
    local categories,categoryContent=fixedPane(body,categoryWidth,(previewHeight+65)*rows)
    categories.borderRight=8
    local renders=block(body,tes3.flowDirection.topToBottom,gridWidth)
    local grid=block(renders,tes3.flowDirection.topToBottom,gridWidth)
    -- Reserve every row even on short/empty pages. Include native button margins
    -- and the card's padding/bottom border in the height of each row.
    local sizingButton=thinButton(renders,"Pose")
    sizingButton.autoWidth=true; sizingButton.autoHeight=true; sizingButton.wrapText=false; menu:updateLayout()
    local gridHeight=(previewHeight+8+sizingButton.height+margin(sizingButton,"borderTop")+margin(sizingButton,"borderBottom")+6)*rows
    sizingButton:destroy()
    grid.autoHeight=false; grid.height=gridHeight; grid.minHeight=gridHeight; grid.maxHeight=gridHeight
    local navigation=row(renders,gridWidth)
    local previous=button(navigation,"Previous",function() state.page=state.page-1; redraw() end)
    local pageLabel=navigation:createLabel({text=""}); pageLabel.borderLeft=12; pageLabel.borderRight=12
    local nextButton=button(navigation,"Next",function() state.page=state.page+1; redraw() end)
    local info=block(menu,tes3.flowDirection.topToBottom,width)
    local footer=row(menu)
    local actions=row(footer,0); actions.autoWidth=true; actions.maxWidth=nil
    local footerSpacer=row(footer,0)
    local controls=row(footer,0); controls.autoWidth=true; controls.maxWidth=nil
    local function layoutFooter()
        -- Measure both groups in the game font before filling the space between them.
        footerSpacer.width=0; footerSpacer.minWidth=0; footerSpacer.maxWidth=0
        menu:updateLayout()
        local gap=math.max(0,width-actions.width-controls.width)
        footerSpacer.width=gap; footerSpacer.minWidth=gap; footerSpacer.maxWidth=gap
        menu:updateLayout()
    end
    for _,entry in ipairs(entries or {}) do
        if entry.callback and not entry.file then
            local action=entry
            button(controls,action.label,function()
                local handle=state.handle; M.close()
                timer.frame.delayOneFrame(function()
                    if not handle:valid() then return end
                    local current=handle:getObject()
                    if not current.deleted and api.canPose(current) then action.callback(current) end
                end)
            end)
        end
    end
    button(controls,"Create pose",function()
        local handle=state.handle; local records=catalog.list(entries); M.close()
        timer.frame.delayOneFrame(function()
            if not handle:valid() then return end
            local current=handle:getObject()
            if current.deleted or not api.canPose(current) then return end
            if not require("MannequinPoseDesigner.session").start(current,api,nil,records) then
                tes3.messageBox("Pose Designer could not start. Enable Debug mode in the mod's MCM and try again for details in mwse.log.")
            end
        end)
    end)
    button(controls,"Close",M.close)
    local function selected()
        for _,pose in ipairs(state.records) do if identity(pose.file)==identity(state.selected) then return pose end end
    end
    local function apply(pose)
        local current=assert(reference(state),"The mannequin is no longer available")
        if pose.callback then pose.callback(current)
        else
            if pose.editable then library.ensureCompanions(pose.file) end
            assert(api.select(current,pose.file),"Could not apply pose: "..pose.name)
        end
    end
    local function prompt(pose)
        local fields=catalog.fields(pose)
        -- Suspend the library without keeping any live previews underneath a modal.
        state.generation=state.generation+1; state.previews={}; grid:destroyChildren(); menu.visible=false
        tes3ui.leaveMenuMode()
        state.prompt=metadataPrompt.open(fields,function(value)
            assert(active==state and reference(state),"The mannequin is no longer available")
            library.updateMetadata(pose.file,value)
            return true
        end,function()
            state.prompt=nil
            if active~=state or not state.menu then return end
            menu.visible=true; refresh()
            timer.frame.delayOneFrame(function() if active==state and state.menu then tes3ui.enterMenuMode(menuId) end end)
        end,{title="Edit Metadata",button="Save Metadata",immutableId=true,records=state.records})
        if not state.prompt then menu.visible=true; redraw(); tes3ui.enterMenuMode(menuId) end
    end
    details=function(pose)
        info:destroyChildren()
        actions:destroyChildren()
        for file,motion in pairs(state.previews) do
            motion.setSpinning(pose~=nil and file==identity(pose.file))
        end
        if not pose then info:createLabel({text="No matching poses."}); layoutFooter(); return end
        state.selected=pose.file
        local title=info:createLabel({text=pose.name.." | "..(pose.isOAABData and "OAAB_Data (read-only)" or pose.editable and "Custom" or "Registered (read-only)")})
        title.width=width; title.autoWidth=false; title.wrapText=true
        local detailPane,detailContent=fixedPane(info,width,70)
        local metadata=detailContent:createLabel({text="ID: "..(pose.id or "").." | "..(pose.category~="" and pose.category or "Uncategorized")})
        metadata.width=width-28; metadata.wrapText=true
        metadata.autoWidth=false
        local description=detailContent:createLabel({text=pose.description})
        description.width=width-28; description.wrapText=true
        description.autoWidth=false
        -- The path disambiguates manually installed duplicate IDs and equal names.
        local path=detailContent:createLabel({text=pose.file..(pose.duplicateId and " (duplicate ID; kept separately)" or "")})
        path.width=width-28; path.wrapText=true
        path.autoWidth=false
        button(actions,"Apply",function() apply(pose); M.close() end)
        if pose.editable then
            button(actions,"Edit Pose",function()
                local current=assert(reference(state)); local old=api.getSelectedFile(current)
                apply(pose)
                local handle=state.handle; local records=catalog.list(entries); M.close()
                timer.frame.delayOneFrame(function()
                    if not handle:valid() then return end
                    local currentRef=handle:getObject()
                    if currentRef.deleted or not api.canPose(currentRef) then return end
                    if not require("MannequinPoseDesigner.session").start(currentRef,api,pose.file,records) then
                        if old then api.select(currentRef,old) else api.setSelectedFile(currentRef,nil) end
                        tes3.messageBox("Could not edit this pose. Enable Debug mode in the mod's MCM and try again for details in mwse.log.")
                    end
                end)
            end)
            button(actions,"Edit Metadata",function() prompt(pose) end)
            button(actions,"Delete",function()
                local retained={source=state.source,category=state.category,search=state.search,sort=state.sort,page=state.page}
                local handle=state.handle; M.close()
                local answered=false
                timer.frame.delayOneFrame(function()
                    if not handle:valid() then return end
                    tes3.messageBox({message='Delete "'..pose.name..'"?\nThis permanently removes its pose files.',buttons={"Delete","Cancel"},showInDialog=false,
                        callback=function(result)
                            if answered then return end; answered=true
                            timer.frame.delayOneFrame(function()
                                if not handle:valid() then return end
                                local current=handle:getObject()
                                if current.deleted or not api.canPose(current) then return end
                                if result.button==0 then
                                    local isSelected=identity(api.getSelectedFile(current))==identity(pose.file)
                                    local ok,err=pcall(function()
                                        if isSelected then assert(api.select(current,"oaab/k/mann_relax.nif"),"Could not restore Relaxed") end
                                        library.remove(pose.file)
                                    end)
                                    if not ok then
                                        if isSelected then api.select(current,pose.file) end
                                        tes3.messageBox("Could not delete pose: %s",tostring(err))
                                    end
                                end
                                M.open(current,api,entries,retained)
                            end)
                        end})
                end)
            end)
        end
        layoutFooter()
        detailPane.widget:contentsChanged()
    end
    redraw=function()
        if active~=state or not state.menu then return end
        state.generation=state.generation+1
        local generation=state.generation
        state.previews={}
        grid:destroyChildren()
        local filtered=catalog.filter(state.records,state)
        -- Locate the mannequin's pose once on entry; later redraws keep browsing navigation.
        if selectActive then
            selectActive=false
            for index,pose in ipairs(filtered) do
                if identity(pose.file)==identity(state.selected) then state.page=math.ceil(index/pageSize); break end
            end
        end
        local pages=math.max(1,math.ceil(#filtered/pageSize)); state.page=math.max(1,math.min(state.page,pages))
        pageLabel.text=string.format("%d / %d",state.page,pages); previous.disabled=state.page==1; nextButton.disabled=state.page==pages
        status.text=string.format("%s | %s | %d poses",state.source,state.category or "All categories",#filtered); status.color=tes3ui.getPalette("normal_color")
        local pending,visible={},{}
        local cardRow
        for index=(state.page-1)*pageSize+1,math.min(state.page*pageSize,#filtered) do
            local pose=filtered[index]
            if (index-1)%columns==0 then cardRow=row(grid,gridWidth) end
            local card=cardRow:createThinBorder({}); card.flowDirection=tes3.flowDirection.topToBottom
            card.widthProportional=nil; card.heightProportional=nil; card.autoWidth=false; card.autoHeight=true
            card.width=cardWidth; card.minWidth=cardWidth; card.maxWidth=cardWidth
            card.paddingAllSides=4; card.borderRight=6; card.borderBottom=6
            local holder=card:createBlock({})
            holder.autoWidth=false; holder.autoHeight=false
            holder.width=cardWidth-12; holder.height=previewHeight
            pending[#pending+1]={holder=holder,pose=pose}
            nameButton(card,pose.name,function() details(pose) end,cardWidth-12)
            visible[#visible+1]=pose
        end
        local pose=selected(); local isVisible=false
        for _,value in ipairs(visible) do if pose and value.file==pose.file then isVisible=true end end
        details(isVisible and pose or visible[1])
        -- One native scene per frame, strictly bounded by the visible page. A
        -- generation guard prevents timers from touching destroyed UI userdata.
        local function load(index)
            if active~=state or not state.menu or state.generation~=generation then return end
            local entry=pending[index]; if not entry then return end
            local ok,element,motion=pcall(preview.create,entry.holder,entry.pose.file,cardWidth-12,previewHeight)
            if not ok then
                entry.holder:createLabel({text="Preview unavailable"})
                log("[OAAB Pose Library] Preview %s: %s",entry.pose.file,tostring(element))
            else
                state.previews[identity(entry.pose.file)]=motion
                motion.setSpinning(identity(entry.pose.file)==identity(state.selected))
            end
            menu:updateLayout()
            timer.frame.delayOneFrame(function() load(index+1) end)
        end
        timer.frame.delayOneFrame(function() load(1) end)
        menu:updateLayout()
    end
    local function removeCategory(category)
        local count,readOnly=catalog.categoryUsage(state.records,category)
        assert(count>0 and readOnly==0,"Category contains read-only poses and cannot be deleted")
        local retained={source=state.source,category=state.category,search=state.search,sort=state.sort,page=state.page,selected=state.selected}
        local handle=state.handle; M.close()
        local answered=false
        timer.frame.delayOneFrame(function()
            if not handle:valid() then return end
            tes3.messageBox({message='Delete category "'..category..'"?\n'..count..(count==1 and ' pose' or ' poses')..' will move to Uncategorized. Their NIF metadata will be updated.',
                buttons={"Delete Category","Cancel"},showInDialog=false,callback=function(result)
                    if answered then return end; answered=true
                    timer.frame.delayOneFrame(function()
                        if not handle:valid() then return end
                        local current=handle:getObject()
                        if current.deleted or not api.canPose(current) then return end
                        if result.button==0 then
                            local ok,err=pcall(function() library.removeCategory(category,catalog.list(entries)) end)
                            if ok then
                                if retained.category==category then retained.category=nil; retained.page=1 end
                            else tes3.messageBox("Could not delete category: %s",tostring(err)) end
                        end
                        M.open(current,api,entries,retained)
                    end)
                end})
        end)
    end
    refresh=function()
        state.records=catalog.list(entries)
        local values=catalog.categories(state.records)
        local found=state.category==nil
        for _,value in ipairs(values) do if value==state.category then found=true end end
        if not found then state.category=nil; state.page=1 end
        categoryContent:destroyChildren()
        local categoryRowWidth=categoryContent.width-6
        local allCategories=button(categoryContent,"All categories",function() state.category=nil; state.page=1; redraw() end)
        allCategories.width=categoryRowWidth-margin(allCategories,"borderLeft")-margin(allCategories,"borderRight")
        allCategories.autoWidth=false; allCategories.autoHeight=true; allCategories.wrapText=true
        for _,value in ipairs(values) do
            local category=value
            local categoryRow=row(categoryContent,categoryRowWidth)
            local item=button(categoryRow,category,function() state.category=category; state.page=1; redraw() end)
            item.width=categoryRowWidth-margin(item,"borderLeft")-margin(item,"borderRight")
            item.autoWidth=false; item.autoHeight=true; item.wrapText=true
            if category~="Uncategorized" then
                local count,readOnly=catalog.categoryUsage(state.records,category)
                local remove=button(categoryRow,"X",function() removeCategory(category) end)
                remove.width=28; remove.minWidth=28; remove.maxWidth=28; remove.autoWidth=false; remove.borderLeft=4
                item.width=item.width-remove.width-margin(remove,"borderLeft")-margin(remove,"borderRight")
                remove.disabled=count==0 or readOnly>0
            end
        end
        menu:updateLayout()
        categories.widget:contentsChanged()
        redraw()
    end
    local function escape(e)
        if e.data0==tes3.scanCode.escape then M.close(); return false end
    end
    search:registerBefore(tes3.uiEvent.keyPress,escape)
    menu:register(tes3.uiEvent.keyPress,escape)
    local stopRepeat=textRepeat.bind(menu,{search})
    menu:register(tes3.uiEvent.destroy,function()
        stopRepeat()
        if active==state then active=nil end
        state.menu=nil; state.generation=state.generation+1
        state.previews={}
        if state.prompt then metadataPrompt.close(state.prompt); state.prompt=nil end
    end)
    refresh()
    timer.frame.delayOneFrame(function() if active==state and state.menu then tes3ui.enterMenuMode(menuId) end end)
    return true
end
function M.update(e)
    local state=active
    if not state then return end
    if not reference(state) then M.close(); return end
    if state.prompt or not state.menu or state.menu.visible==false then return end
    for _,motion in pairs(state.previews) do motion.update(e.delta) end
end
return M
