package.path="./MWSE/mods/?.lua;"..package.path
local count=0
local function check(ok,reason) assert(ok,reason); count=count+1 end
local menus,buttons,labels,queued={},{},{},{}
local menuMode,entries=false,0
local function element()
    local result={events={}}
    function result:createLabel(args)
        local label=element(); label.text=args.text; labels[#labels+1]=label; return label
    end
    function result:createButton(args)
        local button=element(); button.text=args.text; buttons[#buttons+1]=button; return button
    end
    function result:register(event,fn) self.events[event]=fn end
    function result:updateLayout() end
    function result:destroy()
        self.destroyed=true; menus[self.id]=nil
        if self.events.destroy then self.events.destroy({}) end
    end
    return result
end
tes3={flowDirection={topToBottom=1},uiEvent={mouseClick="click",keyPress="key",destroy="destroy"},scanCode={escape=1}}
tes3ui={findMenu=function(id) return menus[id] end,
    createMenu=function(args)
        buttons,labels={},{}
        local menu=element(); menu.id=args.id; menus[args.id]=menu; return menu
    end,
    menuMode=function() return menuMode end,
    enterMenuMode=function() entries=entries+1; menuMode=true end,
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
local groundMenu=require("MannequinPoseDesigner.ground_menu")
local closed,actions=0,{}
local function open()
    return groundMenu.open(function(scope)
        check(not menuMode,"Grounding runs after leaving menu mode")
        actions[#actions+1]=scope
    end,function() closed=closed+1 end)
end
for _,case in ipairs({{"Ground Left Foot","left"},{"Ground Right Foot","right"},{"Ground Both Feet","both"}}) do
    local ui=open()
    check(ui.menu and not menuMode,"The menu is created before taking native input")
    check(not open(),"Repeated opening cannot create duplicate Ground Feet menus")
    check(labels[1].text=="Ground Feet" and labels[2].text:find("Z heading",1,true),"The menu explains its command and heading preservation")
    advance(); check(menuMode,"The grounding menu takes input on the following frame")
    local button=click(case[1])
    check(not ui.menu and actions[#actions]==case[2],"Each foot choice dispatches the correct target and closes")
    local total=#actions
    button.events.click({}); advance()
    check(#actions==total and not menuMode,"Stale clicks and activation cannot apply the command twice or reopen")
end
local ui=open()
local actionCount=#actions
click("Cancel"); advance()
check(not ui.menu and #actions==actionCount and not menuMode,"Cancel leaves the pose alone and cancels delayed activation")
ui=open(); advance()
local menu=ui.menu
check(menu.events.key({data0=2})==nil,"Ordinary keys belong to the native menu")
check(menu.events.key({data0=1})==false and not ui.menu and #actions==actionCount,"Escape closes only the grounding menu")
groundMenu.close(ui); check(closed==5,"Repeated close is harmless")
ui=open(); menu=ui.menu
local entryCount=entries
groundMenu.close(ui); advance()
check(menu.destroyed and not menuMode and entries==entryCount and #actions==actionCount,
    "Session cleanup destroys the dialog without grounding or delayed activation")
print("PASS: "..count.." Ground Feet selection, cancel and menu lifecycle assertions")
