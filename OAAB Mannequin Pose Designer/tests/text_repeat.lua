package.path="./MWSE/mods/?.lua;"..package.path
local count=0
local function check(ok,reason) assert(ok,reason); count=count+1 end
local callbacks={}
local down,control,alt,super,mode=false,false,false,false,true
local focus
tes3={scanCode={backspace=14},keyboardCode={backspace=14},uiEvent={keyPress="keyPress"},
    worldController={inputController={isKeyDown=function(_,key) check(key==14,"Poll the physical Backspace key"); return down end,
        isControlDown=function() return control end,isAltDown=function() return alt end,isSuperDown=function() return super end},
        menuController={inputController={}}}}
tes3ui={menuMode=function() return mode end}
event={register=function(name,fn,options)
    check(not callbacks[name],"Only one repeat handler of each type per dialog")
    if name=="keyUp" then check(options.filter==14,"Release is filtered to Backspace") end
    callbacks[name]=fn
end,unregister=function(name,fn,options)
    check(callbacks[name]==fn,"Unregister the exact owned handler")
    if name=="keyUp" then check(options.filter==14,"Unregister the same release filter") end
    callbacks[name]=nil
end}
local menu={layouts=0,updateLayout=function(self) self.layouts=self.layouts+1 end}
local fields={}
local function setFocus(value)
    focus=value; tes3.worldController.menuController.inputController.textInputFocus=value
end
for _,key in ipairs({"name","id","description","category"}) do
    local field={parent=menu,calls=0}
    -- Native paragraph inputs own a text child. The recorded native callback
    -- knows that child; code must retain all native event routing information.
    field.editor=key=="id" and field or {parent=field}
    function field:findChild(id) return self.editor~=self and self.editor or nil end
    function field:registerBefore(id,fn) check(id=="keyPress","Only intercept editing keys"); self.before=fn end
    field.editor.registerBefore=field.registerBefore
    local function nativeEdit(target,e)
        check(e.source==target and e.widget==field and e.forwardSource==field.editor and e.id==123,
            "Replay the original native event and its paragraph/caret target")
        check(e.data0==-0x80000000 or e.data0==0x80000000,"Retain native Backspace encoding")
        local raw=field.editor.rawText
        local cursor=assert(raw:find("|",1,true))
        if cursor>1 then field.editor.rawText=raw:sub(1,cursor-2)..raw:sub(cursor) end
        field.calls=field.calls+1
    end
    function field.editor:forwardEvent(e) nativeEdit(self,e) end
    if field.editor~=field then
        function field:forwardEvent(e)
            local childEvent={source=self.editor,widget=self,forwardSource=self.editor,id=e.id,data0=e.data0,data1=e.data1}
            if self.editor.before(childEvent)~=false then self.editor:forwardEvent(childEvent) end
        end
    end
    fields[key]=field
end
local stop=require("MannequinPoseDesigner.text_repeat").bind(menu,fields)
local function nativePress(field,code,target)
    target=target or field
    local e={source=target,widget=field,forwardSource=field.editor,id=123,data0=code or -0x80000000,data1=0,
        keyData={keyCode=14,isControlDown=control,isAltDown=alt,isSuperDown=super}}
    if target.before(e)~=false then target:forwardEvent(e) end
end
local function press(field,code)
    down=true; setFocus(field); nativePress(field,code)
end
local function frames(seconds,step)
    step=step or 0.05
    for i=1,math.floor(seconds/step+0.5) do callbacks.enterFrame({delta=step}) end
end
local function release()
    down=false; callbacks.keyUp({keyCode=14})
end
for key,field in pairs(fields) do
    field.editor.rawText="Repeat|Suffix"
    press(field)
    check(field.editor.rawText=="Repea|Suffix","Initial Backspace deletes once at the caret in "..key)
    frames(0.3)
    check(field.editor.rawText=="Repea|Suffix","Short holds do not repeat yet in "..key)
    frames(0.1)
    check(field.editor.rawText=="Repe|Suffix","One physical press repeats after the delay in "..key)
    frames(0.1)
    check(field.editor.rawText=="Re|Suffix","Held Backspace continues at a steady cadence in "..key)
    release(); frames(0.5)
    check(field.editor.rawText=="Re|Suffix","Key release immediately stops repeat in "..key)
end
local name,description=fields.name,fields.description
name.editor.rawText="ABCDE|tail"; press(name,0x80000000)
nativePress(name); check(name.editor.rawText=="ABCD|tail","An engine repeat cannot double-delete or reset our delay")
frames(0.4); check(name.editor.rawText=="ABC|tail","The repeat still starts at the original deadline")
setFocus(name.editor); frames(0.05)
check(name.editor.rawText=="AB|tail","Focus on the paragraph's native child is supported")
description.editor.rawText="Other|text"; setFocus(description); frames(0.05)
nativePress(description); frames(0.5)
check(name.editor.rawText=="AB|tail" and description.editor.rawText=="Other|text","Changing focus cancels the hold without transferring deletion")
release(); press(description); frames(0.4)
check(description.editor.rawText=="Oth|text","A fresh press starts repeat in the newly focused field")
release()
name.editor.rawText="Direct|suffix"; down=true; setFocus(name.editor)
nativePress(name,-0x80000000,name.editor); frames(0.4)
check(name.editor.rawText=="Dire|suffix","Clicking directly into the paragraph's text child also repeats")
release()
description.editor.rawText="ab\n|cd"; press(description); frames(0.4)
check(description.editor.rawText=="a|cd","Native paragraph replay deletes across a line break and preserves the suffix")
release()
name.editor.rawText="|Suffix"; press(name); frames(1)
check(name.editor.rawText=="|Suffix","Repeat at the start never deletes letters after the caret")
release()
for _,reason in ipairs({"hidden","disabled","menu closed","control","alt","super"}) do
    name.editor.rawText="ABCDE|"; press(name)
    if reason=="hidden" then menu.visible=false
    elseif reason=="disabled" then name.disabled=true
    elseif reason=="menu closed" then mode=false
    elseif reason=="control" then control=true
    elseif reason=="alt" then alt=true
    else super=true end
    frames(0.5)
    check(name.editor.rawText=="ABCD|","Repeat cancels when "..reason)
    menu.visible=true; name.disabled=false; mode=true; control=false; alt=false; super=false
    frames(0.5)
    check(name.editor.rawText=="ABCD|","Cancelled holds require release before restarting")
    release()
end
name.editor.rawText="ABCDE|"; press(name); down=false; frames(0.05)
down=true; nativePress(name); frames(0.4)
check(name.editor.rawText=="AB|","Polling release recovers even if keyUp was lost")
release()
name.editor.rawText="ABCDE|"; press(name); callbacks.enterFrame({delta=5})
check(name.editor.rawText=="ABCD|","A stalled frame never deletes a backlog of letters")
local stale=callbacks.enterFrame
stop(); stop(); stale({delta=1}); nativePress(name)
check(not next(callbacks),"Closing unregisters frame and release handlers exactly once")
check(name.editor.rawText=="ABC|","Stale callbacks do not delete after closing")
print("PASS: "..count.." single-key-down Backspace repeat, cadence, native caret, focus and cleanup assertions")
