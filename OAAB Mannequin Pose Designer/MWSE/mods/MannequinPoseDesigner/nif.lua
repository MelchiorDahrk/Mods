-- NetImmerse 4.0.0.2 writer. The NIF contains the complete skeleton and constant
-- animation keys. xNIF/KF are engine compatibility companions derived from it.
local math3d = require("MannequinPoseDesigner.math3d")
local M = {}
local function u32(n)
    n=n % 4294967296
    local a=n%256; n=math.floor(n/256)
    local b=n%256; n=math.floor(n/256)
    local c=n%256; n=math.floor(n/256)
    return string.char(a,b,c,n%256)
end
local function u16(n) return string.char(n%256,math.floor(n/256)%256) end
local function f32(x)
    assert(x==x and math.abs(x)<3.4028234e38, "Non-finite pose transform")
    local sign=0
    if x<0 then sign=2147483648; x=-x end
    if x==0 then return u32(sign) end
    local m,e=math.frexp(x)
    local exponent=e+126
    local mantissa
    if exponent<=0 then
        exponent=0; mantissa=math.floor(x/2^-149+0.5)
    else
        mantissa=math.floor((m*2-1)*8388608+0.5)
    end
    if mantissa>=8388608 then exponent=exponent+1; mantissa=0 end
    return u32(sign+exponent*8388608+mantissa)
end
local function floats(values)
    local out={} for _,v in ipairs(values) do out[#out+1]=f32(v) end
    return table.concat(out)
end
local function str(s) return u32(#s)..s end
local null=u32(-1)
local function net(name, extra, controller) return str(name)..u32(extra or -1)..u32(controller or -1) end
local function stream(blocks)
    local out={"NetImmerse File Format, Version 4.0.0.2\n",u32(0x04000002),u32(#blocks)}
    for _,b in ipairs(blocks) do out[#out+1]=str(b[1])..b[2] end
    out[#out+1]=u32(1)..u32(0)
    return table.concat(out)
end
-- CSSE's updateGridGeometry uses four rotated NiLines sharing one data block.
-- MWSE exposes their data, but not the native NiLines constructor or segment
-- flags. Load this small generated NIF instead of calling an unavailable API.
M.gridSegments=16
function M.encodeGrid(vertexCount)
    local rowVertices=2*M.gridSegments
    assert(vertexCount>=5*rowVertices and vertexCount<=32767 and vertexCount%rowVertices==0,"Invalid focus grid vertex count")
    local g=vertexCount/M.gridSegments-2
    local vertices,colors,flags={},{},{}
    local radius=0
    local function vertex(vx,vy,connected)
        vertices[#vertices+1]=vx; vertices[#vertices+1]=vy; vertices[#vertices+1]=0
        -- Fade around the world grid origin, not the shared data's bound center.
        local t=math.min(math.sqrt(vx*vx+vy*vy)/g,1)
        local alpha=0.2*(1-t*t*(3-2*t))
        colors[#colors+1]=floats({1,1,1,alpha})
        flags[#flags+1]=string.char(connected and 1 or 0)
        radius=math.max(radius,math.sqrt(vx*vx+(vy-g*0.5)^2))
    end
    -- Keep rows on the same two-unit lattice right through the rim. Clip their
    -- ends to the actual circle instead of CSSE's outward-offset endpoints.
    for i=0,g,2 do
        local width=math.sqrt(math.max(g*g-i*i,0))
        -- Each rotation draws one center-axis half. Full center rows would
        -- overlap their opposite rotation, making those lines look thicker.
        local length=i==0 and width or 2*width
        local connected=i<g -- Omit the outermost row in all four line sets.
        for segment=0,M.gridSegments-1 do
            vertex(width-length*segment/M.gridSegments,i,connected)
            vertex(width-length*(segment+1)/M.gridSegments,i,false)
        end
    end
    local function av(name,rotation,properties)
        local out={net(name),u16(0),floats({0,0,0}),floats(rotation),f32(1),floats({0,0,0}),u32(#properties)}
        for _,id in ipairs(properties) do out[#out+1]=u32(id) end
        out[#out+1]=u32(0)
        return table.concat(out)
    end
    local blocks={
        {"NiNode",av("OAAB Pose Designer focus grid",math3d.identity(),{1,2,3,4})
            ..u32(4)..u32(5)..u32(6)..u32(7)..u32(8)..u32(0)},
        -- Match gridRoot in CSSE's widgets.nif: emissive vertex colors,
        -- source-alpha blending without alpha testing, half-opacity material.
        {"NiVertexColorProperty",net("")..u16(0)..u32(1)..u32(0)},
        {"NiAlphaProperty",net("")..u16(8429)..string.char(0)},
        {"NiMaterialProperty",net("")..u16(1)..floats({1,1,1,1,1,1,1,1,1,1,1,1})..f32(0)..f32(0.5)},
        {"NiZBufferProperty",net("")..u16(1)},
    }
    local rotations={math3d.identity(),{0,-1,0,1,0,0,0,0,1},{-1,0,0,0,-1,0,0,0,1},{0,1,0,-1,0,0,0,0,1}}
    for i,rotation in ipairs(rotations) do
        blocks[#blocks+1]={"NiLines",av("grid"..(i-1)*90,rotation,{})..u32(9)..null}
    end
    -- End with the shared data, as in the engine's serialized geometry graphs.
    -- A terminal NiLines was observed with bogus extra/controller links after
    -- loading in Morrowind even though its on-disk links were both null.
    blocks[#blocks+1]={"NiLinesData",u16(vertexCount)..u32(1)..floats(vertices)..u32(0)
        ..floats({0,g*0.5,0})..f32(radius)..u32(1)..table.concat(colors)
        ..u16(0)..u32(0)..table.concat(flags)}
    return stream(blocks)
end
function M.validate(bones)
    assert(#bones>0 and #bones<=256, "Invalid skeleton size")
    local names={}
    for i,b in ipairs(bones) do
        assert(type(b.name)=="string" and #b.name>0 and #b.name<128 and not names[b.name:lower()], "Invalid or duplicate bone name")
        names[b.name:lower()]=true
        assert(b.parent>=0 and b.parent<i, "Skeleton must be in parent-first order")
        assert(#b.translation==3 and #b.rotation==9 and b.scale>0, "Invalid transform")
        floats(b.translation); floats(b.rotation); f32(b.scale)
        for row=0,2 do
            local k=row*3
            local length=b.rotation[k+1]^2+b.rotation[k+2]^2+b.rotation[k+3]^2
            assert(math.abs(length-1)<0.02,"Bone rotation has collapsed: "..b.name)
        end
        local r=b.rotation
        local det=r[1]*(r[5]*r[9]-r[6]*r[8])-r[2]*(r[4]*r[9]-r[6]*r[7])+r[3]*(r[4]*r[8]-r[5]*r[7])
        assert(math.abs(det-1)<0.03,"Bone rotation is not orthogonal: "..b.name)
    end
    assert(names.bip01, "TES3 Bip01 root missing")
end
-- Patch complete OAAB animations, preserving geometry, skin data and
-- attachment nodes while replacing fixed-size transforms and keys.
local function readU32(bytes,offset)
    local a,b,c,d=bytes:byte(offset,offset+3)
    assert(d,"Truncated animation template")
    return a+b*256+c*65536+d*16777216
end
local function put(changes,bytes,offset,value)
    assert(offset>=1 and offset+#value-1<=#bytes,"Template patch outside file")
    changes[#changes+1]={offset=offset,value=value}
end
local function blocks(bytes,kind)
    local marker=str(kind)
    local found={}
    local from=1
    while true do
        local at=bytes:find(marker,from,true)
        if not at then return found end
        found[#found+1]=at+#marker
        from=at+#marker
    end
end
local function keyframe(changes,bytes,at,bone)
    assert(readU32(bytes,at)==2 and readU32(bytes,at+4)==1,
        "Unexpected template rotation keys")
    local q=floats(math3d.quaternion(bone.rotation))
    local rotation=at+8
    put(changes,bytes,rotation+4,q)
    put(changes,bytes,rotation+24,q)
    local position=rotation+40
    assert(readU32(bytes,position)==2 and readU32(bytes,position+4)==2,
        "Unexpected template position keys")
    local t=floats(bone.translation)..string.rep("\0",24)
    put(changes,bytes,position+12,t)
    put(changes,bytes,position+52,t)
    local scale=position+88
    assert(readU32(bytes,scale)==2 and readU32(bytes,scale+4)==2,
        "Unexpected template scale keys")
    local s=f32(bone.scale)..string.rep("\0",8)
    put(changes,bytes,scale+12,s)
    put(changes,bytes,scale+28,s)
end
function M.patchTemplate(bones,bytes,kind)
    M.validate(bones)
    assert(kind=="nif" or kind=="xnif" or kind=="kf","Unknown animation template")
    local byName={}
    for _,bone in ipairs(bones) do byName[bone.name:lower()]=bone end
    local ordered,seen,changes={},{},{}
    if kind=="kf" then
        for _,at in ipairs(blocks(bytes,"NiStringExtraData")) do
            local length=readU32(bytes,at+8)
            local name=bytes:sub(at+12,at+11+length)
            local bone=byName[name:lower()]
            assert(bone and not seen[name:lower()],"KF template skeleton mismatch: "..name)
            seen[name:lower()]=true
            ordered[#ordered+1]=bone
        end
    else
        for _,at in ipairs(blocks(bytes,"NiNode")) do
            local length=readU32(bytes,at)
            assert(length<128,"Invalid template node name")
            local name=bytes:sub(at+4,at+3+length)
            local bone=byName[name:lower()]
            if bone then
                assert(not seen[name:lower()],"Duplicate template bone: "..name)
                seen[name:lower()]=true
                local controller=readU32(bytes,at+8+length)
                if kind=="nif" then
                    assert(controller~=4294967295,"Unanimated template bone: "..name)
                    ordered[#ordered+1]=bone
                end
                put(changes,bytes,at+14+length,
                    floats(bone.translation)..floats(bone.rotation)..f32(bone.scale))
            end
        end
    end
    assert(#ordered==(kind=="xnif" and 0 or #bones),"Template animation count mismatch")
    for _,bone in ipairs(bones) do
        assert(seen[bone.name:lower()],"Template is missing bone: "..bone.name)
    end
    if kind~="xnif" then
        local keys=blocks(bytes,"NiKeyframeData")
        assert(#keys==#ordered,"Template keyframe count mismatch")
        for i,at in ipairs(keys) do keyframe(changes,bytes,at,ordered[i]) end
    end
    -- Assemble once instead of copying the complete NIF for every bone/key.
    table.sort(changes,function(a,b) return a.offset<b.offset end)
    local parts,from={},1
    for _,change in ipairs(changes) do
        assert(change.offset>=from,"Overlapping template patches")
        parts[#parts+1]=bytes:sub(from,change.offset-1)
        parts[#parts+1]=change.value
        from=change.offset+#change.value
    end
    parts[#parts+1]=bytes:sub(from)
    return table.concat(parts)
end
return M
