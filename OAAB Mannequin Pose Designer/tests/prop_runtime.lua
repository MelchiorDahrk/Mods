package.path="./MWSE/mods/?.lua;"..package.path
local F=dofile("tests/prop_fixture.lua")
local props=require("MannequinPoseDesigner.props")
local rig=require("MannequinPoseDesigner.rig")
local bones=dofile("tests/template_fixture.lua")
local apiFile=assert(arg[1])
package.preload['OAAB.Mannequins.pose_props']=function() return dofile(apiFile:gsub("poses%.lua$","pose_props.lua")) end
package.preload['OAAB.Mannequins.discovery']=function() return {getMannequinProfile=function() return {id="full"} end} end
local events={}
event={register=function(name,fn) events[name]=events[name] or {}; table.insert(events[name],fn) end}
tes3.event={simulate="simulate",simulated="simulated"}
tes3.skipAnimationFrame=function() end
tes3.makeSafeObjectHandle=function(r) return {valid=function() return true end,getObject=function() return r end} end
local source,sourceNodes=F.scene(bones)
local p={id="0001",objectId="test",name="Sword",mesh="sword.nif",attachmentType="bone",parentBone="Bip01 R Hand",
    translation={2,-3,4},rotation={1,0,0,0,1,0,0,0,1},scale=0.75}
local wrapper=F.node(props.prefix..p.id); wrapper:attachChild(F.mesh()); props.apply(p,wrapper)
rig.find(source,p.parentBone):attachChild(wrapper)
local free=F.node(props.prefix.."0002"); free:attachChild(F.mesh()); free.translation=tes3vector3.new(30,-25,0)
source:attachChild(free); source:update()
tes3.loadMesh=function(file,cache)
    assert(cache==false)
    if file=="empty.nif" then return F.scene(bones) end
    if file=="bad.nif" then error("Bad NIF") end
    return source
end
local ref={data={},sceneNode=F.scene(bones),updateLighting=function() end}
local api=dofile(apiFile)
local count=0
local function check(ok,why) assert(ok,why); count=count+1 end
local logged=0
mwse.log=function() logged=logged+1 end
check(api.apiVersion>=5 and api.select(ref,"props.nif"),"API v5 applies decorated NIF without the designer")
check(logged==0,"Standalone embedded-prop playback is quiet")
local live=rig.find(ref.sceneNode,wrapper.name)
check(live and live~=wrapper and live.parent.name==p.parentBone,"Bone prop is independently cloned beneath runtime skeleton")
check(rig.find(ref.sceneNode,free.name).parent==ref.sceneNode,"Free prop stays outside Bip01")
for _,fn in ipairs(events.simulated) do fn() end
check(live.translation.x==2 and live.scale==0.75,"Normal static-pose maintenance retains wrapper transforms")
check(api.select(ref,"props.nif"),"Selecting the same pose can refresh props")
local function countWrappers(root)
    local total=0
    local function visit(n)
        if n.name:sub(1,#props.prefix)==props.prefix then total=total+1; return end
        if n:isInstanceOfType(tes3.niType.NiNode) then for _,c in pairs(n.children) do if c then visit(c) end end end
    end
    visit(root); return total
end
check(countWrappers(ref.sceneNode)==2,"Refresh never accumulates duplicate wrappers")
check(not api.select(ref,"bad.nif") and countWrappers(ref.sceneNode)==2,"Failed pose switch retains prior props")
check(api.select(ref,"empty.nif") and countWrappers(ref.sceneNode)==0,"Switching to ordinary pose removes old props")
check(api.select(ref,"props.nif"),"Props can be restored after switching poses")
api.setSelectedFile(ref,nil); check(countWrappers(ref.sceneNode)==0,"Clearing pose selection removes runtime props")
local runtime=require('OAAB.Mannequins.pose_props')
local prepared=runtime.prepare(source,source.children[1],ref.sceneNode.children[1],{})
check(prepared[1].parent==ref.sceneNode,"Missing runtime bone falls back to root")
runtime.debugLog=require("MannequinPoseDesigner.logger")
local config=require("MannequinPoseDesigner.config")
logged=0
runtime.prepare(source,source.children[1],ref.sceneNode.children[1],{})
check(logged==0,"Missing-parent diagnostics respect disabled debug mode")
config.debugMode=true
runtime.prepare(source,source.children[1],ref.sceneNode.children[1],{})
check(logged>0,"Missing-parent diagnostics use the enabled designer logger")
logged=0
api.select(ref,"props.nif")
check(logged==1,"Embedded-prop application uses the enabled designer logger")
config.debugMode=false
logged=0
api.select(ref,"props.nif")
check(logged==0,"Disabling debug silences runtime playback immediately")
local badParent=F.node("Bad Parent"); badParent.attachChild=function() error("Attachment failed") end
check(not pcall(runtime.replace,ref.sceneNode,{{node=F.node(props.prefix.."0003"),parent=badParent}})
    and countWrappers(ref.sceneNode)==2,"Failed runtime attachment restores existing wrappers")
print("PASS: "..count.." embedded NIF runtime playback, refresh, fallback and pose-switch cleanup assertions")
