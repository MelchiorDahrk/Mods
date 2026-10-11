-- Real OAAB pickup/place and pose playback, with invalid native references that
-- throw on every field access after deletion (as MWSE userdata does).
package.path="./MWSE/mods/?.lua;"..package.path
local F=dofile("tests/prop_fixture.lua")
local props=require("MannequinPoseDesigner.props")
local rig=require("MannequinPoseDesigner.rig")
local v=require("MannequinPoseDesigner.math3d")
local apiFile=assert(arg[1])
local posed=dofile("tests/template_fixture.lua")
local relaxed=rig.clone(posed)
for _,bone in ipairs(relaxed) do bone.translation={0,0,0}; bone.rotation=v.identity(); bone.scale=1 end
local events,frames,states={},{},{}
local count,invalidReads,skipped=0,0,0
local function check(ok,why) assert(ok,why); count=count+1 end
event={register=function(name,fn,options)
    events[name]=events[name] or {}; table.insert(events[name],{fn=fn,once=options and options.doOnce})
end}
timer={frame={delayOneFrame=function(fn) frames[#frames+1]=fn end}}
local function fire(name)
    local pending=events[name] or {}; events[name]={}
    for _,entry in ipairs(pending) do
        if not entry.once then events[name][#events[name]+1]=entry end
        entry.fn()
    end
end
local function frame()
    local pending=frames; frames={}; for _,fn in ipairs(pending) do fn() end
end
local base={id="ab_mannequinheadm",objectType="npc",inventory={items={}}}
local portableItem={id="AB_Furn_MannequinHeadM"}
local function reference(object,scene)
    local r={}; local state={valid=true,fields={object=object,data={},sceneNode=scene,cell={},scale=1,
        position=tes3vector3.new(),orientation=tes3vector3.new(),deleted=false,updateLighting=function() end}}
    states[r]=state
    state.fields.delete=function() state.valid=false end
    return setmetatable(r,{
        __index=function(_,key)
            if not state.valid then invalidReads=invalidReads+1; error("sol: received nil for 'self' argument") end
            return state.fields[key]
        end,
        __newindex=function(_,key,value) assert(state.valid); state.fields[key]=value end,
    })
end
tes3.event={simulate="simulate",simulated="simulated"}
tes3.objectType={npc="npc"}; tes3.player={}
tes3.makeSafeObjectHandle=function(r)
    return {valid=function() return states[r].valid end,getObject=function()
        assert(states[r].valid,"Do not resolve an invalid safe handle"); return r
    end}
end
tes3.skipAnimationFrame=function(args) assert(states[args.reference].valid); skipped=skipped+1 end
tes3.messageBox=function() error("Unexpected pickup error") end
tes3.getObject=function() return base end
local itemData
tes3.addItem=function() itemData={data={}}; return 1,portableItem,itemData end
tes3.createReference=function() return reference(base,F.scene(relaxed)) end
local source,sourceNodes=F.scene(posed)
local wrapper=F.node(props.prefix.."0001"); wrapper:attachChild(F.mesh())
wrapper.translation=tes3vector3.new(2,3,4); wrapper.scale=0.7
rig.find(source,"Bip01 R Hand"):attachChild(wrapper)
local free=F.node(props.prefix.."0002"); free:attachChild(F.mesh())
free.translation=tes3vector3.new(20,-10,5); source:attachChild(free); source:update()
tes3.loadMesh=function(file,cache)
    assert(cache==false)
    return file=="plain.nif" and F.scene(posed) or source
end
package.loaded['OAAB.Mannequins.discovery']={
    getMannequinProfile=function(r) return r.object==base and {id="full"} end,
    isMannequin=function(r) return r.object==base end,
    isPortable=function(r) return r.object==portableItem end,
    getPortableId=function() return portableItem.id end,getMannequinId=function() return base.id end,
}
package.loaded['OAAB.Mannequins.retail']={clearDisplay=function() return true end,hasRealItems=function() return false end}
package.preload['OAAB.Mannequins.pose_props']=function() return dofile(apiFile:gsub("poses%.lua$","pose_props.lua")) end
local api=dofile(apiFile); package.loaded['OAAB.Mannequins.poses']=api
local pickup=dofile(apiFile:gsub("poses%.lua$","pickup.lua"))
local function wrappers(root)
    local total=0
    local function visit(node)
        if node.name:sub(1,#props.prefix)==props.prefix then total=total+1; return end
        if node:isInstanceOfType(tes3.niType.NiNode) then
            for _,child in pairs(node.children) do if child then visit(child) end end
        end
    end
    visit(root); return total
end
local function matchesPose(r)
    local captured=rig.capture(r.sceneNode)
    for i,bone in ipairs(posed) do
        if math.abs(captured[i].scale-bone.scale)>1e-6 then return false end
        for _,key in ipairs({"translation","rotation"}) do
            for j,n in ipairs(bone[key]) do if math.abs(captured[i][key][j]-n)>1e-6 then return false end end
        end
    end
    return true
end
local live=reference(base,F.scene(relaxed))
local other=reference(base,F.scene(relaxed))
check(api.select(live,"props.nif") and api.select(other,"plain.nif"),"Start decorated and ordinary pose playback")
for cycle=1,3 do
    local old=live
    check(pickup.pickUp(old),"Pick up a posed mannequin with visual props")
    check(itemData.data.oaabMannequins.poseFile=="props.nif","Portable item retains its saved pose path")
    check(pcall(fire,"simulate") and pcall(fire,"simulated"),"Deleted pickup reference cannot interrupt pose events")
    local dropped=reference(portableItem)
    dropped.data=itemData.data
    live=assert(pickup.place(dropped)); frame()
    check(api.getSelectedFile(live)=="props.nif" and matchesPose(live),"Drop restores all saved bone transforms")
    check(wrappers(live.sceneNode)==2,"Drop restores one bone prop and one free prop without duplicates")
    local hand=rig.find(live.sceneNode,"Bip01 R Hand")
    check(rig.find(live.sceneNode,wrapper.name).parent==hand and rig.find(live.sceneNode,free.name).parent==live.sceneNode,
        "Both prop attachment modes survive portable placement")
    local _,liveNodes=rig.capture(live.sceneNode); local _,otherNodes=rig.capture(other.sceneNode)
    rig.apply(relaxed,liveNodes,live.sceneNode); rig.apply(relaxed,otherNodes,other.sceneNode)
    local before=skipped
    check(pcall(fire,"simulate") and pcall(fire,"simulated"),"Playback remains safe after the new reference is placed")
    check(matchesPose(live) and matchesPose(other) and skipped==before+2,
        "Animation cannot leave either the dropped or another mannequin relaxed")
    check(wrappers(live.sceneNode)==2,"Maintaining bone transforms leaves embedded props intact")
end
local stale=reference(base,F.scene(relaxed))
check(api.select(stale,"props.nif"),"Track another posed reference before native deletion")
stale:delete()
check(pcall(api.refreshFile,"props.nif"),"Refresh ignores invalid references before reading persistent state")
local placeholder=reference(base,F.scene(relaxed)); api.suspend(placeholder,true); placeholder:delete()
check(pcall(api.refreshFile,"props.nif") and pcall(fire,"simulate") and pcall(fire,"simulated"),
    "Deleted suspended placeholders are retired safely")
local suspended=reference(base,F.scene(relaxed)); api.select(suspended,"props.nif"); api.suspend(suspended,true); suspended:delete()
check(pcall(fire,"simulate") and pcall(fire,"simulated"),"Invalid handles are checked even for suspended pose entries")
live.sceneNode=F.scene(relaxed)
check(pcall(fire,"simulate") and pcall(fire,"simulated"),"Scene replacement does not use cached bones from the previous scene")
check(api.apply(live) and matchesPose(live) and wrappers(live.sceneNode)==2,"Normal rebuild flow rebinds the pose and props to the new scene")
check(invalidReads==0,"No deleted reference field was read anywhere in maintenance or refresh")
print("PASS: "..count.." portable pose/prop lifecycle, invalid userdata, refresh and scene-rebuild assertions")
