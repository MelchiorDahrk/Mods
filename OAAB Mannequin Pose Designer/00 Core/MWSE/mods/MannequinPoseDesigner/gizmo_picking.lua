-- Read-only screen-space picking of the authored rings and depth mask.
local v=require("MannequinPoseDesigner.math3d")
local rig=require("MannequinPoseDesigner.rig")
local props=require("MannequinPoseDesigner.props")
local M={tolerance=6}
function M.geometry(data)
    if not data then return end
    local geometry={vertices={},edges={},triangles={},min={math.huge,math.huge,math.huge},max={-math.huge,-math.huge,-math.huge}}
    local seen={}
    for i=1,data.vertexCount do
        local point=rig.vector(data.vertices[i]); geometry.vertices[i]=point
        for axis=1,3 do
            geometry.min[axis]=math.min(geometry.min[axis],point[axis])
            geometry.max[axis]=math.max(geometry.max[axis],point[axis])
        end
    end
    local function edge(a,b)
        if a>b then a,b=b,a end
        local key=a..":"..b
        if not seen[key] then seen[key]=true; geometry.edges[#geometry.edges+1]={a,b} end
    end
    for i=1,data.activeTriangleCount do
        -- MWSE triangle vertices are zero-based indices.
        local triangle=data.triangles[i]
        local indices=assert(triangle.vertices,"Missing triangle vertex indices")
        local a,b,c=indices[1]+1,indices[2]+1,indices[3]+1
        edge(a,b); edge(b,c); edge(c,a)
        local p=geometry.vertices[a]
        local e1=v.sub(geometry.vertices[b],p); local e2=v.sub(geometry.vertices[c],p)
        geometry.triangles[#geometry.triangles+1]={p,e1,e2}
    end
    return geometry
end
function M.closest(cursor,a,b)
    local x,y=b.x-a.x,b.y-a.y
    local length=x*x+y*y
    local t=length>1e-10 and v.clamp(((cursor[1]-a.x)*x+(cursor[2]-a.y)*y)/length,0,1) or 0
    local px,py=a.x+t*x,a.y+t*y
    return (cursor[1]-px)^2+(cursor[2]-py)^2,px,py
end
function M.prepareMasks(occluders)
    local masks={}
    for _,entry in ipairs(occluders) do
        if entry.geometry and not entry.shape.appCulled then
            local transform=props.nodeTransform(entry.shape)
            masks[#masks+1]={geometry=entry.geometry,translation=transform.translation,
                inverse=v.transpose(transform.rotation),scale=transform.scale}
        end
    end
    return masks
end
function M.masked(origin,point,masks)
    for _,mask in ipairs(masks) do
        local start=v.scale(v.transform(mask.inverse,v.sub(origin,mask.translation)),1/mask.scale)
        local finish=v.scale(v.transform(mask.inverse,v.sub(point,mask.translation)),1/mask.scale)
        local direction=v.sub(finish,start)
        for _,triangle in ipairs(mask.geometry.triangles) do
            local a,e1,e2=unpack(triangle)
            local p=v.cross(direction,e2); local determinant=v.dot(e1,p)
            if math.abs(determinant)>1e-10 then
                local offset=v.sub(start,a)
                local u=v.dot(offset,p)/determinant
                if u>=-1e-7 and u<=1+1e-7 then
                    local q=v.cross(offset,e1)
                    local w=v.dot(direction,q)/determinant
                    if w>=-1e-7 and u+w<=1+1e-7 then
                        local t=v.dot(e2,q)/determinant
                        if t>1e-7 and t<1-1e-6 then return true end
                    end
                end
            end
        end
    end
    return false
end
local function project(entry,camera,cursor)
    local transform=props.nodeTransform(entry.shape)
    local lo,hi=entry.geometry.min,entry.geometry.max
    if lo and hi then
        local minX,minY,maxX,maxY=math.huge,math.huge,-math.huge,-math.huge
        local complete=true
        for _,x in ipairs({lo[1],hi[1]}) do for _,y in ipairs({lo[2],hi[2]}) do for _,z in ipairs({lo[3],hi[3]}) do
            local point=v.add(transform.translation,v.scale(v.transform(transform.rotation,{x,y,z}),transform.scale))
            local p=camera:worldPointToScreenPoint(rig.engineVector(point))
            if p then
                minX,minY=math.min(minX,p.x),math.min(minY,p.y)
                maxX,maxY=math.max(maxX,p.x),math.max(maxY,p.y)
            else complete=false end
        end end end
        if complete and (cursor[1]<minX-M.tolerance or cursor[1]>maxX+M.tolerance
            or cursor[2]<minY-M.tolerance or cursor[2]>maxY+M.tolerance) then return end
    end
    local world,screen={},{}
    for i,point in ipairs(entry.geometry.vertices) do
        world[i]=v.add(transform.translation,v.scale(v.transform(transform.rotation,point),transform.scale))
        screen[i]=camera:worldPointToScreenPoint(rig.engineVector(world[i]))
    end
    return world,screen
end
function M.fuzzy(components,cursor,camera,masks)
    local best,axis,depth=M.tolerance^2,nil,math.huge
    -- Stable axis order resolves coincident projections consistently.
    for _,name in ipairs({"x","y","z"}) do
        local entry=components[name]
        if entry.geometry and not entry.shape.appCulled then
            local world,screen=project(entry,camera,cursor)
            if world then
            for _,edge in ipairs(entry.geometry.edges) do
                local a,b=screen[edge[1]],screen[edge[2]]
                if a and b then
                    local distance,x,y=M.closest(cursor,a,b)
                    if distance<=best then
                        local origin,direction=camera:windowPointToRay({x,y})
                        if origin and direction then
                            origin,direction=rig.vector(origin),rig.vector(direction)
                            local start,finish=world[edge[1]],world[edge[2]]
                            local segment=v.sub(finish,start)
                            local cross=v.cross(segment,direction)
                            local length=v.dot(cross,cross)
                            -- Intersect the projected edge's ray with its 3D
                            -- segment; screen-linear interpolation is inaccurate
                            -- under perspective and could misclassify the mask.
                            local t=length>1e-12 and v.clamp(v.dot(v.cross(v.sub(origin,start),direction),cross)/length,0,1) or 0
                            local point=v.add(start,v.scale(segment,t))
                            local pointDepth=v.length(v.sub(point,origin))
                            if (distance<best or pointDepth<depth) and not M.masked(origin,point,masks) then
                                best,axis,depth=distance,name,pointDepth
                            end
                        end
                    end
                end
            end
            end
        end
    end
    return axis
end
return M
