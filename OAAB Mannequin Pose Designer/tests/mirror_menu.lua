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
    function result:createBlock() return element() end
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
tes3={flowDirection={topToBottom=1,leftToRight=2},uiEvent={mouseClick="click",keyPress="key",destroy="destroy"},scanCode={escape=1}}
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
local mirrorMenu=require("MannequinPoseDesigner.mirror_menu")
local closed,actions=0,{}
local function open(initial)
    return mirrorMenu.open(initial,function(action,scope)
        check(not menuMode,"Command runs after leaving menu mode")
        actions[#actions+1]={action,scope}
    end,function() closed=closed+1 end)
end
local ui=open("entire")
check(ui.menu and ui.scope=="entire" and entries==0,"Opening M creates the menu before requesting menu mode")
check(not open("legs"),"Repeated M cannot create duplicate menus")
advance(); check(menuMode and entries==1,"Menu mode starts on the following frame")
check(labels[2].text=="Target: Entire Pose","Entire Pose is the visible default target")
click("Arms")
check(ui.scope=="arms" and labels[2].text=="Target: Arms","Arms selection updates the displayed target")
click("Legs")
check(ui.scope=="legs" and labels[2].text=="Target: Legs","Each target button keeps its own callback")
local button=click("Mirror Legs")
check(not ui.menu and closed==1 and actions[1][1]=="swap" and actions[1][2]=="legs","Mirror dispatches the chosen scope and closes")
button.events.click({})
check(#actions==1,"Repeated command callbacks cannot apply twice")
advance(); check(entries==1,"Stale activation callbacks cannot reopen a closed menu")
for _,case in ipairs({{"arms","Copy Left -> Right","leftToRight"},{"entire","Copy Right -> Left","rightToLeft"}}) do
    ui=open(case[1]); advance()
    click(case[2])
    local action=actions[#actions]
    check(action[1]==case[3] and action[2]==case[1],"Copy buttons dispatch their direction and initial scope")
    advance()
end
ui=open("invalid")
check(ui.scope=="entire","Unknown previous scope falls back to Entire Pose")
local actionCount=#actions
click("Cancel"); advance()
check(not ui.menu and #actions==actionCount and not menuMode,"Cancel changes no pose and cancels pending activation")
ui=open("legs"); advance()
local menu=ui.menu
check(menu.events.key({data0=2})==nil,"Ordinary keys pass through the native menu")
check(menu.events.key({data0=1})==false and not ui.menu and #actions==actionCount,"Escape closes only the mirror menu")
mirrorMenu.close(ui); check(closed==5,"Closing an already closed prompt is harmless")
ui=open("arms"); menu=ui.menu
mirrorMenu.close(ui); advance()
check(menu.destroyed and not menuMode and #actions==actionCount,"Session cleanup destroys the menu without running a command")
print("PASS: "..count.." mirror menu, targets, commands and lifecycle assertions")
