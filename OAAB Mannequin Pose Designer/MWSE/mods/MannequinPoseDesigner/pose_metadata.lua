-- NetImmerse 4.0 extra data has no Name member. Use a stable string prefix
-- instead of inventing one: OAAB:PoseMetadata:<JSON with only four fields>.
local M={prefix="OAAB:PoseMetadata:",maxBytes=16384}
local function trim(value) return value:gsub("^%s+",""):gsub("%s+$","") end
function M.validateId(id,limit)
    if type(id)~="string" or not id:match("^[A-Za-z0-9][A-Za-z0-9_%-]*$") then
        return nil,"ID must start with a letter or number and contain only letters, numbers, underscores or hyphens."
    end
    if #id>(limit or 64) then return nil,"ID must be "..(limit or 64).." characters or fewer." end
    return id
end
function M.normalize(value)
    if type(value)~="table" then return nil end
    local result={description="",category=""}
    -- Optional malformed fields must never hide an otherwise playable NIF.
    if M.validateId(value.id) then result.id=value.id end
    for key,limit in pairs({name=120,description=2000,category=80}) do
        if type(value[key])=="string" and #value[key]<=limit and not value[key]:find("%z") then
            result[key]=trim(value[key])
        end
    end
    if result.name=="" then result.name=nil end
    return result
end
function M.validate(value)
    assert(type(value)=="table","Pose metadata is required")
    local id,err=M.validateId(value.id); assert(id,err)
    assert(type(value.name)=="string" and trim(value.name)~="" and #value.name<=120 and not value.name:find("%z"),
        "Enter a pose name of at most 120 characters.")
    for key,limit in pairs({description=2000,category=80}) do
        assert(value[key]==nil or type(value[key])=="string" and #value[key]<=limit and not value[key]:find("%z"),
            key.." is too long or invalid")
    end
    return M.normalize(value)
end
function M.parse(text)
    if type(text)~="string" or #text>M.maxBytes or text:sub(1,#M.prefix)~=M.prefix then return end
    local ok,value=pcall(json.decode,text:sub(#M.prefix+1))
    if ok then return M.normalize(value) end
end
function M.find(root,prefix)
    prefix=prefix or M.prefix
    local seenNodes,seenExtras={},{}
    local function visit(node)
        if not node or seenNodes[node] then return end
        seenNodes[node]=true
        local extra=node.extraData
        while extra and not seenExtras[extra] do
            seenExtras[extra]=true
            if extra:isInstanceOfType(tes3.niType.NiStringExtraData)
                and extra.string:sub(1,#prefix)==prefix then return extra,node end
            extra=extra.next
        end
        if tes3.niType.NiNode and node:isInstanceOfType(tes3.niType.NiNode) then
            for _,child in pairs(node.children) do
                local found,owner=visit(child)
                if found then return found,owner end
            end
        end
    end
    return visit(root)
end
function M.read(root)
    local extra=M.find(root)
    return extra and M.parse(extra.string) or nil
end
function M.readFile(file)
    -- Never keep native meshes in the descriptor cache, or write while browsing.
    local ok,value=pcall(function() return M.read(assert(tes3.loadMesh(file,false))) end)
    return ok and value or nil
end
function M.update(root,fields)
    local text=M.prefix..json.encode(M.validate(fields))
    assert(#text<=M.maxBytes,"Pose metadata is too large")
    local extra=M.find(root)
    if extra then extra.string=text
    else
        -- MWSE constructs this value inside Lua userdata. Only the clone is
        -- a native allocation whose lifetime follows the scene's refCount.
        root:addExtraData(niStringExtraData.new(text):clone())
    end
end
local function decorate(stage,edit)
    local relative=assert(stage:match("^Data Files/meshes/(.*)$"),"Invalid metadata stage path")
    local output=stage..".metadata.nif"
    local ok,err=pcall(function()
        local root=assert(tes3.loadMesh(relative,false),"Could not load metadata stage")
        edit(root)
        local expected=assert(M.find(root),"Pose lost its metadata").string
        assert(root:saveBinary(output),"Could not serialize pose metadata")
        local reopened=assert(tes3.loadMesh(relative..".metadata.nif",false),"Could not verify pose metadata")
        local saved=assert(M.find(reopened),"Serialized pose lost its metadata")
        assert(saved.string==expected,"Serialized pose metadata changed")
        local input=assert(io.open(output,"rb")); local bytes=input:read("*a"); assert(input:close())
        assert(bytes and #bytes>0,"Serialized metadata NIF is empty")
        local target=assert(io.open(stage,"wb")); assert(target:write(bytes)); assert(target:close())
    end)
    os.remove(output)
    if not ok then error(err) end
end
function M.decorate(stage,fields)
    decorate(stage,function(root) M.update(root,fields) end)
end
function M.clearCategory(stage,category)
    decorate(stage,function(root)
        local extra=assert(M.find(root),"Pose no longer has category metadata")
        local normalized=assert(M.parse(extra.string),"Pose metadata is invalid")
        assert(normalized.category==category,"Pose category changed before deletion")
        -- Change only the category, including on imports with partial metadata.
        -- Do not invent an ID/name or repair unrelated optional fields here.
        local fields=json.decode(extra.string:sub(#M.prefix+1))
        fields.category=""
        local text=M.prefix..json.encode(fields)
        assert(#text<=M.maxBytes,"Pose metadata is too large")
        extra.string=text
    end)
end
return M
