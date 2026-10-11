-- The author's NIF is a temporary control under the handle root.
local v=require("MannequinPoseDesigner.math3d")
local rig=require("MannequinPoseDesigner.rig")
local props=require("MannequinPoseDesigner.props")
local constraintMath=require("MannequinPoseDesigner.gizmo_math")
local picking=require("MannequinPoseDesigner.gizmo_picking")
local M={}
local shapeNames={X_move={mode="move",axis="x"},Y_move={mode="move",axis="y"},Z_move={mode="move",axis="z"},
    X={mode="rotate",axis="x"},Y={mode="rotate",axis="y"},Z={mode="rotate",axis="z"}}
local path="pose\\h\\gizmo.nif"
local function setHighlight(self,entry)
    if self.highlighted==entry then return end
    if self.highlighted then
        self.highlighted.shape.materialProperty=self.highlighted.material
    end
    if entry then
        if not entry.highlightMaterial then
            local material=entry.material:clone()
            local color=niColor.new(1,0.85,0.25)
            material.diffuse=color
            material.emissive=color
            entry.highlightMaterial=material
        end
        entry.shape.materialProperty=entry.highlightMaterial
    end
    self.highlighted=entry
    self.root:updateProperties()
end
function M.create(parent)
    local self={root=niNode.new(),components={move={},rotate={}},byShape={},masks={},occluders={}}
    local geometry={}
    local function pickGeometry(shape)
        local data=shape.data
        if data and geometry[data]==nil then
            local ok,result=pcall(picking.geometry,data)
            geometry[data]=ok and result or false
            if not ok then
                self.fuzzyUnavailable=true
                mwse.log("[OAAB Pose Designer] Fuzzy ring picking unavailable for %s; retaining exact picking: %s",shape.name,tostring(result))
            end
        end
        return data and geometry[data] or nil
    end
    self.root.name="OAAB:MannequinPoseDesigner:Gizmo"
    self.root.appCulled=true
    -- The uncached loader already returns a session-owned graph. Use that
    -- graph directly, including the loaded NiSortAdjustNode accumulator.
    local mesh=assert(tes3.loadMesh(path,false),"Could not load transform gizmo: "..path)
    mesh:update()
    self.extent=mesh.worldBoundRadius+v.length(rig.vector(mesh.worldBoundOrigin))
    local function prepare(shape)
        if not shape then return end
        if shape.name=="sphere" then
            -- The mask follows the rings, independently of their shared
            -- sorting parent, which also contains the movement arrows.
            shape.appCulled=false
            self.masks[#self.masks+1]=shape
            self.occluders[#self.occluders+1]={shape=shape,geometry=pickGeometry(shape)}
            return
        end
        if shape:isInstanceOfType(tes3.niType.NiTriShape) then
            if shape.name=="node" then
                -- Bone markers clone this separately at their own screen size.
                shape.appCulled=true
                return
            end
            local definition=shapeNames[shape.name]
            assert(definition,"Invalid gizmo component: "..tostring(shape.name))
            -- Keep the authored material for idle rendering. Hover/drag uses
            -- a temporary private copy and restores this exact property.
            local entry={shape=shape,material=assert(shape.materialProperty,"Missing gizmo material"),
                mode=definition.mode,axis=definition.axis}
            assert(not self.components[entry.mode][entry.axis],"Duplicate gizmo component")
            self.components[entry.mode][entry.axis]=entry
            self.byShape[shape.name]=entry
            if entry.mode=="rotate" then
                self.radius=math.max(self.radius or 0,shape.worldBoundRadius)
                entry.geometry=pickGeometry(shape)
            end
            shape.appCulled=entry.mode=="move"
        elseif shape:isInstanceOfType(tes3.niType.NiNode) then
            -- Retain authored grouping, per-shape rotations, and inherited scales.
            if shape.name=="rotate" then
                assert(shape:isInstanceOfType(tes3.niType.NiSortAdjustNode),"The rotation group must retain its NiSortAdjustNode")
                assert(not self.rotationGroup,"Duplicate gizmo rotation group")
                self.rotationGroup=shape
                shape.appCulled=false
            end
            for _,child in pairs(shape.children) do prepare(child) end
        else
            error("Unsupported gizmo node: "..tostring(shape.name))
        end
    end
    prepare(mesh)
    for _,mode in ipairs({"move","rotate"}) do for _,axis in ipairs({"x","y","z"}) do
        assert(self.components[mode][axis],"Missing gizmo component: "..mode.." "..axis)
    end end
    assert(self.rotationGroup and #self.masks>0,"The gizmo NIF is missing its rotation group or mask")
    assert(self.radius and self.radius>0 and self.extent>0,"The gizmo NIF has no usable bounds")
    self.mesh=mesh; self.root:attachChild(mesh)
    parent:attachChild(self.root)
    -- Resolve authored property inheritance after attaching the complete graph.
    self.root:updateProperties()
    return self
end
function M.ray(cursor)
    local camera=tes3.getCamera()
    local origin,direction=camera:windowPointToRay(cursor)
    if origin and direction then return rig.vector(origin),v.unit(rig.vector(direction)) end
end
function M.pick(self,cursor)
    if not self or not self.root.parent or self.root.appCulled or self.root.parent.appCulled then return end
    local camera=tes3.getCamera()
    local origin,direction=camera:windowPointToRay(cursor)
    if not origin or not direction then return end
    local hit=tes3.rayTest({position=origin,direction=direction,root=self.root,
        useBackTriangles=true,maxDistance=self.maxDistance})
    local entry=hit and hit.object and self.byShape[hit.object.name]
    local masks=self.mode=="rotate" and not self.fuzzyUnavailable and picking.prepareMasks(self.occluders) or {}
    if entry and entry.mode==self.mode
        and (not hit.intersection or not picking.masked(rig.vector(origin),rig.vector(hit.intersection),masks)) then
        return entry.axis
    end
    if self.mode=="rotate" and not self.fuzzyUnavailable then
        return picking.fuzzy(self.components.rotate,cursor,camera,masks)
    end
end
function M.update(self,s,world)
    local drag=s.drag and s.drag.button==0 and s.drag
    local prop=props.get(s)
    local transform=world[s.selected]
    if prop then
        local node=s.propScene.nodes[prop.id]
        transform=node and props.nodeTransform(node)
    end
    local mode=drag and drag.mode or s.mode
    if mode=="Scale" or not transform or not s.handles then self.root.appCulled=true; setHighlight(self); return end
    local moving=mode=="Move" or (mode=="IK" and (s.chains[s.selected] or s.bones[s.selected].parent==0))
    self.mode=moving and "move" or "rotate"
    local center=drag and drag.poleMode and drag.pole or transform.translation
    local camera=tes3.getCamera()
    local position=rig.engineVector(center)
    local p=camera:worldPointToScreenPoint(position)
    local sample=p and (camera:worldPointToScreenPoint(position+camera.worldUp)
        or camera:worldPointToScreenPoint(position-camera.worldUp))
    if not sample then self.root.appCulled=true; setHighlight(self); return end
    local pixels=((sample.x-p.x)^2+(sample.y-p.y)^2)^0.5
    if pixels<1e-5 then self.root.appCulled=true; setHighlight(self); return end
    local parent=props.nodeTransform(self.root.parent)
    local inverse=v.transpose(parent.rotation)
    -- Keep the starting axes fixed during a constraint drag.
    local rotation=drag and drag.constraint and drag.constraint.rotation or transform.rotation
    self.root.translation=rig.engineVector(v.scale(v.transform(inverse,v.sub(center,parent.translation)),1/parent.scale))
    self.root.rotation=rig.engineMatrix(v.mul(inverse,rotation))
    self.root.scale=70/(self.radius*pixels*parent.scale)
    self.maxDistance=v.length(v.sub(center,rig.vector(camera.worldTransform.translation)))+self.extent*70/(self.radius*pixels)
    self.root.appCulled=false
    -- Both modes live beneath the same authored sorting node. Keep that
    -- parent active and show the sphere only with the rotation rings.
    for mode,entries in pairs(self.components) do
        for _,entry in pairs(entries) do entry.shape.appCulled=self.mode~=mode end
    end
    for _,shape in ipairs(self.masks) do shape.appCulled=self.mode~="rotate" end
    self.root:update(); self.root:updateEffects()
    local selected=drag and drag.constraint and drag.constraint.component
        or (not s.drag and M.pick(self,s.cursor))
    setHighlight(self,selected and self.components[self.mode][selected] or nil)
    return selected
end
function M.begin(self,s,transform)
    local component=M.pick(self,s.cursor)
    if not component then return end
    local origin,direction=M.ray(s.cursor)
    if not origin then return end
    return constraintMath.begin(self.mode,component,transform.translation,transform.rotation,origin,direction),component
end
function M.destroy(self)
    if self then
        self.root.appCulled=true
        setHighlight(self)
        if self.root.parent then self.root.parent:detachChild(self.root) end
    end
end
return M
