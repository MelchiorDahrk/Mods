-- Read real transforms from the bundled mannequin, with its documented
-- parent-first skeletal hierarchy. No engine scene or generated pose needed.
local ffi=require("ffi")
local bones=dofile("tests/template_fixture.lua")
local file=assert(io.open("MWSE/mods/MannequinPoseDesigner/templates/mann_relax.nif","rb"))
local bytes=assert(file:read("*a")); file:close()
local central={
    ["Bip01 Pelvis"]="Bip01",["Bip01 Spine"]="Bip01 Pelvis",
    ["Bip01 Spine1"]="Bip01 Spine",["Bip01 Spine2"]="Bip01 Spine1",
    ["Bip01 Neck"]="Bip01 Spine2",["Bip01 Head"]="Bip01 Neck",
    ["Weapon Bone"]="Bip01 R Hand",["Shield Bone"]="Bip01 L Hand",
}
local parents={Thigh="Bip01 Spine",Calf="Thigh",Foot="Calf",Clavicle="Bip01 Neck",
    UpperArm="Clavicle",Forearm="UpperArm",Hand="Forearm",
    Finger0="Hand",Finger01="Finger0",Finger1="Hand",Finger11="Finger1",Finger2="Hand",Finger21="Finger2"}
local indices={}
for i,bone in ipairs(bones) do
    local name=bone.name
    local marker=string.char(6,0,0,0).."NiNode"..string.char(#name,0,0,0)..name
    local at=assert(bytes:find(marker,1,true),name)+#marker+10
    local transform=ffi.new("float[13]")
    ffi.copy(transform,bytes:sub(at,at+51),52)
    bone.translation={tonumber(transform[0]),tonumber(transform[1]),tonumber(transform[2])}
    bone.rotation={}
    for component=1,9 do bone.rotation[component]=tonumber(transform[component+2]) end
    bone.scale=tonumber(transform[12])
    local parentName=central[name]
    local side,part=name:match("^Bip01 ([LR]) (.+)$")
    if side then
        parentName=assert(parents[part])
        if not parentName:match("^Bip01") then parentName="Bip01 "..side.." "..parentName end
    end
    bone.parent=parentName and assert(indices[parentName],parentName) or 0
    indices[name]=i
end
return bones
