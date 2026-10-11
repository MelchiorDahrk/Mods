-- Model native container bounds and clipping, rather than only the existence of
-- Lua UI objects. Empty blocks have no size until explicitly sized/auto-sized.
package.path="./MWSE/mods/?.lua;"..package.path
local count=0
local function check(ok,reason) assert(ok,reason); count=count+1 end
local menus,frames={},{}
local viewportWidth,viewportHeight=2560,1440
local fontScale=1
local nativeScenes=0
local repeatCallbacks={}
local backspaceDown=false
local previewState
local measure,position
local function element(kind,args,parent)
    args=args or {}
    local e={kind=kind,text=args.text or "",placeholderText=args.placeholderText,id=args.id,parent=parent,children={},events={},widget={},
        width=0,height=0,autoWidth=false,autoHeight=false}
    if parent then parent.children[#parent.children+1]=e end
    if kind=="Label" or kind=="Button" or kind=="TextInput" then e.autoWidth=true; e.autoHeight=true end
    if kind=="TextInput" then e.widget.getIsPlaceholding=function() return false end end
    -- Native buttons have external margins as well as internal text padding.
    if kind=="Button" then e.borderAllSides=4; e.borderLeft=-1; e.borderRight=-1; e.borderTop=-1; e.borderBottom=-1 end
    if kind=="Menu" then e.autoWidth=true; e.autoHeight=true; e.paddingAllSides=16 end
    for _,childKind in ipairs({"Block","ThinBorder","Button","Label","TextInput","ParagraphInput"}) do
        e["create"..childKind]=function(self,a) return element(childKind,a,self) end
    end
    function e:createVerticalScrollPane(a)
        local pane=element("Pane",a,self)
        pane.widthProportional=1; pane.heightProportional=1
        pane.content=element("Block",{},pane)
        pane.widget.contentsChanged=function()
            check(pane.content.laidOut,"Scroll limits must use laid-out content")
            pane.widget.maxScroll=math.max(0,pane.content.height-pane.height)
        end
        return pane
    end
    function e:getContentElement() return self.content or self end
    function e:createNif(a)
        local scene=element("Nif",a,self); nativeScenes=nativeScenes+1
        return previewState.canvas(scene)
    end
    function e:register(id,fn) self.events[id]=fn end
    function e:findChild() end
    function e:registerBefore(id,fn)
        local previous=self.events["before:"..id]
        self.events["before:"..id]=function(data)
            if previous and previous(data)==false then return false end
            return fn(data)
        end
    end
    function e:registerAfter(id,fn) self.events["after:"..id]=fn end
    function e:forwardEvent(data)
        check(self.kind=="TextInput" and data.source==self and data.id=="key"
            and data.data0==-0x80000000,"Replay the search field's native editing event")
        self.nativeCalls=(self.nativeCalls or 0)+1
        local caret=self.caret or #self.text
        if caret==0 then return end
        self.text=self.text:sub(1,caret-1)..self.text:sub(caret+1); self.caret=caret-1
        local updated=self.events["after:"..(#self.text==0 and "textCleared" or "textUpdated")]
        if updated then updated({source=self}) end
    end
    function e:updateLayout()
        -- Native size changes must be laid out from the top-level menu.
        if self.kind~="Menu" then return end
        measure(self); position(self,0,0)
    end
    function e:isValid() return not self.destroyed end
    function e:destroyChildren()
        for _,child in ipairs(self.children) do child:destroy() end
        self.children={}
    end
    function e:destroy()
        if self.destroyed then return end
        self.destroyed=true; self:destroyChildren()
        if self.kind=="Nif" then nativeScenes=nativeScenes-1 end
        if self.id then menus[self.id]=nil end
        if self.events.destroy then self.events.destroy() end
    end
    return e
end
local function margin(e,key)
    local value=e[key]
    return value and value>=0 and value or e.borderAllSides or 0
end
local function padding(e) return e.paddingAllSides or 0 end
local function textWidth(text)
    local width=0
    for char in text:gmatch(".[\128-\191]*") do
        width=width+(char=="W" and 12 or char=="i" and 4 or 7)*fontScale
    end
    return math.ceil(width)
end
local function textHeight(e,width)
    local lines=0
    for line in (e.text.."\n"):gmatch("(.-)\n") do
        lines=lines+math.max(1,e.wrapText and math.ceil(textWidth(line)/math.max(1,width-(e.kind=="Button" and 16 or 0))) or 1)
    end
    return lines*math.ceil(20*fontScale)+(e.kind=="Button" and 6 or 0)
end
measure=function(e)
    local pad=padding(e)
    if e.widthProportional and e.parent and not e.parent.autoWidth then
        e.width=math.floor((e.parent.width-padding(e.parent)*2-margin(e,"borderLeft")-margin(e,"borderRight"))*e.widthProportional)
    end
    if e.heightProportional and e.parent and not e.parent.autoHeight then
        e.height=math.floor((e.parent.height-padding(e.parent)*2)*e.heightProportional)
    end
    if e.kind=="Label" or e.kind=="Button" or e.kind=="TextInput" then
        if e.autoWidth then e.width=textWidth(e.text)+(e.kind=="Button" and 16 or 0) end
        if e.autoHeight then e.height=textHeight(e,e.width) end
    else
        for _,child in ipairs(e.children) do measure(child) end
        if e.kind~="Pane" then
            local width,height=0,0
            for _,child in ipairs(e.children) do
                local w=child.width+margin(child,"borderLeft")+margin(child,"borderRight")
                local h=child.height+margin(child,"borderTop")+margin(child,"borderBottom")
                if e.flowDirection==2 then width=width+w; height=math.max(height,h)
                else width=math.max(width,w); height=height+h end
            end
            if e.autoWidth then e.width=width+pad*2 end
            if e.autoHeight then e.height=height+pad*2 end
        end
    end
    e.width=math.max(e.minWidth or 0,math.min(e.maxWidth or math.huge,e.width))
    e.height=math.max(e.minHeight or 0,math.min(e.maxHeight or math.huge,e.height))
    e.laidOut=true
end
position=function(e,x,y)
    e.x=x; e.y=y
    local nextX,nextY=x+padding(e),y+padding(e)
    for _,child in ipairs(e.children) do
        position(child,nextX+margin(child,"borderLeft"),nextY+margin(child,"borderTop"))
        if e.flowDirection==2 then nextX=nextX+child.width+margin(child,"borderLeft")+margin(child,"borderRight")
        else nextY=nextY+child.height+margin(child,"borderTop")+margin(child,"borderBottom") end
    end
end
local function visible(e)
    local left,top,right,bottom=e.x,e.y,e.x+e.width,e.y+e.height
    local node=e
    while node do
        if node.visible==false or node.destroyed then return false end
        left=math.max(left,node.x); top=math.max(top,node.y)
        right=math.min(right,node.x+node.width); bottom=math.min(bottom,node.y+node.height)
        node=node.parent
    end
    return right>left and bottom>top
end
local function fullyVisible(e)
    local node=e.parent
    while node do
        if e.x<node.x or e.y<node.y or e.x+e.width>node.x+node.width or e.y+e.height>node.y+node.height then return false end
        node=node.parent
    end
    return visible(e)
end
local function find(root,text)
    if root.text==text then return root end
    for _,child in ipairs(root.children) do local found=find(child,text); if found then return found end end
end
local function visit(root,fn)
    fn(root); for _,child in ipairs(root.children) do visit(child,fn) end
end
local function drain()
    local budget=30
    while #frames>0 do
        check(budget>0,"Preview creation must terminate"); budget=budget-1
        local pending=frames; frames={}; for _,fn in ipairs(pending) do fn() end
    end
end
tes3={flowDirection={topToBottom=1,leftToRight=2},uiEvent={mouseClick="click",destroy="destroy",keyPress="key",keyEnter="enter",textUpdated="textUpdated",textCleared="textCleared"},
    scanCode={escape=1,backspace=14},makeSafeObjectHandle=function(ref) return {valid=function() return true end,getObject=function() return ref end} end,
    worldController={menuController={inputController={}},inputController={
        isKeyDown=function(_,code) check(code==14,"Poll physical Backspace"); return backspaceDown end,
        isControlDown=function() return false end,isAltDown=function() return false end,isSuperDown=function() return false end}}}
previewState=dofile("tests/preview_fixture.lua").install()
tes3ui={findMenu=function(id) return menus[id] end,
    createMenu=function(args) local e=element("Menu",args); menus[args.id]=e; return e end,
    getViewportSize=function() return viewportWidth,viewportHeight end,getPalette=function() return {1,1,1} end,
    enterMenuMode=function() end,leaveMenuMode=function() end,menuMode=function() return true end,acquireTextInput=function() end}
timer={frame={delayOneFrame=function(fn) frames[#frames+1]=fn end}}
event={register=function(id,fn)
    repeatCallbacks[id]=repeatCallbacks[id] or {}; repeatCallbacks[id][fn]=true
end,unregister=function(id,fn)
    check(repeatCallbacks[id] and repeatCallbacks[id][fn],"Remove only the closing menu's repeat callback")
    repeatCallbacks[id][fn]=nil
    if not next(repeatCallbacks[id]) then repeatCallbacks[id]=nil end
end}
mwse={log=function() end}
local records={}
for i=1,9 do records[i]={file="pose/k/guard"..i..".nif",id="guard"..i,name="Guard Pose "..i,label="Guard Pose "..i,
    description=string.rep("A relaxed guard stance. ",60),category="Category "..i,editable=true} end
local longName="Guard Pose 1: Kneel with sword and sword on back"
records[1].name=longName; records[1].label=longName
local defaults={}
for _,name in ipairs({"Relaxed","Contrapposto","Adlocutio","Adlocutio II"}) do
    defaults[#defaults+1]={file="oaab/k/mann_"..name:gsub(" ",""):lower()..".nif",label=name}
end
local library={list=function() return records end,readMetadata=function() end,
    isDefault=function(file) return file:find("/mann_",1,true)~=nil end,poseId=function(file) return file:match("/([^/]+)%.nif$") end}
package.loaded["MannequinPoseDesigner.library"]=library
local ui=arg[3] and assert(loadfile(arg[3]))() or require("MannequinPoseDesigner.library_menu")
local ref={}; local api={canPose=function() return true end,getSelectedFile=function() return records[9].file end}
-- Prove the fixture reproduces the original missing-width clipping symptom.
local blank=element("Menu",{})
local row=blank:createBlock({}); row.flowDirection=2; row.autoHeight=true
local hidden=row:createButton({text="Hidden"})
blank:updateLayout()
check(row.width==0 and not visible(hidden),"Unsized native rows clip existing buttons")
blank:destroy()
-- Reproduce the screenshot's cut-off border with the old width calculation.
local sidebar=element("Block",{}); sidebar.width=210; sidebar.autoHeight=true; sidebar.flowDirection=2
local oldCategory=sidebar:createButton({text="Standing"}); oldCategory.autoWidth=false; oldCategory.width=sidebar.width-32
local clipped=sidebar:createButton({text="X"}); clipped.autoWidth=false; clipped.width=28
measure(sidebar); position(sidebar,0,0)
check(not fullyVisible(clipped),"Native button margins reproduce the old clipped category border")
sidebar:destroy()
for _,viewport in ipairs({{2560,1440,8},{1920,1080,8},{1280,720,4},{1024,720,3},{800,600,2},{640,480,2},{1920,1080,8,1.25}}) do
    viewportWidth,viewportHeight=viewport[1],viewport[2]
    fontScale=viewport[4] or 1
    check(ui.open(ref,api,defaults),"Library opens")
    drain()
    local menu=assert(menus["OAAB:MannequinPoseDesigner:Library"])
    for _,text in ipairs({"Name A-Z","All poses","OAAB_Data","Custom","All categories","Create pose","Close"}) do
        check(visible(assert(find(menu,text),text)),"Control must render inside its parent bounds: "..text)
    end
    check(not find(menu,"Refresh"),"Refresh is removed from the footer")
    check(not find(menu,"Favorites") and not find(menu,"Favorite") and not find(menu,"Unfavorite"),
        "Favorite controls are absent at every viewport size")
    local previous,nextButton=assert(find(menu,"Previous")),assert(find(menu,"Next"))
    local previousX,previousY,nextX,nextY=previous.x,previous.y,nextButton.x,nextButton.y
    local function stableNavigation()
        check(previous.x==previousX and previous.y==previousY and nextButton.x==nextX and nextButton.y==nextY,
            "Page buttons stay in position across full, short and empty pages")
    end
    check(menu.width<=viewportWidth and menu.height<=viewportHeight,"Library "..menu.width.."x"..menu.height.." fits "..viewportWidth.."x"..viewportHeight)
    local category=assert(find(menu,"Category 1"))
    local remove=assert(find(category.parent,"X"))
    check(fullyVisible(category) and fullyVisible(remove) and remove.x>=category.x+category.width,
        "Category and adjacent delete control fit the sidebar at "..viewportWidth.."x"..viewportHeight)
    for _,text in ipairs({"All categories","Uncategorized"}) do
        local item=assert(find(menu,text))
        check(fullyVisible(item) and item.width>=#text*7+16,"Category label fits without clipping: "..text)
    end
    local scenes=0
    visit(menu,function(e)
        if e.kind=="Nif" then
            -- The empty NIF is a zero-size anchor for a 3D scene, as in Fishing.
            -- Its fixed parent is the viewport; the mesh has its own scene fit.
            scenes=scenes+1; check(fullyVisible(e.parent),"Every preview viewport must fit completely inside the menu")
            check(e.parent.width>0 and e.parent.height>0,"Preview viewport has a visible rendering rectangle")
            check(e.parent.childOffsetX==math.floor(e.parent.width/2) and e.parent.childOffsetY==-math.floor(e.parent.height/2),"3D canvas is anchored at its viewport centre")
        end
    end)
    local expected=viewport[3]
    local lastPage=math.ceil((#records+#defaults)/expected)
    local activePage=math.ceil((#records+#defaults-1)/expected) -- Relaxed sorts after Guard Pose 9.
    check(find(menu,activePage.." / "..lastPage),"The active pose's page opens at "..viewportWidth.."x"..viewportHeight)
    check(visible(assert(find(menu,"Guard Pose 9 | Custom"))),"The active pose's details render at "..viewportWidth.."x"..viewportHeight)
    check(visible(assert(find(menu,"Guard Pose 9"))),"The active pose's card renders at "..viewportWidth.."x"..viewportHeight)
    local pageCount=math.min(expected,#records+#defaults-(activePage-1)*expected)
    check(scenes==pageCount and nativeScenes==pageCount,"Only the active pose's page has instantiated previews")
    find(menu,"Custom").events.click(); drain()
    stableNavigation()
    check(nativeScenes==expected,"A full page shows "..expected.." poses at "..viewportWidth.."x"..viewportHeight)
    local shortened
    visit(menu,function(e)
        if e.kind=="Button" and e.text:sub(1,13)=="Guard Pose 1:" then shortened=e end
    end)
    check(shortened and shortened.text:sub(-3)=="..." and shortened.text~=longName,"Long names end in three dots")
    check(shortened.wrapText==false and shortened.height==math.ceil(20*fontScale)+6 and textWidth(shortened.text)+16<=shortened.width,
        "The entire shortened name fits on one line in the measured game font")
    shortened.events.click(); drain()
    check(find(menu,longName.." | Custom") and records[1].name==longName,"Selection retains the complete pose name and metadata")
    stableNavigation()
    find(menu,"Next").events.click(); drain(); stableNavigation()
    find(menu,"Previous").events.click(); drain(); stableNavigation()
    for _,text in ipairs({"Apply","Edit Pose","Edit Metadata","Delete"}) do
        check(visible(assert(find(menu,text))),"Custom action must render: "..text)
    end
    local scrollingDetails=false
    visit(menu,function(e) if e.kind=="Pane" and e.widget.maxScroll>0 then scrollingDetails=true end end)
    check(scrollingDetails,"Long details retain a refreshed scrollbar")
    find(menu,"Edit Metadata").events.click(); drain()
    local prompt=assert(menus["OAAB:MannequinPoseDesigner:Metadata"])
    check(visible(assert(find(prompt,"Save Metadata"))) and visible(assert(find(prompt,"Cancel"))),"Metadata dialog buttons have visible container bounds")
    visit(prompt,function(e)
        if e.kind=="ParagraphInput" then check(visible(e),"Wrapped metadata inputs retain visible bounds") end
    end)
    check(nativeScenes==0,"Suspending the library destroys its previews")
    find(prompt,"Cancel").events.click(); drain()
    check(visible(assert(find(menu,"Name A-Z"))) and nativeScenes==expected,"Returning from a dialog restores the complete library")
    local search
    visit(menu,function(e) if e.placeholderText=="Search poses" then search=e end end)
    search.text="No matches"; search.events["after:textUpdated"](); drain()
    stableNavigation()
    check(nativeScenes==0 and visible(assert(find(menu,"No matching poses."))),"An empty filter still renders its result and navigation")
    ui.close(); drain()
    check(nativeScenes==0,"Close destroys every instantiated scene")
    check(not next(repeatCallbacks),"Closing the library releases all repeat callbacks")
end
fontScale=1
viewportWidth,viewportHeight=2560,1440
for _,name in ipairs({"Kneel with sword and sword on back",string.rep("W",35),string.rep("i",40),string.rep("\195\169",50)}) do
    records[1].name=name; records[1].label=name
    check(ui.open(ref,api,defaults,{source="Custom",category="Category 1",page=1}),"Library opens a name fitting case")
    drain()
    local menu=assert(menus["OAAB:MannequinPoseDesigner:Library"])
    local pick
    visit(menu,function(e) if e.kind=="Button" and e.parent.kind=="ThinBorder" then pick=e end end)
    check(pick and not pick.wrapText and textWidth(pick.text)+16<=pick.width,"Variable-width and UTF-8 names fit their card")
    if name:sub(1,1)=="i" then check(pick.text==name,"A long narrow name stays complete when it fits")
    else check(pick.text:sub(-3)=="...","An oversized name gets three dots") end
    if name:sub(1,2)=="\195\169" then
        check(pick.text:sub(1,-4):gsub("\195\169","")=="","Truncation preserves complete UTF-8 characters")
    end
    pick.events.click(); drain()
    check(find(menu,name.." | Custom") and records[1].name==name,"Card shortening preserves the actual selected name")
    ui.close(); drain()
end
records[1].name=longName; records[1].label=longName
viewportWidth,viewportHeight=640,480
check(ui.open(ref,api,defaults,{page=1}),"Library reopens with retained navigation")
drain()
check(find(menus["OAAB:MannequinPoseDesigner:Library"],"1 / 7"),"An explicitly retained page takes precedence over the active pose")
ui.close(); drain()
viewportWidth,viewportHeight=2560,1440
check(ui.open(ref,api,defaults,{source="Custom",search="Guard Pose 9xy"}),"Library opens a held Backspace case")
drain()
local menu=assert(menus["OAAB:MannequinPoseDesigner:Library"])
local search
visit(menu,function(e) if e.placeholderText=="Search poses" then search=e end end)
local function dispatch(id,data)
    for fn in pairs(repeatCallbacks[id] or {}) do fn(data) end
end
local function pressSearch()
    backspaceDown=true; tes3ui.acquireTextInput(search)
    tes3.worldController.menuController.inputController.textInputFocus=search
    local data={source=search,widget=search.widget,id="key",data0=-0x80000000,data1=0}
    if search.events["before:key"](data)~=false then search:forwardEvent(data) end
end
local function tick(seconds)
    for i=1,math.floor(seconds/0.05+0.5) do dispatch("enterFrame",{delta=0.05}) end
    drain()
end
local function releaseSearch()
    backspaceDown=false; dispatch("keyUp",{keyCode=14})
end
pressSearch(); drain()
check(search.text=="Guard Pose 9x" and search.nativeCalls==1,"A search Backspace tap deletes exactly once")
tick(0.3)
check(search.text=="Guard Pose 9x","Search waits for the repeat delay")
tick(0.1)
check(search.text=="Guard Pose 9" and search.nativeCalls==2 and nativeScenes==1
    and find(menu,"Guard Pose 9 | Custom"),"One held press repeats and immediately refreshes search results")
tick(0.05)
check(search.text=="Guard Pose " and nativeScenes==8 and find(menu,"1 / 2"),"Repeated search deletion updates previews and pagination")
releaseSearch(); tick(0.5)
check(search.text=="Guard Pose ","Release stops search deletion")
search.text="Guard Pose 9"; search.caret=#search.text
pressSearch(); tick(1)
check(search.text=="" and nativeScenes==8,"Held Backspace clears the query and restores unfiltered results")
releaseSearch()
search.text="abcDEF"; search.caret=3
pressSearch(); tick(0.4)
check(search.text=="aDEF","Search repetition preserves text after the caret")
tes3.worldController.menuController.inputController.textInputFocus=nil; tick(0.5)
check(search.text=="aDEF","Search loses the hold when focus changes")
releaseSearch()
search.text="Guard Pose 9"; search.caret=#search.text
pressSearch(); drain()
find(menu,"Edit Metadata").events.click(); drain(); tick(0.5)
check(search.text=="Guard Pose " and menu.visible==false,"Opening metadata cancels deletion in the hidden library")
find(menus["OAAB:MannequinPoseDesigner:Metadata"],"Cancel").events.click(); drain()
tes3.worldController.menuController.inputController.textInputFocus=search; tick(0.5)
check(search.text=="Guard Pose ","Returning from metadata cannot resume the old held key")
releaseSearch(); pressSearch(); tick(0.4)
check(search.text=="Guard Pos","A fresh search press repeats after returning from metadata")
ui.close(); drain(); tick(0.5)
check(not next(repeatCallbacks),"Closing while Backspace is held releases all repeat callbacks")
releaseSearch()
print("PASS: "..count.." native container bounds, clipping, wrapped details and responsive library layout assertions")
