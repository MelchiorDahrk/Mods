package.path="./MWSE/mods/?.lua;"..package.path
json=dofile(assert(arg[2]))
local count=0
local function check(ok,why) assert(ok,why); count=count+1 end
local callbacks,frames,menus={},{},{}
local message,errors=nil,{}
local valid,mode=true,false
local nifActive,nifCreated=0,0
local previewState
local function element(args,parent)
    args=args or {}
    local e={text=args.text or "",placeholderText=args.placeholderText,id=args.id,parent=parent,children={},events={},before={},after={},
        widget={getIsPlaceholding=function() return false end},width=0,height=26,borderLeft=4,borderRight=4,borderTop=4,borderBottom=4}
    if parent then parent.children[#parent.children+1]=e end
    for _,kind in ipairs({"Label","Block","Button","ThinBorder","TextInput","ParagraphInput","VerticalScrollPane"}) do
        e["create"..kind]=function(self,a) return element(a,self) end
    end
    function e:createVerticalScrollPane(a)
        local pane=element(a,self); pane.content=element({},pane)
        pane.widget.contentsChanged=function() end
        return pane
    end
    function e:createNif(a)
        check(a.path=="pose/h/pose_preview.nif","Preview loads its empty canvas relative to Meshes")
        local child=element(a,self); child.nif=true; nifActive=nifActive+1; nifCreated=nifCreated+1; return previewState.canvas(child)
    end
    function e:getContentElement() return self.content or self end
    function e:register(id,fn) self.events[id]=fn end
    function e:findChild() end
    function e:registerBefore(id,fn) self.before[id]=fn end
    function e:registerAfter(id,fn) self.after[id]=fn end
    function e:updateLayout()
        self.laidOut=true
        if self.autoWidth then self.width=#self.text*7+16 end
        for _,child in ipairs(self.children) do child:updateLayout() end
    end
    function e:isValid() return not self.destroyed end
    function e:destroyChildren() for _,child in ipairs(self.children) do child:destroy() end; self.children={} end
    function e:destroy()
        if self.destroyed then return end
        self.destroyed=true; self:destroyChildren()
        if self.nif then nifActive=nifActive-1 end
        if self.id then menus[self.id]=nil end
        if self.events.destroy then self.events.destroy() end
    end
    return e
end
local function drain()
    local budget=30
    while #frames>0 do
        check(budget>0,"Deferred work terminates"); budget=budget-1
        local pending=frames; frames={}; for _,fn in ipairs(pending) do fn() end
    end
end
local function find(root,text)
    if root.text==text then return root end
    for _,child in ipairs(root.children) do local value=find(child,text); if value then return value end end
end
local menuId="OAAB:MannequinPoseDesigner:Library"
local function menu() return assert(menus[menuId],"Library expected") end
local function click(text)
    local button=assert(find(menu(),text),"Missing button: "..text)
    check(not button.disabled,"Button is available: "..text)
    button.events.mouseClick(); drain()
end
local function emit(name,e) for _,fn in ipairs(callbacks[name] or {}) do fn(e or {}) end end
local function searchInput(root)
    if root.placeholderText=="Search poses" then return root end
    for _,child in ipairs(root.children) do local value=searchInput(child); if value then return value end end
end
local function canvases(root,result)
    result=result or {}
    if root.nif then result[#result+1]=root end
    for _,child in ipairs(root.children) do canvases(child,result) end
    return result
end
local function same(a,b)
    for i=1,9 do if math.abs(a[i]-b[i])>1e-8 then return false end end
    return true
end
event={register=function(name,fn) callbacks[name]=callbacks[name] or {}; table.insert(callbacks[name],fn) end,
    unregister=function(name,fn) for i,value in ipairs(callbacks[name] or {}) do if value==fn then table.remove(callbacks[name],i); return end end end,
    trigger=emit}
local ref={profile={id="full"},data={},sceneNode={}}
tes3={event={simulate="simulate",simulated="simulated"},uiEvent={mouseClick="mouseClick",keyPress="keyPress",keyEnter="keyEnter",destroy="destroy",textUpdated="textUpdated",textCleared="textCleared"},
    flowDirection={topToBottom=1,leftToRight=2},scanCode={escape=1},
    makeSafeObjectHandle=function(reference) return {valid=function() return valid end,getObject=function() return reference end} end,
    messageBox=function(args,...) if type(args)=="table" then message=args else errors[#errors+1]=string.format(args,...) end end}
previewState=dofile("tests/preview_fixture.lua").install()
tes3ui={createMenu=function(args) local e=element(args); menus[args.id]=e; return e end,findMenu=function(id) return menus[id] end,
    enterMenuMode=function() mode=true end,leaveMenuMode=function() mode=false end,menuMode=function() return mode end,
    acquireTextInput=function() end,getViewportSize=function() return 1024,720 end,getPalette=function() return {1,1,1} end}
timer={frame={delayOneFrame=function(fn) frames[#frames+1]=fn end}}
mwse={log=function() end}
package.preload["OAAB.Mannequins.discovery"]=function() return {getMannequinProfile=function(reference) return reference.profile end} end
local api=assert(loadfile(arg[1]))(); package.loaded["OAAB.Mannequins.poses"]=api
check(api.showMenu(ref) and #message.buttons==5,"OAAB alone keeps its original menu")
local files,prepared,removed,categoryDeletes={},{},{},{}
for i=1,10 do files[i]={file="pose/k/pose"..i..".nif",name="Pose "..i,label="Pose "..i,id="pose"..i,
    description="A useful pose",category=i%2==0 and "Standing" or "",editable=true,isOAABData=false} end
local library={maxIdLength=19}
function library.list() local result={}; for _,pose in ipairs(files) do result[#result+1]=pose end; return result end
function library.readMetadata() return nil end
local categoryFailure=false
function library.removeCategory(category,records)
    if categoryFailure then error("Simulated category failure") end
    categoryDeletes[#categoryDeletes+1]={category=category,records=records}
    for _,pose in ipairs(files) do if pose.category==category then pose.category="" end end
end
function library.poseId(file) return file:match("/([^/]+)%.nif$") end
function library.isDefault(file) return file:find("/mann_",1,true)~=nil end
function library.find(file) for _,pose in ipairs(files) do if pose.file==file then return pose end end end
function library.ensureCompanions(file) prepared[#prepared+1]=file end
function library.idFile(id) if id=="pose1" then return nil,"ID exists" end return "pose/k/"..id..".nif" end
function library.updateMetadata(file,fields) local p=assert(library.find(file)); assert(p.id==fields.id); p.name=fields.name; p.label=fields.name end
function library.remove(file)
    assert(not library.isDefault(file)); removed[#removed+1]=file
    for i,pose in ipairs(files) do if pose.file==file then table.remove(files,i); return end end
end
function library.invalidate() end
package.loaded["MannequinPoseDesigner.library"]=library
local starts={}
package.loaded["MannequinPoseDesigner.session"]={register=function() end,start=function(_,_,file,records)
    starts[#starts+1]={file=file,records=records}; return true
end}
api.select=function(reference,file) api.setSelectedFile(reference,file); return true end
api.registerPose("external",{label="External pose",file="external/pose.nif"})
local extended=0
event.register("OAAB:mannequinPoseMenu",function(e) e.entries[#e.entries+1]={label="External action",callback=function() extended=extended+1 end} end)
require("MannequinPoseDesigner.main"); emit("initialized")
local oldMessage=message
check(api.showMenu(ref) and message==oldMessage and not menus[menuId],"Replacement is deferred and suppresses the stock menu")
drain(); check(mode and menu().laidOut and nifActive==3,"Only a visible three-card page has native previews")
check(find(menu(),"5 / 5") and find(menu(),"Relaxed | OAAB_Data (read-only)") and not api.getSelectedFile(ref),
    "A mannequin without a saved selection opens on Relaxed without applying a pose")
local libraryMenu=require("MannequinPoseDesigner.library_menu")
libraryMenu.close(); drain()
api.setSelectedFile(ref,"POSE\\K\\POSE8.NIF")
api.showMenu(ref); drain()
check(find(menu(),"5 / 5") and find(menu(),"Pose 8 | Custom") and find(menu(),files[8].file),
    "Opening finds the active pose on a later page regardless of path case or separators")
local activePreviews=canvases(menu(),{})
local activeFacing=activePreviews[1].sceneNode.children[1].rotation:copy()
emit("enterFrame",{delta=1})
check(not same(activePreviews[1].sceneNode.children[1].rotation,activeFacing),"The active pose preview spins immediately on entry")
for i=2,#activePreviews do check(same(activePreviews[i].sceneNode.children[1].rotation,activeFacing),"Other entry previews remain still") end
click("Previous")
check(find(menu(),"4 / 5") and find(menu(),"Pose 5 | Custom"),"Browsing can move away from the active pose's page")
check(not find(menu(),"Refresh"),"The footer has no Refresh button")
check(not find(menu(),"Favorites") and not find(menu(),"Favorite") and not find(menu(),"Unfavorite"),
    "The library has no favorite filter or actions")
libraryMenu.close(); drain(); api.showMenu(ref); drain()
check(find(menu(),"5 / 5") and find(menu(),"Pose 8 | Custom") and api.getSelectedFile(ref)=="POSE\\K\\POSE8.NIF" and #prepared==0,
    "Reopening selects the mannequin's pose again without applying the browsed pose")
libraryMenu.close(); drain(); api.setSelectedFile(ref,"missing/pose.nif"); api.showMenu(ref); drain()
check(find(menu(),"1 / 5") and find(menu(),"Adlocutio | OAAB_Data (read-only)"),"An unavailable active file keeps the first-page fallback")
libraryMenu.close(); drain(); api.setSelectedFile(ref,nil); api.showMenu(ref); drain()
click("Custom"); check(nifActive==3,"Source filtering destroys old previews before instantiating a new page")
click("Next"); check(nifActive==3,"Pagination bounds live native scenes")
local search=assert(searchInput(menu()))
check(not find(menu(),"Search"),"Live filtering needs no Search button")
search.text="Pose 10"; search.after.textUpdated(); drain()
check(nifActive==1 and find(menu(),"1 / 1") and find(menu(),"Pose 10"),"Typing immediately filters and resets the page")
search.text="Pose 1"; search.after.textUpdated()
search.text="No matches"; search.after.textUpdated(); drain()
check(nifActive==0 and find(menu(),"No matching poses."),"Rapid typing cancels pending previews for superseded results")
search.text="Search poses"; search.widget.getIsPlaceholding=function() return true end
search.after.textCleared(); drain()
check(nifActive==3 and find(menu(),"1 / 4"),"Clearing restores results without filtering on the placeholder")
local created=nifCreated
search.after.textUpdated(); drain()
check(nifCreated==created,"Placeholder and unchanged queries do not rebuild previews")
search.widget.getIsPlaceholding=function() return false end; search.text=""
search.text="standing"; search.after.textUpdated(); drain()
check(nifActive==3 and find(menu(),"1 / 2"),"Live searches match metadata within the current source")
search.text=""; search.after.textUpdated(); drain()
click("Pose 1")
local visible=canvases(menu(),{})
local facing=visible[1].sceneNode.children[1].rotation:copy()
emit("enterFrame",{delta=1})
check(not same(visible[1].sceneNode.children[1].rotation,facing),"The selected pose spins in menu mode")
for i=2,#visible do check(same(visible[i].sceneNode.children[1].rotation,facing),"Unselected previews remain still") end
click("Pose 2"); emit("enterFrame",{delta=1})
check(same(visible[1].sceneNode.children[1].rotation,facing) and not same(visible[3].sceneNode.children[1].rotation,facing),"Selecting another card transfers rotation and resets the old preview")
click("Pose 1")
check(find(menu(),"Edit Pose") and find(menu(),"Edit Metadata") and find(menu(),"Delete")
    and not find(menu(),"Duplicate"),"Custom poses expose editing and deletion without a redundant Duplicate option")
check(not find(menu(),"Favorite") and not find(menu(),"Unfavorite") and find(menu(),"Pose 1"),
    "Metadata-less custom poses have plain names and no favorite action")
click("Apply"); check(api.getSelectedFile(ref)==files[1].file and prepared[#prepared]==files[1].file and nifActive==0 and not mode,"Apply closes and releases every preview")
api.showMenu(ref); drain(); click("OAAB_Data")
check(not find(menu(),"Edit Pose") and not find(menu(),"Edit Metadata") and not find(menu(),"Delete"),"Read-only stock poses never expose write actions")
check(find(menu(),"Apply") and not find(menu(),"Favorite") and not find(menu(),"Unfavorite") and not find(menu(),"Duplicate"),
    "Stock poses retain Apply without a favorite action")
click("Custom"); click("Pose 1"); click("Edit Metadata")
local prompt=assert(menus["OAAB:MannequinPoseDesigner:Metadata"])
check(nifActive==0 and not menu().visible,"Metadata dialogs do not retain hidden live previews")
emit("enterFrame",{delta=1})
local inputs={}
local function collect(root)
    if root.widget.lengthLimit then inputs[#inputs+1]=root end
    for _,child in ipairs(root.children) do collect(child) end
end
collect(prompt)
check(#inputs==3 and find(prompt,"ID: pose1 (fixed)"),"Metadata edits cannot alter IDs")
inputs[1].text="Renamed"; find(prompt,"Save Metadata").events.mouseClick(); drain()
check(prompt.destroyed and #files==10 and menu().visible,"Metadata edits return to the library without creating a pose")
check(files[1].id=="pose1" and files[1].name=="Renamed","Display-name edits preserve identity")
local function categoryX(category)
    local item=assert(find(menu(),category),"Category expected: "..category)
    return find(item.parent,"X")
end
check(categoryX("Standing") and not categoryX("Uncategorized"),"Named categories have an X; Uncategorized is permanent")
click("Standing")
categoryX("Standing").events.mouseClick(); drain()
check(message.buttons[1]=="Delete Category" and message.message:find("5 poses",1,true)
    and #categoryDeletes==0 and nifActive==0,"Category confirmation counts all poses and releases previews")
message.callback({button=1}); drain()
check(#categoryDeletes==0 and find(menu(),"Custom | Standing | 5 poses"),"Cancel retains the category and active filter")
categoryFailure=true
categoryX("Standing").events.mouseClick(); drain(); message.callback({button=0}); drain()
check(#categoryDeletes==0 and categoryX("Standing") and find(menu(),"Custom | Standing | 5 poses")
    and errors[#errors]:find("Simulated category failure",1,true),"Failed category deletion returns to the original category")
categoryFailure=false
-- Search must not restrict which poses lose the category.
search=assert(searchInput(menu())); search.text="Pose 2"; search.after.textUpdated(); drain()
categoryX("Standing").events.mouseClick(); drain()
message.callback({button=0}); message.callback({button=0}); drain()
check(#categoryDeletes==1 and #categoryDeletes[1].records>#files and not find(menu(),"Standing")
    and find(menu(),"Custom | All categories | 1 poses"),"Confirm deletes globally once and clears the category filter while retaining search")
for _,pose in ipairs(files) do check(pose.category=="","Every affected pose is now Uncategorized") end
check(api.getSelectedFile(ref)==files[1].file and #removed==0,"Removing categories never deletes or reapplies a pose")
search=assert(searchInput(menu())); search.text=""; search.after.textUpdated(); drain()
files[2].category="Shared"
library.readMetadata=function(file)
    if file=="external/pose.nif" then return {name="External pose",category="Shared"} end
end
libraryMenu.close(); drain(); api.showMenu(ref); drain()
check(categoryX("Shared").disabled,"Categories shared with registered read-only poses cannot be deleted")
files[2].category=""; library.readMetadata=function() end
libraryMenu.close(); drain(); api.showMenu(ref); drain()
click("Custom"); click("Delete"); check(#removed==0 and message.buttons[1]=="Delete","Delete requires confirmation")
message.callback({button=1}); drain(); check(#removed==0 and menus[menuId],"Cancel preserves the pose and returns to browsing")
click("Delete"); message.callback({button=0}); message.callback({button=0}); drain(); check(#removed==1,"Repeated confirmation callbacks cannot delete twice")
click("External action"); check(extended==1 and nifActive==0,"Other extensions' actions survive replacement")
api.showMenu(ref); drain(); click("Create pose"); check(#starts==1 and not starts[1].file,"Create starts the designer after releasing UI")
check(starts[1].records and #starts[1].records>#files,"New sessions reserve registered poses' IDs too")
api.showMenu(ref); drain(); click("Custom"); click("Edit Pose"); check(#starts==2 and starts[2].file,"Edit applies the selected custom pose before starting its saved session")
check(starts[2].records and #starts[2].records>#files,"Save As retains the complete library identity context")
api.showMenu(ref); drain(); local before=nifCreated; click("Next")
require("MannequinPoseDesigner.library_menu").close(); drain(); check(nifActive==0,"Closing invalidates queued native preview creation")
search.after.textUpdated(); emit("enterFrame",{delta=1}); drain()
check(nifActive==0,"Closed library callbacks cannot recreate or animate previews")
api.showMenu(ref); valid=false; drain(); check(not menus[menuId],"Unloaded references cannot open a deferred menu")
valid=true; api.showMenu(ref); drain(); valid=false; emit("enterFrame"); drain(); check(not menus[menuId] and nifActive==0,"Reference invalidation destroys active previews")
valid=true; api.showMenu(ref); drain(); emit("load"); drain(); check(not menus[menuId] and nifActive==0,"Loading a save closes the library")
check(not api.showMenu({profile={id="stand"}}),"Dress stands remain excluded")
for _,light in ipairs(previewState.lights) do check(not next(light.affected),"Destroyed previews release every private light's affected-node link") end
print("PASS: "..count.." live-preview lifecycle, library UI and optional API replacement assertions")
