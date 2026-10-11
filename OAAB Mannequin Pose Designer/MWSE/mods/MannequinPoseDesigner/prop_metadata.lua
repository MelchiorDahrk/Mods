-- NetImmerse 4.0 extra data has no Name member. Keep editable prop sources in
-- their own NiStringExtraData, separate from descriptive pose metadata.
local props=require("MannequinPoseDesigner.props")
local poseMetadata=require("MannequinPoseDesigner.pose_metadata")
local M={prefix="OAAB:PoseProps:",maxBytes=1048576}
function M.find(root) return poseMetadata.find(root,M.prefix) end
function M.decode(bytes)
    assert(type(bytes)=="string" and #bytes<=M.maxBytes,"Prop metadata is too large or invalid")
    local state=assert(json.decode(bytes),"Invalid prop metadata JSON")
    assert(type(state)=="table" and state.version==1 and type(state.props)=="table" and state.props~=json.null,
        "Unsupported prop metadata version")
    local count=0
    for key in pairs(state.props) do
        assert(type(key)=="number" and key>=1 and key%1==0,"Invalid prop metadata array")
        count=count+1
    end
    assert(count==#state.props,"Incomplete prop metadata array")
    return props.clone(state.props)
end
function M.read(root)
    local extra=M.find(root)
    if not extra then return {},false end
    assert(#extra.string<=M.maxBytes,"Prop metadata is too large")
    return M.decode(extra.string:sub(#M.prefix+1)),true
end
function M.readFile(file)
    local ok,root=pcall(function() return tes3.loadMesh(file,false) end)
    if not ok or not root then return {},false end
    -- Present but invalid definitions must stop editing rather than silently
    -- becoming an empty prop list that could overwrite the user's geometry.
    return M.read(root)
end
function M.encode(definitions)
    local copied=setmetatable(props.clone(definitions),{__jsontype="array"})
    local text=M.prefix..json.encode({version=1,props=copied})
    assert(#text<=M.maxBytes,"Prop metadata is too large")
    return text
end
function M.update(root,definitions)
    local text=M.encode(definitions)
    local extra=M.find(root)
    if extra then extra.string=text
    else
        -- Attach a native clone, not the Lua-owned constructor value: its
        -- userdata finalizer destroys it even while a scene points to it.
        root:addExtraData(niStringExtraData.new(text):clone())
    end
    return text
end
function M.decorate(stage,definitions)
    local relative=assert(stage:match("^Data Files/meshes/(.*)$"),"Invalid prop metadata stage path")
    local output=stage..".props.nif"
    local ok,err=pcall(function()
        local root=assert(tes3.loadMesh(relative,false),"Could not load prop metadata stage")
        local expected=M.update(root,definitions)
        assert(root:saveBinary(output),"Could not serialize prop metadata")
        local reopened=assert(tes3.loadMesh(relative..".props.nif",false),"Could not verify prop metadata")
        local saved=assert(M.find(reopened),"Serialized pose lost its prop metadata")
        assert(saved.string==expected,"Serialized prop metadata changed")
        M.read(reopened)
        local input=assert(io.open(output,"rb")); local bytes=input:read("*a"); assert(input:close())
        assert(bytes and #bytes>0,"Serialized prop metadata NIF is empty")
        local target=assert(io.open(stage,"wb")); assert(target:write(bytes)); assert(target:close())
    end)
    os.remove(output)
    if not ok then error(err) end
end
return M
