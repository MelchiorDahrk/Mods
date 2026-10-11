-- Native scene-graph contract mock; all transform math is production code.
local v=require("MannequinPoseDesigner.math3d")
local F={}
local function vector(x,y,z)
    return {x=x or 0,y=y or 0,z=z or 0,copy=function(a) return vector(a.x,a.y,a.z) end}
end
local function matrix(...)
    local a={...}; if #a==0 then a=v.identity() end
    return {x=vector(unpack(a,1,3)),y=vector(unpack(a,4,6)),z=vector(unpack(a,7,9)),
        copy=function() return matrix(unpack(a)) end}
end
tes3vector3={new=vector}; tes3matrix33={new=matrix}
local rig=require("MannequinPoseDesigner.rig")
local props=require("MannequinPoseDesigner.props")
tes3={niType={NiNode="NiNode",RootCollisionNode="RootCollisionNode",NiTriShape="NiTriShape",NiParticles="NiParticles",NiLight="NiLight",
    NiCamera="NiCamera",NiCollisionSwitch="NiCollisionSwitch",NiSortAdjustNode="NiSortAdjustNode",NiBSParticleNode="NiBSParticleNode",NiKeyframeController="NiKeyframeController",NiStringExtraData="NiStringExtraData"}}
mwse={log=function() end}
function F.extra(text)
    local extra={string=text,isInstanceOfType=function(_,kind) return kind=="NiStringExtraData" end}
    function extra:clone()
        local copy=F.extra(self.string)
        if self.next then copy.next=self.next:clone() end
        return copy
    end
    return extra
end
niStringExtraData={new=F.extra}
function F.node(name,kind)
    kind=kind or "NiNode"
    local n={name=name,RTTI={name=kind},children={},translation=vector(),rotation=matrix(),scale=1,appCulled=false}
    -- MWSE exposes the embedded linked-list head even when it has no effects.
    if kind=="NiNode" or kind=="NiBSParticleNode" or kind=="NiCollisionSwitch" or kind=="NiSortAdjustNode" or kind=="RootCollisionNode" then n.effectList={} end
    function n:isInstanceOfType(t)
        return kind==t or t=="NiNode" and (kind=="NiBSParticleNode" or kind=="NiCollisionSwitch" or kind=="NiSortAdjustNode" or kind=="RootCollisionNode")
    end
    function n:removeAllControllers() self.controller=nil end
    function n:detachAllProperties() return {} end
    function n:attachProperty() end
    function n:addExtraData(extra)
        if not self.extraData then self.extraData=extra; return end
        local tail=self.extraData; while tail.next do tail=tail.next end; tail.next=extra
    end
    function n:attachChild(child) assert(not child.parent); self.children[#self.children+1]=child; child.parent=self end
    function n:detachChild(child)
        for i,c in pairs(self.children) do if c==child then self.children[i]=nil; child.parent=nil; return child end end
    end
    function n:clone()
        local c=F.node(self.name,kind)
        c.translation=self.translation:copy(); c.rotation=matrix(unpack(rig.matrix(self.rotation))); c.scale=self.scale
        c.skinInstance=self.skinInstance; c.controller=self.controller; c.effectList=self.effectList
        if self.extraData then c.extraData=self.extraData:clone() end
        for _,child in pairs(self.children) do if child then c:attachChild(child:clone()) end end
        return c
    end
    function n:update()
        local t={translation=rig.vector(self.translation),rotation=rig.matrix(self.rotation),scale=self.scale}
        if self.parent then t=props.compose(props.nodeTransform(self.parent),t) end
        self.worldTransform={translation=vector(unpack(t.translation)),rotation=matrix(unpack(t.rotation)),scale=t.scale}
        for _,child in pairs(self.children) do if child then child:update() end end
    end
    return n
end
niNode={new=function() return F.node("") end}
niCollisionSwitch={new=function() return F.node("","NiCollisionSwitch") end}
function F.mesh()
    local root=F.node("Inventory Root")
    root:attachChild(F.node("Mesh","NiTriShape"))
    return root
end
function F.scene(bones)
    local root=F.node("Pose Root")
    local nodes={}
    for i,b in ipairs(bones) do
        nodes[i]=F.node(b.name); props.apply(b,nodes[i])
        nodes[i].controller={isInstanceOfType=function(_,kind) return kind=="NiKeyframeController" end}
        (b.parent==0 and root or nodes[b.parent]):attachChild(nodes[i])
    end
    root:update()
    return root,nodes
end
function F.installLoader()
    tes3.loadMesh=function(path) if path=="missing.nif" then error("Missing mesh") end; return F.mesh() end
end
return F
