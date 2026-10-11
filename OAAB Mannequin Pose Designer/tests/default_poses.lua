package.path="./MWSE/mods/?.lua;"..package.path
local ffi=require("ffi")
local rig=require("MannequinPoseDesigner.rig")
local library=require("MannequinPoseDesigner.library")
local blend=require("MannequinPoseDesigner.blend")
local nif=require("MannequinPoseDesigner.nif")
local apiFile=assert(arg[1],"Pass OAAB_Data poses.lua")
local oaabRoot=assert(apiFile:gsub("\\","/"):match("^(.*)/01 MWSE Functions/MWSE/mods/OAAB/Mannequins/poses%.lua$"))
local count=0
local function check(ok,reason) assert(ok,reason); count=count+1 end
local function read(path)
    local file=assert(io.open(path,"rb")); local bytes=assert(file:read("*a")); file:close(); return bytes
end
local function u32(bytes,at)
    local a,b,c,d=bytes:byte(at,at+3)
    return a+b*256+c*65536+d*16777216
end
local function marker(kind) return string.char(#kind,0,0,0)..kind end
local function vector(a,b,c) return {x=a,y=b,z=c} end
-- A read-only adapter for the actual stock NIFs: index their known 4.0.0.2
-- blocks, recover NiNode transforms/children/controllers, then use real rig.capture.
local function scene(bytes)
    local blocks={}
    for _,kind in ipairs({"NiNode","NiKeyframeController","NiKeyframeData","NiMaterialProperty",
        "NiSkinInstance","NiSkinData","NiTextKeyExtraData","NiTriShape","NiTriShapeData"}) do
        local at=1; local tag=marker(kind)
        while true do
            at=bytes:find(tag,at,true)
            if not at then break end
            blocks[#blocks+1]={at=at+#tag,kind=kind}; at=at+#tag
        end
    end
    table.sort(blocks,function(a,b) return a.at<b.at end)
    check(#blocks==u32(bytes,assert(bytes:find("\n",1,true))+5),"Stock NIF block index is complete")
    local records={}
    for i,block in ipairs(blocks) do
        local kind=block.kind
        records[i-1]={isInstanceOfType=function(_,wanted) return wanted==kind end}
    end
    for i,block in ipairs(blocks) do
        if block.kind=="NiNode" then
            local node=records[i-1]; local at=block.at
            local length=u32(bytes,at); at=at+4
            node.name=bytes:sub(at,at+length-1); at=at+length
            node.controller=records[u32(bytes,at+4)]; at=at+10
            local values=ffi.new("float[13]"); ffi.copy(values,bytes:sub(at,at+51),52)
            node.translation=vector(tonumber(values[0]),tonumber(values[1]),tonumber(values[2]))
            node.rotation={x=vector(tonumber(values[3]),tonumber(values[4]),tonumber(values[5])),
                y=vector(tonumber(values[6]),tonumber(values[7]),tonumber(values[8])),
                z=vector(tonumber(values[9]),tonumber(values[10]),tonumber(values[11]))}
            node.scale=tonumber(values[12]); at=at+64
            local properties=u32(bytes,at); at=at+4+properties*4
            node.children={}
            if u32(bytes,at)~=0 then
                -- This non-skeletal leaf is irrelevant to pose capture.
                assert(node.name=="Bounding Box","Unexpected bounded skeletal node: "..node.name)
            else
                at=at+4
                local children=u32(bytes,at); at=at+4
                for child=1,children do node.children[child]=records[u32(bytes,at)]; at=at+4 end
            end
        end
    end
    return records[0]
end
tes3={niType={NiNode="NiNode",NiKeyframeController="NiKeyframeController"},loadMesh=function(path,cache)
    check(cache==false,"Stock pose reads bypass the mesh cache")
    return scene(read(oaabRoot.."/00 Core/meshes/"..path))
end}
library.list=function() return {} end -- No custom files needed, and no test writes.
local defaults=library.blendList()
local api=read(apiFile)
local poses={}
for _,pose in ipairs(defaults) do
    local label=pose.label:gsub(" %(Default%)$","")
    check(api:find('{ label = "'..label..'", file = "'..pose.file..'" }',1,true),
        "Default blend choices match the actual OAAB API")
    poses[#poses+1]=library.read(pose.file)
    check(#poses[#poses]==35,"Every stock NIF exposes the complete 35-bone skeleton")
end
local function same(a,b)
    for i,bone in ipairs(a) do
        if bone.scale~=b[i].scale then return false end
        for _,field in ipairs({"translation","rotation"}) do
            for axis,value in ipairs(bone[field]) do if value~=b[i][field][axis] then return false end end
        end
    end
    return #a==#b
end
for i,pose in ipairs(poses) do poses[i]=blend.align(pose,poses[1]) end
check(not same(poses[1],poses[2]) and not same(poses[2],poses[3]) and not same(poses[3],poses[4]),
    "Each default loads its own authored pose")
for _,a in ipairs(poses) do
    for _,b in ipairs(poses) do
        check(same(blend.apply(a,b,0),a) and same(blend.apply(a,b,1),b),"All stock pairs reproduce both exact endpoints")
        nif.validate(blend.apply(a,b,0.5))
        check(true,"All stock pairs produce valid exportable midpoint transforms")
    end
end
print("PASS: "..count.." actual OAAB default NIF reads, hierarchy, endpoints and export validation assertions")
