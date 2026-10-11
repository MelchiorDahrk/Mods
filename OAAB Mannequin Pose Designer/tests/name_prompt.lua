package.path="./MWSE/mods/?.lua;"..package.path
local count=0
local function check(ok,reason) assert(ok,reason); count=count+1 end
local menus={}
local buttons={}
local input,border,focused
local nextFrame
local menuMode,pendingMode,menuEntries=false,false,0
local function advanceFrame()
    local fn=assert(nextFrame,"Expected a scheduled frame")
    nextFrame=nil
    if pendingMode then menuMode=true; pendingMode=false end
    fn()
end
local function element()
    local e={events={},beforeEvents={},afterEvents={},widget={},children={}}
    local function child()
        local c=element()
        c.parent=e
        e.children[#e.children+1]=c
        return c
    end
    function e:createLabel(args) local child=element(); child.text=args.text; return child end
    function e:createThinBorder() border=child(); return border end
    function e:createBlock() return child() end
    function e:createParagraphInput()
        local value=child(); value.text=""
        value.widget=setmetatable({},{__newindex=function(t,k,v)
            assert(k=="lengthLimit","Paragraph inputs do not expose "..k)
            rawset(t,k,v)
        end})
        value.events.keyPress=function(event)
            if event.data0==0x80000000 then value.text=value.text:sub(1,-2)
            elseif #value.text<value.widget.lengthLimit then value.text=value.text..(event.character or "") end
        end
        return value
    end
    function e:createButton(args) local child=element(); child.text=args.text; buttons[args.text]=child; return child end
    function e:createTextInput(args)
        input=child()
        input.text=args.text
        -- Model the native PartTextInput handler's two insertion guards. When
        -- lengthLimit is set, it checks occupied pixel width BEFORE text length.
        -- Filling the parent's available width blocks even the first character.
        input.nativeKeyPress=function(event)
            local field=event.source
            if event.data0==0x80000000 then
                field.text=field.text:sub(1,-2)
            elseif event.character and #event.character==1 then
                local available=field.parent.width-(field.parent.paddingLeft or 0)-(field.parent.paddingRight or 0)
                local occupied=field.width+(field.borderLeft or 0)+(field.borderRight or 0)
                if field.widget.lengthLimit and (occupied>=available or #field.text>=field.widget.lengthLimit) then return end
                field.text=field.text..event.character
            end
        end
        input.events.keyPress=input.nativeKeyPress
        return input
    end
    function e:register(id,fn) self.events[id]=fn end
    function e:findChild() end
    function e:registerBefore(id,fn)
        local previous=self.beforeEvents[id]
        self.beforeEvents[id]=function(data)
            if previous and previous(data)==false then return false end
            return fn(data)
        end
    end
    function e:registerAfter(id,fn) self.afterEvents[id]=fn end
    function e:updateLayout()
        self.layouts=(self.layouts or 0)+1
        if self.widthProportional then
            self.width=(self.parent.width-(self.parent.paddingLeft or 0)-(self.parent.paddingRight or 0))
                *self.widthProportional-(self.borderLeft or 0)-(self.borderRight or 0)
        elseif self.autoWidth and self.text then
            self.width=(#self.text+1)*8 -- Include the caret in the test font.
        end
        for _,c in ipairs(self.children) do c:updateLayout() end
    end
    function e:destroy()
        self.destroyed=true
        menus[self.id]=nil
        if self.events.destroy then self.events.destroy({source=self}) end
    end
    return e
end
tes3={flowDirection={topToBottom=1,leftToRight=2},uiEvent={mouseClick="mouseClick",keyEnter="keyEnter",keyPress="keyPress",destroy="destroy"},scanCode={escape=1,backspace=8},
    worldController={menuController={inputController={}}},mobilePlayer={controlsDisabled=false}}
mwse={log=function() end}
local repeatCallbacks={}
event={register=function(id,fn) repeatCallbacks[id]=fn end,unregister=function(id,fn)
    check(repeatCallbacks[id]==fn,"A closing dialog releases its own repeat callback")
    repeatCallbacks[id]=nil
end}
tes3ui={
    findMenu=function(id) return menus[id] end,
    createMenu=function(args) local menu=element(); menu.id=args.id; menus[args.id]=menu; return menu end,
    enterMenuMode=function() pendingMode=true; menuEntries=menuEntries+1 end,
    leaveMenuMode=function() menuMode=false; pendingMode=false end,
    menuMode=function() return menuMode end,
    acquireTextInput=function(value)
        focused=value
        tes3.worldController.menuController.inputController.textInputFocus=value
    end,
}
timer={frame={delayOneFrame=function(fn) nextFrame=fn end}}
json=dofile(assert(arg[2]))
local library={maxIdLength=19,idFile=function(id) if id=="taken" then return nil,"ID exists" end return "pose.nif" end}
package.loaded["MannequinPoseDesigner.library"]=library
local prompt=require("MannequinPoseDesigner.metadata_prompt")
local saved,closed=nil,0
local fail=false
local ui=prompt.open({},function(fields) if fail then error("Disk full") end saved=fields; return true end,function() closed=closed+1 end)
check(ui and not prompt.open({},function() end),"Only one metadata dialog can own input")
advanceFrame(); advanceFrame()
check(menuMode and focused==ui.inputs.name,"Deferred dialog activation focuses the display name")
local name=ui.inputs.name
check(name.widthProportional==1 and name.widget.lengthLimit==120,"Names wrap independently of the path length limit")
name.events.keyPress({source=name,character="G",data0=1})
check(name.text=="G","Paragraph fields accept input at their full layout width")
local id=ui.inputs.id
check(id.widget.lengthLimit==19,"The ID input uses the current filename budget")
id.events.keyPress({source=id,character="g",data0=1})
check(id.text=="g" and id.autoWidth,"The short ID field avoids the native full-width insertion guard")
name.text=string.rep("A",119); name:updateLayout()
name.events.keyPress({source=name,character="B",data0=1})
check(#name.text==120,"Long display names remain editable after wrapping")
name.text="Guard Leaning on Spear"; ui.inputs.id.text="taken"
buttons.Save.events.mouseClick()
check(ui.menu and not saved,"An ID collision preserves the dialog and its fields")
ui.inputs.id.text="guardlean"; ui.inputs.description.text="Relaxed stance."; ui.inputs.category.text="Standing"
fail=true; buttons.Save.events.mouseClick()
check(ui.menu and not saved and ui.inputs.id.text=="guardlean","I/O failures retain editable input")
fail=false; buttons.Save.events.mouseClick()
check(saved.id=="guardlean" and saved.name==name.text and saved.description=="Relaxed stance." and saved.category=="Standing",
    "Successful saves return only the four normalized portable fields")
check(not ui.menu and not menuMode and closed==1,"Save releases the modal exactly once")
check(not next(repeatCallbacks),"Saving unregisters held-backspace callbacks")
local n=closed; buttons.Save.events.mouseClick(); check(closed==n,"Stale callbacks cannot repeat a save")
ui=prompt.open({id="guardlean",name="Existing"},function() end,function() closed=closed+1 end,{immutableId=true})
check(not ui.inputs.id,"Editing metadata provides no mutable ID input")
ui.inputs.name.beforeEvents.keyPress({data0=tes3.scanCode.escape})
check(not ui.menu and closed==2,"Escape in a native input cancels only its modal")
check(not next(repeatCallbacks),"Cancel unregisters held-backspace callbacks")
if nextFrame then advanceFrame() end
check(not menuMode,"Closed-dialog timers cannot reacquire input")
print("PASS: "..count.." metadata prompt, native text sizing, collision and error-retry assertions")
