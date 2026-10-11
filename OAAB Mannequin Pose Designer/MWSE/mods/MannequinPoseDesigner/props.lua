-- Editable definitions contain only plain values. Native nodes live separately.
local v=require("MannequinPoseDesigner.math3d")
local rig=require("MannequinPoseDesigner.rig")
local highlight=require("MannequinPoseDesigner.highlight")
local M={prefix="OAAB Pose Prop "}
local function log(format,...)
    mwse.log("[OAAB Pose Designer Props] "..format,...)
end
local function finite(n) return type(n)=="number" and n==n and math.abs(n)<1e10 end
local function array(a,size)
    assert(type(a)=="table" and #a==size,"Invalid prop transform")
    for i=1,size do assert(finite(a[i]),"Non-finite prop transform") end
    return v.copy(a)
end
local function rotation(a)
    local copy=array(a,9)
    local normalized=v.orthonormalize(copy)
    for i=1,9 do assert(math.abs(copy[i]-normalized[i])<1e-3,"Invalid prop rotation matrix") end
    return copy
end
local function close(a,b,epsilon)
    -- Native node/NIF transforms use floats; tolerate their relative precision
    -- even when a valid free prop is far from the mannequin's origin.
    return math.abs(a-b)<=(epsilon or 1e-4)+math.abs(b)*2e-7
end
function M.meshPath(path)
    assert(type(path)=="string","Prop has no mesh")
    path=path:gsub("\\","/"):gsub("^[Mm][Ee][Ss][Hh][Ee][Ss]/","")
    assert(path~="" and not path:find(":",1,true) and path:sub(1,1)~="/"
        and not path:find("%c") and path:lower():match("%.nif$"),"Invalid prop mesh path")
    for part in path:gmatch("[^/]+") do assert(part~=".." and part~=".","Invalid prop mesh path") end
    return path
end
function M.clone(definitions)
    local out,ids={},{}
    for _,p in ipairs(definitions or {}) do
        assert(type(p.id)=="string" and p.id:match("^[%w_%-]+$") and #p.id<=64 and not ids[p.id],"Invalid/duplicate prop ID")
        assert(type(p.objectId)=="string" and type(p.name)=="string","Invalid prop source")
        assert(p.attachmentType=="root" or p.attachmentType=="bone","Unsupported prop attachment")
        assert(p.attachmentType~="bone" or type(p.parentBone)=="string","Missing prop parent")
        assert(finite(p.scale) and p.scale>1e-6,"Invalid prop scale")
        ids[p.id]=true
        out[#out+1]={id=p.id,objectId=p.objectId,mesh=M.meshPath(p.mesh),name=p.name,
            attachmentType=p.attachmentType,parentBone=p.parentBone,
            translation=array(p.translation,3),rotation=rotation(p.rotation),scale=p.scale}
    end
    return out
end
function M.get(s,id)
    id=id or s.selectedProp
    for i,p in ipairs(s.props or {}) do if p.id==id then return p,i end end
end
local function nextId(s)
    repeat s.propSerial=(s.propSerial or 0)+1 until not M.get(s,string.format("%04d",s.propSerial))
    return string.format("%04d",s.propSerial)
end
function M.new(s,item)
    local p={id=nextId(s),objectId=item.id,mesh=M.meshPath(item.mesh),name=item.name or item.id,
        attachmentType="root",translation={0,0,0},rotation=v.identity(),scale=1}
    return M.clone({p})[1]
end
function M.nodeTransform(node)
    local t=node.worldTransform
    return {translation=rig.vector(t.translation),rotation=rig.matrix(t.rotation),scale=t.scale}
end
function M.compose(parent,localTransform)
    return {translation=v.add(parent.translation,v.scale(v.transform(parent.rotation,localTransform.translation),parent.scale)),
        rotation=v.mul(parent.rotation,localTransform.rotation),scale=parent.scale*localTransform.scale}
end
function M.relative(world,parent)
    assert(finite(parent.scale) and parent.scale>1e-6,"Prop parent has an invalid scale")
    local inverse=v.transpose(parent.rotation)
    return {translation=v.scale(v.transform(inverse,v.sub(world.translation,parent.translation)),1/parent.scale),
        rotation=v.orthonormalize(v.mul(inverse,world.rotation)),scale=world.scale/parent.scale}
end
function M.apply(p,node)
    node.translation=rig.engineVector(p.translation)
    node.rotation=rig.engineMatrix(p.rotation)
    node.scale=p.scale
end
local function shapeCount(node)
    if node:isInstanceOfType(tes3.niType.NiTriShape) then return 1 end
    local count=0
    if node:isInstanceOfType(tes3.niType.NiNode) then
        for _,child in pairs(node.children) do if child then count=count+shapeCount(child) end end
    end
    return count
end
local function kind(node,name)
    local types=tes3.niType
    return types[name] and node:isInstanceOfType(types[name])
end
local function collision(node)
    return kind(node,"RootCollisionNode") or node.RTTI and node.RTTI.name=="RootCollisionNode"
        or (node.name or ""):lower()=="rootcollisionnode"
end
-- Only known static containers/triangles are accepted. Preserve source-root
-- transforms and properties; reject unusual branches rather than guessing.
function M.sanitize(root)
    local shapes=0
    local function visit(node)
        assert((node.name or ""):sub(1,#M.prefix)~=M.prefix,"Imported mesh uses reserved prop wrapper names")
        assert(not kind(node,"NiParticles") and not kind(node,"NiBSParticleNode")
            and not kind(node,"NiLight") and not kind(node,"NiCamera"),"Particles, lights and cameras are unsupported prop meshes")
        local t={translation=rig.vector(node.translation),rotation=rig.matrix(node.rotation),scale=node.scale}
        array(t.translation,3); rotation(t.rotation)
        assert(finite(t.scale) and t.scale>1e-6,"Invalid imported mesh scale")
        node:removeAllControllers()
        -- Property animation (for example animated textures) can own controllers too.
        for _,property in pairs(node:detachAllProperties()) do
            local copy=property:clone()
            copy:removeAllControllers(); node:attachProperty(copy)
        end
        if kind(node,"NiTriShape") then
            assert(not node.skinInstance,"Skinned inventory meshes are unsupported; use the ground/inventory mesh")
            shapes=shapes+1
        elseif kind(node,"NiNode") then
            local name=node.RTTI and node.RTTI.name
            assert(not name or name=="NiNode" or name=="NiBSAnimationNode" or name=="NiSortAdjustNode" or name=="NiCollisionSwitch",
                "Unsupported prop container: "..tostring(name))
            if kind(node,"NiCollisionSwitch") then node.collisionActive=false end
            -- MWSE always exposes the embedded list head, including when its
            -- data is nil. Only actual entries are unsupported dynamic effects.
            local effect=node.effectList
            while effect do
                assert(not effect.data,"Imported mesh has unsupported dynamic effects")
                effect=effect.next
            end
            local children={}
            for _,child in pairs(node.children) do if child then children[#children+1]=child end end
            for _,child in ipairs(children) do
                if collision(child) then
                    node:detachChild(child)
                    log("Skipped collision branch: name=%s type=%s",child.name or "",child.RTTI and child.RTTI.name or "unknown")
                else visit(child) end
            end
        else error("Unsupported prop geometry: "..tostring(node.RTTI and node.RTTI.name)) end
    end
    assert(not collision(root),"Prop mesh contains only collision")
    visit(root)
    assert(shapes>0,"Prop mesh contains no static triangles")
    return root
end
function M.construct(p)
    local ok,result=pcall(function()
        local source=assert(tes3.loadMesh(M.meshPath(p.mesh),false),"Mesh load returned no scene graph")
        local mesh=M.sanitize(assert(source:clone(),"Mesh clone failed"))
        local wrapper=niNode.new()
        wrapper.name=M.prefix..p.id
        -- A collision switch may contain visible geometry. Disable collision
        -- without deleting that hierarchy, including implicit triangle collision.
        local visual=niCollisionSwitch.new()
        visual.name="OAAB Prop Visual"
        visual.collisionActive=false
        visual:attachChild(mesh)
        wrapper:attachChild(visual)
        M.apply(p,wrapper)
        return wrapper
    end)
    if not ok then log("Mesh failed: id=%s object=%s mesh=%s: %s",p.id,p.objectId,p.mesh,tostring(result)); error(result) end
    return result
end
function M.parent(root,bones,nodes,p)
    if p.attachmentType=="bone" then
        for i,b in ipairs(bones) do if b.name:lower()==p.parentBone:lower() then return nodes[i] end end
        log("Missing parent %s for %s; using free/root",p.parentBone,p.id)
        p.attachmentType,p.parentBone="root",nil
    end
    return assert(nodes[1].parent or root,"Pose root is unavailable")
end
function M.clearLive(s)
    local live=s.propScene
    if not live then return end
    if live.highlight then highlight.clear(live.highlight) end
    for _,node in pairs(live.nodes) do if node.parent then node.parent:detachChild(node) end end
    live.nodes,live.errors,live.highlight={}, {}, nil
end
function M.restore(s)
    M.clearLive(s)
    s.propScene=s.propScene or {nodes={},errors={}}
    for _,p in ipairs(s.props or {}) do
        local ok,node=pcall(function()
            local wrapper=M.construct(p)
            M.parent(s.scene,s.bones,s.nodes,p):attachChild(wrapper)
            return wrapper
        end)
        if ok then s.propScene.nodes[p.id]=node else s.propScene.errors[p.id]=tostring(node) end
    end
    if #s.props>0 then s.scene:update() end
    if not M.get(s) then s.selectedProp=nil end
end
function M.add(s,item)
    local p=M.new(s,item)
    local parent=M.parent(s.scene,s.bones,s.nodes,p)
    -- Start near the last bone selection, in the same frame as free props.
    local world=rig.world(s.bones,rig.frame(s.nodes))[s.selected]
    p.translation=M.relative(world,M.nodeTransform(parent)).translation
    local node=M.construct(p) -- Failure leaves the editor definitions intact.
    parent:attachChild(node)
    s.props[#s.props+1]=p
    s.propScene=s.propScene or {nodes={},errors={}}
    s.propScene.nodes[p.id]=node
    s.selectedProp=p.id; s.mode="Move"
    s.scene:update()
    log("Added id=%s object=%s mesh=%s parent=root",p.id,p.objectId,p.mesh)
    return p
end
function M.replace(s,p,item)
    local replacement=M.clone({p})[1]
    replacement.objectId,replacement.name,replacement.mesh=item.id,item.name or item.id,M.meshPath(item.mesh)
    replacement=M.clone({replacement})[1]
    -- Load and validate first, so an unusable replacement leaves the old prop intact.
    local node=M.construct(replacement)
    local live=s.propScene
    local old=live.nodes[p.id]
    local parent=old and old.parent or M.parent(s.scene,s.bones,s.nodes,replacement)
    local ok,err=pcall(function()
        parent:attachChild(node)
        if old and old.parent then old.parent:detachChild(old) end
        s.scene:update()
    end)
    if not ok then
        if node.parent then node.parent:detachChild(node) end
        if old and not old.parent then parent:attachChild(old) end
        pcall(function() s.scene:update() end)
        error(err)
    end
    if live.highlight and live.highlight.selected==p.id then highlight.clear(live.highlight); live.highlight=nil end
    p.objectId,p.name,p.mesh=replacement.objectId,replacement.name,replacement.mesh
    live.nodes[p.id],live.errors[p.id]=node,nil
    log("Replaced id=%s object=%s mesh=%s parent=%s",p.id,p.objectId,p.mesh,p.parentBone or "root")
    return p
end
function M.reparent(s,p,bone)
    local node=assert(s.propScene.nodes[p.id],"This prop mesh is unavailable")
    s.scene:update()
    local world=M.nodeTransform(node)
    local target=M.clone({p})[1]
    target.attachmentType,target.parentBone=bone and "bone" or "root",bone
    local parent=M.parent(s.scene,s.bones,s.nodes,target)
    local localTransform=M.relative(world,M.nodeTransform(parent))
    assert(finite(localTransform.scale) and localTransform.scale>1e-6,"Prop scale is too small in this parent's frame")
    local old=node.parent
    if old~=parent then
        old:detachChild(node)
        local ok,err=pcall(function() parent:attachChild(node) end)
        if not ok then old:attachChild(node); error(err) end
    end
    p.attachmentType,p.parentBone=target.attachmentType,target.parentBone
    p.translation,p.rotation,p.scale=localTransform.translation,localTransform.rotation,localTransform.scale
    M.apply(p,node); s.scene:update()
    log("Reparented id=%s parent=%s (world transform preserved)",p.id,p.parentBone or "root")
end
function M.delete(s,p)
    local _,index=M.get(s,p.id)
    table.remove(s.props,assert(index))
    local live=s.propScene
    if live.highlight then highlight.clear(live.highlight); live.highlight=nil end
    local node=live.nodes[p.id]
    if node and node.parent then node.parent:detachChild(node) end
    live.nodes[p.id],live.errors[p.id]=nil,nil
    log("Deleted id=%s mesh=%s",p.id,p.mesh)
    if s.selectedProp==p.id then s.selectedProp=nil end
    s.scene:update()
end
function M.duplicate(s,p)
    local copy=M.clone({p})[1]; copy.id=nextId(s)
    local node=M.construct(copy)
    M.parent(s.scene,s.bones,s.nodes,copy):attachChild(node)
    s.props[#s.props+1]=copy; s.propScene.nodes[copy.id]=node
    s.selectedProp=copy.id; s.scene:update()
    log("Duplicated id=%s from=%s mesh=%s parent=%s",copy.id,p.id,copy.mesh,copy.parentBone or "root")
    return copy
end
function M.reset(s,p,component)
    if not component or component=="translation" then p.translation={0,0,0} end
    if not component or component=="rotation" then p.rotation=v.identity() end
    if not component or component=="scale" then p.scale=1 end
    local node=s.propScene.nodes[p.id]
    if node then M.apply(p,node); s.scene:update() end
end
function M.select(s)
    local live=s.propScene
    if not live then return end
    if live.highlight and live.highlight.selected==s.selectedProp then return end
    if live.highlight then highlight.clear(live.highlight); live.highlight=nil end
    local node=live.nodes[s.selectedProp]
    if node then live.highlight=highlight.createProp(node); highlight.update(live.highlight,s.selectedProp) end
end
-- Temporarily hide runtime clones while editable replacements own the scene.
function M.hideEmbedded(s)
    s.embeddedProps={}
    local function visit(node)
        if not node then return end
        if (node.name or ""):sub(1,#M.prefix)==M.prefix then
            s.embeddedProps[#s.embeddedProps+1]={node=node,culled=node.appCulled}
            node.appCulled=true
        elseif kind(node,"NiNode") then for _,child in pairs(node.children) do visit(child) end end
    end
    visit(s.scene)
end
function M.hasEmbedded(root)
    if not root then return false end
    if (root.name or ""):sub(1,#M.prefix)==M.prefix then return true end
    if kind(root,"NiNode") then
        for _,child in pairs(root.children) do if M.hasEmbedded(child) then return true end end
    end
    return false
end
function M.unhideEmbedded(s)
    for _,entry in ipairs(s.embeddedProps or {}) do entry.node.appCulled=entry.culled end
    s.embeddedProps=nil
end
-- Called only after the ordinary main NIF has been written to a stage file.
-- Keep a separate serialized output; do not touch stage on failure.
function M.decorate(stage,definitions,bones,replaceEmbedded)
    if not definitions or #definitions==0 and not replaceEmbedded then return end
    local output=stage..".props.nif"
    local ok,err=pcall(function()
        log("Export processing %s (%d props)",stage,#definitions)
        local relative=assert(stage:match("^Data Files/meshes/(.*)$"),"Invalid export stage")
        local root=assert(tes3.loadMesh(relative,false),"Generated pose NIF could not be loaded")
        if replaceEmbedded then
            local function remove(node)
                if not node:isInstanceOfType(tes3.niType.NiNode) then return end
                local children={}; for _,child in pairs(node.children) do if child then children[#children+1]=child end end
                for _,child in ipairs(children) do
                    if (child.name or ""):sub(1,#M.prefix)==M.prefix then node:detachChild(child)
                    else remove(child) end
                end
            end
            remove(root)
        end
        local nodes=rig.bind(root,bones)
        local expected=M.clone(definitions)
        local shapes={}
        for _,p in ipairs(expected) do
            local wrapper=M.construct(p)
            shapes[p.id]=shapeCount(wrapper)
            M.parent(root,bones,nodes,p):attachChild(wrapper)
            log("Export prop id=%s mesh=%s parent=%s",p.id,p.mesh,p.parentBone or "root")
        end
        nodes[1]:update(); root:update()
        assert(root:saveBinary(output),"Prop NIF serialization failed")
        local input=assert(io.open(output,"rb"),"Serialized NIF is missing")
        local bytes=input:read("*a"); input:close()
        assert(bytes and #bytes>0,"Serialized NIF is empty")
        local loaded=assert(tes3.loadMesh(relative..".props.nif",false),"Serialized NIF cannot be reopened")
        local captured,savedNodes=rig.capture(loaded)
        assert(#captured==#bones,"Serialized prop NIF changed the skeleton")
        for i,b in ipairs(bones) do
            local actual=captured[i]
            assert(actual.name==b.name and actual.parent==b.parent,"Serialized prop NIF changed bone topology")
            for _,key in ipairs({"translation","rotation"}) do
                for j,n in ipairs(b[key]) do assert(close(actual[key][j],n,1e-3),"Serialized prop NIF changed bone transforms") end
            end
            assert(close(actual.scale,b.scale),"Serialized prop NIF changed bone scale")
            local node=savedNodes[i]
            assert(node.controller and kind(node.controller,"NiKeyframeController"),"Serialized prop NIF lost bone controllers")
        end
        for _,p in ipairs(expected) do
            local wrapper=assert(rig.find(loaded,M.prefix..p.id),"Serialized NIF lost a prop")
            local parent=M.parent(loaded,bones,savedNodes,p)
            assert(wrapper.parent==parent,"Serialized NIF changed prop attachment")
            assert(shapeCount(wrapper)==shapes[p.id],"Serialized NIF lost prop geometry")
            local translation,rotation=rig.vector(wrapper.translation),rig.matrix(wrapper.rotation)
            for j,n in ipairs(p.translation) do assert(close(translation[j],n,1e-3),"Serialized NIF changed prop translation") end
            for j,n in ipairs(p.rotation) do assert(close(rotation[j],n),"Serialized NIF changed prop rotation") end
            assert(close(wrapper.scale,p.scale),"Serialized NIF changed prop scale")
        end
        -- All checks passed. The publisher still owns rollback for this stage.
        local f=assert(io.open(stage,"wb")); local written,problem=f:write(bytes)
        local closed,closeProblem=f:close(); assert(written,problem); assert(closed,closeProblem)
    end)
    os.remove(output)
    if not ok then log("Export serialization failed: %s",tostring(err)); error(err) end
    log("Export serialization verified: %s",stage)
end
return M
