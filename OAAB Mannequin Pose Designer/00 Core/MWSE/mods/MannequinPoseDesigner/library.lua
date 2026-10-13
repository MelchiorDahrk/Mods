local log=require("MannequinPoseDesigner.logger")
local lfs = require("lfs")
local nif = require("MannequinPoseDesigner.nif")
local rig = require("MannequinPoseDesigner.rig")
local props = require("MannequinPoseDesigner.props")
local poseMetadata = require("MannequinPoseDesigner.pose_metadata")
local propMetadata = require("MannequinPoseDesigner.prop_metadata")
-- Morrowind's actor model path has a 31-character limit. Leave one character
-- for the x-prefixed animation companions that its loader derives.
local M = {
    folder="pose/k",
    cache="pose/k/c",
    templateRoot="Data Files/MWSE/mods/MannequinPoseDesigner/templates",
}
-- The companion's x prefix and .nif extension leave 19 characters for the ID.
M.maxIdLength=31-#(M.folder.."/x.nif")
local serial=0
-- Built-in poses are available to the library and blend dialog.
local defaults={
    {label="Relaxed (Default)",file="oaab/k/mann_relax.nif"},
    {label="Contrapposto (Default)",file="oaab/k/mann_contrapposto.nif"},
    {label="Adlocutio (Default)",file="oaab/k/mann_adlocutio.nif"},
    {label="Adlocutio II (Default)",file="oaab/k/mann_adlocutio2.nif"},
}
local defaultFiles={}
for _,pose in ipairs(defaults) do defaultFiles[pose.file]=true end
local digits="0123456789abcdefghijklmnopqrstuvwxyz"
local function base36(n,width)
    local out=""
    repeat
        local digit=n%36
        out=digits:sub(digit+1,digit+1)..out
        n=math.floor(n/36)
    until n==0
    assert(#out<=width,"Pose name timestamp overflow")
    return string.rep("0",width-#out)..out
end
local function disk(path) return "Data Files/meshes/"..path end
local function mkdir(path)
    local current=""
    for part in path:gmatch("[^/]+") do
        current=current=="" and part or current.."/"..part
        if lfs.attributes(current,"mode")~="directory" then assert(lfs.mkdir(current)) end
    end
end
local function exists(path) return lfs.attributes(disk(path),"mode")=="file" end
local playableCache={}
local function playable(file)
    local attr=lfs.attributes(disk(file))
    local stamp=type(attr)=="table" and attr.modification and attr.size
        and tostring(attr.modification)..":"..tostring(attr.size)
    local cached=playableCache[file]
    if stamp and cached and cached.stamp==stamp then return cached.value end
    local f=io.open(disk(file),"rb")
    if not f then return false end
    local bytes=f:read("*a")
    f:close()
    local valid=not not (bytes and bytes:find("NiTriShape",1,true)
        and bytes:find("NiSkinInstance",1,true)
        and bytes:find("NiKeyframeController",1,true))
    if stamp then playableCache[file]={stamp=stamp,value=valid} end
    return valid
end
local function companions(file)
    local directory,stem=file:match("^(.*)/([^/]+)%.[Nn][Ii][Ff]$")
    assert(directory and stem,"Invalid pose path")
    return directory.."/x"..stem..".nif",directory.."/x"..stem..".kf"
end
local function identity(file)
    return type(file)=="string" and file:lower():gsub("\\","/") or ""
end
function M.isDefault(file) return defaultFiles[identity(file)]==true end
function M.isCustom(file)
    local path=identity(file)
    if path:sub(1,#M.folder+1)~=M.folder.."/" then return false end
    local name=path:sub(#M.folder+2)
    if not name:match("^[%w_%-]+%.nif$") then return false end
    return not (name:sub(1,1)=="x" and exists(M.folder.."/"..name:sub(2)))
end
function M.poseId(file)
    local stem=file:match("([^/\\]+)%.[Nn][Ii][Ff]$") or file
    return stem
end
local descriptiveCache={}
function M.invalidate(file)
    if file then
        descriptiveCache[identity(file)]=nil
        playableCache[file]=nil
    else descriptiveCache={}; playableCache={} end
end
function M.readMetadata(file)
    local key=identity(file)
    local attr=lfs.attributes(disk(file))
    local stamp=type(attr)=="table" and tostring(attr.modification)..":"..tostring(attr.size) or "packed"
    local cached=descriptiveCache[key]
    if not cached or cached.stamp~=stamp then
        cached={stamp=stamp,value=poseMetadata.readFile(file)}
        descriptiveCache[key]=cached
    end
    return cached.value
end
function M.readProps(file)
    return propMetadata.readFile(file)
end
function M.label(file)
    local descriptive=M.readMetadata(file)
    if descriptive and descriptive.name then return descriptive.name end
    local stem=M.poseId(file)
    return M.isCustom(file) and stem:gsub("_"," ") or stem
end
function M.find(file)
    if not M.isCustom(file) then return end
    for _,pose in ipairs(M.list()) do
        if identity(pose.file)==identity(file) then return pose end
    end
end
local function write(path,bytes)
    local f=assert(io.open(path,"wb"))
    local ok,err=f:write(bytes)
    local closed,closeErr=f:close()
    assert(ok,err); assert(closed,closeErr)
end
-- Stage complete output before moving any existing file. Keep backups until
-- the caller has applied the pose, then commit or roll back the entire bundle.
local function publish(file,contents,apply,createOnly)
    local paths={}
    local token=".edit-"..base36(os.time(),7).."-"..base36(serial,2)
    serial=(serial+1)%1296
    for _,part in ipairs(contents) do
        local path=disk(part.file)
        local mode=lfs.attributes(path,"mode")
        assert(not createOnly or not mode,"A file for this ID already exists: "..part.file)
        assert(not mode or mode=="file","Pose path is not a file: "..part.file)
        local entry={path=path,stage=path..token..".tmp"..(part.decorate and ".nif" or ""),backup=path..token..".bak",bytes=part.bytes,decorate=part.decorate}
        assert(not lfs.attributes(entry.stage) and not lfs.attributes(entry.backup),"Pose transaction path is occupied")
        paths[#paths+1]=entry
    end
    local ok,err=pcall(function()
        for _,entry in ipairs(paths) do
            assert(not createOnly or not lfs.attributes(entry.path),"A file for this ID appeared while saving")
            write(entry.stage,entry.bytes)
            if entry.decorate then entry.decorate(entry.stage) end
        end
        for _,entry in ipairs(paths) do
            assert(not createOnly or not lfs.attributes(entry.path),"A file for this ID appeared while saving")
            if lfs.attributes(entry.path,"mode")=="file" then
                assert(os.rename(entry.path,entry.backup))
                entry.backedUp=true
            end
            assert(os.rename(entry.stage,entry.path))
            entry.published=true
        end
        if apply then apply(file) end
    end)
    if not ok then
        local problems={}
        for i=#paths,1,-1 do
            local entry=paths[i]
            if entry.published then
                local removed,problem=os.remove(entry.path)
                if not removed then problems[#problems+1]=tostring(problem) end
            end
            if entry.backedUp then
                local restored,problem=os.rename(entry.backup,entry.path)
                if not restored then problems[#problems+1]=tostring(problem) end
            end
            os.remove(entry.stage)
        end
        error(tostring(err)..(#problems>0 and " (rollback: "..table.concat(problems,"; ")..")" or ""))
    end
    for _,entry in ipairs(paths) do
        if entry.backedUp then
            local removed,problem=os.remove(entry.backup)
            if not removed then log("[OAAB Pose Designer] Backup retained at %s: %s",entry.backup,tostring(problem)) end
        end
    end
    return file
end
local function template(name)
    local path=M.templateRoot.."/"..name
    local f=assert(io.open(path,"rb"),"Missing animation template: "..path)
    local bytes=assert(f:read("*a"))
    assert(f:close())
    return bytes
end
local function render(bones,sourceFile)
    local main=template("mann_relax.nif")
    if sourceFile then
        local input=io.open(disk(sourceFile),"rb")
        if input then main=assert(input:read("*a")); assert(input:close()) end
    end
    return nif.patchTemplate(bones,main,"nif"),
        nif.patchTemplate(bones,template("xmann_relax.nif"),"xnif"),
        nif.patchTemplate(bones,template("xmann_relax.kf"),"kf")
end
local function mainPart(file,bytes,bones,definitions,descriptive,sourceFile)
    local part={file=file,bytes=bytes}
    local hasDefinitions=definitions and (#definitions>0 or sourceFile and select(2,M.readProps(sourceFile)))
    if hasDefinitions then
        local copied=props.clone(definitions)
        part.decorate=function(stage)
            -- Checkpoints keep definitions without importing source meshes.
            if file:sub(1,#M.cache+1)~=M.cache.."/" then props.decorate(stage,copied,bones,true) end
            propMetadata.decorate(stage,copied)
        end
    end
    if descriptive then
        local decorate=part.decorate
        part.decorate=function(stage)
            if decorate then decorate(stage) end
            poseMetadata.decorate(stage,descriptive)
        end
    end
    return part
end
local function unique(folder)
    mkdir(disk(folder))
    local file,x,kf
    repeat
        serial=(serial+1)%1296
        file=folder.."/p"..base36(os.time(),7)..base36(serial,2)..".nif"
        x,kf=companions(file)
    until not exists(file) and not exists(x) and not exists(kf)
    assert(#x<=31 and #kf<=31,"Animation paths must be at most 31 characters")
    return file
end
function M.replace(bones,file,apply,definitions)
    local pose=assert(M.find(file),"Only an existing custom pose can be replaced")
    local mainBytes,xBytes,kfBytes=render(bones,pose.file)
    local x,kf=companions(pose.file)
    assert(#x<=31 and #kf<=31,"Pose filename is too long for Morrowind animations")
    local contents={{file=x,bytes=xBytes},{file=kf,bytes=kfBytes}}
    local descriptive=M.readMetadata(pose.file)
    if descriptive and descriptive.id then descriptive.name=descriptive.name or pose.label else descriptive=nil end
    contents[#contents+1]=mainPart(pose.file,mainBytes,bones,definitions,descriptive,pose.file)
    local result=publish(pose.file,contents,apply)
    M.invalidate(pose.file)
    return result
end
function M.write(bones,descriptive,definitions,apply,sourceFile,records)
    local file
    if descriptive then
        descriptive=poseMetadata.validate(descriptive)
        local err
        file,err=M.idFile(descriptive.id,records)
        assert(file,err)
    else
        file=unique(M.cache)
    end
    local mainBytes,xBytes,kfBytes=render(bones,sourceFile)
    local x,kf=companions(file)
    local contents={{file=x,bytes=xBytes},{file=kf,bytes=kfBytes}}
    contents[#contents+1]=mainPart(file,mainBytes,bones,definitions,descriptive,sourceFile)
    local result=publish(file,contents,apply,true)
    M.invalidate(file)
    return result
end
function M.removeDraft(file)
    if not file or file:sub(1,#M.cache+1)~=M.cache.."/" then return end
    local x,kf=companions(file)
    os.remove(disk(file)); os.remove(disk(x)); os.remove(disk(kf))
end
function M.remove(file)
    assert(M.isCustom(file),"Only custom poses can be deleted")
    assert(playable(file),"Custom pose file is missing or invalid")
    local x,kf=companions(file)
    local paths={x,kf,file}
    for _,path in ipairs(paths) do
        local mode=lfs.attributes(disk(path),"mode")
        assert(not mode or mode=="file","Pose path is not a file: "..path)
    end
    M.invalidate(file)
    -- Remove the main NIF last. A failed companion deletion keeps the pose
    -- listed, and ensureCompanions can regenerate a partially removed bundle.
    for _,path in ipairs(paths) do
        if exists(path) then
            local ok,err=os.remove(disk(path))
            assert(ok,"Could not delete "..path..": "..tostring(err))
        end
    end
    -- Reapply loaded users only after the bundle is gone. OAAB's missing-file
    -- fallback updates their skeleton, removes props and persists Relaxed.
    -- Unloaded mannequins use the same fallback when their scene is restored.
    local api=package.loaded["OAAB.Mannequins.poses"]
    if api and api.refreshFile then
        local ok,err=pcall(api.refreshFile,file)
        if not ok then log("[OAAB Pose Designer] Deleted pose refresh failed for %s: %s",file,tostring(err)) end
    end
end
function M.read(file)
    -- OAAB's installed defaults can reside in a BSA, which loadMesh resolves
    -- without a loose file. Custom imports still require a complete main NIF.
    if not defaultFiles[file:lower():gsub("\\","/")] then
        assert(playable(file),"Pose NIF lacks the mannequin geometry and cannot be played safely")
    end
    -- Read local pose data from the main NIF without playing it or writing
    -- companions. This also supports a shared pose with only its main file.
    local mesh=assert(tes3.loadMesh(file,false),"Could not load pose NIF")
    local bones,nodes=rig.capture(mesh)
    nif.validate(bones)
    for _,node in ipairs(nodes) do
        local c=node.controller
        assert(c and c:isInstanceOfType(tes3.niType.NiKeyframeController),"Pose NIF is missing a bone keyframe controller")
    end
    return bones
end
function M.ensureCompanions(file)
    assert(M.isCustom(file),"Only custom pose companions can be generated")
    local x,kf=companions(file)
    assert(#x<=31 and #kf<=31,"Pose filename is too long for Morrowind animations")
    assert(playable(file),"Pose NIF lacks the mannequin geometry and cannot be played safely")
    if exists(x) and exists(kf) then return end
    local bones=M.read(file)
    local _,xBytes,kfBytes=render(bones)
    write(disk(x),xBytes)
    write(disk(kf),kfBytes)
end
function M.list()
    mkdir(disk(M.folder))
    local files={}
    for name in lfs.dir(disk(M.folder)) do
        local file=M.folder.."/"..name
        if M.isCustom(file) and playable(file) then
            local descriptive=M.readMetadata(file) or {}
            local label=descriptive.name or M.poseId(file):gsub("_"," ")
            files[#files+1]={file=file,label=label,name=label,id=descriptive.id,
                description=descriptive.description or "",
                category=descriptive.category or "",editable=true,isOAABData=false}
        end
    end
    table.sort(files,function(a,b) return a.file<b.file end)
    return files
end
function M.blendList()
    local files={}
    for _,pose in ipairs(defaults) do files[#files+1]={label=pose.label,file=pose.file} end
    for _,pose in ipairs(M.list()) do files[#files+1]=pose end
    return files
end
function M.disk(file) return disk(file) end
-- IDs are independent of display names. Reserve both descriptive IDs and all
-- bundle filenames, including orphaned companions and metadata-less imports.
function M.idFile(id,records)
    local valid,err=poseMetadata.validateId(id,M.maxIdLength)
    if not valid then return nil,err end
    mkdir(disk(M.folder))
    -- Recheck disk metadata at commit time, including same-size files replaced
    -- within one filesystem timestamp tick. Caller records add registered poses.
    M.invalidate()
    local current=M.list()
    for _,pose in ipairs(defaults) do
        local data=M.readMetadata(pose.file)
        current[#current+1]={file=pose.file,id=data and data.id}
    end
    for _,pose in ipairs(records or {}) do current[#current+1]=pose end
    for _,pose in ipairs(current) do
        local stem=M.poseId(pose.file)
        if (pose.id and pose.id:lower()==id:lower()) or (stem and stem:lower()==id:lower()) then
            return nil,"A pose with that ID already exists. Choose another ID."
        end
    end
    local file=M.folder.."/"..id..".nif"
    local x,kf=companions(file)
    local reserved={}
    for _,path in ipairs({file,x,kf}) do reserved[path:match("[^/]+$"):lower()]=true end
    for entry in lfs.dir(disk(M.folder)) do
        if reserved[entry:lower()] then return nil,"Files for that ID already exist. Choose another ID." end
    end
    return file
end
function M.updateMetadata(file,fields)
    M.invalidate(file)
    local pose=assert(M.find(file),"Only an existing custom pose can have its metadata edited")
    local original=M.readMetadata(file)
    local id=original and original.id or M.poseId(file)
    assert(fields.id==id,"A saved pose's ID cannot be changed")
    fields=poseMetadata.validate(fields)
    local input=assert(io.open(disk(pose.file),"rb")); local bytes=input:read("*a"); assert(input:close())
    publish(pose.file,{{file=pose.file,bytes=bytes,decorate=function(stage) poseMetadata.decorate(stage,fields) end}})
    M.invalidate(pose.file)
    return pose.file
end
function M.removeCategory(category,records)
    assert(type(category)=="string" and category~="" and category~="Uncategorized","Choose a named category to delete")
    -- Recheck every custom pose, including those hidden by source/search/page
    -- filters, and registered read-only files before preparing any writes.
    M.invalidate()
    local current=M.list()
    local custom={}
    for _,pose in ipairs(current) do custom[identity(pose.file)]=true end
    for _,source in ipairs({defaults,records or {}}) do
        for _,pose in ipairs(source) do
            if pose.file and not custom[identity(pose.file)] then
                local fields=M.readMetadata(pose.file)
                assert((fields and fields.category or pose.category)~=category,"Category contains read-only poses and cannot be deleted")
            end
        end
    end
    local contents={}
    for _,pose in ipairs(current) do
        if pose.category==category then
            local input=assert(io.open(disk(pose.file),"rb"))
            local bytes=assert(input:read("*a")); assert(input:close())
            contents[#contents+1]={file=pose.file,bytes=bytes,decorate=function(stage)
                poseMetadata.clearCategory(stage,category)
            end}
        end
    end
    if #contents==0 then return 0 end
    -- Stage and verify every main NIF before publishing, with rollback across
    -- all affected files. Animation companions stay intact.
    publish(contents[1].file,contents)
    M.invalidate()
    return #contents
end
return M
