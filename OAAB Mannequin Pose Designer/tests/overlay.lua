package.path="./MWSE/mods/?.lua;"..package.path
-- This fixture verifies the native text/bone renderer; gizmo scene tests are separate.
local gizmoHover
package.loaded["MannequinPoseDesigner.gizmos"]={create=function() return {} end,update=function() return gizmoHover end,destroy=function() end}
local count=0
local function check(ok,reason) assert(ok,reason); count=count+1 end
local function near(a,b) return math.abs(a-b)<1e-6 end
local vector={}
local function vec(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},vector) end
vector.__index={copy=function(a) return vec(a.x,a.y,a.z) end}
vector.__add=function(a,b) return vec(a.x+b.x,a.y+b.y,a.z+b.z) end
vector.__sub=function(a,b) return vec(a.x-b.x,a.y-b.y,a.z-b.z) end
vector.__mul=function(a,b) return vec(a.x*b,a.y*b,a.z*b) end
local function same(a,b) return near(a.x,b.x) and near(a.y,b.y) and near(a.z,b.z) end
local function rotate(p,yaw)
    return vec(p.x*math.cos(yaw)-p.y*math.sin(yaw),p.x*math.sin(yaw)+p.y*math.cos(yaw),p.z)
end
local transform={}
local function rotation(yaw)
    return {yaw=yaw or 0,copy=function(a) return rotation(a.yaw) end}
end
local function frame(position,scale,yaw)
    return setmetatable({translation=position or vec(),scale=scale or 1,yaw=yaw or 0,rotation=rotation(yaw)},transform)
end
transform.__mul=function(t,p) return t.translation+rotate(p*t.scale,t.yaw) end
transform.__index={invert=function(t)
    return frame(rotate(t.translation*(-1/t.scale),-t.yaw),1/t.scale,-t.yaw),t.scale~=0
end}
tes3vector3={new=vec}
local function color(r,g,b) return {r=r,g=g,b=b} end
niColor={new=color}
ni={zBufferPropertyTestFunction={always=0}}
niZBufferProperty={new=function() return {propertyFlags=3,testFunction=3} end}
niAlphaProperty={new=function() return {propertyFlags=0} end}
local clones=0
local shared={diffuse=color(0.6,0.6,0.6),emissive=color(0,0,0),alpha=0.8}
function shared:clone()
    clones=clones+1
    return {diffuse=self.diffuse,emissive=self.emissive,alpha=self.alpha}
end
niMaterialProperty={new=function() return shared:clone() end}
local originalDepth={propertyFlags=3,testFunction=3}
local originalAlpha={propertyFlags=0}
local function node(kind,children)
    local n={kind=kind,children=children or {},translation=vec(),scale=1,rotation=rotation(),propertyUpdates=0}
    function n:isInstanceOfType(asked) return self.kind==asked end
    function n:attachChild(child)
        assert(not child.parent,"A child cannot belong to two parents")
        self.children[#self.children+1]=child; child.parent=self
    end
    function n:detachChild(child)
        for i,c in pairs(self.children) do
            if c==child then table.remove(self.children,i); child.parent=nil; return child end
        end
    end
    function n:updateProperties() self.propertyUpdates=self.propertyUpdates+1 end
    function n:updateEffects() self.effectsUpdated=true end
    function n:clone()
        local result=node(self.kind)
        result.name=self.name
        result.translation=self.translation:copy(); result.scale=self.scale; result.rotation=self.rotation:copy()
        result.materialProperty=self.materialProperty
        result.zBufferProperty=self.zBufferProperty; result.alphaProperty=self.alphaProperty
        result.origin=self.origin; result.radius=self.radius
        for i,child in pairs(self.children) do result.children[i]=child:clone(); result.children[i].parent=result end
        return result
    end
    function n:update()
        local parent=self.parent and self.parent.worldTransform or frame()
        self.worldTransform=frame(parent*self.translation,parent.scale*self.scale,parent.yaw+self.rotation.yaw)
        if self.kind=="shape" then
            self.worldBoundOrigin=self.worldTransform*self.origin
            self.worldBoundRadius=self.radius*self.worldTransform.scale
        else
            local first
            for _,child in pairs(self.children) do
                child:update()
                if not first then first=child end
            end
            self.worldBoundOrigin=first and first.worldBoundOrigin or self.worldTransform.translation
            self.worldBoundRadius=first and first.worldBoundRadius or 0
        end
    end
    for _,child in pairs(n.children) do child.parent=n end
    return n
end
niNode={new=function() return node("node") end}
local function meshRoot()
    local direct=node("shape"); direct.origin=vec(0.5,0,2); direct.radius=2
    direct.name="X_move"
    direct.materialProperty=shared; direct.zBufferProperty=originalDepth; direct.alphaProperty=originalAlpha
    local inherited=node("shape"); inherited.origin=vec(0.5,0,2); inherited.radius=2
    inherited.name="node"; inherited.scale=2; inherited.materialProperty=shared
    inherited.zBufferProperty=originalDepth; inherited.alphaProperty=originalAlpha
    local branch=node("node",{[2]=inherited}); branch.materialProperty=shared
    branch.translation=vec(4,-2,1); branch.scale=3; branch.rotation=rotation(0.4)
    local root=node("node",{direct,[4]=branch}); root.translation=vec(2,3,4)
    root.scale=2; root.rotation=rotation(0.3)
    function root:clone() error("Bone handles must not clone the arrows, rings or accumulator") end
    return root
end
local template=meshRoot()
local worldRoot=node("node")
worldRoot.translation=vec(1000,-30,5); worldRoot.scale=2; worldRoot.rotation=rotation(0.7); worldRoot:update()
local zoom,offscreen,missingMesh=10,false,false
local loadPath,cache
local camera={worldUp=vec(0,1,0),worldPointToScreenPoint=function(_,point)
    if offscreen and near(point.x,1) then return nil end
    return {x=point.x*zoom,y=point.y*zoom}
end}
tes3={flowDirection={topToBottom=1,leftToRight=2},niType={NiNode="node",NiTriShape="shape"},
    getCamera=function() return camera end,
    worldController={worldCamera={root=worldRoot}},
    loadMesh=function(path,useCache) loadPath,cache=path,useCache; if not missingMesh then return template end end}
local live,created={},0
local w,h=800,600
local glyphWidth,lineHeight=8,18
local function textLines(text,width)
    local limit=math.max(1,math.floor(width/glyphWidth))
    local lines,used=1,0
    for word in text:gmatch("%S+") do
        local length=#word
        if used>0 and used+1+length>limit then lines=lines+1; used=0 end
        if used>0 then used=used+1 end
        lines=lines+math.floor((length-1)/limit)
        used=used+(length-1)%limit+1
    end
    return lines
end
-- Native coordinates use the top-left corner and positive Y points upward.
-- Check drawn descendants as well as height, so a misplaced top edge cannot
-- pass merely because the menu's height is smaller than the viewport.
local function drawBounds(e,x,y,shown)
    shown=shown and e.visible~=false
    rawset(e,"drawX",x); rawset(e,"drawY",y); rawset(e,"drawn",shown)
    local padding=e.paddingAllSides or 0
    local offset=0
    for _,child in ipairs(e.children) do
        local top,bottom=child.borderTop or 0,child.borderBottom or 0
        local cx,cy=x+padding,y-padding
        if e.flowDirection==tes3.flowDirection.leftToRight then
            cx=cx+offset
            cy=cy-top-(e.height-padding*2-child.height-top-bottom)*(e.childAlignY or 0.5)
        else
            cx=cx+(e.width-padding*2-child.width)*(e.childAlignX or 0)
            cy=cy-offset-top
        end
        drawBounds(child,cx,cy,shown)
        if child.visible~=false then
            offset=offset+(e.flowDirection==tes3.flowDirection.leftToRight
                and child.width+(child.borderRight or 0) or child.height+top+bottom)
        end
    end
end
-- Native UI elements reject fields outside their exposed MWSE properties.
local elementProperties={alpha=true,autoWidth=true,autoHeight=true,width=true,height=true,
    minWidth=true,minHeight=true,visible=true,text=true,color=true,wrapText=true,heightProportional=true,
    consumeMouseEvents=true,borderAllSides=true,paddingAllSides=true,borderTop=true,borderBottom=true,borderRight=true,
    flowDirection=true,childAlignY=true,childAlignX=true,ignoreLayoutX=true,ignoreLayoutY=true,positionX=true,positionY=true}
local function element()
    local e={kind="block",children={},labels={},blocks={},images={},layouts=0,height=414,width=30,alpha=1}
    function e:createLabel(args)
        local child=element(); child.text=args.text; child.width=10; child.height=18
        child.kind="label"
        rawset(child,"sceneNode",{})
        self.labels[#self.labels+1]=child
        self.children[#self.children+1]=child
        return child
    end
    function e:createBlock(args)
        local child=element(); self.blocks[#self.blocks+1]=child
        self.children[#self.children+1]=child
        if args and args.id then rawset(child,"id",args.id); live[args.id]=child; created=created+1 end
        return child
    end
    function e:createNif() error("UI NIF widgets must not be used for bone markers") end
    function e:createImage(args)
        local child=element(); rawset(child,"path",args.path); rawset(child,"sceneNode",{})
        self.images[#self.images+1]=child
        self.children[#self.children+1]=child
        return child
    end
    function e:findChild(id) return live[id] end
    function e:destroyChildren()
        for _,child in ipairs(self.labels) do child:destroy() end
        for _,child in ipairs(self.blocks) do child:destroy() end
        for _,child in ipairs(self.images) do child:destroy() end
        self.children={}; self.labels={}; self.blocks={}; self.images={}; rawset(self,"frameRemoved",true)
        -- The menu's own rectangle survives destruction of its border children.
    end
    function e:updateLayout()
        self.layouts=self.layouts+1
        if self.kind=="label" then
            self.height=lineHeight*(self.wrapText and textLines(self.text,self.width) or 1)
            return
        end
        local width,height=0,0
        for _,child in ipairs(self.children) do
            child:updateLayout()
            if child.visible~=false then
                local cw=child.width+(child.borderRight or 0)
                local ch=child.height+(child.borderTop or 0)+(child.borderBottom or 0)
                if self.flowDirection==tes3.flowDirection.leftToRight then
                    width=width+cw; height=math.max(height,ch)
                else width=math.max(width,cw); height=height+ch end
            end
        end
        if self.autoWidth then self.width=math.max(self.minWidth or 0,width) end
        if self.autoHeight then self.height=math.max(self.minHeight or 0,height+(self.paddingAllSides or 0)*2) end
        drawBounds(self,self.positionX or 0,self.positionY or 0,true)
    end
    function e:destroy()
        rawset(self,"destroyed",true)
        if self.id then live[self.id]=nil end
    end
    return setmetatable(e,{__newindex=function(self,key,value)
        assert(elementProperties[key],"Unknown MWSE UI element property: "..key)
        if key=="wrapText" and value then rawset(self,"heightProportional",1) end
        rawset(self,key,value)
    end})
end
local helpRoot=element()
tes3.worldController.menuController={helpRoot=helpRoot}
tes3ui=setmetatable({createHelpLayerMenu=function(args)
        local menu=element(); rawset(menu,"id",args.id); live[args.id]=menu; created=created+1
        rawset(menu,"sceneNode",{}); menu.alpha=0.8; menu.minWidth=30; menu.minHeight=30
        menu.blocks={element()} -- Native frame border.
        return menu
    end,
    findHelpLayerMenu=function(id) return live[id] end,
    getViewportSize=function() return w,h end},
    {__index=function(_,name) error("Unknown MWSE tes3ui API: "..name) end})
local prefix="OAAB:MannequinPoseDesigner:"
local previousCursor=element(); rawset(previousCursor,"id",prefix.."Cursor"); live[previousCursor.id]=previousCursor
local overlay=require("MannequinPoseDesigner.overlay")
local controls=require("MannequinPoseDesigner.controls")
local bones={{name="Bip01",parent=0},{name="Bip01 L Hand",parent=1},{name="Bip01 L Finger0",parent=2}}
local ui=overlay.create(bones,{1,2})
check(created==2,"Only controls and cursor create help-layer menus")
check(previousCursor.destroyed,"An existing cursor menu is replaced")
check(ui.menu==live[prefix.."Controls"] and ui.menu.sceneNode and ui.cursor.menu.sceneNode,"Controls and cursor have drawable native menu scene nodes")
check(ui.menu.frameRemoved and ui.cursor.menu.frameRemoved and ui.menu.alpha==0 and ui.cursor.menu.alpha==0,"Frame children are removed and both menus' own background rectangles are transparent")
check(ui.bone.alpha==1 and ui.cursor.image.alpha==1,"Controls and editing pointer remain opaque inside transparent menus")
check(ui.cursor.image.path=="textures\\tx_cursor.tga" and #ui.cursor.menu.labels==0,"The pointer uses the vanilla cursor texture without a text cursor")
check(not ui.cursor.menu.consumeMouseEvents and not ui.cursor.image.consumeMouseEvents,"The pointer passes clicks through to session bone picking")
check(#ui.menu.blocks==3 and #ui.rows==8 and not ui.left.visible and not ui.spacer.visible,
    "Only the existing compact sidebar is visible before expansion")
check(ui.menu.positionX==43 and ui.menu.positionY==h/2-12,"Controls stay at the top-right of the viewport")
check(ui.native.markers[3]==nil and ui.native.markers[1].menu==nil,"Bones have scene meshes, with no marker menus or finger handles")
check(loadPath=="pose\\h\\gizmo.nif" and cache==false,"Bone markers load the authored gizmo through its uncached meshes-relative path")
check(ui.native.root.parent==worldRoot and #worldRoot.children==1,"The handle group is attached directly to the world scene")
local shape1=ui.native.markers[1].mesh
local shape2=ui.native.markers[2].mesh
local sourceShape=template.children[4].children[2]
check(shape1~=shape2 and shape1~=sourceShape and shape1.name=="node" and #shape1.children==0,
    "Each bone clones only the named node shape without arrows or rotation geometry")
check(near(shape1.scale,sourceShape.worldTransform.scale) and near(shape1.rotation.yaw,sourceShape.worldTransform.rotation.yaw),
    "Extraction preserves the source shape's complete nested scale and rotation")
check(shape1.materialProperty~=shared and shape2.materialProperty~=shape1.materialProperty,"Each marker isolates the source shape's shared material")
check(shape1.zBufferProperty.testFunction==0 and shape1.zBufferProperty.propertyFlags==1,"Bone markers ignore scene depth and do not write depth")
check(shape1.alphaProperty.propertyFlags==237 and shape2.alphaProperty.propertyFlags==237,"Every bone marker is drawn in the alpha pass after opaque scene geometry")
check(same(ui.native.markers[1].mesh.worldBoundOrigin,worldRoot.translation),"An offset bone marker pivot is centered in the scene before bone placement")
local s={cursor={100,-100},selected=1,bones=bones,mode="IK",chains={[2]={}},handles=true}
local function shows(id)
    local input=controls.input(id)..": "
    for _,row in ipairs(ui.rows) do if row.visible and row.text:sub(1,#input)==input then return true end end
    return false
end
local world={{translation={0,0,10}},{translation={1,2,20}},{translation={2,3,30}}}
overlay.update(ui,s,world)
check(not ui.native.root.appCulled and not ui.native.markers[1].node.appCulled,"Meshes become visible when the editor updates")
check(same(ui.native.markers[1].mesh.worldBoundOrigin,vec(0,0,10)) and same(ui.native.markers[2].mesh.worldBoundOrigin,vec(1,2,20)),"Pearl centers follow bones even with a rotated, scaled scene parent")
check(near(ui.native.markers[1].mesh.worldBoundRadius*2*zoom,16) and near(ui.native.markers[2].mesh.worldBoundRadius*2*zoom,12),"Projected diameters are 16 pixels selected and 12 normally")
check(s.screen[1].x==0 and s.screen[2].x==10 and s.screen[3]==nil,"Projected selectable bone positions remain available for picking")
check(shape1.materialProperty.emissive.g==0.8 and shape2.materialProperty.emissive.b==1 and shape2.materialProperty.emissive.r==0.3,"Selected bone markers are amber and IK bone markers are cyan")
check(ui.native.root.children[#ui.native.root.children]==ui.native.markers[1].node,"The selected handle is last in its scene group")
check(ui.mode.text=="Mode: IK","Root translation displays IK without a rotation axis")
check(ui.focus.text=="Focus: Off (F)" and ui.symmetry.text=="Symmetry: Off (S)",
    "Focus and symmetry remain visible status information")
check(shows("depth") and shows("rotate") and shows("cycle") and shows("resetBone") and shows("help"),
    "Root movement prioritizes depth, rotation, selection, current reset and help")
check(not shows("axis") and not shows("lock") and not shows("blend") and shows("props"),
    "Root movement omits unrelated controls and the full flat list")
check(ui.bone.text=="ROOT" and ui.node.text=="Bip01","The friendly root name dominates its subordinate node name")
for mode,label in pairs({entire="Full",arms="Arms",legs="Legs",off="Off"}) do
    s.symmetry=mode; overlay.update(ui,s,world)
    check(ui.symmetry.text=="Symmetry: "..label.." (S)","The panel displays each live symmetry scope")
end
s.symmetry="off"
check(shared.emissive.r==0 and shared.diffuse.r==0.6 and shared.alpha==0.8 and originalDepth.propertyFlags==3 and originalAlpha.propertyFlags==0,"The original bone marker and its material, depth and alpha properties are untouched")
local hoverClones=clones
s.cursor={25,20}; overlay.update(ui,s,world)
check(s.hovered==2 and s.selected==1,"Moving within the selection radius previews a different bone without selecting it")
check(near(ui.native.markers[2].mesh.worldBoundRadius*2*zoom,18) and shape2.materialProperty.emissive.r==1
    and shape2.materialProperty.emissive.g==1,"The hovered IK marker enlarges and brightens to pale gold")
check(near(ui.native.markers[1].mesh.worldBoundRadius*2*zoom,16) and shape1.materialProperty.emissive.g==0.8,
    "The selected marker retains its amber selection while another bone is hovered")
check(ui.native.root.children[#ui.native.root.children]==ui.native.markers[2].node,"The hovered marker renders last")
s.cursor={100,-100}; overlay.update(ui,s,world)
check(not s.hovered and shape2.materialProperty.emissive.r==0.3 and near(ui.native.markers[2].mesh.worldBoundRadius*2*zoom,12),
    "Leaving the radius restores the IK marker's cyan color and normal size")
s.locks={[2]=true}; s.cursor={10,20}; overlay.update(ui,s,world)
check(s.hovered==2 and shape2.materialProperty.emissive.r==1,"Locked markers can still be hovered")
s.cursor={100,-100}; overlay.update(ui,s,world)
check(shape2.materialProperty.emissive.r==0.4 and shape2.materialProperty.emissive.g==1,
    "Leaving a locked marker restores its green state")
s.locks=nil; s.cursor={10,20}; s.drag={button=1}; overlay.update(ui,s,world)
check(not s.hovered and near(ui.native.markers[2].mesh.worldBoundRadius*2*zoom,12),"Viewing drags suppress bone hover")
s.drag={button=0,mode="IK"}; overlay.update(ui,s,world)
check(not s.hovered,"Pose drags suppress bone hover")
s.drag=nil; gizmoHover="x"; overlay.update(ui,s,world)
check(not s.hovered,"Gizmo hover takes priority over nearby bone markers")
gizmoHover=nil; overlay.update(ui,s,world)
check(s.hovered==2,"Bone hover resumes after leaving the gizmo")
s.handles=false; overlay.update(ui,s,world)
check(not s.hovered and ui.native.markers[2].node.appCulled,"V hides markers and removes their hover feedback")
s.handles=true; overlay.setVisible(ui,false); overlay.update(ui,s,world)
check(not s.hovered and ui.native.root.appCulled,"Modal visibility removes bone hover")
overlay.setVisible(ui,true); overlay.update(ui,s,world)
check(s.hovered==2,"Closing a dialog restores hover at the current pointer")
zoom=20; overlay.update(ui,s,world)
check(not s.hovered,"Camera zoom resolves hover from fresh projected coordinates")
zoom=10; world[2].translation={8,8,20}; overlay.update(ui,s,world)
check(not s.hovered,"Moving the bone away from a stationary cursor clears hover")
world[2].translation={1,2,20}; offscreen=true; overlay.update(ui,s,world)
check(not s.hovered and ui.native.markers[2].node.appCulled,"Off-screen nodes cannot retain hover")
offscreen=false; world[2].translation={0,0,20}; s.selected=2; s.cursor={0,0}; overlay.update(ui,s,world)
check(s.hovered==2 and ui.native.root.children[#ui.native.root.children]==ui.native.markers[2].node,
    "A selected overlapping pivot owns both hover and draw priority")
s.selected=1; world[2].translation={1,2,20}; overlay.update(ui,s,world)
check(s.hovered==1 and near(ui.native.markers[1].mesh.worldBoundRadius*2*zoom,18),"Hovering the selected marker also enlarges it")
check(clones==hoverClones and shared.emissive.r==0,"Hover reuses private materials without changing the mesh source")
check(ui.cursor.menu.width==32 and ui.cursor.menu.height==32,"The vanilla cursor retains its original 32-pixel dimensions")
check(ui.cursor.menu.positionX==-8 and ui.cursor.menu.positionY==0,"The stock arrow tip coincides with its selection point using the original cursor hotspot")
local previousClones=clones
s.selected=2; zoom=20; world[1].translation={4,5,10}; s.cursor={137,-84}
overlay.update(ui,s,world)
check(ui.cursor.menu.positionX+8==s.cursor[1] and ui.cursor.menu.positionY==s.cursor[2],"Moving the pointer keeps the arrow tip on the bone pick coordinates")
check(clones==previousClones,"Selection and camera updates reuse private materials")
check(same(ui.native.markers[1].mesh.worldBoundOrigin,vec(4,5,10)),"Moving a bone updates the bone marker's actual world center")
check(shape1.materialProperty.emissive.r==0.85 and shape2.materialProperty.emissive.g==0.8,"Selection restores the previous bone marker and highlights the new one")
check(near(ui.native.markers[1].mesh.worldBoundRadius*2*zoom,12) and near(ui.native.markers[2].mesh.worldBoundRadius*2*zoom,16),"Zoom preserves handle size and selected size follows selection")
offscreen=true
overlay.update(ui,s,world)
check(ui.native.markers[2].node.appCulled and s.screen[2]==nil,"Off-screen handles hide and leave the pick list")
overlay.setVisible(ui,false)
check(not ui.menu.visible and not ui.cursor.menu.visible and ui.native.root.appCulled,"Modal UI hides all text and the entire handle group")
w,h=640,480; s.handles=false; s.mode="Rotate"; s.axis="x"
overlay.update(ui,s,world)
check(ui.menu.positionX==-37 and ui.menu.positionY==h/2-12,"Controls adapt to a smaller viewport while retaining their top anchor")
check(ui.rows[8].visible and shows("props"),"Rotation retains eight quick controls including Props")
check(shows("axis") and shows("move") and shows("cycle") and not shows("bend") and not shows("depth"),
    "Rotation shows its axis and mode controls without IK movement controls")
check(ui.rows[2].text=="Hold X / Y / Z: Local rotation axis" and ui.mode.text=="Mode: Rotate (Local X)",
    "The compact guide explains held axes and displays the active local constraint")
overlay.setVisible(ui,true)
local originalMenu,originalBlock=ui.menu,ui.block
local compactHeight=ui.menu.height
w,h=1827,1438; s.expandedControls=true; overlay.update(ui,s,world)
check(created==2 and ui.menu==originalMenu and ui.block==originalBlock and ui.menu.visible,
    "H expands the existing controls and creates no separate help menu")
check(ui.menu.alpha==0 and ui.menu.frameRemoved and not ui.menu.consumeMouseEvents and ui.cursor.menu.visible,
    "Expanded controls keep the same frameless styling and editing pointer")
check(ui.heading.text=="ALL CONTROLS (H / Esc: collapse)" and ui.full.block.visible and not ui.rows[1].visible,
    "Categorized controls replace quick rows inside the default sidebar")
check(ui.mode.text=="Mode: Rotate (Local X)" and ui.focus.text=="Focus: Off (F)" and ui.symmetry.text=="Symmetry: Off (S)",
    "Expanding retains the live bone, transform, focus, and symmetry status")
for i,category in ipairs(controls.categories) do
    check(ui.full.headings[i].text==category.title,"Every control category appears in the existing sidebar")
    local left=category.id=="transform" or category.id=="selection" or category.id=="edit" or category.id=="save" or category.id=="props"
    check(left and ui.full.headings[i].drawX<0 or not left and ui.full.headings[i].drawX>0,
        "Categories balance between the left-side editing controls and right-side modifiers/view")
end
local represented={}
for _,row in ipairs(ui.full.rows) do
    check(row.input.text~="" and row.description.text~="" and row.input.wrapText and row.description.wrapText
        and row.block.autoHeight and row.block.childAlignY==0 and not row.input.consumeMouseEvents
        and not row.description.consumeMouseEvents,
        "Aligned shortcut/action rows size to their text and pass through editing input")
    for _,id in ipairs(row.ids) do represented[id]=true end
end
local dialogControls={blendSources=true,blendAmount=true,blendAccept=true}
for _,entry in ipairs(controls.entries) do
    check(dialogControls[entry.id] and not represented[entry.id] or not dialogControls[entry.id] and represented[entry.id],
        "Expanded controls omit only the three blend-dialog controls: "..entry.id)
end
check(ui.full.block.height>80 and ui.menu.height>compactHeight and ui.menu.height<h-24,
    "At the screenshot resolution every category fits at its natural height without a tiny viewport or scrolling")
local function expandedBounds()
    check(ui.menu.positionX==math.floor(-w/2+12) and math.abs(ui.menu.positionY-ui.menu.height/2)<=0.5
        and ui.menu.positionX+ui.menu.width==math.floor(w/2-12),
        "Expansion centers the same overlay vertically with text at both viewport edges")
    check(ui.left.drawX==math.floor(-w/2+12) and ui.block.drawX+ui.block.width==math.floor(w/2-12)
        and ui.menu.childAlignY==0.5,
        "Both sidebars retain their edge positions and center within the overlay")
    check(math.abs(ui.left.drawY-ui.left.height/2)<=0.5 and math.abs(ui.block.drawY-ui.block.height/2)<=0.5,
        "Each complete sidebar is vertically centered even when their heights differ")
    check(ui.spacer.width>=w*0.3 and ui.left.drawX+ui.left.width<0 and ui.block.drawX>0,
        "A wide empty region between the sidebars reserves the mannequin working area")
    local rendered=0
    local function visibleLabels(e)
        if e.kind=="label" and e.drawn then
            check(e.drawX>=-w/2+12 and e.drawX+e.width<=w/2-12
                and e.drawY<=h/2-12 and e.drawY-e.height>=-h/2+12,
                "Visible control/status text stays inside the viewport: "..e.text)
            rendered=rendered+1
        end
        for _,child in ipairs(e.children) do visibleLabels(child) end
    end
    visibleLabels(ui.menu)
    local hidden=0
    for _,row in ipairs(ui.full.rows) do if not controls.available(row.ids[1],s) then hidden=hidden+2 end end
    for _,note in ipairs(ui.full.notes) do if not note.block.visible then hidden=hidden+1 end end
    check(rendered==7+#ui.full.headings+#ui.full.rows*2+#ui.full.notes-hidden,
        "Every category, shortcut, action, note, and live status is drawn")
end
expandedBounds()
w,h=1920,1080; overlay.update(ui,s,world)
check(ui.menu.height<h-24 and ui.full.block.visible and created==2,
    "The two-sided control list also fits a 1080p viewport without creating menus")
expandedBounds()
w,h=1653,1324; overlay.update(ui,s,world); expandedBounds()
w,h=1772,1439; overlay.update(ui,s,world); expandedBounds()
glyphWidth,lineHeight=10,22
overlay.update(ui,s,world); expandedBounds()
w,h=1920,1080; overlay.update(ui,s,world); expandedBounds()
glyphWidth,lineHeight=8,18
local full=ui.full
s.expandedControls=false; w,h=640,480; overlay.update(ui,s,world)
check(ui.menu.positionX==-37 and ui.menu.visible and ui.menu.width==345 and not full.block.visible and shows("help"),
    "Collapsing restores the compact guide in the same sidebar")
check(not ui.left.visible and not ui.spacer.visible,"Collapsing hides every left-side control")
check(ui.menu.childAlignY==0 and ui.menu.positionY==h/2-12,"Collapsing restores the compact sidebar's top placement")
s.expandedControls=true; overlay.update(ui,s,world)
check(ui.full==full and created==2 and ui.menu.width<=w-24,
    "Repeated expansion reuses the controls and bounds its width on smaller viewports")
s.expandedControls=false; overlay.update(ui,s,world)
overlay.setVisible(ui,false)
check(shows("resetBone") and shows("help") and not shows("resetPose"),"Only the current reset and full-help entry appear in the quick guide")
s.focus={}; overlay.update(ui,s,world)
check(ui.focus.text=="Focus: On (F)",
    "The compact guide shows active focus and its shortcut")
s.focus=nil; overlay.update(ui,s,world)
check(ui.focus.text=="Focus: Off (F)","Leaving focus immediately updates its panel status")
s.axis=nil; overlay.update(ui,s,world)
check(ui.mode.text=="Mode: Rotate (Camera)","Releasing the axis displays camera rotation")
s.drag={button=0,mode="Rotate",axisName="x",totalAngle=math.pi*2.5}
overlay.update(ui,s,world)
check(ui.mode.text=="Mode: Rotate (Local X) | 450.0 deg","A drag shows its frozen local axis and unwrapped angle")
s.axis="z"; s.drag.axisName=nil; s.drag.totalAngle=-math.pi/4
overlay.update(ui,s,world)
check(ui.mode.text=="Mode: Rotate (Camera) | -45.0 deg","A camera drag stays labeled Camera while other axis keys are held")
s.drag.mode="IK"; s.mode="Rotate"; overlay.update(ui,s,world)
check(ui.mode.text=="Mode: IK","A key change cannot relabel an active translation drag as rotation")
check(shows("depth") and shows("bend") and shows("lock") and not shows("axis"),"The guide follows the active drag instead of the next mode setting")
s.drag.poleMode=true; overlay.update(ui,s,world)
check(ui.heading.text=="QUICK CONTROLS: IK BEND" and ui.rows[1].text=="Left drag: Adjust elbow / knee bend" and not shows("bend"),
    "An active pole drag explains its bend action without suggesting another bend toggle")
s.drag={button=1}; overlay.update(ui,s,world)
check(shows("turn") and shows("pan") and shows("zoom") and not shows("resetBone"),"Viewing drags prioritize camera controls")
s.drag=nil; s.axis=nil; overlay.update(ui,s,world)
check(ui.native.root.appCulled and ui.native.markers[1].node.appCulled,"Updates cannot restore handles while modal or toggled off")
s.handles=true; offscreen=false
overlay.setVisible(ui,true); overlay.update(ui,s,world)
check(ui.menu.visible and ui.cursor.menu.visible and not ui.native.root.appCulled and not ui.native.markers[2].node.appCulled,"Text and scene handles return when editing resumes")
check(ui.cursor.menu.alpha==0 and ui.cursor.image.alpha==1,"Resuming after modal UI preserves a visible pointer without its black background")
s.selected=1; overlay.update(ui,s,world)
check(shape2.materialProperty.emissive.r==0.3,"Deselected IK handle returns to cyan")
s.locks={[2]={}}; overlay.update(ui,s,world)
check(shape2.materialProperty.emissive.g==1 and shape2.materialProperty.emissive.r==0.4,"Locked IK handles are green when deselected")
s.selected=2; overlay.update(ui,s,world)
check(shape2.materialProperty.emissive.g==0.8 and ui.bone.text=="LEFT HAND [Locked]" and ui.node.text=="Bip01 L Hand","Selected locks retain amber selection and show their lock state beside the friendly name")
s.locks={}; overlay.update(ui,s,world)
check(ui.bone.text=="LEFT HAND","Unlocking clears the panel's lock indicator")
s.selected=1; overlay.update(ui,s,world)
check(shape2.materialProperty.emissive.r==0.3,"Unlocking restores the ordinary cyan IK handle")
s.mode="IK"; s.chains={}; s.selected=2; overlay.update(ui,s,world)
check(ui.mode.text=="Mode: Rotate (Camera)","G fallback rotation on ordinary bones displays the camera axis")
s.expandedControls=true
s.blendPrompt={percent=73,menu={width=350}}; overlay.setVisible(ui,false,true); overlay.update(ui,s,world)
check(ui.menu.visible and not ui.cursor.menu.visible and ui.native.root.appCulled,
    "Blend preview keeps its guide visible without enabling editing handles or the editing pointer")
check(ui.menu.positionX==-w/2+12 and ui.menu.width<=w/2-24 and ui.mode.text=="Mode: Blend Poses | 73%",
    "The blend guide sits opposite the native blend dialog and displays its mix")
check(ui.menu.positionX+ui.menu.width<w/2-s.blendPrompt.menu.width-12,
    "The compact blend guide reserves the native dialog's actual width on small viewports")
check(shows("blendSources") and shows("blendAmount") and shows("blendAccept") and shows("cancel") and not shows("axis") and not shows("help"),
    "The blend guide shows only controls owned by the blend dialog")
check(not full.block.visible and s.expandedControls,"Blend retains the expansion setting while showing its compact dialog guide")
check(not ui.left.visible and not ui.spacer.visible,"Blend does not leave expanded controls on the left")
s.blendPrompt=nil; overlay.setVisible(ui,true); overlay.update(ui,s,world)
check(full.block.visible and ui.menu==originalMenu and created==2,"Closing Blend restores the expanded controls in their existing sidebar")
s.editFile="pose/k/Edit.nif"; s.editLabel="Guard Stance"
overlay.update(ui,s,world)
check(ui.title.text=="EDIT POSE: Guard Stance","The overlay identifies the pose being edited")

world[0]={translation={0,0,0},rotation={1,0,0,0,1,0,0,0,1},scale=1}
for _,t in ipairs(world) do t.rotation=world[0].rotation; t.scale=1 end
s.props={{id="0001",name="Iron Longsword",attachmentType="bone",parentBone="Bip01 R Hand",translation={10,0,0},rotation=world[0].rotation,scale=1}}
s.propScene={errors={}}; s.selectedProp="0001"; s.mode="Move"; s.expandedControls=false
s.cursor={s.screen[1].x,s.screen[1].y}
overlay.update(ui,s,world)
check(ui.bone.text=="Iron Longsword" and ui.node.text:find("Attached: RIGHT HAND",1,true),"Selected prop shows its own name and attachment in the HUD")
check(ui.heading.text=="QUICK CONTROLS: MOVE PROP" and shows("props") and shows("propAttach") and shows("propDuplicate")
    and shows("propReplace") and shows("propResetScale") and shows("propResetRotation") and shows("propResetTranslation") and shows("propDelete") and shows("propDetach"),
    "Selected props show every contextual action directly in the existing sidebar")
check(ui.symmetry.text=="Selected bone: "..controls.boneName(s.bones[s.selected].name),"The attachment bone remains visible in prop context")
local inactive=ui.native.markers[s.selected].mesh.materialProperty.emissive
check(ui.native.markers[s.selected].state=="inactive" and inactive.b==1 and inactive.r==0.45,
    "The selected inactive bone retains its node with a blue tint")
local propMarker=ui.native.propMarkers["0001"]
check(propMarker and propMarker.mesh.name=="node" and propMarker.mesh.materialProperty~=shape1.materialProperty,
    "Each prop uses its own copy of the same node geometry and material")
check(propMarker.state=="selected" and propMarker.mesh.materialProperty.emissive.g==0.8,
    "The active prop node stays amber alongside the inactive bone")
check(s.propScreen["0001"] and near(propMarker.mesh.worldBoundRadius*2*zoom,16),"Prop nodes project with the same selected diameter as bones")
check(s.hovered==1,"Bone targets remain available during prop editing")
local liveProp={worldTransform={translation=vec(15,4,8),rotation={x=vec(1,0,0),y=vec(0,1,0),z=vec(0,0,1)},scale=1}}
s.propScene.nodes={['0001']=liveProp}; overlay.update(ui,s,world)
check(same(propMarker.mesh.worldBoundOrigin,vec(15,4,8)) and s.propScreen['0001'].x==15*zoom,
    "A live prop's handle follows its world transform under the scene parent's rotated/scaled frame")
s.propScene.nodes={}
s.props[1].attachmentType="root"; s.mode="Scale"; overlay.update(ui,s,world)
check(ui.node.text:find("Free",1,true) and ui.heading.text=="QUICK CONTROLS: SCALE PROP","Free props and scale mode are clearly identified")
check(not shows("propDetach") and shows("propAttach"),"Detach appears only for a bone attachment")
s.cursor={s.propScreen["0001"].x,s.propScreen["0001"].y}; overlay.update(ui,s,world)
check(s.hoveredProp=="0001" and propMarker.state=="hovered" and near(propMarker.mesh.worldBoundRadius*2*zoom,18),"Prop nodes share the bone hover radius, color and sizing")
s.cursor={1000,1000}; s.handles=false; overlay.update(ui,s,world)
check(propMarker.node.appCulled and not s.hoveredProp,"V hides prop nodes and disables their hover")
s.handles=true; overlay.update(ui,s,world)
s.propScene.errors['0001']="Missing mesh"; overlay.update(ui,s,world)
check(ui.node.text:find("Mesh unavailable",1,true),"Missing prop meshes remain selectable and visibly reported")
w,h=1920,1080; glyphWidth,lineHeight=10,22; overlay.update(ui,s,world)
check(ui.menu.height<h-24 and shows("propDelete") and shows("propResetTranslation"),"Every compact prop action fits 1080p with larger text")
s.props[1].attachmentType="bone"; s.props[1].parentBone=s.bones[2].name; overlay.update(ui,s,world)
check(ui.menu.height<h-24 and shows("propDetach"),"All attached-prop compact controls fit 1080p with larger text")
s.props[1].attachmentType="root"
s.expandedControls=true; overlay.update(ui,s,world)
check(ui.menu.height<h-24 and ui.full.block.visible,"Expanded prop controls fit 1080p with larger text")
expandedBounds()
for _,row in ipairs(ui.full.rows) do
    if row.ids[1]=="propDetach" then check(not row.block.visible,"Expanded controls also hide Detach for free props") end
end
s.selectedProp=nil; overlay.update(ui,s,world)
overlay.destroy(ui); overlay.destroy(ui)
check(ui.menu.destroyed and ui.cursor.menu.destroyed and #worldRoot.children==0,"Cleanup removes text and detaches all transient meshes, including repeated cleanup")
missingMesh=true
local ok,problem=pcall(overlay.create,bones,{1,2})
check(not ok and tostring(problem):find("Could not load the bone handle mesh",1,true),"Mesh loading fails visibly instead of leaving invisible widgets")
check(live[prefix.."Controls"]==nil and #worldRoot.children==0,"Failed creation leaves no UI or scene handles")
missingMesh=false; sourceShape.name="old_marker"
ok,problem=pcall(overlay.create,bones,{1,2})
check(not ok and tostring(problem):find("missing its node shape",1,true),"An older gizmo without node fails with a clear shape error")
check(live[prefix.."Controls"]==nil and #worldRoot.children==0,"A missing node shape leaves no UI or scene handles")
print("PASS: "..count.." native bone marker geometry, bounds, depth, material isolation, frameless overlay and lifecycle assertions")
