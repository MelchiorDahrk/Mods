-- Native scene API fixture shared by viewer and menu lifecycle tests. This
-- models graph ownership/API use, not the engine's final image or projection.
local math3d=require("MannequinPoseDesigner.math3d")
local M={}
function M.install()
    local state={loads={},poses={},bodies={},hosts={},lights={},exists=true}
    local function vector(x,y,z)
        local v={x=x or 0,y=y or 0,z=z or 0}
        function v:copy() return vector(self.x,self.y,self.z) end
        return v
    end
    local function matrix(...)
        local m={...}; if #m==0 then m=math3d.identity() end
        m.x=vector(m[1],m[2],m[3]); m.y=vector(m[4],m[5],m[6]); m.z=vector(m[7],m[8],m[9])
        function m:copy() return matrix(unpack(self)) end
        return m
    end
    tes3vector3={new=vector}
    tes3matrix33={new=matrix}
    niColor={new=function(r,g,b) return {r=r,g=g,b=b} end}
    ni={sourceVertexMode={ambDiff=2},lightingMode={emiAmbDif=1},zBufferPropertyTestFunction={lessEqual=3}}
    tes3.niType={NiNode="NiNode",NiCollisionSwitch="NiCollisionSwitch",RootCollisionNode="RootCollisionNode"}
    local function node(kind)
        local n={kind=kind or "NiNode",children={},properties={},effects={},affected={},updates={},
            translation=vector(),rotation=matrix(),scale=1,appCulled=false,controller={}}
        function n:isInstanceOfType(t) return self.kind==t or (t=="NiNode" and (self.kind=="RootCollisionNode" or self.kind=="NiCollisionSwitch")) end
        function n:attachChild(child) assert(not child.parent,"Mesh must have a single owner"); child.parent=self; self.children[#self.children+1]=child end
        function n:attachProperty(property) self.properties[#self.properties+1]=property end
        function n:attachEffect(effect) self.effects[effect]=true end
        function n:detachEffect(effect) self.effects[effect]=nil end
        function n:attachAffectedNode(affected) self.affected[affected]=true end
        function n:detachAffectedNode(affected) self.affected[affected]=nil end
        function n:setRadius(radius) self.radius=radius end
        function n:updateProperties() self.propertiesUpdated=true end
        function n:updateEffects() self.effectsUpdated=true end
        function n:removeAllControllers() self.controller=nil; self.frozen=true end
        function n:update(options)
            options=options or {controllers=false}
            self.updates[#self.updates+1]=options
            if self.parent then
                local p=self.parent.worldTransform
                local r=math3d.mul(p.rotation,self.rotation)
                local t=math3d.add({p.translation.x,p.translation.y,p.translation.z},math3d.scale(math3d.transform(p.rotation,{self.translation.x,self.translation.y,self.translation.z}),p.scale))
                self.worldTransform={rotation=matrix(unpack(r)),translation=vector(unpack(t)),scale=p.scale*self.scale}
            else
                self.worldTransform={rotation=self.rotation:copy(),translation=self.translation:copy(),scale=self.scale}
            end
            for _,child in pairs(self.children) do child:update(options) end
        end
        function n:createBoundingBox(options)
            assert(options.accurateSkinned and options.observeAppCullFlag and options.onlyActiveChildren,"Must measure posed/visible geometry")
            assert(#self.updates>0,"Scene transforms must update before measurement")
            self.boundsOptions=options
            if state.bounds then return state.bounds end
            local lo,hi={math.huge,math.huge,math.huge},{-math.huge,-math.huge,-math.huge}
            local function visit(child,translation,rotation,scale)
                if child.appCulled then return end
                if child.kind=="NiCollisionSwitch" and not child.collisionActive then return end
                for _,point in ipairs(child.deform and child.deform() or child.vertices or {}) do
                    local transformed=math3d.add(translation,math3d.scale(math3d.transform(rotation,point),scale))
                    for i=1,3 do lo[i]=math.min(lo[i],transformed[i]); hi[i]=math.max(hi[i],transformed[i]) end
                end
                for _,sub in pairs(child.children) do
                    local t={sub.translation.x,sub.translation.y,sub.translation.z}
                    visit(sub,math3d.add(translation,math3d.scale(math3d.transform(rotation,t),scale)),math3d.mul(rotation,sub.rotation),scale*sub.scale)
                end
            end
            visit(self,{0,0,0},math3d.identity(),1)
            return {min=vector(unpack(lo)),max=vector(unpack(hi))}
        end
        return n
    end
    state.node=node
    niNode={new=node}
    niVertexColorProperty={new=function() return {kind="VertexColor"} end}
    niZBufferProperty={new=function()
        local p={kind="ZBuffer",flags={}}
        function p:setFlag(value,bit) self.flags[bit]=value end
        return p
    end}
    niPointLight={new=function() local n=node("PointLight"); state.lights[#state.lights+1]=n; return n end}
    tes3.getFileExists=function(file)
        assert(file:sub(1,7)=="Meshes/","Existence path is relative to Data Files")
        return state.exists and file~=state.missing
    end
    tes3.loadMesh=function(file,cache)
        assert(cache==false,"A viewer must not mutate cached meshes")
        assert(file:sub(1,7)~="meshes/" and not file:find("xp_",1,true),"Load the main NIF relative to Meshes")
        if state.loadError then error(state.loadError) end
        if state.noMesh then return nil end
        local mesh=node(); mesh.name=file
        local isBody=file=="oaab/b/mannequin.nif"
        local bip=node(); bip.name="Bip01"; mesh:attachChild(bip)
        local bones={bip}
        for i=2,35 do local bone=node(); bone.name="Bip01 Bone "..i; bip:attachChild(bone); bones[i]=bone end
        if isBody then
            local shape=node("NiTriShape"); shape.name="Visible skinned body"
            shape.vertices=state.vertices or {{-20,-10,0},{20,10,120}}
            -- Rigid weights to Bip01 suffice to exercise skin movement in this
            -- API/lifecycle fixture; the real-asset test checks all body weights.
            bip:attachChild(shape)
            local entry={file=file,cache=cache,mesh=mesh,shape=shape,bones=bones}
            state.loads[#state.loads+1]=entry; state.bodies[#state.bodies+1]=entry
            if state.missingBone then bones[state.missingBone].name="Wrong bone" end
            return mesh
        end
        if state.rootTransform then
            mesh.rotation=matrix(unpack(state.rootTransform.rotation))
            mesh.translation=vector(state.rootTransform.translation.x,state.rootTransform.translation.y,state.rootTransform.translation.z)
            mesh.scale=state.rootTransform.scale
        end
        if state.bipTranslation then bip.translation=vector(unpack(state.bipTranslation)) end
        -- Actual animation NIFs supply a culled shadow, not visible body skin.
        local shadow=node("NiTriShape"); shadow.name="Tri Shadow"; shadow.appCulled=true
        shadow.vertices={{-40,-20,0},{40,20,150}}; mesh:attachChild(shadow)
        local prop=node("NiCollisionSwitch"); prop.name="OAAB Prop Visual"; prop.collisionActive=false
        prop.vertices=state.prop or {{0,-5,70},{65,5,140}}
        -- The real wrapper has a separate NiCollisionSwitch below this node.
        local wrapper=node(); wrapper.name="OAAB Pose Prop cube"; wrapper:attachChild(prop); bip:attachChild(wrapper)
        local collision=node("RootCollisionNode"); collision.vertices={{-10000,-10000,-10000},{10000,10000,10000}}
        mesh:attachChild(collision)
        local entry={file=file,cache=cache,mesh=mesh,prop=prop,collision=collision,shadow=shadow,bones=bones}
        state.loads[#state.loads+1]=entry; state.poses[#state.poses+1]=entry
        return mesh
    end
    function state.canvas(element)
        local root=node(); root.name="Native UI canvas"
        -- Native UI transforms must survive preview fitting unchanged.
        root.rotation=matrix(unpack(math3d.axisAngle({1,0,0},math.rad(-90))))
        root.translation=vector(100,200,10)
        element.sceneNode=root; state.hosts[#state.hosts+1]=root
        return element
    end
    return state
end
return M
