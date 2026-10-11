package.path="./MWSE/mods/?.lua;"..package.path
local v=require("MannequinPoseDesigner.math3d")
local rig=require("MannequinPoseDesigner.rig")
local F=dofile("tests/prop_fixture.lua")
local props=require("MannequinPoseDesigner.props")
local g=require("MannequinPoseDesigner.gizmos")
local picking=require("MannequinPoseDesigner.gizmo_picking")
local constraintMath=require("MannequinPoseDesigner.gizmo_math")
local count=0
local function check(ok,message) assert(ok,message); count=count+1 end
local oldVector=tes3vector3.new
tes3vector3.new=function(...)
    return setmetatable(oldVector(...),{__add=function(a,b) return tes3vector3.new(a.x+b.x,a.y+b.y,a.z+b.z) end,
        __sub=function(a,b) return tes3vector3.new(a.x-b.x,a.y-b.y,a.z-b.z) end})
end
niColor={new=function(r,g,b) return {r=r,g=g,b=b} end}
niZBufferProperty={new=function() error("Picking must not change depth properties") end}
niAlphaProperty={new=function() error("Picking must not change alpha properties") end}
local function data(vertices,triangles)
    local result={vertices={},triangles={},vertexCount=#vertices,activeTriangleCount=#triangles}
    for i,p in ipairs(vertices) do result.vertices[i]=rig.engineVector(p) end
    for i,triangle in ipairs(triangles) do result.triangles[i]={vertices=triangle} end
    return result
end
local vertices,triangles={},{}
local steps=64
for i=0,steps-1 do
    local angle=i*2*math.pi/steps
    for _,radius in ipairs({29.5,30.5}) do vertices[#vertices+1]={0,radius*math.cos(angle),radius*math.sin(angle)} end
    local a,b,c,d=2*i,2*i+1,(2*i+2)%(2*steps),(2*i+3)%(2*steps)
    triangles[#triangles+1]={a,b,c}; triangles[#triangles+1]={b,d,c}
end
local ringData=data(vertices,triangles)
check(picking.geometry(ringData).triangles[1],"Read the installed MWSE triangle vertices field")
vertices,triangles={},{}
local longitude,latitude=32,16
for i=0,latitude do for j=0,longitude-1 do
    local phi,theta=i*math.pi/latitude,j*2*math.pi/longitude
    vertices[#vertices+1]={25*math.cos(phi),25*math.sin(phi)*math.cos(theta),25*math.sin(phi)*math.sin(theta)}
end end
for i=0,latitude-1 do for j=0,longitude-1 do
    local a,b=i*longitude+j,i*longitude+(j+1)%longitude
    local c,d=a+longitude,b+longitude
    triangles[#triangles+1]={a,b,c}; triangles[#triangles+1]={b,d,c}
end end
local sphereData=data(vertices,triangles)
local function material(color,alpha)
    return {diffuse=niColor.new(unpack(color)),emissive=niColor.new(0,0,0),alpha=alpha,
        clone=function() return material(color,alpha) end}
end
local colors={X={1,0,0},Y={0,1,0},Z={0,0,1}}
local function shape(name,scale,geometry)
    local node=F.node(name,"NiTriShape"); node.scale=scale; node.data=geometry
    node.materialProperty=material(colors[name:sub(1,1)] or {0,0,0},name=="sphere" and 0 or 1)
    local update=node.update
    function node:update() update(self); self.worldBoundRadius=30.5*self.worldTransform.scale end
    return node
end
local function mesh()
    local root=F.node("gizmo.nif"); root.worldBoundOrigin=tes3vector3.new(); root.worldBoundRadius=40
    function root:clone() return mesh() end
    function root:updateProperties() end
    local rotate=F.node("rotate","NiSortAdjustNode"); rotate.scale=.2; rotate.sortingMode=64
    rotate.alphaProperty={propertyFlags=0}; rotate.accumulator={}
    root:attachChild(rotate)
    local collision=F.node("","NiCollisionSwitch"); collision.collisionActive=false; rotate:attachChild(collision)
    local sphere=shape("sphere",.95,sphereData); sphere.alphaProperty={propertyFlags=1}; collision:attachChild(sphere)
    rotate:attachChild(shape("X",1.1,ringData)); rotate:attachChild(shape("Y",1.05,ringData)); rotate:attachChild(shape("Z",1,ringData))
    for _,axis in ipairs({"X","Y","Z"}) do rotate:attachChild(shape(axis.."_move",6.4)) end
    root:attachChild(shape("node",2))
    return root
end
niNode.new=function()
    local node=F.node("")
    function node:updateEffects() end
    function node:updateProperties() end
    return node
end
tes3.loadMesh=function() return mesh() end
local zoom=10
local right,up,direction={0,1,0},{0,0,1},{1,0,0}
local camera={worldTransform={translation=tes3vector3.new(-100,0,0)},worldUp=rig.engineVector(up)}
function camera:worldPointToScreenPoint(point)
    point=rig.vector(point); return {x=v.dot(point,right)*zoom,y=v.dot(point,up)*zoom}
end
function camera:windowPointToRay(cursor)
    local origin=v.add(rig.vector(self.worldTransform.translation),v.add(v.scale(right,cursor[1]/zoom),v.scale(up,cursor[2]/zoom)))
    return rig.engineVector(origin),rig.engineVector(direction)
end
tes3.getCamera=function() return camera end
local hit,calls=nil,0
tes3.rayTest=function(args) calls=calls+1; check(args.useBackTriangles and args.maxDistance>0,"Keep the exact triangle ray test"); return hit end
local parent=niNode.new(); parent:update()
local self=g.create(parent)
local world={{translation={0,0,0},rotation=v.identity(),scale=1}}
local s={selected=1,bones={{parent=0}},chains={},handles=true,mode="Rotate",cursor={500,500}}
local function updateSingle()
    g.update(self,s,world)
    self.components.rotate.y.shape.appCulled=true; self.components.rotate.z.shape.appCulled=true
end
for _,value in ipairs({2,4,10}) do
    zoom=value; updateSingle()
    check(g.pick(self,{75,0})=="x","A click five pixels outside the ring selects it at every zoom")
    check(g.pick(self,{65,0})=="x","The wider selection also reaches inside the ring")
    check(not g.pick(self,{77,0}),"A click seven pixels outside stays outside the tolerance")
end
local before=calls
check(not g.pick(self,{500,500}) and calls==before+1,"Distant cursors use one native ray and skip mesh projection")
local constraint=g.begin(self,{cursor={75,0}},world[1])
check(constraint and constraint.component=="x" and constraint.kind=="rotate","A fuzzy click starts the existing ring constraint")
local angle=math.pi/6
local origin,ray=camera:windowPointToRay({75*math.cos(angle),75*math.sin(angle)})
check(math.abs(constraintMath.step(constraint,rig.vector(origin),rig.vector(ray),1)-angle)<1e-7,
    "Dragging after a fuzzy click preserves the normal rotation angle")
s.cursor={75,0}; local hovered=g.update(self,s,world)
check(hovered=="x","The gizmo exposes its hovered component for bone-hover priority")
check(self.components.rotate.x.shape.materialProperty.emissive.r==1 and self.components.rotate.x.shape.materialProperty.emissive.g==.85,
    "Fuzzy hover highlights the same ring that clicking selects")
s.cursor={500,500}; updateSingle()
check(self.components.rotate.x.shape.materialProperty==self.components.rotate.x.material
    and self.components.rotate.x.material.emissive.r==0,
    "Leaving a fuzzy hover restores the original ring material and authored emission")
self.components.rotate.y.shape.appCulled=false
check(g.pick(self,{63,0})=="y","Overlapping tolerances choose the closest ring")
hit={object=self.components.rotate.x.shape}
check(g.pick(self,{63,0})=="x","An exact triangle hit takes priority over a nearby ring")
hit=nil
self.components.rotate.y.shape.appCulled=true
check(g.pick(self,{65,0})=="x","Hidden rings do not compete for fuzzy selection")
s.mode="IK"; g.update(self,s,world)
check(not g.pick(self,{75,0}),"Movement mode does not use the rotation tolerance")
s.mode="Rotate"; updateSingle(); s.handles=false; g.update(self,s,world)
before=calls; check(not g.pick(self,{75,0}) and calls==before,"V hides fuzzy hit targets as well as exact ones")
s.handles=true; updateSingle()
parent.appCulled=true; before=calls
check(not g.pick(self,{75,0}) and calls==before,"Modal/focus culling also gates fuzzy selection")
parent.appCulled=false
direction=v.unit({1,1,.7}); right=v.unit({1,-1,0}); up=v.unit(v.cross(right,direction))
camera.worldTransform.translation=rig.engineVector(v.scale(direction,-100)); camera.worldUp=rig.engineVector(up)
updateSingle()
local transform=props.nodeTransform(self.components.rotate.x.shape)
local localPoint={0,30.5/math.sqrt(2),30.5/math.sqrt(2)}
local rear=v.add(transform.translation,v.scale(v.transform(transform.rotation,localPoint),transform.scale))
local front=v.sub(transform.translation,v.scale(v.transform(transform.rotation,localPoint),transform.scale))
local rearScreen=camera:worldPointToScreenPoint(rig.engineVector(rear))
local frontScreen=camera:worldPointToScreenPoint(rig.engineVector(front))
check(not g.pick(self,{rearScreen.x,rearScreen.y}),"Fuzzy selection excludes a rear arc behind the sphere")
hit={object=self.components.rotate.x.shape,intersection=rig.engineVector(rear)}
check(not g.pick(self,{rearScreen.x,rearScreen.y}),"An exact rear-ring ray cannot bypass the sphere mask")
hit=nil
check(g.pick(self,{frontScreen.x,frontScreen.y})=="x","The corresponding visible front arc stays selectable")
local orthoProjection,orthoRay=camera.worldPointToScreenPoint,camera.windowPointToRay
local focal=300
function camera:worldPointToScreenPoint(point)
    local offset=v.sub(rig.vector(point),rig.vector(self.worldTransform.translation))
    local depth=v.dot(offset,direction)
    if depth<=0 then return end
    return {x=focal*v.dot(offset,right)/depth,y=focal*v.dot(offset,up)/depth}
end
function camera:windowPointToRay(cursor)
    return self.worldTransform.translation,rig.engineVector(v.unit(v.add(direction,v.add(v.scale(right,cursor[1]/focal),v.scale(up,cursor[2]/focal)))))
end
updateSingle()
transform=props.nodeTransform(self.components.rotate.x.shape)
front=v.sub(transform.translation,v.scale(v.transform(transform.rotation,localPoint),transform.scale))
frontScreen=camera:worldPointToScreenPoint(rig.engineVector(front))
check(g.pick(self,{frontScreen.x,frontScreen.y})=="x","Perspective projection keeps visible edges selectable")
rear=v.add(transform.translation,v.scale(v.transform(transform.rotation,localPoint),transform.scale))
rearScreen=camera:worldPointToScreenPoint(rig.engineVector(rear))
check(not g.pick(self,{rearScreen.x,rearScreen.y}),"Perspective edge interpolation preserves rear-arc masking")
camera.worldPointToScreenPoint=function() return nil end
check(not g.pick(self,{0,0}),"Unavailable projections cannot create fuzzy hit targets")
camera.worldPointToScreenPoint=orthoProjection; camera.windowPointToRay=orthoRay
local rotate=self.mesh.children[1]; local sphere=self.masks[1]
check(rotate.sortingMode==64 and rotate.alphaProperty.propertyFlags==0 and sphere.alphaProperty.propertyFlags==1
    and sphere.materialProperty.alpha==0,"Picking leaves authored alpha, sorting and sphere material untouched")
check(ringData.vertices[1].y==29.5 and sphereData.vertices[1].x==25,"Picking never edits the shared NIF geometry")
g.destroy(self); check(not g.pick(self,{75,0}),"Cleanup removes fuzzy picking")
local damagedData=data({{0,0,0},{1,0,0},{0,1,0}},{{0,1,2}})
damagedData.triangles[1]={}
local originalLoader=tes3.loadMesh
local function damagedMesh()
    local root=mesh()
    root.children[1].children[2].data=damagedData
    root.clone=damagedMesh
    return root
end
tes3.loadMesh=damagedMesh
local fallback=g.create(parent)
check(fallback.fuzzyUnavailable and fallback.root.parent==parent,"An unreadable optional picker cannot prevent editor startup")
s.cursor={500,500}; s.mode="Rotate"; g.update(fallback,s,world)
hit={object=fallback.components.rotate.x.shape}
check(g.pick(fallback,{75,0})=="x","Picker initialization failure preserves exact ring selection")
hit=nil
check(not g.pick(fallback,{75,0}),"Incomplete picker data disables fuzzy selection instead of bypassing masking")
check(not fallback.masks[1].appCulled and fallback.masks[1].materialProperty.alpha==0
    and fallback.mesh.children[1].sortingMode==64,"Exact-picking fallback retains the sphere's rendering and sorting")
g.destroy(fallback); tes3.loadMesh=originalLoader
print("PASS: "..count.." fuzzy ring tolerance, zoom, overlap, drag, masking, perspective and render preservation assertions")
