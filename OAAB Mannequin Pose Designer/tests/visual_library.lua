-- Real filesystem/template/JSON transactions with a native metadata contract
-- mock. Actual saveBinary and preview appearance are in-game acceptance checks.
local lfs=require("lfs")
local project=lfs.currentdir():gsub("\\","/")
package.path=project.."/MWSE/mods/?.lua;"..package.path
json=dofile(assert(arg[2]))
local metadata=require("MannequinPoseDesigner.pose_metadata")
local library=require("MannequinPoseDesigner.library")
local catalog=require("MannequinPoseDesigner.catalog")
library.templateRoot=project.."/MWSE/mods/MannequinPoseDesigner/templates"
local bones=dofile("tests/template_fixture.lua")
local run=1; while lfs.attributes(".work/visual-library-"..run) do run=run+1 end
assert(lfs.mkdir(".work/visual-library-"..run)); assert(lfs.chdir(".work/visual-library-"..run))
local count=0
local function check(ok,why) assert(ok,why); count=count+1 end
local function read(path) local f=assert(io.open(path,"rb")); local b=f:read("*a"); f:close(); return b end
local function write(path,bytes) local f=assert(io.open(path,"wb")); assert(f:write(bytes)); assert(f:close()) end
local marker="\nNATIVE_METADATA_MOCK\n"
local serializationFailure=false
local serializationCount,failSerializationAt=0,nil
local collisionPath
local configReads,configWrites=0,0
mwse={log=function() end,
    loadConfig=function() configReads=configReads+1; error("The library must not load local config") end,
    saveConfig=function() configWrites=configWrites+1; error("The library must not save local config") end}
tes3={niType={NiStringExtraData="string"}}
local function extra(text)
    local value={string=text,isInstanceOfType=function(_,kind) return kind=="string" end}
    function value:clone() return extra(self.string) end
    return value
end
niStringExtraData={new=extra}
tes3.loadMesh=function(file,cache)
    check(cache==false,"Metadata bypasses the mesh cache")
    local path=library.disk(file)
    local bytes
    if library.isDefault(file) and not lfs.attributes(path) then bytes=read(library.templateRoot.."/mann_relax.nif")
    else bytes=read(path) end
    local at=bytes:find(marker,1,true)
    local root={extraData=extra("Unrelated extra data"),base=at and bytes:sub(1,at-1) or bytes}
    if at then root.extraData.next=extra(bytes:sub(at+#marker)) end
    function root:addExtraData(value) self.extraData.next=value end
    function root:saveBinary(output)
        serializationCount=serializationCount+1
        if serializationFailure or serializationCount==failSerializationAt then return false end
        if collisionPath then write(collisionPath,"External file appeared"); collisionPath=nil end
        write(output,self.base..(self.extraData.next and marker..self.extraData.next.string or "")); return true
    end
    return root
end
local fields={id="guardlean",name="Guard Leaning Against His Spear",description="Relaxed guard stance.",category="Standing"}
local file=library.write(bones,fields,{})
check(file=="pose/k/guardlean.nif","User ID is used verbatim in the main filename")
check(lfs.attributes(library.disk("pose/k/xguardlean.nif")) and lfs.attributes(library.disk("pose/k/xguardlean.kf")),"Companions use the same ID")
check(library.label(file)==fields.name,"Long human-readable name is separate from filenames")
local original=read(library.disk(file))
check(not pcall(library.write,bones,fields,{}) and read(library.disk(file))==original,"Duplicate creation IDs never overwrite")
check(not library.idFile("GUARDLEAN"),"ID collisions ignore case")
local record=catalog.list()[5] -- select explicitly below; records are custom first.
for _,pose in ipairs(catalog.list()) do if pose.file==file then record=pose end end
local changed=catalog.fields(record); changed.name="Guard off duty"; changed.description="A quieter moment"
library.updateMetadata(file,changed)
check(library.label(file)==changed.name and library.find(file).id=="guardlean","Metadata editing keeps the stable ID and path")
changed.id="different"
check(not pcall(library.updateMetadata,file,changed),"Existing IDs are immutable")
local legacy="pose/k/Old_Pose.nif"
write(library.disk(legacy),read(library.templateRoot.."/mann_relax.nif"))
local legacyBytes=read(library.disk(legacy))
local oldRecord; for _,pose in ipairs(catalog.list()) do if pose.file==legacy then oldRecord=pose end end
check(oldRecord.name=="Old Pose" and oldRecord.category=="" and oldRecord.description=="","Metadata-less imports retain filename labels and empty fields")
library.updateMetadata(legacy,{id="Old_Pose",name="Legacy renamed",category="Sitting"})
local newRecord; for _,pose in ipairs(catalog.list()) do if pose.file==legacy then newRecord=pose end end
check(newRecord.id=="Old_Pose" and newRecord.name=="Legacy renamed" and newRecord.category=="Sitting",
    "Adding portable metadata preserves the legacy pose's identity")
local propMarker="embedded prop geometry preserved"
write(library.disk(file),read(library.disk(file))..propMarker)
-- Put the geometry marker before the mock metadata so its JSON remains valid.
local sourceBytes=original:gsub(marker,propMarker..marker,1)
write(library.disk(file),sourceBytes); library.invalidate(file)
local copyFields={id="newguard",name="Guard Copy",category="Standing"}
local copy=library.write(bones,copyFields,{},nil,file,catalog.list())
check(read(library.disk(copy)):find(propMarker,1,true) and read(library.disk(file))==sourceBytes,"Save As preserves actual embedded geometry without altering the source")
local default="oaab/k/mann_relax.nif"
local stockCopy=library.write(bones,{id="relaxcopy",name="My Relaxed"},{},nil,default,catalog.list())
check(library.find(stockCopy).editable and library.find(stockCopy).id=="relaxcopy","OAAB starting poses can be saved into editable custom poses")
for _,operation in ipairs({function() library.updateMetadata(default,{id="stock",name="Bad"}) end,
    function() library.replace(bones,default) end,function() library.remove(default) end,function() library.updateMetadata(default,{id="Bad",name="Bad"}) end}) do
    check(not pcall(operation),"OAAB originals reject every write operation")
end
local records=catalog.list()
local beforeBrowse=read(library.disk(file))
check(#catalog.filter(records,{source="OAAB_Data"})==4,"All four stock poses browse read-only")
check(#catalog.filter(records,{source="All poses"})==#records,"All poses includes the complete catalog")
check(#catalog.filter(records,{source="Custom"})==4,"Custom filtering includes editable poses")
check(#catalog.filter(records,{source="Favorites"})==0,"The removed Favorites source has no results")
check(#catalog.filter(records,{search="relaxed guard"})==1,"Search combines words across descriptions and names")
check(#catalog.filter(records,{source="Custom",category="Sitting",search="Old_Pose"})==1,"Category and ID filters compose")
check(#catalog.filter(records,{search="No such phrase"})==0,"Unmatched searches return an empty page")
check(read(library.disk(file))==beforeBrowse,"Browsing cannot modify files")
local paths={file,copy,stockCopy,legacy}
for _,path in ipairs(paths) do
    local pose=library.find(path)
    if pose then check(pose.description~=nil and pose.category~=nil,"Records normalize supported optional fields") end
end
-- Manually installed duplicate metadata IDs stay separate and block new exports.
write(library.disk(copy),sourceBytes); library.invalidate(copy)
records=catalog.list(); local conflicts={}
for _,pose in ipairs(records) do if pose.id=="guardlean" then conflicts[#conflicts+1]=pose end end
check(#conflicts==2 and conflicts[1].duplicateId and conflicts[2].duplicateId,"Duplicate installed IDs are tolerated")
check(conflicts[1].file~=conflicts[2].file,"Duplicate IDs retain distinct pose paths")
check(not library.idFile("guardlean",records),"Duplicate installed IDs remain reserved")
local moved=require("MannequinPoseDesigner.rig").clone(bones)
moved[1].translation[3]=moved[1].translation[3]+1
library.replace(moved,file)
check(read(library.disk(file)):find(propMarker,1,true) and library.find(file).id=="guardlean",
    "Normal Save patches the original NIF and retains embedded geometry and its ID")
local broken="pose/k/oldbroken.nif"
write(library.disk(broken),read(library.templateRoot.."/mann_relax.nif")..marker..metadata.prefix.."{bad JSON")
local brokenBytes=read(library.disk(broken)); local malformed
for _,pose in ipairs(catalog.list()) do if pose.file==broken then malformed=pose end end
check(malformed and malformed.name=="oldbroken" and malformed.description=="" and malformed.category==""
    and read(library.disk(broken))==brokenBytes,"Malformed optional metadata remains browsable without repair writes")
-- A manually installed legacy filename can collide with a stock fallback ID.
local ambiguous="pose/k/mann_relax.nif"
write(library.disk(ambiguous),read(library.templateRoot.."/mann_relax.nif"))
library.updateMetadata(ambiguous,{id="mann_relax",name="Legacy stock-name collision"})
for _,pose in ipairs(catalog.list()) do
    if pose.file==ambiguous then check(pose.duplicateId and pose.name=="Legacy stock-name collision",
        "Metadata edits preserve ambiguous legacy IDs as separate records") end
end
write(library.disk("pose/k/xorphan.kf"),"orphan")
check(not library.idFile("orphan"),"Orphaned companions block ID reuse")
local beforeFailure=read(library.disk(legacy))
serializationFailure=true
check(not pcall(library.updateMetadata,legacy,{id="Old_Pose",name="Failed"}) and read(library.disk(legacy))==beforeFailure,
    "Serialization failures preserve the original NIF")
serializationFailure=false
collisionPath=library.disk("pose/k/xraced.kf")
check(not pcall(library.write,bones,{id="raced",name="Concurrent import"},{})
    and read(library.disk("pose/k/xraced.kf"))=="External file appeared"
    and not lfs.attributes(library.disk("pose/k/raced.nif")),
    "Files arriving after staging are preserved and creation is rolled back")
check(not pcall(library.write,bones,{id="rollback",name="Rollback"},{},function() error("Apply failed") end)
    and not lfs.attributes(library.disk("pose/k/rollback.nif")),"Failed Apply rolls a new bundle back")
-- Categories live in the NIFs; clear them as one transaction, including imports
-- with partial metadata and duplicate IDs, without changing anything else.
local partial="pose/k/partial.nif"
local partialFields={name="Partial metadata",id={invalid=true},description=7,category="Standing"}
write(library.disk(partial),read(library.templateRoot.."/mann_relax.nif")..marker..metadata.prefix..json.encode(partialFields))
library.invalidate()
local categoryFiles={file,copy,partial}
local originals,companionsBefore={},{}
for _,path in ipairs(categoryFiles) do originals[path]=read(library.disk(path)) end
for entry in lfs.dir(library.disk(library.folder)) do
    if entry:sub(1,1)=="x" then companionsBefore[entry]=read(library.disk(library.folder.."/"..entry)) end
end
local unaffected=read(library.disk(legacy))
local external="thirdparty/pose.nif"
assert(lfs.mkdir("Data Files/meshes/thirdparty"))
write(library.disk(external),originals[file])
check(not pcall(library.removeCategory,"Standing",catalog.list({{file=external,label="Registered"}})),
    "A category shared by a registered read-only pose cannot be deleted")
for _,path in ipairs(categoryFiles) do check(read(library.disk(path))==originals[path],"Read-only preflight preserves custom files") end
check(not pcall(library.removeCategory,"Uncategorized") and not pcall(library.removeCategory,""),"Built-in/empty categories cannot be deleted")
failSerializationAt=serializationCount+2
check(not pcall(library.removeCategory,"Standing",catalog.list()),"Failure while staging a later NIF aborts category deletion")
failSerializationAt=nil
for _,path in ipairs(categoryFiles) do check(read(library.disk(path))==originals[path],"Staging failure leaves every source untouched") end
local nativeRename=os.rename
local publicationFailed=false
os.rename=function(source,target)
    if not publicationFailed and target==library.disk(copy) and source:find(".tmp.nif",1,true) then
        publicationFailed=true; return nil,"Simulated publication failure"
    end
    return nativeRename(source,target)
end
local removedCategory,categoryError=pcall(library.removeCategory,"Standing",catalog.list())
os.rename=nativeRename
check(not removedCategory and publicationFailed and categoryError:find("Simulated publication failure",1,true),
    "Failure publishing a later NIF is reported")
for _,path in ipairs(categoryFiles) do check(read(library.disk(path))==originals[path],"Publication failure rolls all source NIFs back") end
check(library.removeCategory("Standing",catalog.list())==3,"Deleting a category clears every affected custom NIF")
for _,path in ipairs(categoryFiles) do
    local bytes=read(library.disk(path))
    local at=assert(bytes:find(marker,1,true))
    local beforeAt=assert(originals[path]:find(marker,1,true))
    check(bytes:sub(1,at-1)==originals[path]:sub(1,beforeAt-1),"Skeleton and embedded geometry remain identical")
    local fieldsAfter=json.decode(bytes:sub(at+#marker+#metadata.prefix))
    local fieldsBefore=json.decode(originals[path]:sub(beforeAt+#marker+#metadata.prefix))
    check(fieldsAfter.category=="","Category is cleared in the persisted NIF metadata")
    for _,key in ipairs({"id","name","description"}) do
        check(json.encode(fieldsAfter[key])==json.encode(fieldsBefore[key]),"Category deletion preserves existing metadata: "..key)
    end
end
for _,category in ipairs(catalog.categories(catalog.list())) do check(category~="Standing","Deleted category does not return during discovery") end
check(read(library.disk(legacy))==unaffected,"Other categories are unchanged")
for entry,bytes in pairs(companionsBefore) do
    check(read(library.disk(library.folder.."/"..entry))==bytes,"Animation companions remain byte-for-byte unchanged")
end
check(read(library.disk(external))==originals[file],"Registered pose metadata remains intact")
check(library.removeCategory("Standing",catalog.list())==0,"Repeating an already completed category deletion is harmless")
for entry in lfs.dir(library.disk(library.folder)) do check(not entry:find(".edit-",1,true),"Finished transactions leave no stage files") end
check(configReads==0 and configWrites==0,"Browsing and metadata transactions never access local config")
print("PASS: "..count.." visual library, stable IDs, read-only sources and file safety assertions")
