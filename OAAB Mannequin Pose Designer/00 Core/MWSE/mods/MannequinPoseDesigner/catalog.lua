local library=require("MannequinPoseDesigner.library")
local M={}
local function identity(file) return file:lower():gsub("\\","/") end
function M.list(entries)
    local records,seen={},{}
    for _,pose in ipairs(library.list()) do records[#records+1]=pose; seen[identity(pose.file)]=true end
    if not entries then
        local ok,api=pcall(require,"OAAB.Mannequins.poses")
        entries=ok and api.listPoses and api.listPoses() or library.blendList()
    end
    for _,entry in ipairs(entries) do
        if entry.file and not seen[identity(entry.file)] then
            local data=library.readMetadata(entry.file) or {}
            local name=data.name or (type(entry.label)=="string" and entry.label:gsub(" %(Default%)$","")) or library.label(entry.file)
            records[#records+1]={file=entry.file,name=name,label=name,id=data.id,
                description=data.description or "",category=data.category or "",
                editable=false,isOAABData=library.isDefault(entry.file),callback=entry.callback}
            seen[identity(entry.file)]=true
        end
    end
    local ids={}
    for _,pose in ipairs(records) do
        pose.id=pose.id or library.poseId(pose.file)
        if pose.id then local key=pose.id:lower(); ids[key]=(ids[key] or 0)+1 end
    end
    for _,pose in ipairs(records) do
        pose.duplicateId=pose.id and ids[pose.id:lower()]>1 or false
    end
    return records
end
function M.fields(pose)
    return {id=pose.id,name=pose.name,description=pose.description or "",category=pose.category or ""}
end
function M.filter(records,options)
    options=options or {}
    local found={}
    local source=options.source or "All poses"
    local words={}
    for word in (options.search or ""):lower():gmatch("%S+") do words[#words+1]=word end
    for _,pose in ipairs(records) do
        local accepts=source=="All poses"
            or source=="OAAB_Data" and pose.isOAABData or source=="Custom" and pose.editable
        local category=pose.category~="" and pose.category or "Uncategorized"
        if accepts and (not options.category or options.category==category) then
            local text=table.concat({pose.name,pose.id or "",pose.description,category}," "):lower()
            local matches=true
            for _,word in ipairs(words) do
                if not text:find(word,1,true) then matches=false; break end
            end
            if matches then found[#found+1]=pose end
        end
    end
    local key=options.sort=="ID" and "id" or options.sort=="Category" and "category" or "name"
    table.sort(found,function(a,b)
        local left,right=(a[key] or ""):lower(),(b[key] or ""):lower()
        if left==right then return identity(a.file)<identity(b.file) end
        if options.sort=="Name Z-A" then return left>right end
        return left<right
    end)
    return found
end
function M.categories(records)
    local values,seen={},{["Uncategorized"]=true}
    for _,pose in ipairs(records) do
        if pose.category~="" and not seen[pose.category] then values[#values+1]=pose.category; seen[pose.category]=true end
    end
    table.sort(values,function(a,b) return a:lower()<b:lower() end)
    table.insert(values,1,"Uncategorized")
    return values
end
function M.categoryUsage(records,category)
    local editable,readOnly=0,0
    for _,pose in ipairs(records) do
        if pose.category==category then
            if pose.editable then editable=editable+1 else readOnly=readOnly+1 end
        end
    end
    return editable,readOnly
end
return M
