package.path="./MWSE/mods/?.lua;"..package.path
local count=0
local function check(ok,reason) assert(ok,reason); count=count+1 end
local menus,buttons,labels,panes,queued={},{},{},{},{}
local slider,menuMode,entries=nil,false,0
local viewportWidth,viewportHeight=800,600
local function element()
    local result={events={},children={},width=350,height=24}
    function result:createLabel(args)
        local label=element(); label.text=args.text; labels[#labels+1]=label
        self.children[#self.children+1]=label; return label
    end
    function result:createVerticalScrollPane()
        local pane=element(); pane.buttons={}; pane.kind="pane"
        -- Model the native defaults responsible for the in-game collapse.
        pane.widthProportional=1; pane.heightProportional=1
        pane.content=element(); pane.content.kind="content"
        pane.widget={refreshes=0}
        function pane.widget:contentsChanged()
            check(pane.layouts and pane.content.layouts,"Scroll limits are refreshed only after content layout")
            self.refreshes=self.refreshes+1
            self.maxScroll=math.max(0,pane.content.height-pane.height)
        end
        panes[#panes+1]=pane; self.children[#self.children+1]=pane; return pane
    end
    function result:getContentElement() return self.content or self end
    function result:createBlock()
        local block=element(); self.children[#self.children+1]=block; return block
    end
    function result:createSlider(args)
        slider=element(); slider.widget=args; return slider
    end
    function result:createButton(args)
        local button=element(); button.text=args.text; buttons[#buttons+1]=button
        if self.buttons then self.buttons[#self.buttons+1]=button end
        local content=self:getContentElement()
        content.children[#content.children+1]=button
        return button
    end
    function result:register(event,fn) self.events[event]=fn end
    function result:updateLayout()
        self.layouts=(self.layouts or 0)+1
        for _,child in ipairs(self.children) do child:updateLayout() end
        if self.content then self.content:updateLayout() end
        if self.kind=="content" then
            if self.autoHeight then self.height=#self.children*24 else self.height=0 end
        elseif self.kind=="pane" and self.heightProportional then
            self.height=0 -- An auto-sized menu gives proportional lists no height.
        end
        self.renderedX=self.positionX; self.renderedY=self.positionY
    end
    function result:destroy()
        self.destroyed=true; menus[self.id]=nil
        if self.events.destroy then self.events.destroy({}) end
    end
    return result
end
tes3={flowDirection={topToBottom=1},uiEvent={mouseClick="click",keyPress="key",destroy="destroy"},scanCode={escape=1}}
tes3ui={findMenu=function(id) return menus[id] end,
    createMenu=function(args)
        buttons,labels,panes={},{},{}
        local menu=element(); menu.height=370; menu.id=args.id; menus[args.id]=menu; return menu
    end,
    getViewportSize=function() return viewportWidth,viewportHeight end,
    menuMode=function() return menuMode end,
    enterMenuMode=function(id)
        entries=entries+1; menuMode=true
        -- Activation can lay out a fixed-frame menu at its default center.
        local menu=menus[id]; menu.renderedX=-menu.width/2
    end,
    leaveMenuMode=function() menuMode=false end}
timer={frame={delayOneFrame=function(fn) queued[#queued+1]=fn end}}
local function advance()
    local pending=queued; queued={}
    for _,fn in ipairs(pending) do fn() end
end
local function click(label)
    for _,button in ipairs(buttons) do if button.text==label then button.events.click({}); return button end end
    error("Button not found: "..label)
end
local blendMenu=require("MannequinPoseDesigner.blend_menu")
local closed,accepted,previews=0,0,{}
local failed=false
local files={}
for i=1,40 do files[i]={file="pose"..i..".nif",label="Pose "..i} end
local function open(poses)
    return blendMenu.open(poses or files,function(a,b,t)
        previews[#previews+1]={a,b,t}
        if failed then return false,"Missing bone in pose" end
        return true
    end,function(keep) closed=closed+1; if keep then accepted=accepted+1 end end)
end
local ui=open()
check(ui.menu and entries==0 and not open(),"Opening B defers input ownership and refuses duplicate menus")
check(#panes==2 and #panes[1].buttons==40 and #panes[2].buttons==40,"Both scrolling lists contain every saved pose")
check(ui.menu.positionX==38 and ui.menu.positionY==185
    and ui.menu.renderedX==38 and ui.menu.renderedY==185,"The preview dialog's rendered position sits beside the mannequin")
for _,pane in ipairs(panes) do
    check(pane.widthProportional==nil and pane.heightProportional==nil
        and pane.autoWidth==false and pane.autoHeight==false,"Pose lists disable native proportional and automatic viewport sizing")
    check(pane.height==100 and pane.minHeight==100 and pane.maxHeight==100,"Both pose lists retain a visible height after layout")
    check(pane.content.flowDirection==tes3.flowDirection.topToBottom and pane.content.autoHeight
        and pane.content.height==40*24,"Pose choices occupy separate rows in the actual scroll content container")
    check(pane.widget.refreshes==1 and pane.widget.maxScroll==40*24-100,"The scrollbar can reach choices beyond the visible rows")
end
check(slider.widget.current==50 and slider.widget.max==100 and slider.widget.step==1,"The slider spans 0 to 100 in one-percent steps")
check(slider.disabled and buttons[1].disabled,"Blending is disabled before selecting both sources")
click("Use blend")
check(ui.menu and #previews==0,"Use blend cannot accept an incomplete pair")
advance(); check(menuMode and entries==1,"The dialog enters menu mode on the following frame")
check(ui.menu.renderedX==38,"Menu activation reapplies the dialog's rendered right-side position")
panes[1].buttons[3].events.click({})
check(ui.a==files[3] and not ui.b and slider.disabled and #previews==0,"Selecting A leaves B independent and does not preview yet")
panes[2].buttons[40].events.click({})
check(ui.b==files[40] and not slider.disabled and ui.valid,"Selecting B enables a live preview")
check(previews[1][1]==files[3].file and previews[1][2]==files[40].file and previews[1][3]==0.5,
    "Each list callback uses its own slot and file")
for _,percent in ipairs({0,25,100,50}) do
    slider.widget.current=percent; slider.events.PartScrollBar_changed({})
    check(previews[#previews][3]==percent/100 and ui.percent==percent and labels[5].text=="Blend: "..percent.."%",
        "Slider changes preview the exact displayed amount including both endpoints")
    check(panes[1].height==100 and panes[2].height==100 and ui.menu.renderedX==38,
        "Preview text changes preserve both visible list heights and menu placement")
end
failed=true; panes[2].buttons[1].events.click({})
check(not ui.valid and buttons[1].disabled and labels[6].text=="Missing bone in pose","Load errors disable acceptance and remain visible")
click("Use blend"); check(ui.menu and accepted==0,"A failed preview cannot be accepted")
failed=false; slider.events.PartScrollBar_changed({})
check(ui.valid,"Another preview can recover after a load error")
local stale=slider
local button=click("Use blend")
check(not ui.menu and accepted==1 and closed==1 and not menuMode,"Use blend closes once and marks the result accepted")
local n=#previews
stale.events.PartScrollBar_changed({}); button.events.click({}); advance()
check(#previews==n and closed==1 and entries==1,"Stale slider, button and activation callbacks cannot affect a closed dialog")
ui=open(); click("Cancel"); advance()
check(not ui.menu and accepted==1 and closed==2,"Cancel closes without accepting, including before activation")
ui=open(); advance(); local menu=ui.menu
check(menu.events.key({data0=2})==nil,"Ordinary keys belong to the native menu")
check(menu.events.key({data0=1})==false and not ui.menu and accepted==1,"Escape cancels only the blend dialog")
blendMenu.close(ui); check(closed==3,"Repeated close is harmless")
ui=open({}); check(#panes[1].buttons==0 and slider.disabled and labels[6].text=="No poses available.",
    "An empty source list reports that no poses are available")
menu=ui.menu; blendMenu.close(ui); advance()
check(menu.destroyed and closed==4 and not menuMode and accepted==1,"Session cleanup closes the pending menu without accepting")
ui=open(); panes[1].buttons[1].events.click({}); panes[2].buttons[1].events.click({})
menu=ui.menu; menu:destroy()
check(closed==5 and accepted==1,"External menu destruction cancels a valid preview")
menuMode=false
viewportWidth,viewportHeight=640,480
ui=open({files[1]})
check(panes[1].height==86 and panes[2].height==86 and panes[1].widget.maxScroll==0,
    "A small viewport and one saved pose still produce two visible selectable lists")
check(ui.menu.renderedX==ui.menu.positionX and ui.menu.renderedY<=viewportHeight/2-12,
    "The small-viewport position is flushed to the menu scene and stays below its top edge")
blendMenu.close(ui); advance()
ui=open({
    {file="oaab/k/mann_relax.nif",label="Relaxed (Default)"},
    {file="oaab/k/mann_contrapposto.nif",label="Contrapposto (Default)"},
})
check(labels[1].text=="Blend Poses" and #panes[1].buttons==2 and #panes[2].buttons==2,
    "A default-only library exposes every default in both lists without asking the user to save first")
panes[1].buttons[1].events.click({}); panes[2].buttons[2].events.click({})
check(ui.valid and previews[#previews][1]=="oaab/k/mann_relax.nif"
    and previews[#previews][2]=="oaab/k/mann_contrapposto.nif", "Two defaults can be selected independently and blended")
blendMenu.close(ui,true); advance()
print("PASS: "..count.." saved-pose selector, blend slider, error and modal lifecycle assertions")
