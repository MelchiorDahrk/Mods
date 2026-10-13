-- Actual bundle deletion and OAAB playback with native scene/loader doubles.
-- Stock poses deliberately have no loose NIF, modelling installation in a BSA.
local lfs=require("lfs")
local project=lfs.currentdir():gsub("\\","/")
package.path=project.."/MWSE/mods/?.lua;"..package.path
local F=dofile("tests/prop_fixture.lua")
local rig=require("MannequinPoseDesigner.rig")
local props=require("MannequinPoseDesigner.props")
local relaxed=dofile("tests/template_fixture.lua")
local custom=rig.clone(relaxed); custom[1].translation[3]=custom[1].translation[3]+40
local apiFile=assert(arg[1])
local count=0
local function check(ok,why) assert(ok,why); count=count+1 end
local callbacks,logs,loads={},{},{}
event={register=function(name,fn,options)
    callbacks[name]=callbacks[name] or {}; callbacks[name][#callbacks[name]+1]={fn=fn,once=options and options.doOnce}
end}
local function fire(name)
    local pending=callbacks[name] or {}; callbacks[name]={}
    for _,entry in ipairs(pending) do
        if not entry.once then callbacks[name][#callbacks[name]+1]=entry end
        entry.fn()
    end
end
mwse.log=function(format,...) logs[#logs+1]=string.format(format,...) end
tes3.event={simulate="simulate",simulated="simulated"}
tes3.messageBox=function() error("Missing assigned poses must not display messages") end
tes3.skipAnimationFrame=function(args) args.reference.skipped=(args.reference.skipped or 0)+1 end
tes3.makeSafeObjectHandle=function(reference)
    return {valid=function() return not reference.invalid end,getObject=function() return reference end}
end
package.loaded["OAAB.Mannequins.discovery"]={getMannequinProfile=function(reference)
    return {id=reference.profile or "full"}
end}
package.preload["OAAB.Mannequins.pose_props"]=function()
    return dofile(apiFile:gsub("poses%.lua$","pose_props.lua"))
end
local source=F.scene(custom)
local wrapper=F.node(props.prefix.."0001"); wrapper:attachChild(F.mesh())
rig.find(source,"Bip01 R Hand"):attachChild(wrapper)
local fallbackFile="oaab/k/mann_relax.nif"
local file="pose/k/delete_me.nif"
local errorMode,defaultMissing
local function identity(path) return path:lower():gsub("\\","/") end
tes3.getFileSource=function(path)
    path=identity(path)
    check(path:sub(1,7)=="meshes/","Existence resolution is relative to Data Files and includes Meshes")
    path=path:sub(8)
    if path==fallbackFile then return not defaultMissing and "bsa" or nil end
    if errorMode or lfs.attributes("Data Files/meshes/"..path,"mode")=="file" then return "file" end
end
tes3.loadMesh=function(path,cache)
    check(cache==false,"Playback bypasses the native mesh cache, including after deletion")
    path=identity(path); loads[path]=(loads[path] or 0)+1
    if path==fallbackFile then return not defaultMissing and F.scene(relaxed) or nil end
    if lfs.attributes("Data Files/meshes/"..path,"mode")=="file" then return source end
    if errorMode=="throw" then error("Missing NIF") end
    if errorMode=="marker" then return F.node("Marker_Error") end
    return nil
end
local api=dofile(apiFile); package.loaded["OAAB.Mannequins.poses"]=api
local library=require("MannequinPoseDesigner.library")
local run=1; while lfs.attributes(".work/missing-pose-"..run) do run=run+1 end
assert(lfs.mkdir(".work/missing-pose-"..run)); assert(lfs.chdir(".work/missing-pose-"..run))
for _,path in ipairs({"Data Files","Data Files/meshes","Data Files/meshes/pose","Data Files/meshes/pose/k"}) do assert(lfs.mkdir(path)) end
local function write(path)
    local output=assert(io.open(library.disk(path),"wb"))
    assert(output:write("NiTriShape NiSkinInstance NiKeyframeController")); assert(output:close())
end
for _,path in ipairs({file,"pose/k/xdelete_me.nif","pose/k/xdelete_me.kf","pose/k/unrelated.nif"}) do write(path) end
local function reference(scene)
    return {data={},sceneNode=scene or F.scene(relaxed),updateLighting=function(self) self.lit=(self.lit or 0)+1 end}
end
local function matches(reference,bones)
    local captured=rig.capture(reference.sceneNode)
    for i,bone in ipairs(bones) do
        for _,key in ipairs({"translation","rotation"}) do
            for j,value in ipairs(bone[key]) do if math.abs(value-captured[i][key][j])>1e-6 then return false end end
        end
        if math.abs(bone.scale-captured[i].scale)>1e-6 then return false end
    end
    return true
end
local first,other=reference(),reference()
check(api.select(first,file) and api.select(other,"POSE\\K\\DELETE_ME.NIF"),"Two loaded mannequins share a custom pose with differently spelled paths")
check(matches(first,custom) and rig.find(first.sceneNode,wrapper.name),"Assigned custom pose includes its transforms and props")
local unrelated=reference(); check(api.select(unrelated,"pose/k/unrelated.nif"),"Another mannequin uses an unrelated custom pose")
local stale=reference(); check(api.select(stale,file),"Track a reference that becomes invalid before deletion"); stale.invalid=true
logs={}
local originalLoads=loads[file]
library.remove(file)
check(not lfs.attributes(library.disk(file)) and not lfs.attributes(library.disk("pose/k/xdelete_me.nif"))
    and not lfs.attributes(library.disk("pose/k/xdelete_me.kf")),"Deletion removes precisely the saved pose bundle")
check(api.getSelectedFile(first)==fallbackFile and api.getSelectedFile(other)==fallbackFile,
    "All loaded users immediately persist Relaxed after deletion, ignoring case/slash spelling")
check(matches(first,relaxed) and matches(other,relaxed) and not rig.find(first.sceneNode,wrapper.name)
    and not rig.find(other.sceneNode,wrapper.name),"Fallback restores the Relaxed skeleton and removes embedded props")
check(#logs==0,"Handled missing assignments are quiet")
check(loads[file]==originalLoads,"Deleted files bypass the native mesh loader and its missing-file warnings")
check(lfs.attributes(library.disk("pose/k/unrelated.nif")) and api.getSelectedFile(unrelated)=="pose/k/unrelated.nif"
    and matches(unrelated,custom) and rig.find(unrelated.sceneNode,wrapper.name),"Unrelated pose files, assignments and props stay intact")
local attempted=loads[file]
api.apply(first); fire("simulate"); fire("simulated")
check(loads[file]==attempted and matches(first,relaxed),"Later rebuilds and static playback do not retry the deleted file")
check(first.skipped and first.lit,"Fallback retains normal animation suppression and deferred lighting")
check(not lfs.attributes(library.disk(fallbackFile)),"Relaxed resolves through the native BSA-aware loader without a loose file")
for _,mode in ipairs({"nil","throw","marker"}) do
    errorMode=mode
    local restored=reference(); restored.data={oaabMannequins={poseFile=file}}
    logs={}
    check(api.apply(restored) and api.getSelectedFile(restored)==fallbackFile and matches(restored,relaxed),
        "Saved assignments fall back for native loader outcome: "..mode)
    check(#logs==0,"Successful fallback emits no load-error log for "..mode)
    restored.sceneNode=F.scene(custom)
    check(api.apply(restored) and matches(restored,relaxed),"Scene replacement rebinds the persisted fallback")
end
errorMode=nil
local unloaded=reference(); unloaded.sceneNode=nil; api.setSelectedFile(unloaded,file)
check(not api.apply(unloaded) and api.getSelectedFile(unloaded)==file,"An unloaded mannequin retains its assignment until a scene is available")
unloaded.sceneNode=F.scene(custom)
check(api.apply(unloaded) and api.getSelectedFile(unloaded)==fallbackFile and matches(unloaded,relaxed),
    "A previously unloaded mannequin falls back when its scene returns")
local suspended=reference(); api.setSelectedFile(suspended,file); api.suspend(suspended,true)
check(api.apply(suspended) and api.getSelectedFile(suspended)==fallbackFile,"A resumed saved assignment can recover a missing pose")
rig.find(suspended.sceneNode,"Bip01").translation.z=-100
fire("simulated")
check(rig.find(suspended.sceneNode,"Bip01").translation.z==-100,"Fallback preserves editor suspension")
api.suspend(suspended,false); fire("simulated")
check(matches(suspended,relaxed),"Static Relaxed playback resumes normally after suspension")
logs={}
check(not api.select(unrelated,"missing.nif") and api.getSelectedFile(unrelated)=="pose/k/unrelated.nif"
    and matches(unrelated,custom) and rig.find(unrelated.sceneNode,wrapper.name),"Explicit failed selection still restores the previous pose and props")
local broken=reference(); api.setSelectedFile(broken,file); defaultMissing=true
check(not api.apply(broken) and api.getSelectedFile(broken)==file,"A failed Relaxed load does not falsely commit a fallback assignment")
defaultMissing=false; logs={}
check(api.apply(broken) and api.getSelectedFile(broken)==fallbackFile and #logs==0,"A fallback can recover after the stock asset becomes available")
local stand=reference(); stand.profile="stand"; api.setSelectedFile(stand,file)
local before=loads[file]
check(not api.apply(stand) and api.getSelectedFile(stand)==file and loads[file]==before,"Dress stands remain outside pose playback and fallback")
print("PASS: "..count.." real bundle deletion, loaded/unloaded missing-pose fallback, BSA defaults, prop cleanup and quiet playback assertions")
