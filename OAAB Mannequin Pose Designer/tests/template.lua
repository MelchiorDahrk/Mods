package.path="./MWSE/mods/?.lua;"..package.path
local nif=require("MannequinPoseDesigner.nif")
local bones=dofile("tests/template_fixture.lua")
local root="MWSE/mods/MannequinPoseDesigner/templates/"
local function read(path)
    local f=assert(io.open(path,"rb"))
    local bytes=assert(f:read("*a"))
    assert(f:close())
    return bytes
end
local function count(bytes,word)
    local n,at=0,1
    while true do
        at=bytes:find(word,at,true)
        if not at then return n end
        n=n+1; at=at+#word
    end
end
for _,case in ipairs({
    {"mann_relax.nif","nif","template.nif"},
    {"xmann_relax.nif","xnif","xtemplate.nif"},
    {"xmann_relax.kf","kf","xtemplate.kf"},
}) do
    local original=read(root..case[1])
    local updated=nif.patchTemplate(bones,original,case[2])
    assert(#updated==#original,"Template size changed")
    assert(updated~=original,"Template pose was not changed")
    assert(count(updated,"NiNode")==count(original,"NiNode"),"Template node count changed")
    assert(count(updated,"NiTriShape")==count(original,"NiTriShape"),"Template geometry changed")
    assert(count(updated,"NiKeyframeData")==count(original,"NiKeyframeData"),"Template controller count changed")
    local f=assert(io.open(".work/"..case[3],"wb"))
    assert(f:write(updated))
    assert(f:close())
end
local missing={}
for i=1,#bones-1 do missing[i]=bones[i] end
assert(not pcall(nif.patchTemplate,missing,read(root.."mann_relax.nif"),"nif"),
    "Mismatched skeleton must be refused before animation loading")
print("PASS: full OAAB animation template patching and skeleton checks")
