-- Shared shortcut descriptions for the compact/expanded sidebar and modal guides.
-- Keyboard handlers resolve these same scan-code names.
local M={}
M.categories={
    {id="transform",title="TRANSFORM"},
    {id="selection",title="SELECTION"},
    {id="modifiers",title="MODIFIERS"},
    {id="edit",title="EDIT"},
    {id="view",title="VIEW"},
    {id="save",title="SAVE / EXIT"},
    {id="props",title="PROPS"},
}
M.entries={
    {id="drag",category="transform",input="Left drag",description="Drag gizmo / bone",contextDescriptions={rotate="Drag axis ring / rotate at bone",ik="Drag axis arrow to move IK",root="Drag axis arrow to move root",pole="Adjust elbow / knee bend"}},
    {id="rotate",category="transform",key="r",description="Rotate in camera view"},
    {id="move",category="transform",key="g",description="Move root / hand / foot (IK)",note="Other bones keep direct rotation."},
    {id="axis",category="transform",keys={"x","y","z"},hold=true,description="Local rotation axis",note="Drag an axis ring, or hold before node dragging."},
    {id="depth",category="transform",input="Shift + left drag",description="Move root / IK in depth"},
    {id="bend",category="transform",input="Alt + left drag",description="Adjust IK bend in G mode"},
    {id="fine",category="transform",input="Ctrl + drag",description="Fine adjustment"},
    {id="lock",category="transform",key="l",description="Lock / unlock hand or foot"},
    {id="pointer",category="selection",input="Mouse",description="Move editing pointer"},
    {id="select",category="selection",input="Left drag near node",description="Select and edit bone / prop"},
    {id="cycle",category="selection",key="tab",alternateModifier="Shift",description="Next / previous bone"},
    {id="symmetry",category="modifiers",key="s",description="Symmetry: Off / Full / Arms / Legs"},
    {id="mirror",category="modifiers",key="m",description="Mirror / copy pose or limbs"},
    {id="blend",category="modifiers",key="b",description="Blend Poses"},
    {id="ground",category="modifiers",key="t",description="Ground Feet: Left / Right / Both"},
    {id="blendSources",category="modifiers",input="Pose lists A / B",description="Choose two poses to blend",dialogOnly=true},
    {id="blendAmount",category="modifiers",input="Blend slider",description="Preview mix: 0% A to 100% B",dialogOnly=true},
    {id="blendAccept",category="modifiers",input="Use blend",description="Keep blended pose",dialogOnly=true},
    {id="undo",category="edit",key="z",modifier="Ctrl",description="Undo"},
    {id="redo",category="edit",key="y",modifier="Ctrl",description="Redo"},
    {id="resetBone",category="edit",key="backspace",description="Reset current bone"},
    {id="resetLimb",category="edit",key="backspace",modifier="Ctrl",description="Reset bone and descendants"},
    {id="resetPose",category="edit",key="backspace",modifier="Ctrl+Shift",description="Reset entire pose"},
    {id="resetMenu",category="edit",key="backspace",modifier="Shift",description="Open reset options",note="All resets restore transforms from session start."},
    {id="turn",category="view",input="Right drag",description="Orbit camera around current focus"},
    {id="pan",category="view",input="Middle drag",description="Pan view"},
    {id="panDepth",category="view",input="Shift + middle drag",description="Pan view in depth"},
    {id="zoom",category="view",input="Wheel",description="Zoom"},
    {id="frontView",category="view",key="numpad1",alternateModifier="Ctrl",description="Front / back view",cameraAction="front"},
    {id="rightView",category="view",key="numpad3",alternateModifier="Ctrl",description="Right / left view",cameraAction="right"},
    {id="topView",category="view",key="numpad7",alternateModifier="Ctrl",description="Top / bottom view",cameraAction="top"},
    {id="orbitLeft",category="view",key="numpad4",description="Orbit left 15 degrees (hold to repeat)",cameraAction="left"},
    {id="orbitRight",category="view",key="numpad6",description="Orbit right 15 degrees (hold to repeat)",cameraAction="orbitRight"},
    {id="orbitUp",category="view",key="numpad8",description="Orbit upward 15 degrees (hold to repeat)",cameraAction="up"},
    {id="orbitDown",category="view",key="numpad2",description="Orbit downward 15 degrees (hold to repeat)",cameraAction="down"},
    {id="oppositeView",category="view",key="numpad9",description="Opposite viewpoint",cameraAction="opposite"},
    {id="zoomIn",category="view",key="add",description="Zoom in (hold to repeat)",cameraAction="zoomIn"},
    {id="zoomOut",category="view",key="subtract",description="Zoom out (hold to repeat)",cameraAction="zoomOut"},
    {id="focus",category="view",key="f",description="Focus Mode: isolate mannequin"},
    {id="handles",category="view",key="v",description="Show / hide bone and prop nodes"},
    {id="help",category="view",key="h",description="Expand / collapse controls",note="Esc collapses controls before cancelling the editor."},
    {id="save",category="save",key="enter",extraKey="numpadEnter",description="Save / manage pose"},
    {id="saveChanges",category="save",key="s",modifier="Ctrl",description="Save Changes (custom Edit Pose only)"},
    {id="cancel",category="save",key="escape",description="Cancel editor / active dialog"},
    {id="props",category="props",key="p",description="Add prop from inventory"},
    {id="propCycle",category="selection",key="tab",modifier="Ctrl",alternateModifier="Ctrl+Shift",description="Next / previous prop",hasPropsOnly=true},
    {id="propBone",category="selection",input="Shift+left click",description="Select attachment bone",propOnly=true},
    {id="propScale",category="props",key="s",description="Scale selected prop",propOnly=true},
    {id="propAttach",category="props",key="p",modifier="Ctrl",description="Attach to selected bone",propOnly=true},
    {id="propDetach",category="props",key="p",modifier="Alt",description="Detach from bone",propOnly=true,attachedOnly=true},
    {id="propDuplicate",category="props",key="d",modifier="Ctrl",description="Duplicate prop",propOnly=true},
    {id="propReplace",category="props",key="p",modifier="Shift",description="Replace prop",propOnly=true},
    {id="propResetScale",category="props",key="s",modifier="Alt",description="Reset scale",propOnly=true},
    {id="propResetRotation",category="props",key="r",modifier="Alt",description="Reset rotation",propOnly=true},
    {id="propResetTranslation",category="props",key="g",modifier="Alt",description="Reset translation",propOnly=true},
    {id="propDelete",category="props",key="delete",description="Delete prop",propOnly=true},
}
M.byId={}
for _,entry in ipairs(M.entries) do M.byId[entry.id]=entry end
for _,id in ipairs({"bend","lock","symmetry","mirror","blend","ground","resetBone","resetLimb","resetPose","resetMenu"}) do M.byId[id].boneOnly=true end
local keyLabels={tab="Tab",backspace="Backspace",delete="Delete",enter="Enter",numpadEnter="Numpad Enter",escape="Esc",add="Numpad +",subtract="Numpad -"}
local function keyLabel(key) return keyLabels[key] or key:gsub("^numpad","Numpad "):gsub("^%l$",string.upper) end
function M.input(entry)
    if type(entry)=="string" then entry=M.byId[entry] end
    if entry.input then return entry.input end
    if entry.keys then
        local labels={}
        for _,key in ipairs(entry.keys) do labels[#labels+1]=keyLabel(key) end
        return (entry.hold and "Hold " or "")..table.concat(labels," / ")
    end
    local label=keyLabel(entry.key)
    if entry.modifier then label=entry.modifier.."+"..label end
    if entry.alternateModifier then label=label.." / "..entry.alternateModifier.."+"..keyLabel(entry.key) end
    if entry.extraKey then label=label.." / "..keyLabel(entry.extraKey) end
    return label
end
-- Keep related numpad pairs on one line without omitting either shortcut.
local fullGroups={
    orbitLeft={ids={"orbitLeft","orbitRight"},input="Numpad 4 / 6",description="Orbit left / right 15 deg (hold)"},
    orbitUp={ids={"orbitUp","orbitDown"},input="Numpad 8 / 2",description="Orbit up / down 15 deg (hold)"},
    zoomIn={ids={"zoomIn","zoomOut"},input="Numpad + / -",description="Zoom in / out (hold)"},
}
local grouped={orbitRight=true,orbitDown=true,zoomOut=true}
function M.full()
    local result={}
    for _,category in ipairs(M.categories) do
        local section={id=category.id,title=category.title,rows={}}
        for _,entry in ipairs(M.entries) do
            if entry.category==category.id and not grouped[entry.id] and not entry.dialogOnly then
                local group=fullGroups[entry.id]
                section.rows[#section.rows+1]={
                    ids=group and group.ids or {entry.id},
                    input=group and group.input or M.input(entry),
                    description=group and group.description or entry.description,
                    note=entry.note,
                }
            end
        end
        result[#result+1]=section
    end
    return result
end
function M.key(id) return tes3.scanCode[M.byId[id].key] end
function M.available(entry,s)
    if type(entry)=="string" then entry=M.byId[entry] end
    local prop
    for _,p in ipairs(s.props or {}) do if p.id==s.selectedProp then prop=p; break end end
    return not (entry.propOnly and not prop or entry.boneOnly and prop
        or entry.attachedOnly and (not prop or prop.attachmentType~="bone")
        or entry.hasPropsOnly and #(s.props or {})==0)
end
function M.matches(id,key)
    if key==nil then return false end
    local entry=M.byId[id]
    return key==M.key(id) or (entry.extraKey~=nil and key==tes3.scanCode[entry.extraKey])
end
function M.axis(key)
    if key==nil then return end
    for _,name in ipairs(M.byId.axis.keys) do if key==tes3.scanCode[name] then return name end end
end
function M.cameraAction(key)
    if key==nil then return end
    for _,entry in ipairs(M.entries) do
        if entry.cameraAction and key==tes3.scanCode[entry.key] then return entry.cameraAction end
    end
end
function M.context(s)
    if s.blendPrompt then return "blend" end
    if s.drag and s.drag.button==1 then return "turn" end
    if s.drag and s.drag.button==2 then return "pan" end
    local drag=s.drag and s.drag.button==0 and s.drag
    local bone=s.bones[s.selected]
    local mode=drag and drag.mode or s.mode
    if s.selectedProp then return mode=="Rotate" and "propRotate" or mode=="Scale" and "propScale" or "propMove" end
    if mode=="IK" and (s.chains[s.selected] or bone.parent==0) then
        if s.chains[s.selected] then return drag and drag.poleMode and "pole" or "ik" end
        return "root"
    end
    return "rotate"
end
local quickIds={
    rotate={"drag","axis","fine","cycle","move","resetBone","props","help"},
    ik={"drag","depth","bend","cycle","lock","rotate","props","help"},
    pole={"drag","depth","fine","cycle","lock","rotate","props","help"},
    root={"drag","depth","fine","cycle","rotate","resetBone","props","help"},
    propMove={"drag","move","cycle","propBone","propAttach","propDetach","propDuplicate","propReplace","propResetScale","propResetRotation","propResetTranslation","propDelete","props","help"},
    propRotate={"drag","move","cycle","propBone","propAttach","propDetach","propDuplicate","propReplace","propResetScale","propResetRotation","propResetTranslation","propDelete","props","help"},
    propScale={"drag","move","cycle","propBone","propAttach","propDetach","propDuplicate","propReplace","propResetScale","propResetRotation","propResetTranslation","propDelete","props","help"},
    turn={"turn","fine","pan","zoom","help"},
    pan={"pan","panDepth","fine","zoom","help"},
    blend={"blendSources","blendAmount","blendAccept","cancel"},
}
function M.description(entry,s,context)
    if type(entry)=="string" then entry=M.byId[entry] end
    context=context or M.context(s)
    local description=entry.contextDescriptions and entry.contextDescriptions[context] or entry.description
    if s.selectedProp then
        local descriptions={drag=context=="propMove" and "Drag node / gizmo to move prop" or context=="propScale" and "Drag node to scale prop" or "Drag node / ring to rotate prop",
            move="Move prop",rotate="Rotate prop",cycle="Next / previous attachment bone",
            select="Select bone / prop node",axis="Local transform axis",depth="Move prop in depth"}
        description=descriptions[entry.id] or description
    elseif entry.id=="select" then description="Select and edit bone / prop" end
    if context=="blend" and entry.id=="cancel" then description="Discard blend preview" end
    return description
end
function M.quick(s)
    local context=M.context(s)
    local result={}
    for _,id in ipairs(quickIds[context]) do
        local entry=M.byId[id]
        if M.available(entry,s) then
            local transform=s.selectedProp and id=="move"
            result[#result+1]={id=id,input=transform and "G / R / S" or M.input(entry),
                description=transform and "Move / rotate / scale prop" or M.description(entry,s,context)}
        end
    end
    return result,context
end
function M.boneName(name)
    local label=name:gsub("^[Bb][Ii][Pp]01%s*","")
    if label=="" then return "ROOT" end
    label=label:gsub("^L%s+","LEFT "):gsub("^R%s+","RIGHT ")
    label=label:gsub("(%l)(%u)","%1 %2")
    return label:upper()
end
return M
