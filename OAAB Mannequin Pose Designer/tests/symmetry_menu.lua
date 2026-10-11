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
local symmetryMenu=require("MannequinPoseDesigner.symmetry_menu")
local closed,choices=0,{}
local function open(initial)
    return symmetryMenu.open(initial,function(mode)
        check(not menuMode,"Mode selection runs after leaving menu mode")
        choices[#choices+1]=mode
    end,function() closed=closed+1 end)
end
for _,case in ipairs({{"off","Off"},{"entire","Full Symmetry"},{"arms","Arms Only"},{"legs","Legs Only"}}) do
    local initialEntries=entries
    local ui=open(case[1])
    check(ui.menu and ui.menu.layouts==1 and labels[2].text=="Current: "..case[2],"The menu lays out its buttons and displays the active mode")
    check(entries==initialEntries and not open("off"),"Opening S defers menu mode and rejects duplicate menus")
    advance(); check(menuMode and entries==initialEntries+1,"Menu mode starts on the next frame")
    local button=click(case[2])
    check(not ui.menu and choices[#choices]==case[1],"Every button selects its own mode and resumes editing")
    local choiceCount=#choices
    button.events.click({}); advance()
    check(#choices==choiceCount and entries==initialEntries+1,"Stale clicks and activation callbacks cannot repeat selection")
end
local ui=open("invalid")
check(labels[2].text=="Current: Off","Unknown mode displays Off")
local choiceCount=#choices
click("Cancel"); advance()
check(not ui.menu and not menuMode and #choices==choiceCount,"Cancel keeps the current setting and cancels activation")
ui=open("arms"); advance()
local menu=ui.menu
check(menu.events.key({data0=2})==nil,"Ordinary keys belong to the native menu")
check(menu.events.key({data0=1})==false and not ui.menu and #choices==choiceCount,"Escape closes the menu without selecting")
symmetryMenu.close(ui); check(closed==6,"Repeated cleanup does not close twice")
ui=open("legs"); menu=ui.menu
symmetryMenu.close(ui); advance()
check(menu.destroyed and not menuMode and #choices==choiceCount,"Session cleanup closes a pending menu without selection")
print("PASS: "..count.." symmetry menu, mode selection and lifecycle assertions")
