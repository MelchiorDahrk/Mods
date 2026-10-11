-- Model MWSE's in-place StringExtraData constructor and ref-counted native
-- clone using real Lua userdata finalizers. This is not a native-engine test.
package.path="./MWSE/mods/?.lua;"..package.path
json=dofile(assert(arg[2]))
local F=dofile("tests/prop_fixture.lua")
local descriptive=require("MannequinPoseDesigner.pose_metadata")
local props=require("MannequinPoseDesigner.prop_metadata")
local count,clones=0,0
local function check(ok,why) assert(ok,why); count=count+1 end
local function collect() collectgarbage("collect"); collectgarbage("collect") end
local wrap
local function release(object)
    assert(not object.destroyed,"Native scene retained freed metadata")
    object.refs=object.refs-1
    if object.refs==0 then object.destroyed=true end
end
wrap=function(object,inline)
    local value=newproxy(true)
    local mt=getmetatable(value)
    mt.object=object
    if not inline then object.refs=object.refs+1 end
    mt.__index=function(_,key)
        assert(not object.destroyed,"Access to freed metadata")
        if key=="isInstanceOfType" then return function(_,kind) return kind==tes3.niType.NiStringExtraData end end
        if key=="clone" then return function()
            clones=clones+1
            return wrap({string=object.string,refs=0},false)
        end end
        return object[key]
    end
    mt.__newindex=function(_,key,value) assert(not object.destroyed); object[key]=value end
    mt.__gc=function()
        if inline then object.destroyed=true -- sol's value destructor ignores refs.
        else release(object) end
    end
    return value
end
niStringExtraData.new=function(text) return wrap({string=text,refs=0},true) end
local function root()
    local scene={}
    function scene:addExtraData(value)
        local object=getmetatable(value).object
        object.refs=object.refs+1
        object.next=self.head
        self.head=object
    end
    function scene:isInstanceOfType() return false end
    function scene:destroy()
        local object=self.head
        while object do local next=object.next; release(object); object=next end
        self.head=nil
    end
    return setmetatable(scene,{__index=function(self,key)
        if key=="extraData" then return self.head and wrap(self.head,false) end
    end})
end

-- Reproduce the old attachment's failure even though the native refCount is 1.
local unsafe=root()
unsafe:addExtraData(niStringExtraData.new("unsafe"))
collect()
check(unsafe.head.refs==1 and unsafe.head.destroyed,"Collection invalidates an attached constructor value despite its scene reference")
check(not pcall(unsafe.destroy,unsafe),"Later scene cleanup detects the dangling pointer")

local fields={id="safe",name="Safe",description="",category=""}
local scene=root()
descriptive.update(scene,fields)
collect()
check(not scene.head.destroyed and scene.head.refs==1,"Descriptive metadata survives collection under scene ownership")
check(descriptive.read(scene).name=="Safe","Descriptive metadata remains readable after its constructor value is collected")
fields.name="Updated"
descriptive.update(scene,fields)
collect()
check(clones==1 and descriptive.read(scene).name=="Updated","Existing metadata is updated without another constructor or clone")
collect()
local descriptiveObject=scene.head
scene:destroy()
check(descriptiveObject.destroyed and descriptiveObject.refs==0,"Scene teardown releases the last descriptive metadata reference")
collect()

scene=root()
props.update(scene,{})
collect()
check(not scene.head.destroyed and scene.head.refs==1,"Prop metadata survives collection under scene ownership")
local definitions,present=props.read(scene)
check(present and #definitions==0,"Prop metadata remains readable after constructor collection")
props.update(scene,{})
collect()
check(clones==2 and scene.head.refs==1,"Existing prop metadata does not create another clone")
local propObject=scene.head
scene:destroy()
check(propObject.destroyed and propObject.refs==0,"Scene teardown releases the last prop metadata reference")
collect()
print("PASS: "..count.." metadata constructor, garbage collection and native ownership assertions")
