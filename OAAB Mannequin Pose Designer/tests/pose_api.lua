local apiFile=assert(arg[1],"Pass OAAB_Data poses.lua")
local function check(ok,reason) assert(ok,reason) end
package.preload["OAAB.Mannequins.discovery"]=function()
    return {getMannequinProfile=function() return {id="full"} end}
end
local function value(n)
    return {n=n,copy=function(self) return value(self.n) end}
end
local function node(name,number,children)
    local result={name=name,translation=value(number),rotation=value(number),scale=1,children=children or {}}
    function result:isInstanceOfType(kind) return kind=="NiNode" end
    function result:update() self.updates=(self.updates or 0)+1 end
    return result
end
local function tree(number)
    local children={}
    for i=1,30 do children[i]=node("Bip01 Test"..i,number+i) end
    return node("Scene",0,{node("Bip01",number,children)})
end
local source=tree(100)
local target=tree(0)
local callbacks={}
local skipped=0
event={register=function(name,fn)
    callbacks[name]=callbacks[name] or {}
    callbacks[name][#callbacks[name]+1]=fn
end}
tes3={event={simulate="simulate",simulated="simulated"},niType={NiNode="NiNode"},
    loadMesh=function(file,cache) assert(file=="pose.nif" and cache==false); return source end,
    loadAnimation=function() error("Dead mannequin must not use native animation loading") end,
    skipAnimationFrame=function() skipped=skipped+1 end,
    makeSafeObjectHandle=function(ref)
        return {valid=function() return true end,getObject=function() return ref end}
    end}
mwse={log=function() end}
local ref={data={},sceneNode=target,isDead=false,updateLighting=function() end}
local api=assert(loadfile(apiFile))()
local registered={label="Registered",file="registered.nif"}
api.registerPose("z",registered)
api.registerPose("a",{label="First registered",file="first.nif"})
local catalog=api.listPoses()
check(#catalog==6 and catalog[1].file=="oaab/k/mann_relax.nif" and catalog[5].file=="first.nif"
    and catalog[6].file=="registered.nif","Catalog includes stock and sorted registered poses without a mannequin")
catalog[1].label="Changed default"; catalog[6].file="changed.nif"; table.remove(catalog,2)
local fresh=api.listPoses()
check(#fresh==6 and fresh[1].label=="Relaxed" and fresh[6].file==registered.file,
    "Catalog snapshots cannot mutate built-in poses, registrations or later lists")
api.unregisterPose("z"); api.unregisterPose("a")
check(#api.listPoses()==4,"Unregistered poses disappear from the independent catalog")
check(api.apiVersion>=2,"Static pose API is available")
check(api.select(ref,"pose.nif"),"Mannequin accepts a NIF pose without native loading")
check(api.getSelectedFile(ref)=="pose.nif","Selected pose persists in reference data")
local live=target.children[1]
check(live.translation.n==100 and live.children[1].translation.n==101,"NIF bone transforms are applied")
live.children[1].translation=value(-1)
for _,fn in ipairs(callbacks.simulate) do fn() end
check(skipped==1,"Native animation frame is skipped for a selected static pose")
for _,fn in ipairs(callbacks.simulated) do fn() end
check(live.children[1].translation.n==101,"Static pose is maintained after simulation")
api.suspend(ref,true)
live.children[1].translation=value(-2)
for _,fn in ipairs(callbacks.simulate) do fn() end
check(skipped==1,"Editor suspension allows its own animation frame handling")
for _,fn in ipairs(callbacks.simulated) do fn() end
check(live.children[1].translation.n==-2,"Designer can suspend static pose playback")
api.suspend(ref,false)
for _,fn in ipairs(callbacks.simulated) do fn() end
check(live.children[1].translation.n==101,"Static pose resumes after editing")
local other={data={},sceneNode=tree(0),updateLighting=function() end}
check(api.select(other,"pose.nif"),"Another mannequin uses the same saved pose")
source=tree(200)
api.refreshFile("POSE.NIF",ref)
check(other.sceneNode.children[1].translation.n==200 and live.translation.n==100,
    "Committed replacements refresh other loaded users, matching paths without case sensitivity")
for _,fn in ipairs(callbacks.simulated) do fn() end
check(other.sceneNode.children[1].children[1].translation.n==201,
    "Static playback maintains the refreshed transforms")
check(api.getSelectedFile(other)=="pose.nif","Refresh retains persistent file identity")
local saved={data={}}
api.setSelectedFile(saved,"pose/k/TestPose.nif")
check(api.getSelectedFile(saved)=="pose/k/TestPose.nif","Selections retain their exact file path")
api.setSelectedFile(saved,nil)
check(api.getSelectedFile(saved)==nil,"Selections can be cleared")
api.setSelectedFile(saved,"oaab/k/mann_relax.nif")
check(api.getSelectedFile(saved)=="oaab/k/mann_relax.nif","Unregistered stock paths retain their identity")
print("PASS: direct mannequin pose application, refresh and editor suspension")
