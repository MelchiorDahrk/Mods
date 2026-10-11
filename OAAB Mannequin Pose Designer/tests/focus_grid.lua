package.path="./MWSE/mods/?.lua;"..package.path
local grid=require("MannequinPoseDesigner.focus_grid")
local nif=require("MannequinPoseDesigner.nif")
local lfs=require("lfs")
local count=0
local function check(value,reason) assert(value,reason); count=count+1 end
check(grid.vertexCount(0)==288 and grid.vertexCount(63)==288,"Double the old minimum radius to eight grid spaces")
check(grid.vertexCount(100)==416 and grid.vertexCount(105)==480,"Double the previous rounded radius with unchanged grid spacing")
check(grid.vertexCount(0,0)==288 and grid.vertexCount(4,1)==288,"Zero spacing is clamped to one")
check(grid.vertexCount(8176)==32736 and grid.vertexCount(8184)==nil,"Include the doubled radius and radial samples in the native vertex limit")
for _,invalid in ipairs({0,9,11,32,128,161,32768}) do
    check(not pcall(nif.encodeGrid,invalid),"Reject invalid line allocations")
end
local output=assert(io.open(".work/focus-grid.nif","wb"))
assert(output:write(nif.encodeGrid(grid.vertexCount(100)))); assert(output:close())
for _,size in ipairs({{"minimum",288},{"maximum",32736}}) do
    local file=assert(io.open(".work/focus-grid-"..size[1]..".nif","wb"))
    assert(file:write(nif.encodeGrid(size[2]))); assert(file:close())
end
local original=lfs.currentdir()
local sandbox=".work/focus-grid-runtime"
for _,path in ipairs({sandbox,sandbox.."/Data Files",sandbox.."/Data Files/meshes"}) do
    if not lfs.attributes(path) then assert(lfs.mkdir(path)) end
end
assert(lfs.chdir(sandbox))
local loadedPath
local function load(path,cache)
    loadedPath="Data Files/meshes/"..path
    local file=assert(io.open(loadedPath,"rb"))
    local bytes=assert(file:read("*a")); assert(file:close())
    check(bytes==nif.encodeGrid(416) and cache==false,"The loader receives the complete generated NIF without caching")
end
local mesh={children={}}
for i=1,4 do mesh.children[i]={data={vertexCount=416},isInstanceOfType=function(_,kind) return kind=="NiLines" end} end
tes3={niType={NiLines="NiLines"},loadMesh=function(path,cache) load(path,cache); return mesh end}
check(grid.load(416)==mesh and not lfs.attributes(loadedPath),"Successful loading removes the temporary NIF immediately")
mesh.children[4].controller=mesh -- Reproduce the bad native link in the crash dump.
check(not pcall(grid.load,416) and not lfs.attributes(loadedPath),"Reject a scene node in a line's controller link before it can render")
mesh.children[4].controller=nil; mesh.children[4].extraData=mesh
check(not pcall(grid.load,416) and not lfs.attributes(loadedPath),"Reject a scene node in a line's extra-data link")
mesh.children[4].extraData=nil; mesh.children[4].data.vertexCount=12
check(not pcall(grid.load,416) and not lfs.attributes(loadedPath),"Reject incomplete native vertex data")
mesh.children[4].data.vertexCount=416
tes3.loadMesh=function(path,cache) load(path,cache); return nil end
check(not pcall(grid.load,416) and not lfs.attributes(loadedPath),"A missing loaded mesh leaves no temporary file")
tes3.loadMesh=function(path,cache) load(path,cache); error("Native loader failed") end
check(not pcall(grid.load,416) and not lfs.attributes(loadedPath),"A native loader exception leaves no temporary file")
local nativeOpen=io.open
io.open=function(path,mode)
    local file=assert(nativeOpen(path,mode))
    return {write=function() return nil,"Disk full" end,close=function() return file:close() end}
end
check(not pcall(grid.load,416),"A write failure is reported")
io.open=nativeOpen
for entry in lfs.dir("Data Files/meshes/pose/h/c") do
    check(entry=="." or entry=="..","A failed write leaves no partial NIF")
end
assert(lfs.chdir(original))
print("PASS: "..count.." CSSE grid sizing, vertex limits, native load bridge and temporary-file cleanup assertions")
