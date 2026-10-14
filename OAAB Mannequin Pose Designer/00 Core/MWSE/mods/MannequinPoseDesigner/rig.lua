local v = require("MannequinPoseDesigner.math3d")
local M = {}
function M.vector(a) return {a.x,a.y,a.z} end
function M.matrix(a) return {a.x.x,a.x.y,a.x.z,a.y.x,a.y.y,a.y.z,a.z.x,a.z.y,a.z.z} end
function M.engineVector(a) return tes3vector3.new(unpack(a)) end
function M.engineMatrix(a) return tes3matrix33.new(unpack(a)) end
-- Weapon Sheathing adds these Bip01-named item attachment branches to actor
-- meshes. They are not animated pose bones and are absent from OAAB templates.
-- Treating them as non-bones also keeps their equipped meshes out of capture.
local weaponSheathingAttachments={
    ["bip01 shortbladeonehand"]=true,
    ["bip01 longbladeonehand"]=true,
    ["bip01 longbladetwoclose"]=true,
    ["bip01 bluntonehand"]=true,
    ["bip01 blunttwoclose"]=true,
    ["bip01 blunttwowide"]=true,
    ["bip01 speartwowide"]=true,
    ["bip01 axeonehand"]=true,
    ["bip01 axetwoclose"]=true,
    ["bip01 marksmanbow"]=true,
    ["bip01 marksmancrossbow"]=true,
    ["bip01 marksmanthrown"]=true,
    ["bip01 attachweapon"]=true,
    ["bip01 attachshield"]=true,
}
local function isBone(name)
    name=(name or ""):lower()
    if weaponSheathingAttachments[name] then return false end
    return name=="bip01" or name:match("^bip01 ") or name=="weapon bone" or name=="shield bone"
end
function M.find(root, name)
    if not root then return end
    if root.name and root.name:lower()==name:lower() then return root end
    if root:isInstanceOfType(tes3.niType.NiNode) then
        for _,child in pairs(root.children) do
            local found=M.find(child,name)
            if found then return found end
        end
    end
end
function M.capture(root)
    local bip=assert(M.find(root,"Bip01"),"Mannequin skeleton is not loaded")
    local bones, nodes, names = {},{},{}
    local function visit(node,parent)
        -- MWSE's NiNode.children is a sparse NI::TArray. Its pairs iterator can
        -- visit a vacant slot and yield nil; equipped body parts leave these.
        if not node then return end
        if not node:isInstanceOfType(tes3.niType.NiNode) then return end
        if isBone(node.name) then
            -- Body-part meshes can contain their own copy of the skeleton. The
            -- first matching branch is the actor skeleton, not those duplicates.
            if names[node.name:lower()] then return end
            local id=#bones+1
            names[node.name:lower()]=id
            bones[id]={name=node.name,parent=parent,translation=M.vector(node.translation),rotation=v.orthonormalize(M.matrix(node.rotation)),scale=node.scale}
            nodes[id]=node
            parent=id
        elseif parent~=0 then
            -- Do not descend into equipped item/model branches.
            return
        end
        for _,child in pairs(node.children) do visit(child,parent) end
    end
    visit(bip,0)
    return bones,nodes
end
function M.clone(bones)
    local out={}
    for i,b in ipairs(bones) do out[i]={name=b.name,parent=b.parent,translation=v.copy(b.translation),rotation=v.copy(b.rotation),scale=b.scale} end
    return out
end
-- Capture order is parent-first. A limb is the selected bone's entire branch,
-- including hidden fingers and attachment offsets, never its ancestors.
function M.reset(bones,initial,selected,scope)
    assert(scope=="bone" or scope=="limb" or scope=="entire","Unknown reset target")
    local result,touched=M.clone(bones),{}
    for i,bone in ipairs(bones) do
        if scope=="entire" or i==selected or (scope=="limb" and touched[bone.parent]) then
            result[i]=M.clone({initial[i]})[1]
            touched[i]=true
        end
    end
    return result,touched
end
-- Anchors use the skeleton parent's frame, so turning the mannequin for viewing
-- carries the locks with it without baking reference placement into the pose.
function M.anchor(bones,tip)
    local transform=M.world(bones)[tip]
    return {target=v.copy(transform.translation),rotation=v.copy(transform.rotation)}
end
function M.cloneLocks(locks)
    local out={}
    for tip,lock in pairs(locks) do
        out[tip]={target=v.copy(lock.target),rotation=v.copy(lock.rotation)}
    end
    return out
end
function M.bind(root,bones)
    local _,nodes=M.capture(root)
    local byName={}
    for _,node in ipairs(nodes) do byName[node.name:lower()]=node end
    local bound={}
    for i,b in ipairs(bones) do bound[i]=assert(byName[b.name:lower()],"Missing bone: "..b.name) end
    return bound
end
function M.frame(nodes)
    local parent=nodes[1].parent
    local t=parent.worldTransform
    return {rotation=M.matrix(t.rotation),translation=M.vector(t.translation),scale=t.scale}
end
function M.world(bones,frame)
    local world={[0]=frame or {rotation=v.identity(),translation={0,0,0},scale=1}}
    for i,b in ipairs(bones) do
        local p=world[b.parent]
        world[i]={rotation=v.mul(p.rotation,b.rotation),translation=v.add(p.translation,v.scale(v.transform(p.rotation,b.translation),p.scale)),scale=p.scale*b.scale}
    end
    return world
end
function M.apply(bones,nodes,scene)
    for i,b in ipairs(bones) do
        local node=nodes[i]
        node.rotation=M.engineMatrix(b.rotation)
        node.translation=M.engineVector(b.translation)
        node.scale=b.scale
    end
    nodes[1]:update()
    -- Skinned body parts/outfits can be siblings of Bip01. Update the bones
    -- first, then the whole actor so their bounds use the new bone transforms,
    -- even when a mesh precedes the skeleton in the scene's child slots.
    local root=scene or nodes[1].parent
    if root then root:update() end
end
function M.chains(bones)
    local byName={}
    for i,b in ipairs(bones) do byName[b.name:lower()]=i end
    local chains={}
    for _,side in ipairs({"L","R"}) do
        for _,parts in ipairs({{"UpperArm","Forearm","Hand"},{"Thigh","Calf","Foot"}}) do
            local a,b,c=byName[("Bip01 "..side.." "..parts[1]):lower()],byName[("Bip01 "..side.." "..parts[2]):lower()],byName[("Bip01 "..side.." "..parts[3]):lower()]
            if a and b and c and bones[b].parent==a and bones[c].parent==b then
                chains[c]={upper=a,lower=b,tip=c}
            end
        end
    end
    return chains
end
function M.pole(bones,chain,frame)
    local w=M.world(bones,frame)
    local a,b,c=w[chain.upper].translation,w[chain.lower].translation,w[chain.tip].translation
    local axis=v.unit(v.sub(c,a))
    local offset=v.sub(b,a)
    local bend=v.sub(offset,v.scale(axis,v.dot(offset,axis)))
    if v.length(bend)<0.01 then
        -- Stable fallback for straight limbs; subsequent drags preserve the pole.
        bend=v.transform(w[chain.upper].rotation,{0,0,1})
    end
    return v.add(b,v.scale(v.unit(bend),40))
end
local function aim(bones,world,index,current,desired)
    local parentRotation=world[bones[index].parent].rotation
    local rotation=v.mul(v.between(current,desired),world[index].rotation)
    bones[index].rotation=v.orthonormalize(v.mul(v.transpose(parentRotation),rotation))
end
function M.solve(bones,chain,target,pole,frame)
    local world=M.world(bones,frame)
    local upper,lower,tip=chain.upper,chain.lower,chain.tip
    local a,b,c=world[upper].translation,world[lower].translation,world[tip].translation
    local elbow,reach=v.twoBone(a,target,pole,v.length(v.sub(b,a)),v.length(v.sub(c,b)))
    local tipRotation=world[tip].rotation
    aim(bones,world,upper,v.sub(b,a),v.sub(elbow,a))
    world=M.world(bones,frame)
    aim(bones,world,lower,v.sub(world[tip].translation,world[lower].translation),v.sub(reach,elbow))
    world=M.world(bones,frame)
    bones[tip].rotation=v.orthonormalize(v.mul(v.transpose(world[lower].rotation),tipRotation))
end
function M.solveLocks(bones,chains,locks,frame,edited)
    frame=frame or {rotation=v.identity(),translation={0,0,0},scale=1}
    local tolerance=1e-4*math.abs(frame.scale)
    for tip in ipairs(bones) do
        local lock,chain=locks[tip],chains[tip]
        if lock and chain then
            local target=v.add(frame.translation,v.scale(v.transform(frame.rotation,lock.target),frame.scale))
            local world=M.world(bones,frame)
            local a,b,c=world[chain.upper].translation,world[chain.lower].translation,world[tip].translation
            if v.length(v.sub(c,target))>tolerance then
                if edited==chain.upper then
                    -- The upper bone's explicit rotation wins. Only the lower
                    -- bone can compensate, placing the tip nearest its anchor.
                    local current=v.sub(c,b)
                    aim(bones,world,chain.lower,current,v.unit(v.sub(target,b),v.unit(current)))
                elseif edited==chain.lower then
                    -- Keep the edited local bend; aim the remaining upper bone
                    -- with this fixed shape, without undoing the user's edit.
                    local current=v.sub(c,a)
                    if v.length(current)>1e-6 then
                        aim(bones,world,chain.upper,current,v.unit(v.sub(target,a),v.unit(current)))
                    end
                else
                    M.solve(bones,chain,target,M.pole(bones,chain,frame),frame)
                end
            end
            world=M.world(bones,frame)
            bones[tip].rotation=v.orthonormalize(v.mul(v.transpose(world[chain.lower].rotation),v.mul(frame.rotation,lock.rotation)))
            local reached=world[tip].translation
            if v.length(v.sub(reached,target))>tolerance then
                -- A forced move becomes the new anchor, preventing a later edit
                -- from pulling the effector back toward an obsolete position.
                lock.target=v.scale(v.transform(v.transpose(frame.rotation),v.sub(reached,frame.translation)),1/frame.scale)
            end
        end
    end
end
return M
