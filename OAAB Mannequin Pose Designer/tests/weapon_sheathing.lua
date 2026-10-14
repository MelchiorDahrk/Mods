package.path="./MWSE/mods/?.lua;"..package.path
local rig=require("MannequinPoseDesigner.rig")
local nif=require("MannequinPoseDesigner.nif")
local blend=require("MannequinPoseDesigner.blend")
local reference=dofile("tests/template_fixture.lua")
tes3={niType={NiNode="NiNode"}}
tes3vector3={new=function(x,y,z) return {x=x,y=y,z=z} end}
tes3matrix33={new=function(a,b,c,d,e,f,g,h,i)
    return {x={x=a,y=b,z=c},y={x=d,y=e,z=f},z={x=g,y=h,z=i}}
end}
local function node(bone)
    return {name=bone.name,children={},translation=rig.engineVector(bone.translation),
        rotation=rig.engineMatrix(bone.rotation),scale=bone.scale,
        isInstanceOfType=function(_,kind) return kind=="NiNode" end,update=function() end}
end
local function attach(parent,child)
    if child.parent then
        for i,previous in ipairs(child.parent.children) do
            if previous==child then table.remove(child.parent.children,i); break end
        end
    end
    parent.children[#parent.children+1]=child; child.parent=parent
end
local function scene()
    local root=node(reference[1]); root.name="Scene"
    local nodes,byName={},{}
    for i,bone in ipairs(reference) do
        nodes[i]=node(bone); byName[bone.name]=nodes[i]
        attach(nodes[bone.parent] or root,nodes[i])
    end
    return root,byName
end
-- Weapon Sheathing 1.6's fourteen attachSlots. They are runtime item
-- attachment branches, despite their Bip01 names; the export has 35 bones.
local names={"ShortBladeOneHand","LongBladeOneHand","LongBladeTwoClose",
    "BluntOneHand","BluntTwoClose","BluntTwoWide","SpearTwoWide",
    "AxeOneHand","AxeTwoClose","MarksmanBow","MarksmanCrossbow",
    "MarksmanThrown","AttachWeapon","AttachShield"}
local root,byName=scene()
local attachments={}
for i,name in ipairs(names) do
    local attachment=node(reference[1]); attachment.name="Bip01 "..name
    -- Matching is case insensitive, as it is for actual skeleton bones.
    if i==1 then attachment.name=attachment.name:upper() end
    attachment.translation={x=i,y=-i,z=100+i}; attachment.scale=2
    attach(byName["Bip01 Spine2"],attachment)
    attachments[i]=attachment
end
-- Attached weapons can contain skeleton-like names. Prune the whole branch
-- before it can shadow the actor's hand or contribute additional bones.
local item=node(reference[17]); item.name="Bip01 L Hand"
local itemBone=node(reference[1]); itemBone.name="Bip01 Weapon"
attach(attachments[13],item); attach(item,itemBone)
local ammo=node(reference[1]); ammo.name="Bip01 Ammo"
attach(attachments[10],ammo)
local captured,nodes=rig.capture(root)
assert(#captured==35 and #nodes==35,"Weapon Sheathing attachments must not enter the pose skeleton")
for i,bone in ipairs(reference) do
    assert(captured[i].name==bone.name and captured[i].parent==bone.parent,"Capture preserves bone order and parents")
    assert(nodes[i]==byName[bone.name],"Capture binds the actor bone, not an item bone")
end
local rebound=rig.bind(root,captured)
for i,node in ipairs(nodes) do assert(rebound[i]==node,"Rebinding uses the same filtered skeleton") end
local plain=rig.capture(scene())
local aligned=blend.align(plain,captured)
assert(#blend.apply(captured,aligned,0.5)==35,"Stock poses still blend with a patched actor")
for _,case in ipairs({{"mann_relax.nif","nif"},{"xmann_relax.nif","xnif"},{"xmann_relax.kf","kf"}}) do
    local f=assert(io.open("MWSE/mods/MannequinPoseDesigner/templates/"..case[1],"rb"))
    local bytes=f:read("*a"); f:close()
    assert(nif.patchTemplate(captured,bytes,case[2])==nif.patchTemplate(plain,bytes,case[2]),
        "Draft and saved animation bundles must be independent of Weapon Sheathing")
end
rig.apply(captured,nodes,root)
for i,attachment in ipairs(attachments) do
    assert(attachment.parent==byName["Bip01 Spine2"] and attachment.translation.x==i
        and attachment.translation.y==-i and attachment.translation.z==100+i and attachment.scale==2,
        "Posing leaves Weapon Sheathing's attachments and transforms intact")
end
-- A different live scene can reparent AttachWeapon when equipment changes.
local changed,changedNames=scene()
attach(changedNames["Bip01 Pelvis"],attachments[13])
local changedNodes=rig.bind(changed,captured)
for i,bone in ipairs(captured) do assert(changedNodes[i]==changedNames[bone.name],"Rebind survives attachment reparenting") end
local unexpected=node(reference[1]); unexpected.name="Bip01 Unexpected"
attach(changedNames.Bip01,unexpected)
local unsupported=rig.capture(changed)
assert(#unsupported==36,"Unknown skeleton bones still reach the strict export checks")
print("PASS: Weapon Sheathing capture, rebinding, blending, exports and attachment preservation")
