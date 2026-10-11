package.path="./MWSE/mods/?.lua;"..package.path
json=dofile(assert(arg[2]))
local F=dofile("tests/prop_fixture.lua")
local metadata=require("MannequinPoseDesigner.prop_metadata")
local descriptive=require("MannequinPoseDesigner.pose_metadata")
local count=0
local function check(ok,why) assert(ok,why); count=count+1 end
local root=F.node("Root")
root:addExtraData(F.extra("Unrelated extra data"))
local original=root.extraData
descriptive.update(root,{id="props",name="Props"})
local label=descriptive.find(root)
local p={id="0001",objectId="sword",name="Sword",mesh="w/sword.nif",attachmentType="bone",parentBone="Bip01 R Hand",
    translation={2,-3,4},rotation={1,0,0,0,1,0,0,0,1},scale=.75,selected=true}
local empty,present=metadata.read(root)
check(#empty==0 and not present,"Absent metadata is distinguished from an explicitly empty prop list")
metadata.update(root,{p})
local saved,found=metadata.read(root)
check(found and #saved==1 and saved[1].parentBone==p.parentBone and saved[1].translation[2]==-3 and saved[1].scale==.75,"Source, attachment and transforms survive embedded JSON")
check(not saved[1].selected,"Runtime state is excluded from portable definitions")
check(root.extraData==original and descriptive.find(root)==label and descriptive.read(root).name=="Props","Prop data preserves descriptive and unrelated extra data")
local owned=metadata.find(root)
metadata.update(root,{})
empty,present=metadata.read(root)
check(present and #empty==0 and metadata.find(root)==owned and not owned.next,"Removing all props updates one entry to an explicit empty list")
for _,text in ipairs({'broken JSON','{"version":99,"props":[]}','{"version":1,"props":null}','{"version":1,"props":[{}]}'}) do
    owned.string=metadata.prefix..text
    check(not pcall(metadata.read,root),"Malformed or unsupported definitions stop editing: "..text)
end
-- A JSON object containing no keys is indistinguishable from an empty Lua
-- table; both represent no definitions. Other object keys are always refused.
owned.string=metadata.prefix..'{"version":1,"props":{"bad":{}}}'
check(not pcall(metadata.read,root),"Object-shaped prop collections are refused")
metadata.update(root,{p})
local child=F.node("Child"); root:attachChild(child)
label.next=nil; child.extraData=owned
check(metadata.find(root)==owned,"Discovery finds data on a descendant node")
owned.next=original
check(metadata.find(root)==owned,"Cyclic extra data cannot hang discovery")
owned.string="unrelated"
check(not metadata.find(root),"Unrelated cyclic extra data is ignored")
print("PASS: "..count.." embedded prop metadata assertions")
