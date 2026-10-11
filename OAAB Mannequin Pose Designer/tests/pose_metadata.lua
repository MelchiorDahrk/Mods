package.path="./MWSE/mods/?.lua;"..package.path
json=dofile(assert(arg[2]))
local metadata=require("MannequinPoseDesigner.pose_metadata")
local count=0
local function check(ok,why) assert(ok,why); count=count+1 end
tes3={niType={NiStringExtraData="string"}}
local function extra(text,kind)
    local value={string=text,isInstanceOfType=function(_,type) return (kind or "string")==type end}
    function value:clone() return extra(self.string,kind) end
    return value
end
niStringExtraData={new=function(text) return extra(text) end}
local unrelated=extra("Prn WeaponBone")
local keys=extra("", "textKeys"); unrelated.next=keys
local root={extraData=unrelated}
function root:addExtraData(value)
    local tail=self.extraData; while tail.next do tail=tail.next end; tail.next=value
end
local fields={id="guardlean",name="Guard Leaning Against His Spear",description="Relaxed guard stance.",category="Standing",
    path="should not persist",editable=true}
check(not metadata.read(root),"Missing metadata is optional")
metadata.update(root,fields)
local stored=assert(metadata.read(root))
check(stored.id==fields.id and stored.name==fields.name and stored.description==fields.description and stored.category==fields.category,
    "Four portable fields round trip")
check(not stored.path and not stored.editable,"Runtime fields cannot enter metadata")
check(root.extraData==unrelated and unrelated.next==keys,"Unrelated extra data remains attached")
local owned=assert(metadata.find(root)); local before=keys.next
fields.name="Renamed, punctuation allowed!"
metadata.update(root,fields)
check(metadata.find(root)==owned and keys.next==before and not owned.next,"Updating does not duplicate the metadata entry")
check(metadata.read(root).name==fields.name,"Name is independent of the ID")
owned.string=metadata.prefix.."broken JSON"
check(not metadata.read(root),"Malformed JSON falls back safely")
metadata.update(root,fields)
check(metadata.read(root).id=="guardlean","Metadata editing repairs only the owned entry")
owned.next=unrelated
check(metadata.find(root)==owned,"Linked lists tolerate cycles")
owned.string="unrelated"
check(not metadata.find(root),"Cyclic unrelated extra data cannot hang discovery")
owned.next=nil
for _,id in ipairs({"", "../unsafe", " spaced", "a/b", "a\\b", "a.b", "-first", "a:drive"}) do
    check(not metadata.validateId(id,19),"Reject unsafe ID: "..id)
end
check(metadata.validateId("Ab_12-safe",19)=="Ab_12-safe","Safe IDs are preserved exactly")
check(not metadata.validateId(string.rep("x",20),19),"Creation IDs respect the companion path budget")
check(metadata.validateId(string.rep("x",30)),"Existing imported metadata IDs are not tied to a new filename budget")
check(not metadata.parse(metadata.prefix..string.rep("x",metadata.maxBytes)),"Oversized optional metadata is ignored")
local partial=metadata.parse(metadata.prefix..json.encode({name="Useful",id={},description=7,category=false}))
check(partial.name=="Useful" and not partial.id and partial.description=="" and partial.category=="",
    "Individual malformed fields do not discard good fields")
tes3.loadMesh=function() error("Unreadable metadata") end
check(not metadata.readFile("bad.nif"),"Metadata load failures do not throw into discovery")
print("PASS: "..count.." portable NIF metadata assertions")
