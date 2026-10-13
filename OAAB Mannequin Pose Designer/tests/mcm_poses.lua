package.path="./MWSE/mods/?.lua;"..package.path
local count=0
local function check(ok,why) assert(ok,why); count=count+1 end
local handlers={}
local held=false
event={register=function(name,fn)
    handlers[name]=handlers[name] or {}; handlers[name][fn]=true
end,unregister=function(name,fn)
    check(handlers[name] and handlers[name][fn],"Close only the current view's repeat handlers")
    handlers[name][fn]=nil
end}
local function handlerCount()
    local n=0; for _,list in pairs(handlers) do for _ in pairs(list) do n=n+1 end end; return n
end
tes3={flowDirection={topToBottom=1,leftToRight=2},scanCode={backspace=14},
    uiEvent={mouseClick="click",destroy="destroy",keyPress="key"},
    worldController={menuController={inputController={}},inputController={
        isKeyDown=function() return held end,isControlDown=function() return false end,
        isAltDown=function() return false end,isSuperDown=function() return false end}}}
local focus,confirmation
tes3ui={acquireTextInput=function(value)
    check(not value or not value.destroyed,"Never focus a destroyed native input")
    focus=value; tes3.worldController.menuController.inputController.textInputFocus=value
end,menuMode=function() return true end,showMessageMenu=function(params)
    check(params.leaveMenuMode==false and params.cancels,"Confirmation stays inside the MCM and supports Cancel")
    confirmation=params
end}
local function element(kind,args,parent)
    args=args or {}
    local e={kind=kind,text=args.text or "",parent=parent,children={},events={},widget={}}
    if parent then parent.children[#parent.children+1]=e end
    for _,name in ipairs({"Block","Label","Button","ThinBorder","TextInput","ParagraphInput"}) do
        e["create"..name]=function(self,data) return element(name,data,self) end
    end
    function e:createVerticalScrollPane()
        local pane=element("Pane",{},self); pane.content=element("Content",{},pane)
        pane.widget.contentsChanged=function() pane.updated=true end
        return pane
    end
    function e:getContentElement() return self.content or self end
    function e:getTopLevelMenu() return self.parent and self.parent:getTopLevelMenu() or self end
    function e:updateLayout() self.layouts=(self.layouts or 0)+1 end
    function e:register(id,fn) assert(id); self.events[id]=fn end
    function e:registerBefore(id,fn) assert(id); self.events["before:"..id]=fn end
    function e:registerAfter(id,fn) assert(id); self.events["after:"..id]=fn end
    function e:findChild() end
    function e:destroyChildren()
        for _,child in ipairs(self.children) do child:destroy() end; self.children={}
    end
    function e:destroy()
        if self.destroyed then return end
        self:destroyChildren(); self.destroyed=true
        if focus==self then tes3ui.acquireTextInput(nil) end
        if self.events.destroy then self.events.destroy() end
    end
    function e:forwardEvent(data)
        check(data.source==self and data.data0==-0x80000000,"Replay the original native Backspace editing event")
        self.text=self.text:sub(1,-2)
    end
    return e
end
local function find(root,text)
    if root.text==text then return root end
    for _,child in ipairs(root.children) do local value=find(child,text); if value then return value end end
end
local function kinds(root,kind,out)
    out=out or {}; if root.kind==kind then out[#out+1]=root end
    for _,child in ipairs(root.children) do kinds(child,kind,out) end; return out
end
local function click(value)
    check(value and not value.destroyed,"The requested MCM action is visible")
    return assert(value.events.click)()
end
local function action(root,file,text)
    return find(assert(find(root,file),"Pose row is visible: "..file).parent,text)
end
local function rowCount(root)
    return #kinds(root,"Pane")[1].content.children
end
local custom={
    {file="pose/k/guard.nif",id="guard",name="Guard",label="Guard",category="Standing",description="Spear stance",editable=true},
    {file="pose/k/import.nif",name="Imported",label="Imported",category="",description="",editable=true},
    {file="pose/k/duplicate.nif",id="guard",name="Guard",label="Guard",category="Sitting",description="Second file",editable=true},
}
local stock={{file="oaab/k/mann_relax.nif",label="Relaxed (Default)"}}
local registered={file="other/pose.nif",label="Other mod"}
local invalidations,writes,removes=0,0,0
local failSave,failDelete,failList=false,false,false
local function copy(value) local result={}; for k,v in pairs(value) do result[k]=v end; return result end
local library={invalidate=function() invalidations=invalidations+1 end,
    list=function()
        if failList then error("Directory unreadable") end
        local result={}; for _,pose in ipairs(custom) do result[#result+1]=copy(pose) end; return result
    end,
    blendList=function() return stock end,
    readMetadata=function() end,
    isDefault=function(file) return file==stock[1].file end,
    poseId=function(file) return file:match("([^/]+)%.nif$") end,
    label=function(file) return file end,
    updateMetadata=function(file,fields)
        if failSave then error("Disk full") end
        for _,pose in ipairs(custom) do if pose.file==file then
            check(fields.id==(pose.id or "import"),"Metadata edits retain a saved or filename-derived ID")
            for k,v in pairs(fields) do pose[k]=v end; pose.label=fields.name; writes=writes+1; return file
        end end
        error("Pose missing")
    end,
    remove=function(file)
        if failDelete then error("Permission denied") end
        for i,pose in ipairs(custom) do if pose.file==file then table.remove(custom,i); removes=removes+1; return end end
        error("Pose missing")
    end,
}
package.loaded["MannequinPoseDesigner.library"]=library
package.loaded["OAAB.Mannequins.poses"]={listPoses=function() return {stock[1],registered} end}
local function page()
    local menu=element("Menu")
    local border=element("ThinBorder",{},menu)
    local outer=element("Block",{},border)
    local inner=element("Block",{},outer)
    local root=element("Block",{},inner)
    require("MannequinPoseDesigner.mcm_poses").create({elements={outerContainer=outer,innerContainer=inner,subcomponentsContainer=root}})
    return root,menu
end
local root,menu=page()
check(rowCount(root)==5 and invalidations==1 and writes==0 and removes==0,
    "Opening MCM discovers every custom, imported, stock and registered pose without a reference or writes")
check(#kinds(root,"Button")==6 and find(root,"Relaxed | OAAB_Data (read-only)")
    and find(root,"Other mod | Registered (read-only)"),"Only custom poses expose Edit Metadata and Delete")
check(find(root,"pose/k/guard.nif (duplicate ID; kept separately)")
    and find(root,"pose/k/duplicate.nif (duplicate ID; kept separately)"),"Equal IDs/names are distinct records with paths")
local pane=kinds(root,"Pane")[1]
check(pane.heightProportional==1 and pane.updated and pane.content.autoHeight and not pane.content.heightProportional,
    "The bounded list scrolls through auto-sized contents")
check(#kinds(root,"TextInput")==0 and handlerCount()==0 and focus==nil,
    "The complete MCM list has no search field or text-repeat handlers")
check(#pane.content.children==5 and pane.content.children[3].children[1].text=="Imported | Custom",
    "Every pose has a row in the full alphabetical list")
click(action(root,"pose/k/import.nif","Edit Metadata"))
check(handlerCount()==2 and find(root,"ID: import (fixed)"),"Opening the editor binds text repeat and preserves imported identity")
local inputs=kinds(root,"ParagraphInput")
check(#inputs==3 and inputs[1].text=="Imported" and inputs[2].widget.lengthLimit==2000 and focus==inputs[1],
    "Metadata opens with populated fields, limits and name focus")
held=true; inputs[1].events["before:key"]({source=inputs[1],id="key",data0=-0x80000000})
for _=1,9 do for fn in pairs(handlers.enterFrame) do fn({delta=0.05}) end end
check(inputs[1].text=="Impor","Held Backspace still edits metadata fields")
held=false; for fn in pairs(handlers.keyUp) do fn() end
inputs[1].text="  "; click(find(root,"Save Metadata"))
check(writes==0 and not inputs[1].destroyed,"Invalid fields leave the editor and unsaved input intact")
inputs[1].text="  Imported renamed  "; inputs[2].text="Description changed"; inputs[3].text="New category"
failSave=true; click(find(root,"Save Metadata"))
check(writes==0 and inputs[2].text=="Description changed" and not inputs[1].destroyed,"I/O failures preserve edits for retry")
failSave=false; click(find(root,"Save Metadata"))
check(writes==1 and custom[2].id=="import" and custom[2].name=="Imported renamed"
    and custom[2].category=="New category" and rowCount(root)==5 and find(root,"Imported renamed | Custom"),
    "Saving normalizes and persists metadata, then restores the full pose list")
check(inputs[1].destroyed and focus==nil and handlerCount()==0,"Returning to the list releases the editor and its handlers")
click(action(root,"pose/k/import.nif","Edit Metadata")); inputs=kinds(root,"ParagraphInput"); inputs[1].text="Discard this"
click(find(root,"Cancel"))
check(writes==1 and custom[2].name=="Imported renamed","Cancel discards metadata edits")
click(action(root,"pose/k/import.nif","Delete")); check(removes==0 and confirmation.message:find("return to Relaxed",1,true),"Delete explains the safe fallback before changing files")
local cancelled=confirmation; cancelled.cancelCallback(); cancelled.buttons[1].callback()
check(removes==0 and rowCount(root)==5,"Cancel and duplicate confirmation callbacks cannot delete")
click(action(root,"pose/k/import.nif","Delete")); failDelete=true; confirmation.buttons[1].callback()
check(removes==0 and custom[2] and rowCount(root)==5,"Deletion failure retains the pose and usable browser")
failDelete=false; click(action(root,"pose/k/import.nif","Delete")); local confirmed=confirmation
confirmed.buttons[1].callback(); confirmed.buttons[1].callback()
check(removes==1 and #custom==2 and rowCount(root)==4 and not find(root,"Imported renamed | Custom"),
    "Confirmed deletion removes the selected row exactly once")
custom[#custom+1]={file="pose/k/new.nif",name="Newly installed",label="Newly installed",description="",category="",editable=true}
root:destroy(); root=page()
check(rowCount(root)==5 and find(root,"Newly installed | Custom"),"Reopening discovers externally installed poses")
click(action(root,"pose/k/new.nif","Delete")); local stale=confirmation
root:destroy(); stale.buttons[1].callback()
check(removes==1 and #custom==3 and handlerCount()==0,"Closing or changing MCM tabs invalidates pending mutations and releases handlers")
root=page()
click(action(root,"pose/k/new.nif","Delete")); stale=confirmation
root:destroy(); local reopened=page(); stale.buttons[1].callback()
check(removes==1 and rowCount(reopened)==5 and handlerCount()==0,"Reopening does not revive an old confirmation")
reopened:destroy(); failList=true; reopened=page()
check(find(reopened,"No poses available."),"Discovery errors leave a readable empty list")
reopened:destroy(); failList=false; reopened=page()
check(rowCount(reopened)==5,"Reopening retries discovery and restores the list")
reopened:destroy()
package.loaded["OAAB.Mannequins.poses"]={apiVersion=6}
root=page(); check(rowCount(root)==4,"Older OAAB v6 helpers still list built-in and custom poses")
root:destroy(); check(handlerCount()==0,"All MCM-owned frame/key handlers are released")
print("PASS: "..count.." MCM full-list discovery, scrolling, metadata, confirmation, retry and lifecycle assertions")
