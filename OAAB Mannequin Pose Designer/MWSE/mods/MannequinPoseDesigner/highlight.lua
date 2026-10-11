-- Temporarily tint the geometry influenced by the selected/hovered bone. Materials can
-- be shared between shapes, so the selected shape must receive its own copy.
local M={}
local color={1,0.68,0.12}
local inactiveColor={0.45,0.6,1}

local function add(parts,index,shape)
    local group=parts[index]
    if not group then group={}; parts[index]=group end
    group[#group+1]=shape
end

local function collect(root,bones,nodes)
    local parts,byName={}, {}
    for i,bone in ipairs(bones) do
        byName[bone.name:lower()]=i
    end
    local candidates={}
    local function visit(node,attached)
        if not node then return end -- NiNode.children can contain vacant slots.
        if (node.name or ""):sub(1,#("OAAB Pose Prop "))=="OAAB Pose Prop " then return end
        -- MWSE can return a fresh Lua wrapper for the same native bone on each
        -- child read. Table keys compare wrappers; == compares native pointers.
        -- Use the name to find a candidate, then verify it is the captured bone
        -- so duplicate skeletons in equipped models cannot redirect attachments.
        local index=node.name and byName[node.name:lower()]
        if index and node==nodes[index] then attached=index end
        if node:isInstanceOfType(tes3.niType.NiTriShape) then
            local skin=node.skinInstance
            local scores={}
            if skin and skin.data then
                for j,bone in pairs(skin.bones) do
                    local index=bone and bone.name and byName[bone.name:lower()]
                    local data=skin.data.boneData[j]
                    if index and data then
                        for _,vertex in pairs(data.weights) do
                            scores[index]=(scores[index] or 0)+vertex.weight
                        end
                    end
                end
            end
            local best,bestScore,total=nil,0,0
            for index,score in pairs(scores) do
                total=total+score
                if score>bestScore then best,bestScore=index,score end
            end
            if best then
                add(parts,best,node)
                candidates[#candidates+1]={shape=node,scores=scores,total=total}
            elseif attached then
                add(parts,attached,node)
            end
        elseif node:isInstanceOfType(tes3.niType.NiNode) then
            for _,child in pairs(node.children) do visit(child,attached) end
        end
    end
    visit(root)
    -- A small bone can influence a mesh without dominating it (fingers are a
    -- common case). Use its strongest affected piece if it has no own piece.
    for index=1,#bones do
        if not parts[index] then
            local best=0
            for _,candidate in ipairs(candidates) do
                best=math.max(best,(candidate.scores[index] or 0)/candidate.total)
            end
            if best>0 then
                for _,candidate in ipairs(candidates) do
                    if (candidate.scores[index] or 0)/candidate.total>=best*0.9 then
                        add(parts,index,candidate.shape)
                    end
                end
            end
        end
    end
    -- The Bip01 root usually has no direct skin weights. Select the largest
    -- skinned piece so entry into the editor still has a visible selection.
    if not parts[1] then
        local largest
        for _,candidate in ipairs(candidates) do
            if not largest or candidate.total>largest.total then largest=candidate end
        end
        if largest then add(parts,1,largest.shape) end
    end
    return parts
end

local function materialFor(shape)
    local node=shape
    while node do
        if node.materialProperty then return node.materialProperty end
        node=node.parent
    end
end

function M.create(root,bones,nodes)
    return {parts=collect(root,bones,nodes),selected=nil,changed={}}
end

function M.createProp(root)
    local shapes={}
    local function visit(node)
        if node:isInstanceOfType(tes3.niType.NiTriShape) then shapes[#shapes+1]=node
        elseif node:isInstanceOfType(tes3.niType.NiNode) then
            for _,child in pairs(node.children) do if child then visit(child) end end
        end
    end
    visit(root)
    local id=root.name:sub(#("OAAB Pose Prop ")+1)
    return {parts={[id]=shapes},changed={}}
end

function M.clear(self)
    for _,entry in ipairs(self.changed) do
        entry.shape.materialProperty=entry.original
        if entry.shape.updateProperties then entry.shape:updateProperties() end
    end
    self.changed={}
    self.selected=nil
    self.inactive=nil
end

function M.update(self,selected,inactive)
    inactive=inactive==true
    if self.selected==selected and self.inactive==inactive then return end
    M.clear(self)
    self.selected=selected
    self.inactive=inactive
    for _,shape in ipairs(self.parts[selected] or {}) do
        local original=shape.materialProperty
        local source=materialFor(shape)
        local material=source and source:clone() or niMaterialProperty.new()
        if not source then
            material.diffuse=niColor.new(1,1,1)
            material.alpha=1
        end
        local tint=niColor.new(unpack(inactive and inactiveColor or color))
        material.emissive=source and source.emissive:lerp(tint,0.85) or tint
        self.changed[#self.changed+1]={shape=shape,original=original}
        shape.materialProperty=material
        if shape.updateProperties then shape:updateProperties() end
    end
end

return M
