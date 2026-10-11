-- Real filesystem/template/JSON transactions with a mocked native serializer.
-- Native MWSE saveBinary and rendering remain separate in-game acceptance checks.
local lfs=require("lfs")
local project=lfs.currentdir():gsub("\\","/")
package.path=project.."/MWSE/mods/?.lua;"..package.path
json=dofile(assert(arg[2],"Pass installed MWSE core/lib/dkjson.lua as argument 2"))
local F=dofile("tests/prop_fixture.lua")
local props=require("MannequinPoseDesigner.props")
local rig=require("MannequinPoseDesigner.rig")
local nif=require("MannequinPoseDesigner.nif")
local propMetadata=require("MannequinPoseDesigner.prop_metadata")
local poseMetadata=require("MannequinPoseDesigner.pose_metadata")
local library=require("MannequinPoseDesigner.library")
library.templateRoot=project.."/MWSE/mods/MannequinPoseDesigner/templates"
local bones=dofile("tests/template_fixture.lua")
local run=1
while lfs.attributes(".work/prop-export-"..run) do run=run+1 end
assert(lfs.mkdir(".work/prop-export-"..run)); assert(lfs.chdir(".work/prop-export-"..run))
local count=0
local function check(ok,why) assert(ok,why); count=count+1 end
local function read(path) local f=assert(io.open(path,"rb")); local bytes=f:read("*a"); f:close(); return bytes end
local function paths(file)
    local main=library.disk(file)
    local directory,stem=main:match("^(.*)/([^/]+)%.nif$")
    return {main,directory.."/x"..stem..".nif",directory.."/x"..stem..".kf"}
end
local function bundle(file)
    local out={}; for _,path in ipairs(paths(file)) do if lfs.attributes(path) then out[path]=read(path) end end; return out
end
local mode,serialized,loads="ok",{},0
local marker="\nNATIVE_PROP_MOCK:"
local serial=0
local p={id="0001",objectId="iron_longsword",name="Iron Longsword",mesh="w/sword.nif",attachmentType="bone",
    parentBone="Bip01 R Hand",translation={2,-3,4},rotation={1,0,0,0,1,0,0,0,1},scale=0.75}
local free=props.clone({p})[1]; free.id="0002"; free.mesh="m/book.nif"; free.attachmentType="root"; free.parentBone=nil
tes3.loadMesh=function(path,cache)
    check(cache==false,"Export and mesh imports bypass MWSE's cache")
    loads=loads+1
    if path=="w/sword.nif" or path=="m/book.nif" then
        if mode=="missing" then error("Source mesh missing") end
        return F.mesh()
    end
    local disk="Data Files/meshes/"..path
    local bytes=read(disk)
    local at=bytes:find(marker,1,true)
    local id=at and tonumber(bytes:sub(at+#marker):match("^(%d+)"))
    local root
    if id then
        root=assert(serialized[id]):clone()
        if mode=="lostBone" then root.children[1]:detachChild(root.children[1].children[1]) end
        if mode=="lostProp" then
            local wrapper=rig.find(root,props.prefix..p.id); wrapper.parent:detachChild(wrapper)
        end
        if mode=="lostController" then root.children[1].controller=nil end
        if mode=="lostGeometry" then
            local wrapper=rig.find(root,props.prefix..p.id)
            for _,child in pairs(wrapper.children) do wrapper:detachChild(child) end
        end
    else
        root=F.scene(bones)
    end
    root:update()
    function root:saveBinary(output)
        if mode=="serialize" then return false end
        serial=serial+1; serialized[serial]=self:clone()
        local strings={}; local extra=self.extraData
        while extra do strings[#strings+1]=extra.string; extra=extra.next end
        if mode=="lostMetadata" then serialized[serial].extraData=nil end
        local f=assert(io.open(output,"wb"))
        assert(f:write((at and bytes:sub(1,at-1) or bytes)..marker..serial.."\n"..table.concat(strings,"\n").."mock serialized static props"))
        assert(f:close())
        return true
    end
    return root
end
local noProps=library.write(bones)
local template=read(library.templateRoot.."/mann_relax.nif")
check(read(library.disk(noProps))==nif.patchTemplate(bones,template,"nif"),"No-prop main NIF stays byte-identical to existing patcher")
check(loads==0,"No-prop export uses no scene serialization")
library.removeDraft(noProps)
local file=library.write(bones,{id="Prop_Pose",name="Prop Pose"},{p,free})
local saved=library.readProps(file)
check(#saved==2 and saved[1].id==p.id and saved[1].parentBone==p.parentBone and saved[2].attachmentType=="root","Prop metadata survives NIF save/load")
check(read(library.disk(file)):find(propMetadata.prefix,1,true),"Prop poses embed definitions in the main NIF")
check(saved[1].translation[2]==-3 and saved[1].scale==0.75 and saved[1].mesh==p.mesh,"Metadata keeps source and full local transform")
local outputPaths=paths(file)
local expectedX=nif.patchTemplate(bones,read(library.templateRoot.."/xmann_relax.nif"),"xnif")
local expectedKf=nif.patchTemplate(bones,read(library.templateRoot.."/xmann_relax.kf"),"kf")
check(read(outputPaths[2])==expectedX and read(outputPaths[3])==expectedKf,"Prop export leaves xp NIF/KF byte-identical")
local original=bundle(file)
for _,failure in ipairs({"serialize","missing","lostBone","lostProp","lostController","lostGeometry","lostMetadata"}) do
    mode=failure
    local ok=pcall(library.replace,bones,file,nil,{free,p})
    check(not ok,"Reject failed/unvalidated serialization: "..failure)
    for path,bytes in pairs(original) do check(read(path)==bytes,"Failed postprocessing preserves complete original bundle") end
end
mode="ok"
local ok=pcall(library.replace,bones,file,function() error("Could not apply final pose") end,{free})
check(not ok,"Application failure rolls back decorated export")
for path,bytes in pairs(original) do check(read(path)==bytes,"Rollback includes metadata and all companions") end
library.replace(bones,file,nil,{free})
check(#library.readProps(file)==1 and library.readProps(file)[1].id==free.id,"Overwrite updates prop metadata atomically")
local draft=library.write(bones,nil,{p,free})
check(#library.readProps(draft)==2 and not props.hasEmbedded(tes3.loadMesh(draft,false)),"Draft embeds definitions without importing prop geometry")
library.removeDraft(draft)
for _,path in ipairs(paths(draft)) do check(not lfs.attributes(path),"Draft cleanup removes the NIF/KF bundle") end
library.replace(bones,file,nil,{})
check(#library.readProps(file)==0 and read(library.disk(file)):find("mock serialized static props",1,true),"Deleting all props runs the native replacement pass and clears stale editor metadata")
for entry in lfs.dir(library.disk(library.folder)) do check(not entry:find(".edit-",1,true),"No transaction/temp outputs remain") end
mode="missing"
local missingDraft=library.write(bones,nil,{p})
check(#library.readProps(missingDraft)==1,"Checkpoints retain definitions with unavailable source meshes")
mode="ok"; library.removeDraft(missingDraft)
local fields={id="described",name="Described Props",category="Standing"}
local described=library.write(bones,fields,{p,free})
check(#library.readProps(described)==2 and library.readMetadata(described).name==fields.name,"Prop and descriptive extra data coexist after serialization")
library.updateMetadata(described,{id=fields.id,name="Renamed Props"})
check(#library.readProps(described)==2,"Descriptive edits preserve prop metadata")
local describedCopy=library.write(bones,{id="bothcopy",name="Both Copy"},{p,free},nil,described)
check(#library.readProps(describedCopy)==2 and props.hasEmbedded(tes3.loadMesh(describedCopy,false)),"Save As preserves embedded definitions and geometry")
local root=tes3.loadMesh(file,false); propMetadata.find(root).string=propMetadata.prefix..'{"version":99,"props":[]}'
assert(root:saveBinary(library.disk(file)))
check(not pcall(library.readProps,file),"Unknown embedded metadata version is refused without discarding user data")
library.remove(file)
for _,path in ipairs(paths(file)) do check(not lfs.attributes(path),"Deleting a pose removes the NIF/KF bundle") end
print("PASS: "..count.." staged prop export, embedded metadata, unchanged companions and failure rollback assertions")
