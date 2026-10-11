-- Native scene attachment and parent transforms for the temporary focus floor.
local v=require("MannequinPoseDesigner.math3d")
local F={floors={},loads=0,meshes={}}
local propertyNames={"alphaProperty","materialProperty","vertexColorProperty","zBufferProperty"}
local function updateProperties(node)
    node.renderProperties={}
    for _,name in ipairs(propertyNames) do
        local current=node
        while current do
            if current[name] then node.renderProperties[name]=current[name]; break end
            current=current.parent
        end
    end
    node.propertyUpdates=(node.propertyUpdates or 0)+1
    for _,child in pairs(node.children or {}) do if child then updateProperties(child) end end
end
function F.fragmentAlpha(mesh,alpha,depth,occluderDepth)
    local properties=mesh.renderProperties
    local z=properties.zBufferProperty
    if z.propertyFlags%2==1 and z.testFunction==3 and depth>occluderDepth then return 0 end
    if properties.alphaProperty.propertyFlags%2==0 then return 1 end
    if properties.vertexColorProperty.source==0 then return properties.materialProperty.alpha end
    return alpha*properties.materialProperty.alpha
end
function F.install(root,lighting)
    local function attach(parent,child)
        parent.children[#parent.children+1]=child
        child.parent=parent
        updateProperties(parent) -- Native attachChild propagates inherited properties.
    end
    local function detach(parent,child)
        for i,value in pairs(parent.children) do
            if value==child then
                if parent==root then parent.children[i]=nil else table.remove(parent.children,i) end
                break
            end
        end
        child.parent=nil
    end
    root.attachChild=attach; root.detachChild=detach
    -- A direct world-root child must not rely on defaults for a normal cell mesh.
    root.alphaProperty={propertyFlags=0}
    root.vertexColorProperty={source=0,lighting=1}
    root.zBufferProperty={propertyFlags=0,testFunction=0}
    root.worldTransform={translation=lighting.vector(0,0,0),rotation=v.identity(),scale=1,
        invert=function(t)
            local rotation=v.transpose(t.rotation)
            local position={t.translation.x,t.translation.y,t.translation.z}
            local inverse={rotation=rotation,scale=1/t.scale}
            return setmetatable(inverse,{__mul=function(_,point)
                local result=v.scale(v.transform(rotation,v.sub({point.x,point.y,point.z},position)),1/t.scale)
                return lighting.vector(unpack(result))
            end}),true
        end}
    niCollisionSwitch={new=function()
        local floor=lighting.node({children={},appCulled=false})
        floor.attachChild=attach; floor.detachChild=detach
        floor.updateProperties=updateProperties
        function floor:isInstanceOfType(kind) return kind==tes3.niType.NiNode end
        function floor:update(args)
            assert(args.controllers==false,"The floor must not advance animation controllers")
            local frame=self.parent.worldTransform
            local position=v.add({frame.translation.x,frame.translation.y,frame.translation.z},
                v.scale(v.transform(frame.rotation,{self.translation.x,self.translation.y,self.translation.z}),frame.scale))
            self.worldBoundOrigin=lighting.vector(unpack(position))
            self.worldTransform={translation=self.worldBoundOrigin,rotation=v.mul(frame.rotation,self.rotation),scale=frame.scale*self.scale}
            local mesh=self.children[1]
            local segments=require("MannequinPoseDesigner.nif").gridSegments
            self.worldBoundRadius=mesh and (mesh.vertexCount/segments-2)*self.worldTransform.scale or 0
        end
        F.floors[#F.floors+1]=floor
        return floor
    end}
    ni={sourceVertexMode={ignore=0,ambDiff=2},lightingMode={emiAmbDif=1},zBufferPropertyTestFunction={always=0,lessEqual=3}}
    niVertexColorProperty={new=function() return {source=0,lighting=1} end}
    niZBufferProperty={new=function() return {propertyFlags=0,testFunction=0} end}
    -- Exercise the real geometry selection while replacing only its disk bridge.
    require("MannequinPoseDesigner.focus_grid").load=function(count)
        return assert(tes3.loadMesh("pose/h/c/focus_grid_"..count..".nif",false),"Could not load the focus grid")
    end
    tes3.loadMesh=function(path,cache)
        local count=assert(tonumber(path:match("^pose/h/c/focus_grid_(%d+)%.nif$")),"Load the generated grid")
        assert(cache==false,"Load the generated grid without caching")
        F.loads=F.loads+1
        if count==F.rejectVertexCount then error("The focus grid loaded with invalid native links") end
        local mesh={name="Grid",appCulled=false,children={},
            alphaProperty={propertyFlags=8429,alphaTestRef=0},materialProperty={alpha=0.5},
            vertexColorProperty={source=1,lighting=0},zBufferProperty={propertyFlags=1,testFunction=3},
            vertexColors={{a=0},{a=0.1},{a=0.2},{a=0}},vertexCount=count}
        F.meshes[#F.meshes+1]=mesh
        return mesh
    end
end
return F
