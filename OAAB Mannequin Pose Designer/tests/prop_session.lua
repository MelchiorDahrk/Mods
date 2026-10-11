package.path="./MWSE/mods/?.lua;"..package.path
local v=require("MannequinPoseDesigner.math3d")
local rig=require("MannequinPoseDesigner.rig")
package.loaded['MannequinPoseDesigner.highlight']={
    create=function() return {parts={}} end,createProp=function() return {parts={}} end,
    clear=function(h) h.selected=nil end,update=function(h,id,inactive) h.selected=id; h.inactive=inactive end}
local F=dofile("tests/prop_fixture.lua")
local props=require("MannequinPoseDesigner.props")
local bones=dofile("tests/template_fixture.lua")
local root,nodes=F.scene(bones)
local callbacks,timers={},{}
event={register=function(name,fn) callbacks[name]=fn end}
timer={frame={delayOneFrame=function(fn) timers[#timers+1]=fn end}}
local player={}
for _,name in ipairs({"controlsDisabled","mouseLookDisabled","attackDisabled","magicDisabled","jumpingDisabled","viewSwitchDisabled","vanityDisabled"}) do player[name]=false end
local ref={sceneNode=root,orientation=tes3vector3.new(),cell={},updateLighting=function() end,data={}}
tes3.mobilePlayer=player; tes3.player={cell=ref.cell,sceneNode=F.node("Player")}
player.firstPersonReference={sceneNode=F.node("Arms")}
tes3.makeSafeObjectHandle=function() return {valid=function() return true end,getObject=function() return ref end} end
tes3.getCameraPosition=function() return tes3vector3.new(0,200,100) end
local camera={worldRight=tes3vector3.new(1,0,0),worldUp=tes3vector3.new(0,0,1),worldDirection=tes3vector3.new(0,1,0)}
function camera:worldPointToScreenPoint(point) return {x=point.x,y=point.z} end
tes3.getCamera=function() return camera end
tes3.worldController={menuController={}}
tes3.keybind={escape=1,rest=2}; tes3.keyTransition={}
tes3.scanCode={p=25,r=19,g=34,s=31,z=44,y=21,x=45,tab=15,escape=1,backspace=14,enter=28,d=32,delete=211}
tes3.skipAnimationFrame=function() end
local reports={}; tes3.messageBox=function(format,...) reports[#reports+1]=string.format(format,...) end
F.installLoader()
tes3ui={menuMode=function() return false end,suppressTooltip=function() end,getViewportSize=function() return 1000,800 end}
local state
package.loaded['MannequinPoseDesigner.overlay']={
    create=function() return {native={root=F.node("Handles")},menu={},markers={}} end,
    update=function(_,s) state=s; s.screen={} end,setVisible=function() end,destroy=function() end}
local saved,metadata,drafts={},{},0
local library={cache="cache",isDefault=function() return false end,find=function(file) return {file=file,label="Saved"} end,
    readProps=function(file) return props.clone(metadata[file]),metadata[file]~=nil end,
    removeDraft=function() end}
function library.write(b,fields,definitions,apply)
    if not fields then drafts=drafts+1; return "cache/"..drafts..".nif" end
    local file=fields.id..".nif"
    saved[file]={bones=rig.clone(b),props=props.clone(definitions)}; metadata[file]=props.clone(definitions)
    if apply then apply(file) end
    return file
end
package.loaded['MannequinPoseDesigner.library']=library
local menu={}
function menu.inventory(onItem,onClose,title)
    menu.current={inventory=true,onItem=onItem,onClose=onClose,title=title}
    menu.current.close=function() menu.current.closed=true; onClose() end
    return menu.current
end
package.loaded['MannequinPoseDesigner.props_menu']=menu
package.loaded['MannequinPoseDesigner.symmetry_menu']={
    open=function(_,onMode,onClose) return {onMode=onMode,onClose=onClose} end,
    close=function(prompt) if prompt then prompt.onClose() end end}
local selectedFile
local api={apiVersion=5,canPose=function() return true end,getSelectedFile=function() return selectedFile end,
    setSelectedFile=function(_,file) selectedFile=file end,suspend=function() end}
function api.select(_,file)
    selectedFile=file
    local data=saved[file]
    if data then
        rig.apply(data.bones,nodes,root)
        local playback={scene=root,bones=data.bones,nodes=nodes,props=props.clone(data.props)}
        props.restore(playback)
    end
    return true
end
local session=require("MannequinPoseDesigner.session"); session.register()
local count=0
local function check(ok,why) assert(ok,why); count=count+1 end
local function key(name,ctrl,alt,shift)
    callbacks.keyDown({keyCode=tes3.scanCode[name],isControlDown=ctrl,isAltDown=alt,isShiftDown=shift})
end
local function frame() callbacks.enterFrame({}); local pending=timers; timers={}; for _,fn in ipairs(pending) do fn() end end
local function selectBone(name,keepProp)
    for i,b in ipairs(state.bones) do if b.name==name then
        state.cursor={100,100}; state.screen={[i]={x=100,y=100}}; state.propScreen={}
        callbacks.mouseButtonDown({button=0,isShiftDown=keepProp}); callbacks.mouseButtonUp({button=0}); frame()
        return i
    end end
    error("Unknown test bone")
end
local function selectProp(id)
    state.cursor={200,200}; state.screen={}; state.propScreen={[id]={x=200,y=200}}
    callbacks.mouseButtonDown({button=0}); callbacks.mouseButtonUp({button=0}); frame()
end
local function command(action,value)
    if action=="attach" then selectBone(value,true); key("p",true)
    elseif action=="free" then key("p",false,true)
    elseif action=="duplicate" then key("d",true)
    elseif action=="reset" then key("backspace")
    elseif action=="delete" then key("delete")
    elseif action=="select" then selectProp(value)
    elseif action=="bone" then selectBone(state.bones[state.selected].name)
    else error("Unknown test command") end
    frame()
end
local function add(item)
    key("p"); local prompt=menu.current
    check(state.propPrompt==prompt and prompt.inventory,"P directly opens the inventory picker")
    prompt.onClose(); prompt.onItem({id=item,name=item,mesh=item..".nif"}); frame()
end
local function copy(p) return props.clone({p})[1] end
local function near(a,b)
    for _,key in ipairs({"translation","rotation"}) do
        for i,n in ipairs(a[key]) do if math.abs(n-b[key][i])>1e-5 then return false end end
    end
    return math.abs(a.scale-b.scale)<1e-5
end
check(session.start(ref,api),"Start ordinary pose session with prop support")
add("sword"); local p=state.props[1]
check(#state.props==1 and state.selectedProp==p.id and #state.undo==1,"Adding inventory prop creates one unified history step and selection")
key("z",true); frame(); check(#state.props==0,"Undo add removes prop")
key("y",true); frame(); check(#state.props==1 and state.selectedProp==p.id,"Redo add recreates same ID and selection")
p=state.props[1]; local original=copy(p)
key("g"); callbacks.mouseButtonDown({button=0}); callbacks.mouseAxis({deltaX=20,deltaY=-10}); callbacks.mouseButtonUp({button=0}); frame()
check(not near(p,original) and near(state.bones[1],bones[1]),"G translates prop without changing bones")
local moved=copy(p); key("z",true); frame(); check(near(state.props[1],original),"Undo translation restores full local transform")
key("y",true); frame(); check(near(state.props[1],moved),"Redo translation restores result")
local activeUndo,activeDrafts=#state.undo,drafts
callbacks.mouseButtonDown({button=0}); callbacks.mouseAxis({deltaX=12,deltaY=-3})
local partialProp=copy(props.get(state))
key("z",true); frame()
check(not state.drag and near(props.get(state),moved) and #state.undo==activeUndo and drafts==activeDrafts+1,
    "Undo during a prop move ends its gesture, restores its transform and checkpoints once")
callbacks.mouseAxis({deltaX=10,deltaY=4}); callbacks.mouseButtonUp({button=0}); frame()
check(near(props.get(state),moved) and drafts==activeDrafts+1,
    "Later mouse movement and release cannot resume an undone prop move")
key("y",true); frame(); check(near(props.get(state),partialProp),"Redo restores the partial prop move")
key("z",true); frame()
key("s"); check(state.mode=="Scale" and state.symmetry=="off","S selects prop scaling without changing bone symmetry")
callbacks.mouseButtonDown({button=0}); callbacks.mouseAxis({deltaX=25,deltaY=0}); callbacks.mouseButtonUp({button=0}); frame()
check(state.props[1].scale>moved.scale,"Scale changes wrapper uniform scale")
key("z",true); frame(); check(near(state.props[1],moved),"Undo scaling")
key("r"); local node=state.propScene.nodes[p.id]; local pivot=props.nodeTransform(node).translation
state.cursor={pivot[1]+40,pivot[3]}
callbacks.mouseButtonDown({button=0}); callbacks.mouseAxis({deltaX=-12,deltaY=-28}); callbacks.mouseButtonUp({button=0}); frame()
check(not near(state.props[1],moved),"R uses existing circular rotation drag on prop")
key("z",true); frame(); check(near(state.props[1],moved),"Undo rotation")
local undoCount,redoCount=#state.undo,#state.redo
callbacks.mouseButtonDown({button=0}); callbacks.mouseButtonUp({button=0})
check(#state.undo==undoCount and #state.redo==redoCount,"An unchanged prop click preserves undo/redo")
key("g"); callbacks.mouseButtonDown({button=0}); callbacks.mouseAxis({deltaX=30,deltaY=0}); key("escape"); frame()
check(#state.undo==undoCount and #state.redo==redoCount and near(state.props[1],moved),"Cancelled prop drag preserves pending redo and full undo history")
callbacks.keyUp({keyCode=tes3.scanCode.escape}); frame()
local world=props.nodeTransform(state.propScene.nodes[p.id])
for _,bone in ipairs({"Bip01 R Hand","Bip01 L Hand",false}) do
    command(bone and "attach" or "free",bone)
    check(near(world,props.nodeTransform(state.propScene.nodes[p.id])),"Session attachment commands preserve world transform")
end
key("z",true); frame(); check(state.props[1].parentBone=="Bip01 L Hand","Undo detaching restores attachment")
key("y",true); frame(); check(state.props[1].attachmentType=="root","Redo detaching restores free mode")
command("duplicate"); local duplicate=state.selectedProp
check(#state.props==2 and duplicate~=p.id,"Duplicate gets independent ID and selection")
command("reset"); check(props.get(state).translation[1]==0 and props.get(state).scale==1,"Reset selected prop")
key("z",true); frame(); check(near(props.get(state),state.props[1]),"Undo reset restores duplicate transform")
command("delete"); check(#state.props==1 and not state.selectedProp,"Delete selection returns to bone mode")
key("z",true); frame(); check(#state.props==2 and state.selectedProp==duplicate,"Undo delete restores selected prop")
local before=copy(props.get(state)); key("g")
callbacks.mouseButtonDown({button=0}); callbacks.mouseAxis({deltaX=30,deltaY=0}); key("escape"); frame()
check(session.isActive() and near(props.get(state),before),"Escape cancels prop drag without cancelling pose session")
callbacks.keyUp({keyCode=tes3.scanCode.escape}); frame()
local selectedBone=state.selected
key("tab"); frame()
check(state.selected~=selectedBone and state.selectedProp==duplicate,"Tab changes the attachment bone while keeping the active prop")
check(state.highlight.selected==state.selected and state.highlight.inactive,"The retained bone shapes stay selected with the inactive tint")
local steps=#state.undo
command("select",state.props[1].id)
check(state.selectedProp==state.props[1].id and not state.propPrompt,"A prop node selects its prop without opening a menu")
check(#state.undo==steps,"Selecting a prop adds no history entry")
local shifted=copy(props.get(state)); local boneBefore=state.selected
state.screen={[1]={x=state.cursor[1],y=state.cursor[2]}}; state.propScreen={}
key("g"); callbacks.mouseButtonDown({button=0,isShiftDown=true})
callbacks.mouseAxis({deltaX=0,deltaY=-20,isShiftDown=true}); callbacks.mouseButtonUp({button=0}); frame()
check(state.selected==boneBefore and not near(props.get(state),shifted),"Shift drag moves a prop in depth instead of selecting the bone under its node")
key("z",true); frame(); check(near(props.get(state),shifted),"Undo restores the Shift depth drag")
local propWorld=props.nodeTransform(state.propScene.nodes[state.selectedProp])
local hand=selectBone("Bip01 R Hand",true)
check(state.selected==hand and state.selectedProp==state.props[1].id and not state.drag,"Shift-click selects one attachment bone without transforming the prop")
key("p",true); frame()
check(props.get(state).parentBone=="Bip01 R Hand" and near(propWorld,props.nodeTransform(state.propScene.nodes[state.selectedProp])),
    "Ctrl+P attaches to the selected bone without moving the prop")
check(#state.undo==steps+1,"Attaching records one shared undo step")
key("z",true); frame(); check(props.get(state).attachmentType=="root","Undo restores a free prop")
command("attach","Bip01 L Hand")
command("bone")
check(not state.selectedProp and state.props[1].parentBone=="Bip01 L Hand","A normal bone click activates bone transforms without changing parenting")
check(state.highlight.selected==state.selected and not state.highlight.inactive,"Reactivating the bone restores its active shape tint")
key("tab",true); frame()
check(state.selectedProp==state.props[1].id,"Ctrl+Tab selects the first prop from bone editing")
key("tab",true); frame(); check(state.selectedProp==duplicate,"Ctrl+Tab cycles overlapping props")
key("tab",true,false,true); frame(); check(state.selectedProp==state.props[1].id,"Ctrl+Shift+Tab cycles props backward")
local componentProp=props.get(state)
componentProp.translation={7,8,9}; componentProp.rotation=v.axisAngle({0,0,1},0.6); componentProp.scale=2
props.apply(componentProp,state.propScene.nodes[componentProp.id]); root:update()
local transformed=copy(componentProp)
for _,test in ipairs({{"s","scale"},{"r","rotation"},{"g","translation"}}) do
    local history=#state.undo
    key(test[1],false,true); frame(); local changed=props.get(state)
    check(#state.undo==history+1,"Each component reset records one history step")
    for _,component in ipairs({"scale","rotation","translation"}) do
        local expected=component==test[2] and (component=="scale" and 1 or component=="rotation" and v.identity() or {0,0,0}) or transformed[component]
        if component=="scale" then check(changed.scale==expected,"Reset scale preserves other components")
        else for i,n in ipairs(expected) do check(math.abs(changed[component][i]-n)<1e-7,"Component reset preserves unrelated transforms") end end
    end
    key("z",true); frame(); check(near(props.get(state),transformed),"Undo restores the component reset")
    key("y",true); frame(); key("z",true); frame()
end
local replaceBefore=copy(props.get(state))
local replaceWorld=props.nodeTransform(state.propScene.nodes[replaceBefore.id])
local history,redoHistory,draftCount=#state.undo,#state.redo,drafts
local replaceMode,attachmentBone=state.mode,state.selected
key("p",false,false,true)
check(state.propPrompt==menu.current and menu.current.title=="Replace Prop","Shift+P opens the same native inventory picker with a replacement title")
menu.current.close(); frame()
check(near(props.get(state),replaceBefore) and props.get(state).mesh==replaceBefore.mesh
    and #state.undo==history and #state.redo==redoHistory and drafts==draftCount and player.controlsDisabled,
    "Cancelling replacement preserves the prop, history and draft and restores editing controls")
local inventory=menu.inventory
menu.inventory=function(_,onClose,title) check(title=="Replace Prop","Empty replacement inventory keeps its title"); onClose(); return {closed=true} end
key("p",false,false,true); frame(); menu.inventory=inventory
check(not state.propPrompt and #state.undo==history and #state.redo==redoHistory,"No eligible replacement items leave editing and history intact")
key("p",false,false,true)
local replacePrompt=menu.current; replacePrompt.onClose(); replacePrompt.onItem({id="axe",name="Iron Axe",mesh="axe.nif"}); frame()
local replaced=props.get(state)
check(replaced.id==replaceBefore.id and replaced.objectId=="axe" and replaced.name=="Iron Axe" and replaced.mesh=="axe.nif",
    "Replacement changes the source while preserving the selected prop ID")
check(near(replaced,replaceBefore) and replaced.parentBone==replaceBefore.parentBone and near(props.nodeTransform(state.propScene.nodes[replaced.id]),replaceWorld),
    "Replacement retains the full transform and attachment")
check(state.mode==replaceMode and state.selected==attachmentBone and #state.props==2 and #state.undo==history+1 and drafts==draftCount+1,
    "Replacement retains editing focus and creates exactly one shared undo and checkpoint step")
key("z",true); frame()
check(props.get(state).mesh==replaceBefore.mesh and near(props.get(state),replaceBefore),"Undo replacement restores the old source and transform")
key("y",true); frame(); check(props.get(state).mesh=="axe.nif","Redo replacement restores the new item")
history,redoHistory,draftCount=#state.undo,#state.redo,drafts
local nodeBefore=state.propScene.nodes[state.selectedProp]; local messages=#reports
key("p",false,false,true); replacePrompt=menu.current
replacePrompt.onClose(); replacePrompt.onItem({id="bad",mesh="missing.nif"}); frame()
check(props.get(state).mesh=="axe.nif" and state.propScene.nodes[state.selectedProp]==nodeBefore
    and #state.undo==history and #state.redo==redoHistory and drafts==draftCount and #reports==messages+1,
    "Failed replacements report the problem while preserving the source, visual and history")
command("bone")
local inventoryBefore=menu.current
key("p",true); key("p",false,true); key("p",false,false,true); key("d",true); key("delete"); frame()
check(menu.current==inventoryBefore and not state.propPrompt,"Prop-only shortcuts do not open inventory or act on bones")
key("s"); check(state.symmetryPrompt and state.mode~="Scale","S still opens symmetry with bone selected")
-- Close the ordinary symmetry menu through its existing module without testing
-- native menu creation here; its standalone menu test covers that contract.
session.finish(false)
check(not session.isActive() and not player.controlsDisabled,"Cancel restores controls and removes editor-owned props")
check(session.start(ref,api),"Start for save/reopen")
add("sword"); command("attach","Bip01 R Hand"); add("book")
key("p",false,false,true); local saveReplacement=menu.current
saveReplacement.onClose(); saveReplacement.onItem({id="new_book",name="New Book",mesh="new_book.nif"}); frame()
local expected=props.clone(state.props)
session.finish(true,false,{id="Props",name="Props"})
check(selectedFile=="Props.nif" and not session.isActive(),"Save applies pose and ends designer")
check(session.start(ref,api,"Props.nif"),"Reopen saved editable prop pose")
check(#state.props==2 and near(state.props[1],expected[1]) and state.props[1].parentBone==expected[1].parentBone
    and state.props[2].mesh==expected[2].mesh,"Reopened session restores sources, transforms and attachments")
selectProp(state.props[1].id); key("p",false,false,true)
local staleReplacement=menu.current; local staleSource=props.get(state).mesh
session.finish(false)
staleReplacement.onItem({id="stale",mesh="stale.nif"})
check(not session.isActive() and state.props[1].mesh==staleSource and not player.controlsDisabled,
    "Exiting with replacement open restores controls and ignores a stale item callback")
metadata['Props.nif']=nil
check(session.start(ref,api,"Props.nif") and state.preserveEmbedded,"Missing prop metadata allows skeleton editing while preserving embedded props")
key("p")
check(not state.propPrompt,"Missing prop metadata cannot add or replace props destructively")
session.finish(false)
check(not player.controlsDisabled,"Cancel restores controls after editing a pose without prop metadata")
print("PASS: "..count.." integrated prop input, history, cancel, save/reopen and metadata-loss assertions")
