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
    function result:updateLayout() self.layouts=(self.layouts or 0)+1 end
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
local resetMenu=require("MannequinPoseDesigner.reset_menu")
local closed,actions=0,{}
local function open()
    return resetMenu.open("Bip01 L Calf",function(scope)
        check(not menuMode,"Reset runs after leaving menu mode")
        actions[#actions+1]=scope
    end,function() closed=closed+1 end)
end
for _,case in ipairs({{"Reset Bone","bone"},{"Reset Limb","limb"},{"Reset Entire Pose","entire"}}) do
    local ui=open()
    check(ui.menu and not menuMode,"The reset menu is created before taking native input")
    check(not open(),"Repeated opening cannot create duplicate reset menus")
    check(labels[2].text=="Selected: Bip01 L Calf","The menu identifies the selected bone")
    check(labels[3].text=="Backspace" and labels[4].text=="Ctrl+Backspace"
        and labels[5].text=="Ctrl+Shift+Backspace","All three reset shortcuts appear beside their choices")
    advance(); check(menuMode,"The reset menu takes input on the following frame")
    local button=click(case[1])
    check(not ui.menu and actions[#actions]==case[2],"Each button dispatches its own reset scope and closes")
    local total=#actions
    button.events.click({}); advance()
    check(#actions==total and not menuMode,"Repeated clicks and stale activation cannot reset twice or reopen")
end
local ui=open()
local actionCount=#actions
click("Cancel"); advance()
check(not ui.menu and #actions==actionCount and not menuMode,"Cancel leaves the pose alone and cancels pending activation")
ui=open(); advance()
local menu=ui.menu
check(menu.events.key({data0=2})==nil,"Ordinary keys pass through the native menu")
check(menu.events.key({data0=1})==false and not ui.menu and #actions==actionCount,"Escape closes only the reset menu")
resetMenu.close(ui); check(closed==5,"Repeated close is harmless")
ui=open(); menu=ui.menu
local entryCount=entries
resetMenu.close(ui); advance()
check(menu.destroyed and not menuMode and entries==entryCount and #actions==actionCount,
    "Session cleanup destroys the menu without a reset or delayed menu activation")
print("PASS: "..count.." reset menu, shortcuts, actions and lifecycle assertions")
