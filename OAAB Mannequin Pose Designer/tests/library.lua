local lfs=require("lfs")
local root=lfs.currentdir():gsub("\\","/")
package.path=root.."/MWSE/mods/?.lua;"..package.path
assert(lfs.chdir(".work")) -- File tests are confined to the ignored test workspace.
local run=1
while lfs.attributes("library-"..run) do run=run+1 end
assert(lfs.mkdir("library-"..run))
assert(lfs.chdir("library-"..run))
local library=require("MannequinPoseDesigner.library")
-- File transactions are tested here; native metadata serialization is covered
-- by visual_library.lua and prop_export.lua.
require("MannequinPoseDesigner.pose_metadata").decorate=function() end
local v=require("MannequinPoseDesigner.math3d")
local bones=dofile(root.."/tests/template_fixture.lua")
library.templateRoot=root.."/MWSE/mods/MannequinPoseDesigner/templates"
local count=0
local function check(ok,reason) assert(ok,reason); count=count+1 end
local defaults=library.blendList()
check(#defaults==4 and #library.list()==0,"Default poses are available before any custom poses are saved")
local defaultNames={"Relaxed","Contrapposto","Adlocutio","Adlocutio II"}
local defaultStems={"mann_relax","mann_contrapposto","mann_adlocutio","mann_adlocutio2"}
for i,pose in ipairs(defaults) do
    check(pose.label==defaultNames[i].." (Default)" and pose.file=="oaab/k/"..defaultStems[i]..".nif",
        "Default blend choices match OAAB's pose names and NIF paths")
end
defaults[1].label="Changed"
check(library.blendList()[1].label=="Relaxed (Default)","Returned blend lists cannot mutate the built-in definitions")
local file=library.write(bones,{id="First",name="First"})
local other=library.write(bones,{id="Second",name="Second"})
check(file~=other,"Every export has a unique path")
check(library.maxIdLength==19,"ID limit accounts for animation companion")
local named=library.write(bones,{id="Guard_Stance",name="Guard Stance"})
check(named=="pose/k/Guard_Stance.nif","Entered name becomes the pose filename")
local namedX=named:gsub("/([^/]+)$","/x%1")
check(#namedX<=31,"Named companion fits the animation path limit")
check(not pcall(library.write,bones,{id="guard_stance",name="Duplicate"}),"IDs are unique without regard to case")
local x,kf=file:match("^(.*)/([^/]+)%.nif$")
check(#file<=30 and #(x.."/x"..kf..".nif")<=31,"Export and companion paths fit Morrowind's model path limit")
local listed=library.list()
check(#listed>=3,"Exports discovered")
local foundNamed=false
for _,pose in ipairs(listed) do
    if pose.file==named then foundNamed=pose.label=="Guard Stance" end
end
check(foundNamed,"Named pose appears with its readable label")
local combined=library.blendList()
check(#combined==#listed+4,"Both blend lists include defaults followed by the complete custom library")
for i,pose in ipairs(listed) do
    check(combined[i+4].file==pose.file and combined[i+4].label==pose.label,"Custom blend choices retain their own paths and labels")
end
for _,pose in ipairs(listed) do check(not pose.file:match("/xpose_"),"Exclude generated companion skeleton") end
local function read(path) local f=assert(io.open(path,"rb")); local text=f:read("*a"); f:close(); return text end
local bytes=read(library.disk(file))
-- Read main-only shared NIFs without generating companions or selecting an
-- animation. The mesh/capture stubs model the engine's baked local transforms.
local import=library.write(bones,{id="Blend_Source",name="Blend Source"})
local importX=library.disk(import:gsub("/([^/]+)$","/x%1"))
local importKf=importX:gsub("%.nif$",".kf")
assert(os.remove(importX)); assert(os.remove(importKf))
local rig=require("MannequinPoseDesigner.rig")
local capture=rig.capture
local mesh={}
local missingController,missingMesh=false,false
local expectedRead=import
tes3={niType={NiKeyframeController="keyframe"},loadMesh=function(path,cache)
    check(path==expectedRead and cache==false,"Reading uses the selected main NIF and bypasses the mesh cache")
    if not missingMesh then return mesh end
end}
rig.capture=function(rootNode)
    check(rootNode==mesh,"The imported NIF supplies the pose data")
    local nodes={}
    for i=1,#bones do
        nodes[i]={controller=not missingController and {isInstanceOfType=function(_,kind) return kind=="keyframe" end} or nil}
    end
    return rig.clone(bones),nodes
end
for _,pose in ipairs(library.blendList()) do
    if pose.label:find("(Default)",1,true) then
        expectedRead=pose.file
        check(not lfs.attributes(library.disk(pose.file)),"Default fixture has no loose file, modeling BSA-installed assets")
        local stock=library.read(pose.file)
        check(#stock==#bones and stock[1].scale==bones[1].scale,"Defaults load complete local pose data through the mesh loader")
        missingController=true
        check(not pcall(library.read,pose.file),"Default poses still require validated bone controllers")
        missingController=false; missingMesh=true
        check(not pcall(library.read,pose.file),"Missing default assets fail visibly through the mesh loader")
        missingMesh=false
    end
end
expectedRead=import
local imported=library.read(import)
check(#imported==#bones and imported[1].translation[1]==bones[1].translation[1],"Read returns complete local bone transforms")
check(not lfs.attributes(importX) and not lfs.attributes(importKf),"Reading a main-only pose writes no companion files")
imported[1].translation[1]=999
check(bones[1].translation[1]~=999,"Imported data do not alias the capture source")
missingController=true
check(not pcall(library.read,import),"Read rejects a skeleton without pose controllers")
missingController=false; missingMesh=true
check(not pcall(library.read,import),"Read reports a failed mesh load")
missingMesh=false
library.ensureCompanions(import)
check(lfs.attributes(importX,"mode")=="file" and lfs.attributes(importKf,"mode")=="file",
    "The existing importer still generates companions from the same pose data")
rig.capture=capture
library.remove(import)
check(not pcall(library.read,import),"Read reports a removed pose file")
local draft=library.write(bones)
library.removeDraft(draft)
check(not lfs.attributes(library.disk(draft)),"Remove draft")
library.removeDraft(file)
check(read(library.disk(file))==bytes,"Draft cleanup never deletes saved poses")
local originalOpen=io.open
local writes=0
io.open=function(path,mode)
    if mode=="wb" then
        writes=writes+1
        if writes==2 then return nil,"Simulated write failure" end
    end
    return originalOpen(path,mode)
end
local before=#library.list()
local ok=pcall(library.write,bones,{id="Failure",name="Failure"})
io.open=originalOpen
check(not ok and #library.list()==before,"Partial bundle removed on disk error")
local function companionPaths(path)
    local directory,stem=path:match("^(.*)/([^/]+)%.nif$")
    return library.disk(directory.."/x"..stem..".nif"),library.disk(directory.."/x"..stem..".kf")
end
local namedNif,namedKf=companionPaths(named)
library.remove(named)
check(not lfs.attributes(library.disk(named)) and not lfs.attributes(namedNif)
    and not lfs.attributes(namedKf),"Deleting a named pose removes all three files")
check(library.idFile("Guard_Stance")==named,"Deleted pose name can be reused")
local fileNif,fileKf=companionPaths(file)
library.remove(file)
check(not lfs.attributes(library.disk(file)) and not lfs.attributes(fileNif)
    and not lfs.attributes(fileKf),"Saved poses can be deleted")
check(lfs.attributes(library.disk(other),"mode")=="file","Deletion preserves unrelated poses")
local shared=library.write(bones,{id="Shared",name="Shared"})
local sharedNif,sharedKf=companionPaths(shared)
assert(os.remove(sharedNif)); assert(os.remove(sharedKf))
library.remove(shared)
check(not lfs.attributes(library.disk(shared)),"Shared main-only NIF can be deleted")
local protected=library.write(bones,{id="Protected",name="Protected"})
local protectedBytes=read(library.disk(protected))
for _,path in ipairs({"oaab/k/mann_relax.nif","pose/k/xProtected.nif",
    "pose/k/c/p_Protected.nif","pose/k/../Protected.nif",
    "pose/k/..\\Protected.nif",
    "other/p_Protected.nif","pose/k/Protected.nif/extra"}) do
    check(not pcall(library.remove,path),"Refuse non-library or non-custom deletion: "..path)
end
check(read(library.disk(protected))==protectedBytes,"Invalid deletion never touches saved poses")
local protectedNif,protectedKf=companionPaths(protected)
local originalRemove=os.remove
os.remove=function(path)
    if path==protectedKf then return nil,"Simulated removal failure" end
    return originalRemove(path)
end
local removed,removeErr=pcall(library.remove,protected)
os.remove=originalRemove
check(not removed and tostring(removeErr):find("Simulated removal failure",1,true),"Removal failure is reported")
check(read(library.disk(protected))==protectedBytes and lfs.attributes(protectedKf,"mode")=="file",
    "Companion removal failure preserves the main NIF and stops deletion")
local stillListed=false
for _,pose in ipairs(library.list()) do if pose.file==protected then stillListed=true end end
check(stillListed,"Failed removal leaves the pose available in the menu")
library.remove(protected)
check(not lfs.attributes(library.disk(protected)) and not lfs.attributes(protectedKf),"Partially removed pose can be deleted on retry")
check(not pcall(library.remove,protected),"Repeated deletion reports the missing pose")
local editable=library.write(bones,{id="Editable",name="Editable"})
local editableNif,editableKf=companionPaths(editable)
local originalBytes={read(library.disk(editable)),read(editableNif),read(editableKf)}
local changed=rig.clone(bones)
changed[1].translation[3]=changed[1].translation[3]+12
local appliedFile
library.replace(changed,editable,function(path) appliedFile=path end)
check(appliedFile==editable and read(library.disk(editable))~=originalBytes[1],
    "Save Changes keeps the existing identity and publishes modified transforms")
local editedBytes={read(library.disk(editable)),read(editableNif),read(editableKf)}
local function unchanged()
    return read(library.disk(editable))==editedBytes[1] and read(editableNif)==editedBytes[2]
        and read(editableKf)==editedBytes[3]
end
check(not pcall(library.replace,bones,editable,function() error("Cannot apply") end) and unchanged(),
    "Failed pose application rolls all three replacement files back")
writes=0
io.open=function(path,mode)
    if mode=="wb" then writes=writes+1; if writes==2 then return nil,"Disk full" end end
    return originalOpen(path,mode)
end
ok=pcall(library.replace,bones,editable)
io.open=originalOpen
check(not ok and unchanged(),"Staging failure preserves the complete saved bundle")
local originalRename=os.rename
local renames=0
os.rename=function(from,to)
    renames=renames+1
    if renames==4 then return nil,"Rename denied" end
    return originalRename(from,to)
end
ok=pcall(library.replace,bones,editable)
os.rename=originalRename
check(not ok and unchanged(),"A publication failure restores companions already replaced")
for entry in lfs.dir(library.disk(library.folder)) do
    check(not entry:find(".edit-",1,true),"Finished and rolled-back transactions leave no staging files")
end
-- Portable metadata edits and Save As are covered in visual_library.lua.
library.remove(editable)
check(not pcall(library.replace,bones,"oaab/k/mann_relax.nif")
    and not pcall(library.updateMetadata,"pose/k/c/p_test.nif",{id="Unsafe",name="Unsafe"}),"Default and draft poses cannot be replaced or have metadata edited")
assert(lfs.mkdir("Data Files/meshes/oaab")); assert(lfs.mkdir("Data Files/meshes/oaab/k"))
for _,stem in ipairs({"mann_relax","mann_contrapposto","mann_adlocutio","mann_adlocutio2"}) do
    local baseline="oaab/k/"..stem..".nif"
    local output=assert(io.open(library.disk(baseline),"wb"))
    assert(output:write(originalBytes[1])); assert(output:close())
    check(not pcall(library.replace,changed,baseline) and not pcall(library.updateMetadata,baseline,{id="default",name="Renamed Default"})
        and not pcall(library.remove,baseline),
        "Every baseline file is excluded from saved-pose editing and management")
    check(read(library.disk(baseline))==originalBytes[1],"Refused baseline actions preserve actual animation bytes")
end
print("PASS: "..count.." filesystem assertions")
