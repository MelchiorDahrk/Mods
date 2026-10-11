package.path="./MWSE/mods/?.lua;"..package.path
local count=0
local function check(ok,reason) assert(ok,reason); count=count+1 end
tes3={scanCode={}}
local controls=require("MannequinPoseDesigner.controls")
local full=controls.full()
check(not controls.byId.saveAs and controls.byId.saveChanges.modifier=="Ctrl",
    "Save As has no redundant hotkey and Ctrl+S remains Save Changes")
local represented={}
local expected={"TRANSFORM","SELECTION","MODIFIERS","EDIT","VIEW","SAVE / EXIT","PROPS"}
for i,title in ipairs(expected) do
    local section=full[i]
    check(section.title==title and #section.rows>0,"Every category remains discoverable in the expanded controls")
    for _,row in ipairs(section.rows) do
        check(row.input~="" and row.description~="","Expanded controls include both shortcut and action")
        for _,id in ipairs(row.ids) do
            local entry=controls.byId[id]
            check(entry and entry.category==section.id and not represented[id],"Each control appears exactly once in its category: "..id)
            represented[id]=row
            if entry.note then check(row.note==entry.note,"Expanded controls retain the explanatory note: "..id) end
        end
    end
end
local dialogControls={blendSources=true,blendAmount=true,blendAccept=true}
for _,entry in ipairs(controls.entries) do
    check(dialogControls[entry.id] and not represented[entry.id] or not dialogControls[entry.id] and represented[entry.id],
        "Expanded controls include editor shortcuts and omit only blend-dialog controls: "..entry.id)
end
check(represented.orbitLeft==represented.orbitRight and represented.orbitLeft.input=="Numpad 4 / 6",
    "Horizontal numpad orbit pairs share one compact row")
check(represented.orbitUp==represented.orbitDown and represented.orbitUp.input=="Numpad 8 / 2",
    "Vertical numpad orbit pairs share one compact row")
check(represented.zoomIn==represented.zoomOut and represented.zoomIn.input=="Numpad + / -",
    "Numpad zoom pairs share one compact row")
check(controls.byId.blend.category=="modifiers" and controls.byId.symmetry.category=="modifiers"
    and controls.byId.ground.category=="modifiers" and controls.byId.focus.category=="view",
    "Blend, symmetry and grounding are Modifiers; Focus belongs to View")
for _,id in ipairs({"resetBone","resetLimb","resetPose","resetMenu","undo","redo"}) do
    check(controls.byId[id].category=="edit","Every reset and history command stays together in Edit")
end
local keyboard={rotate="r",move="g",lock="l",cycle="tab",symmetry="s",mirror="m",blend="b",ground="t",undo="z",redo="y",
    resetBone="backspace",resetLimb="backspace",resetPose="backspace",resetMenu="backspace",focus="f",handles="v",help="h",save="enter",cancel="escape"}
for id,key in pairs(keyboard) do check(controls.byId[id].key==key,"Existing keyboard bindings are preserved: "..id) end
check(controls.byId.save.extraKey=="numpadEnter" and table.concat(controls.byId.axis.keys,",")=="x,y,z",
    "Numpad Enter and held X/Y/Z remain available")
local code=0
for _,entry in ipairs(controls.entries) do
    for _,key in ipairs(entry.keys or {entry.key,entry.extraKey}) do
        if not tes3.scanCode[key] then code=code+1; tes3.scanCode[key]=code end
    end
end
for _,entry in ipairs(controls.entries) do
    if entry.key then
        check(controls.matches(entry.id,tes3.scanCode[entry.key]) and not controls.matches(entry.id,-1),
            "The shared catalog resolves each existing keyboard handler: "..entry.id)
        if entry.cameraAction then
            check(controls.cameraAction(tes3.scanCode[entry.key])==entry.cameraAction and entry.category=="view",
                "Every numpad action remains in View and resolves to its camera handler")
        end
    end
end
check(controls.matches("save",tes3.scanCode.numpadEnter) and not controls.matches("help",nil),
    "Alternate save input resolves while missing input stays inactive")
check(controls.axis(tes3.scanCode.x)=="x" and controls.axis(tes3.scanCode.y)=="y" and controls.axis(tes3.scanCode.z)=="z",
    "Held axes resolve from the same catalog")
check(represented.help.description=="Expand / collapse controls" and not represented.help.note:find("scroll",1,true),
    "H describes in-place expansion without scrolling or a separate window")
check(controls.boneName("Bip01 R UpperArm")=="RIGHT UPPER ARM" and controls.boneName("Bip01 L Hand")=="LEFT HAND"
    and controls.boneName("Bip01")=="ROOT" and controls.boneName("CustomJoint")=="CUSTOM JOINT",
    "Friendly names support standard and unfamiliar rig nodes")
local s={bones={{name="Bip01",parent=0}},selected=1,chains={},mode="IK",props={}}
local rows=controls.quick(s)
local function has(rows,id) for _,row in ipairs(rows) do if row.id==id then return true end end end
check(has(rows,"props") and controls.input("props")=="P","Add Prop is available directly in bone quick controls")
check(not controls.available("propAttach",s) and not controls.available("propCycle",s),"Prop-only actions stay hidden before adding a prop")
s.props={{id="one",attachmentType="root"}}; s.selectedProp="one"
for _,mode in ipairs({"Move","Rotate","Scale"}) do
    s.mode=mode; rows=controls.quick(s)
    for _,id in ipairs({"propAttach","propDuplicate","propReplace","propResetScale","propResetRotation","propResetTranslation","propDelete","propBone"}) do
        check(has(rows,id),"Every prop action stays visible in each transform context: "..id)
    end
    check(not has(rows,"propDetach"),"Free props do not show Detach")
end
s.props[1].attachmentType="bone"; rows=controls.quick(s)
check(has(rows,"propDetach") and controls.input("propDuplicate")=="Ctrl+D","Attached props show Detach and the requested duplicate hotkey")
s.selectedProp=nil
check(not controls.available("propReplace",s) and controls.input("propReplace")=="Shift+P" and not controls.available("propResetScale",s) and controls.available("propCycle",s),"Bone editing hides prop actions but retains cycling for existing props")
print("PASS: "..count.." categorized control coverage and shortcut assertions")
