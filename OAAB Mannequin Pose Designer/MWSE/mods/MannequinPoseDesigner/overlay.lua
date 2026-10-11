-- Text uses transparent help-layer menus; bone markers use the world scene.
local markers=require("MannequinPoseDesigner.markers")
local gizmos=require("MannequinPoseDesigner.gizmos")
local controls=require("MannequinPoseDesigner.controls")
local props=require("MannequinPoseDesigner.props")
local M={}
local prefix="OAAB:MannequinPoseDesigner:"
local panelWidth=345
local expandedSideWidth=460
local shortcutGap=12
local panelMargin=12
-- cursor.nif is a 32x32 textured quad extending eight pixels left of its tip.
local cursorSize=32
local cursorHotspotX=8
local symmetryLabels={off="Off",entire="Full",arms="Arms",legs="Legs"}
local contextLabels={rotate="ROTATION",ik="MOVE / IK",root="MOVE ROOT",pole="IK BEND",turn="VIEW",pan="VIEW",blend="BLEND POSES",propMove="MOVE PROP",propRotate="ROTATE PROP",propScale="SCALE PROP"}
local leftCategories={transform=true,selection=true,edit=true,save=true,props=true}
local function createMenu(id)
    local previous=tes3ui.findHelpLayerMenu(id)
    if previous then previous:destroy() end
    local result=tes3ui.createHelpLayerMenu({id=id})
    -- A top-level block has no menu scene node. Keep the native drawable menu,
    -- remove its border children, and hide its own background rectangle.
    result:destroyChildren()
    result.alpha=0
    result.consumeMouseEvents=false
    result.borderAllSides=0
    result.paddingAllSides=0
    result.minWidth=0
    result.minHeight=0
    return result
end
local function addLabel(parent,value,color)
    local e=parent:createLabel({text=value})
    e.consumeMouseEvents=false
    e.color=color or {1,1,1}
    e.alpha=1
    return e
end
local function addBlock(parent,flow)
    local block=parent:createBlock()
    block.flowDirection=flow or tes3.flowDirection.topToBottom
    block.autoWidth=false; block.autoHeight=true
    block.minWidth=0; block.minHeight=0
    block.consumeMouseEvents=false
    return block
end
local function expandControls(left,right)
    local full={block=addBlock(right),headings={},rows={},notes={}}
    for _,category in ipairs(controls.full()) do
        local parentColumn=leftCategories[category.id] and left or full.block
        local heading=addLabel(parentColumn,category.title,{1,0.85,0.48})
        heading.borderTop=12; heading.borderBottom=6
        full.headings[#full.headings+1]=heading
        for _,entry in ipairs(category.rows) do
            local row=addBlock(parentColumn,tes3.flowDirection.leftToRight)
            row.childAlignY=0; row.borderBottom=2
            local input=addLabel(row,entry.input,{1,0.85,0.48})
            input.borderRight=shortcutGap
            local description=addLabel(row,entry.description)
            full.rows[#full.rows+1]={ids=entry.ids,input=input,description=description,block=row}
            if entry.note then
                -- Keep proportional wrapping local to a single auto-sized note.
                local noteRow=addBlock(parentColumn)
                local note=addLabel(noteRow,entry.note,{0.7,0.7,0.7})
                noteRow.borderBottom=4
                full.notes[#full.notes+1]={label=note,block=noteRow,id=entry.ids[1]}
            end
        end
    end
    return full
end
local function placePanel(self,w,h)
    self.menu.childAlignY=self.expanded and 0.5 or 0
    self.menu.ignoreLayoutX=true
    self.menu.ignoreLayoutY=true
    self.menu.positionX=(self.blending or self.expanded) and math.floor(-w/2+panelMargin) or math.floor(w/2-self.menu.width-panelMargin)
    -- Native menu positionY is its top edge; content extends down in -Y.
    -- Center each expanded side within the tallest side, then center that
    -- container on screen. Clamp its top when the viewport is too short.
    self.menu.positionY=math.floor(self.expanded and math.min(self.menu.height/2,h/2-panelMargin) or h/2-panelMargin)
    self.menu:updateLayout()
end
local function placeCursor(cursor,x,y)
    local menu=cursor.menu
    menu.ignoreLayoutX=true
    menu.ignoreLayoutY=true
    menu.positionX=math.floor(x-cursorHotspotX)
    menu.positionY=math.floor(y)
end
function M.create(bones,selectable)
    local panel=createMenu(prefix.."Controls")
    panel.autoWidth=false; panel.autoHeight=true
    panel.flowDirection=tes3.flowDirection.leftToRight; panel.childAlignY=0
    panel.width=panelWidth
    -- Expansion spreads text to both edges inside this same native menu.
    local left=addBlock(panel); left.paddingAllSides=8; left.visible=false
    local spacer=addBlock(panel); spacer.autoHeight=false; spacer.height=0; spacer.visible=false
    local block=panel:createBlock()
    block.flowDirection=tes3.flowDirection.topToBottom
    block.autoWidth=false; block.autoHeight=true
    block.width=panelWidth
    block.paddingAllSides=8
    block.consumeMouseEvents=false
    local title=addLabel(block,"POSE DESIGNER",{1,0.85,0.48})
    local bone=addLabel(block,controls.boneName(bones[1].name),{1,0.85,0.48})
    local node=addLabel(block,bones[1].name,{0.65,0.65,0.65})
    local mode=addLabel(block,"Mode: IK")
    local focus=addLabel(block,"Focus: Off (F)")
    local symmetry=addLabel(block,"Symmetry: Off (S)")
    local heading=addLabel(block,"QUICK CONTROLS",{1,0.85,0.48})
    heading.borderTop=8; heading.borderBottom=4
    local rows={}
    for i=1,8 do rows[i]=addLabel(block,""); rows[i].visible=false end
    local w,h=tes3ui.getViewportSize()
    local self={menu=panel,title=title,block=block,left=left,spacer=spacer,bone=bone,node=node,mode=mode,focus=focus,symmetry=symmetry,heading=heading,rows=rows}
    panel.visible=true
    panel:updateLayout()
    placePanel(self,w,h)
    selectable=selectable or {}
    if #selectable==0 then for i=1,#bones do selectable[i]=i end end
    local ok,native=pcall(markers.create,selectable)
    if not ok then panel:destroy(); error(native) end
    self.native=native
    local gizmoOk,gizmo=pcall(gizmos.create,native.root)
    if not gizmoOk then markers.destroy(native); panel:destroy(); error(gizmo) end
    self.gizmo=gizmo
    local cursorMenu=createMenu(prefix.."Cursor")
    cursorMenu.autoWidth=true; cursorMenu.autoHeight=true
    local cursor=cursorMenu:createImage({path="textures\\tx_cursor.tga"})
    cursor.width=cursorSize; cursor.height=cursorSize
    cursor.color={1,1,1}; cursor.alpha=1
    cursor.consumeMouseEvents=false
    self.cursor={menu=cursorMenu,image=cursor}
    cursorMenu.visible=true
    cursorMenu:updateLayout()
    placeCursor(self.cursor,0,0)
    return self
end
function M.setVisible(self,value,guide)
    self.visible=value
    self.menu.visible=value or guide==true
    self.cursor.menu.visible=value
    markers.setVisible(self.native,value)
end
function M.update(self,s,world)
    self.title.text=s.editFile and "EDIT POSE: "..s.editLabel or "POSE DESIGNER"
    local w,h=tes3ui.getViewportSize()
    local gizmoHit=gizmos.update(self.gizmo,s,world)
    markers.update(self.native,s,world,not gizmoHit)
    self.cursor.menu:updateLayout()
    placeCursor(self.cursor,s.cursor[1],s.cursor[2])
    local quick,context=controls.quick(s)
    self.blending=context=="blend"
    local expanded=s.expandedControls and not self.blending
    self.expanded=expanded==true
    local blendWidth=s.blendPrompt and s.blendPrompt.menu and s.blendPrompt.menu.width or math.floor(w/2)
    local width=expanded and math.min(expandedSideWidth,math.floor((w-panelMargin*2)*0.32)) or panelWidth
    if self.blending then width=math.min(panelWidth,w-blendWidth-panelMargin*3) end
    width=math.min(width,w-panelMargin*2)
    self.menu.width=expanded and w-panelMargin*2 or width
    self.block.width=width
    self.left.visible=expanded==true; self.spacer.visible=expanded==true
    if expanded then
        self.left.width=width
        self.spacer.width=self.menu.width-width*2
    end
    local prop=props.get(s)
    self.bone.text=prop and prop.name or controls.boneName(s.bones[s.selected].name)..(s.locks and s.locks[s.selected] and " [Locked]" or "")
    self.node.text=prop and ("Prop ["..prop.id.."] | "..(prop.attachmentType=="bone" and "Attached: "..controls.boneName(prop.parentBone) or "Free")
        ..(s.propScene.errors[prop.id] and " | Mesh unavailable" or "")) or s.bones[s.selected].name
    local drag=s.drag and s.drag.button==0 and s.drag
    local rotating=drag and drag.mode=="Rotate" or (not drag and (s.mode=="Rotate" or (not prop and not s.chains[s.selected] and s.bones[s.selected].parent~=0)))
    local axis=s.axis
    if drag then axis=drag.axisName end
    self.mode.text="Mode: "..(rotating and "Rotate ("..(axis and "Local "..axis:upper() or "Camera")..")" or (drag and drag.mode or s.mode))
    if not rotating and drag and drag.constraint then
        self.mode.text=self.mode.text.." (Local "..drag.constraint.component:upper()..")"
    end
    if rotating and drag then self.mode.text=self.mode.text..string.format(" | %.1f deg",drag.totalAngle*180/math.pi) end
    if self.blending then self.mode.text="Mode: Blend Poses | "..(s.blendPrompt.percent or 50).."%" end
    self.focus.text="Focus: "..(s.focus and "On" or "Off").." ("..controls.input("focus")..")"
    self.symmetry.text="Symmetry: "..(symmetryLabels[s.symmetry] or "Off").." ("..controls.input("symmetry")..")"
    if prop then self.symmetry.text="Selected bone: "..controls.boneName(s.bones[s.selected].name) end
    self.heading.text=expanded and "ALL CONTROLS (H / Esc: collapse)" or "QUICK CONTROLS: "..contextLabels[context]
    for _,label in ipairs({self.bone,self.node,self.mode,self.focus,self.symmetry,self.heading}) do
        label.autoWidth=false; label.width=width-16; label.wrapText=true
    end
    while #self.rows<#quick do self.rows[#self.rows+1]=addLabel(self.block,"") end
    for i,row in ipairs(self.rows) do
        row.text=quick[i] and quick[i].input..": "..quick[i].description or ""
        row.visible=not expanded and i<=#quick
        row.autoWidth=false; row.width=width-16; row.wrapText=true
    end
    if expanded and not self.full then self.full=expandControls(self.left,self.block) end
    if self.full then
        self.full.block.visible=expanded==true
        if expanded then
            self.full.block.width=width-16
            local contentWidth=width-16
            local inputWidth=math.min(164,math.floor(contentWidth*0.4))
            for _,heading in ipairs(self.full.headings) do heading.autoWidth=false; heading.width=contentWidth end
            for _,row in ipairs(self.full.rows) do
                row.block.visible=controls.available(row.ids[1],s)
                if #row.ids==1 then row.description.text=controls.description(row.ids[1],s) end
                row.block.width=contentWidth
                row.input.autoWidth=false; row.input.width=inputWidth; row.input.wrapText=true
                row.description.autoWidth=false; row.description.width=contentWidth-inputWidth-shortcutGap; row.description.wrapText=true
            end
            for _,note in ipairs(self.full.notes) do
                note.block.visible=controls.available(note.id,s) and not (prop and note.id=="move")
                note.block.width=contentWidth
                note.label.autoWidth=false; note.label.width=contentWidth; note.label.wrapText=true
            end
        end
    end
    self.menu:updateLayout()
    placePanel(self,w,h)
end
function M.destroy(self)
    if not self then return end
    gizmos.destroy(self.gizmo)
    markers.destroy(self.native)
    for _,id in ipairs({prefix.."Controls",prefix.."Cursor"}) do
        local current=tes3ui.findHelpLayerMenu(id)
        if current then current:destroy() end
    end
end
return M
