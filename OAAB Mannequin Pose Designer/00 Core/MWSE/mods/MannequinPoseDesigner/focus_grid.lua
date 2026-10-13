local lfs=require("lfs")
local nif=require("MannequinPoseDesigner.nif")
local M={spacing=16}
local folder="pose/h/c"
local serial=0

function M.vertexCount(radius,spacing)
    spacing=math.max(spacing or M.spacing,1)
    local g=math.floor(2*math.max(radius,spacing*4)/spacing)
    g=2*(g+g%2) -- Double the previous radius while keeping 16-unit spacing.
    -- Each original row becomes independent segments sampling a radial fade.
    local count=nif.gridSegments*(g+2)
    if count<=32767 then return count end
end

function M.load(vertexCount)
    local current="Data Files/meshes"
    for part in folder:gmatch("[^/]+") do
        current=current.."/"..part
        if lfs.attributes(current,"mode")~="directory" then assert(lfs.mkdir(current)) end
    end
    local path,disk
    repeat
        serial=serial+1
        path=folder.."/focus_grid_"..os.time().."_"..serial..".nif"
        disk="Data Files/meshes/"..path
    until not lfs.attributes(disk)
    local file=assert(io.open(disk,"wb"))
    local ok,result=pcall(function()
        local written,err=file:write(nif.encodeGrid(vertexCount))
        local closed,closeErr=file:close(); file=nil
        assert(written,err); assert(closed,closeErr)
        local mesh=assert(tes3.loadMesh(path,false),"Could not load the focus grid")
        -- Validate the native result as well as the serialized bytes. A scene
        -- node in a NiLines controller/extra-data link crashes native Display;
        -- neither updating with controllers=false nor pcall can contain it.
        local lines=0
        for _,child in pairs(mesh.children) do
            if child then
                assert(child:isInstanceOfType(tes3.niType.NiLines),"Unexpected focus grid geometry")
                assert(not child.controller and not child.extraData,"The focus grid loaded with invalid native links")
                assert(child.data and child.data.vertexCount==vertexCount,"The focus grid loaded with invalid native vertices")
                lines=lines+1
            end
        end
        assert(lines==4,"The focus grid must contain four line sets")
        return mesh
    end)
    if file then file:close() end
    local removed,removeErr=os.remove(disk)
    if not ok then error(result,0) end
    assert(removed,removeErr)
    return result
end

return M
