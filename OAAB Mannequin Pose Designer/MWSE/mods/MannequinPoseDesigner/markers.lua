-- Real scene geometry for bone handles. UI NIF widgets use the menu renderer's
-- model loader and fixed-frame menus leave background geometry behind.
local picking=require("MannequinPoseDesigner.bone_picking")
local props=require("MannequinPoseDesigner.props")
local M={}
local path="pose\\h\\gizmo.nif" -- loadMesh paths are relative to meshes.
local colors={normal={0.85,0.85,0.85},ik={0.3,0.9,1},locked={0.4,1,0.4},selected={1,0.8,0.2},inactive={0.45,0.6,1},hovered={1,1,0.5}}

local function prepare(mesh)
    local materials={}
    local function visit(node,source)
        if not node then return end
        source=node.materialProperty or source
        if node:isInstanceOfType(tes3.niType.NiTriShape) then
            local material=source and source:clone() or niMaterialProperty.new()
            material.alpha=1
            node.materialProperty=material
            local depth=niZBufferProperty.new()
            depth.propertyFlags=1 -- Test enabled, writes disabled.
            depth.testFunction=ni.zBufferPropertyTestFunction.always
            node.zBufferProperty=depth
            local alpha=niAlphaProperty.new()
            alpha.propertyFlags=237 -- Blend source alpha / inverse source alpha.
            node.alphaProperty=alpha -- Draw in the alpha pass, after opaque world meshes.
            materials[#materials+1]=material
        elseif node:isInstanceOfType(tes3.niType.NiNode) then
            for _,child in pairs(node.children) do visit(child,source) end
        end
    end
    visit(mesh)
    assert(#materials>0,"The bone handle contains no renderable shapes")
    mesh:updateProperties()
    return materials
end

function M.create(indices)
    local source=assert(tes3.loadMesh(path,false),"Could not load the bone handle mesh: "..path)
    source:update()
    local template
    local function find(node)
        if node:isInstanceOfType(tes3.niType.NiTriShape) and node.name=="node" then
            assert(not template,"The gizmo NIF contains duplicate node shapes")
            template=node
        elseif node:isInstanceOfType(tes3.niType.NiNode) then
            for _,child in pairs(node.children) do if child then find(child) end end
        end
    end
    find(source)
    assert(template,"The gizmo NIF is missing its node shape")
    local radius=template.worldBoundRadius
    assert(radius and radius>0,"The node shape has no usable bounds")
    local center=template.worldBoundOrigin:copy()
    local frame=template.worldTransform
    local self={root=niNode.new(),source=source,markers={},propMarkers={},indices=indices,radius=radius}
    self.root.name="OAAB:MannequinPoseDesigner:Handles"
    self.root.appCulled=true
    function self:createMarker(name)
        local mesh=template:clone()
        -- Clone only the marker, retaining its complete authored transform.
        mesh.translation=frame.translation-center
        mesh.rotation=frame.rotation:copy()
        mesh.scale=frame.scale
        mesh.appCulled=false
        local node=niNode.new()
        node.name=name
        node.appCulled=true
        node:attachChild(mesh)
        self.root:attachChild(node)
        return {node=node,mesh=mesh,materials=prepare(mesh)}
    end
    for _,i in ipairs(indices) do
        self.markers[i]=self:createMarker("OAAB:MannequinPoseDesigner:Bone:"..i)
    end
    local parent=assert(tes3.worldController.worldCamera.root,"The world scene is unavailable")
    parent:attachChild(self.root)
    self.root:update()
    if mwse then
        mwse.log("[OAAB Pose Designer] Bone scene handles: mesh=%s, shape=node, handles=%d, source radius=%.4f, attached=%s",
            path,#indices,radius,tostring(self.root.parent~=nil))
    end
    return self
end

function M.setVisible(self,value)
    self.visible=value
    self.root.appCulled=not value
end

function M.update(self,s,world,hoverAllowed)
    local selected=s.selected
    local camera=tes3.getCamera()
    local inverse,valid=self.root.worldTransform:invert()
    assert(valid,"The handle scene transform cannot be inverted")
    local parentScale=self.root.worldTransform.scale
    s.screen={}; s.propScreen={}
    local targets,retained={},{}
    for _,i in ipairs(self.indices) do
        local position=tes3vector3.new(unpack(world[i].translation))
        s.screen[i]=camera:worldPointToScreenPoint(position)
        targets[#targets+1]={marker=self.markers[i],position=position,screen=s.screen[i],selected=i==selected,
            locked=s.locks and s.locks[i],ik=s.chains[i],bone=i}
    end
    for _,p in ipairs(s.props or {}) do
        retained[p.id]=true
        local marker=self.propMarkers[p.id]
        if not marker then
            marker=self:createMarker("OAAB:MannequinPoseDesigner:Prop:"..p.id)
            self.propMarkers[p.id]=marker
        end
        -- Definitions also provide a handle when a source mesh is unavailable.
        local parent=world[0]
        if p.attachmentType=="bone" then
            for i,b in ipairs(s.bones) do if b.name:lower()==p.parentBone:lower() then parent=world[i]; break end end
        end
        local live=s.propScene and s.propScene.nodes and s.propScene.nodes[p.id]
        local transform=live and props.nodeTransform(live) or props.compose(parent,p)
        local position=tes3vector3.new(unpack(transform.translation))
        s.propScreen[p.id]=camera:worldPointToScreenPoint(position)
        targets[#targets+1]={marker=marker,position=position,screen=s.propScreen[p.id],selected=p.id==s.selectedProp,prop=p.id}
    end
    for id,marker in pairs(self.propMarkers) do
        if not retained[id] then
            self.root:detachChild(marker.node); self.propMarkers[id]=nil
            if self.foreground==marker then self.foreground=nil end
        end
    end
    -- Resolve hover after projecting every target with this frame's camera.
    s.hovered,s.hoveredProp=nil,nil
    if self.visible~=false and not s.drag and hoverAllowed~=false then s.hovered,s.hoveredProp=picking.target(s,false,self.indices) end
    for _,target in ipairs(targets) do
        local marker,position,p=target.marker,target.position,target.screen
        local hovered=target.bone and target.bone==s.hovered or target.prop and target.prop==s.hoveredProp
        marker.node.appCulled=not (p and s.handles)
        if p then
            marker.node.translation=inverse*position
            local sample=camera:worldPointToScreenPoint(position+camera.worldUp)
                or camera:worldPointToScreenPoint(position-camera.worldUp)
            if sample then
                local pixels=math.sqrt((sample.x-p.x)^2+(sample.y-p.y)^2)
                if pixels>0 then
                    local size=hovered and 18 or (target.selected and 16 or 12)
                    marker.node.scale=size/(2*self.radius*pixels*parentScale)
                end
            end
        end
        local state=target.selected and target.bone and s.selectedProp and "inactive" or hovered and "hovered"
            or (target.selected and "selected" or (target.locked and "locked" or (target.ik and "ik" or "normal")))
        if marker.state~=state then
            local color=niColor.new(unpack(colors[state]))
            for _,material in ipairs(marker.materials) do
                material.diffuse=color
                material.emissive=color
            end
            marker.state=state
        end
    end
    local foreground=s.hoveredProp and self.propMarkers[s.hoveredProp] or s.hovered and self.markers[s.hovered]
        or s.selectedProp and self.propMarkers[s.selectedProp] or self.markers[selected]
    if self.foreground~=foreground then
        local marker=foreground
        if marker then
            -- Render the hovered/selected marker last when joints share a pivot.
            self.root:detachChild(marker.node)
            self.root:attachChild(marker.node)
        end
        self.foreground=foreground
    end
    self.root:update()
    self.root:updateEffects()
    self.root.appCulled=self.visible==false
end

function M.destroy(self)
    if not self or self.destroyed then return end
    self.destroyed=true
    local parent=self.root.parent
    if parent then parent:detachChild(self.root) end
    self.markers={}
    self.propMarkers={}; self.source=nil; self.createMarker=nil
end

return M
