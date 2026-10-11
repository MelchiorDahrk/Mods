package.path="./MWSE/mods/?.lua;"..package.path
local count=0
local function check(ok,why) assert(ok,why); count=count+1 end
local menus,buttons,frames={},{},{}
local mode=false
local function element()
    local e={events={}}
    function e:createLabel(args) return {text=args.text} end
    function e:createButton(args) local b=element(); buttons[args.text]=b; return b end
    function e:register(id,fn) self.events[id]=fn end
    function e:updateLayout() end
    function e:destroy() menus[self.id]=nil; self.events.destroy() end
    return e
end
tes3={flowDirection={topToBottom=1},uiEvent={mouseClick="click",keyPress="key",destroy="destroy"},scanCode={escape=1}}
tes3ui={findMenu=function(id) return menus[id] end,
    createMenu=function(args) local e=element(); e.id=args.id; menus[args.id]=e; return e end,
    menuMode=function() return mode end,enterMenuMode=function() mode=true end,leaveMenuMode=function() mode=false end}
timer={frame={delayOneFrame=function(fn) frames[#frames+1]=fn end}}
local function advance() local queue=frames; frames={}; for _,fn in ipairs(queue) do fn() end end
local saveMenu=require("MannequinPoseDesigner.save_menu")
local actions,closed={},0
local function open()
    return saveMenu.open("Guard Stance",function(action)
        check(not mode,"Actions run after the save selector releases input")
        actions[#actions+1]=action
    end,function() closed=closed+1 end)
end
for _,case in ipairs({{"Save Changes","changes"},{"Save As","as"},{"Edit Metadata","rename"}}) do
    local prompt=open()
    check(prompt.menu and not mode and not open(),"The selector opens only once and defers activation")
    check(not buttons.Duplicate,"The selector has no redundant Duplicate option")
    advance(); check(mode,"The selector acquires menu input")
    local button=buttons[case[1]]
    button.events.click()
    check(not prompt.menu and actions[#actions]==case[2],"Every action dispatches its intended operation")
    local n=#actions
    button.events.click(); advance()
    check(#actions==n and not mode,"Stale clicks and timers cannot repeat an operation")
end
local n=#actions
local prompt=open()
buttons.Cancel.events.click(); advance()
check(not prompt.menu and not mode and #actions==n,"Cancel returns to editing without an operation")
prompt=open(); advance()
prompt.menu.events.key({data0=1})
check(not prompt.menu and not mode and #actions==n,"Escape belongs to the selector")
prompt=open(); saveMenu.close(prompt); saveMenu.close(prompt); advance()
check(closed==6 and not mode,"Session cleanup cancels pending activation and is idempotent")
print("PASS: "..count.." save action menu assertions")
