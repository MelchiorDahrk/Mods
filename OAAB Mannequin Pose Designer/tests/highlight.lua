package.path="./MWSE/mods/?.lua;"..package.path
local function check(ok,message) assert(ok,message) end
local function color(r,g,b)
    return {r=r,g=g,b=b,lerp=function(self,other,t)
        return color(self.r*(1-t)+other.r*t,self.g*(1-t)+other.g*t,self.b*(1-t)+other.b*t)
    end}
end
niColor={new=color}
niMaterialProperty={new=function() return {emissive=color(0,0,0)} end}
tes3={niType={NiNode="node",NiTriShape="shape"}}
local function node(name,kind,children)
    local result={name=name,kind=kind,children=children or {}}
    function result:isInstanceOfType(asked) return self.kind==asked end
    for _,child in pairs(result.children) do child.parent=result end
    return result
end
local shared={emissive=color(0.1,0.1,0.1),diffuse=color(0.7,0.7,0.7),alpha=0.8}
function shared:clone()
    return {emissive=self.emissive,diffuse=self.diffuse,alpha=self.alpha}
end
local hand=node("hand mesh","shape")
hand.materialProperty=shared
hand.skinInstance={bones={{name="Bip01 L Hand"},{name="Bip01 L Finger0"}},data={boneData={
    {weights={{weight=0.9},{weight=0.9}}},
    {weights={{weight=0.1},{weight=0.1}}},
}}}
local foot=node("foot mesh","shape")
foot.materialProperty=shared
foot.skinInstance={bones={{name="Bip01 L Foot"}},data={boneData={{weights={{weight=1}}}}}}
local ring=node("ring","shape")
local finger=node("Bip01 L Finger0","node",{ring})
local left=node("Bip01 L Hand","node",{hand,finger})
left.materialProperty=shared
local right=node("Bip01 L Foot","node",{foot})
local root=node("root","node",{left,right})
local bones={{name="Bip01 L Hand"},{name="Bip01 L Finger0"},{name="Bip01 L Foot"}}
local highlight=require("MannequinPoseDesigner.highlight")
local selected=highlight.create(root,bones,{left,finger,right})
highlight.update(selected,1)
check(hand.materialProperty~=shared and hand.materialProperty.emissive.r>0.8,"Hand mesh receives a bright tint")
check(foot.materialProperty==shared and shared.emissive.r==0.1,"Shared material and other part stay untouched")
highlight.update(selected,1,true)
check(selected.selected==1 and selected.inactive and hand.materialProperty.emissive.b>hand.materialProperty.emissive.r,
    "Selected inactive bone shapes use a blue tint while keeping their selection")
local inactiveMaterial=hand.materialProperty
highlight.update(selected,1,true)
check(hand.materialProperty==inactiveMaterial,"An unchanged inactive selection does not clone materials every frame")
highlight.update(selected,1,false)
check(not selected.inactive and hand.materialProperty.emissive.r>0.8,"Reactivating the same bone restores amber")
check(ring.materialProperty==nil,"Finger attachment stays unchanged for hand selection")
highlight.update(selected,2)
check(hand.materialProperty==shared,"Previous hand tint is restored")
check(ring.materialProperty~=nil and ring.materialProperty~=shared,"Finger attachment is tinted")
highlight.clear(selected)
check(ring.materialProperty==nil and foot.materialProperty==shared,"Cleanup restores inherited and shared materials")
-- Without a separate attachment, a finger still identifies the skinned hand.
finger.children={}
local fallback=highlight.create(root,bones,{left,finger,right})
highlight.update(fallback,2)
check(hand.materialProperty~=shared and foot.materialProperty==shared,"Small skin influence selects the affected hand")
highlight.clear(fallback)
check(hand.materialProperty==shared,"Fallback tint restores its original property")
local rooted=highlight.create(root,{{name="Bip01"},{name="Bip01 L Hand"}},{root,left})
check(rooted.parts[1] and #rooted.parts[1]>0,"Unweighted root selects a visible skinned piece")

-- MWSE returns fresh wrappers on every scene-node read. == compares the native
-- pointer, but table keys still compare wrapper identity. Rigid body parts have
-- no skin weights to rescue a failed lookup of their attachment bone.
local sources=setmetatable({}, {__mode="k"})
local proxyMeta={}
local function wrap(source)
    if not source then return end
    local proxy=setmetatable({},proxyMeta)
    sources[proxy]=source
    return proxy
end
proxyMeta.__eq=function(a,b) return sources[a]==sources[b] end
proxyMeta.__index=function(proxy,key)
    local source=sources[proxy]
    if key=="parent" then return wrap(source.parent) end
    if key=="children" then
        local children={}
        for index,child in pairs(source.children) do children[index]=wrap(child) end
        return children
    end
    if key=="isInstanceOfType" then return function(_,kind) return source:isInstanceOfType(kind) end end
    return source[key]
end
proxyMeta.__newindex=function(proxy,key,value) sources[proxy][key]=value end

local headA,headB=node("Tri Head 0","shape"),node("Tri Head 1","shape")
local helmet=node("helmet","shape")
helmet.materialProperty=shared
local headBone=node("Bip01 Head","node",{[3]=node("head model","node",{headA,headB}),[8]=helmet})
headBone.materialProperty=shared
local rigidBones={{name="Bip01"},{name="Bip01 Head"}}
local rigidNodes={false,headBone}
local pieces={{},{headA,headB,helmet}}
local branches={headBone}
for _,side in ipairs({"L","R"}) do
    for _,limb in ipairs({{"UpperArm","Forearm","sleeve"},{"Thigh","Calf","trousers"}}) do
        local upper=node(side.." "..limb[3].." upper","shape")
        local lower=node(side.." "..limb[3].." lower","shape")
        upper.materialProperty=shared
        local lowerBone=node("Bip01 "..side.." "..limb[2],"node",{node("attachment offset","node",{lower})})
        lowerBone.materialProperty=shared
        local upperBone=node("Bip01 "..side.." "..limb[1],"node",{[2]=upper,[9]=lowerBone})
        branches[#branches+1]=upperBone
        for _,entry in ipairs({{upperBone,upper},{lowerBone,lower}}) do
            rigidBones[#rigidBones+1]={name=entry[1].name}
            rigidNodes[#rigidNodes+1]=entry[1]
            pieces[#pieces+1]={entry[2]}
        end
    end
end
local bip=node("Bip01","node",branches)
rigidNodes[1]=bip
-- A duplicate bone inside an attached model must keep the real parent's mapping.
local attachedDuplicate=node("duplicate skeleton geometry","shape")
headBone.children[12]=node("Bip01 L Thigh","node",{attachedDuplicate})
headBone.children[12].parent=headBone
pieces[2][#pieces[2]+1]=attachedDuplicate
-- A same-named sibling outside the captured skeleton is not an attachment.
local unrelated=node("unrelated geometry","shape")
local scene=node("scene","node",{bip,node("Bip01 Head","node",{unrelated}),hand,foot})
local captured={}
for i,bone in ipairs(rigidNodes) do captured[i]=wrap(bone) end
check(wrap(headBone)==captured[2] and not rawequal(wrap(headBone),captured[2]),
    "Fixture models equal native bones with distinct Lua wrappers")
local rigid=highlight.create(wrap(scene),rigidBones,captured)
local allPieces={unrelated,hand,foot}
local originals={}
for _,group in ipairs(pieces) do
    for _,shape in ipairs(group) do allPieces[#allPieces+1]=shape end
end
for _,shape in ipairs(allPieces) do
    originals[shape]=shape.materialProperty
    function shape:updateProperties() self.propertyUpdates=(self.propertyUpdates or 0)+1 end
end
for index=2,#rigidBones do
    local group=assert(rigid.parts[index],"Rigid attachment missing for "..rigidBones[index].name)
    check(#group==#pieces[index],"Every rigid piece maps to its nearest captured bone")
    highlight.update(rigid,index)
    for _,shape in ipairs(allPieces) do
        local selectedPiece=false
        for _,selectedShape in ipairs(pieces[index]) do if shape==selectedShape then selectedPiece=true end end
        if selectedPiece then
            check(shape.materialProperty~=originals[shape] and shape.materialProperty.emissive.r>0.8,
                "Head, sleeves and trouser legs receive a tint through fresh wrappers")
        else
            check(shape.materialProperty==originals[shape],"Other limbs and duplicate skeletons stay untouched")
        end
    end
end
highlight.clear(rigid)
for _,shape in ipairs(allPieces) do
    check(shape.materialProperty==originals[shape],"Cleanup restores rigid attachment materials through fresh wrappers")
end
check(shared.emissive.r==0.1,"Inherited and shared materials remain unchanged")
check(headA.propertyUpdates==2 and headB.propertyUpdates==2,"Both head shapes refresh properties on tint and restoration")
local propShape=node("Prop shape","shape"); propShape.materialProperty=shared
local propRoot=node("OAAB Pose Prop 0001","node",{propShape})
local propHighlight=highlight.createProp(propRoot)
highlight.update(propHighlight,"0001")
check(propShape.materialProperty~=shared and shared.emissive.r==0.1,"Selected prop receives an independent material tint")
highlight.clear(propHighlight)
check(propShape.materialProperty==shared,"Prop tint restores its imported material")
print("PASS: selected mesh tint, rigid head/outfit attachments, fresh native wrappers, shared materials, fallback and cleanup")
