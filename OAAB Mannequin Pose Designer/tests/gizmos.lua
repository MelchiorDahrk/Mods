package.path="./MWSE/mods/?.lua;"..package.path
local v=require("MannequinPoseDesigner.math3d")
local rig=require("MannequinPoseDesigner.rig")
local F=dofile("tests/prop_fixture.lua")
local props=require("MannequinPoseDesigner.props")
local g=require("MannequinPoseDesigner.gizmos")
local count=0
local function check(ok,reason) assert(ok,reason); count=count+1 end
local oldVector=tes3vector3.new
local mt={__add=function(a,b) return tes3vector3.new(a.x+b.x,a.y+b.y,a.z+b.z) end,
    __sub=function(a,b) return tes3vector3.new(a.x-b.x,a.y-b.y,a.z-b.z) end}
tes3vector3.new=function(...) return setmetatable(oldVector(...),mt) end
niColor={new=function(r,g,b) return {r=r,g=g,b=b} end}
ni={zBufferPropertyTestFunction={always=0}}
niZBufferProperty={new=function() error("Do not override the authored gizmo depth properties") end}
niAlphaProperty={new=function() error("Do not override the authored gizmo alpha properties") end}
local colors={X={.74947739,.14947738,.14947738},Y={.40833142,.89901578,.40833142},Z={.19018845,.19018845,.90000761},
    X_move={.89019608,.49019608,.55294120}}
local materialClones=0
local function material(alpha,color)
    return {alpha=alpha,diffuse=niColor.new(unpack(color)),emissive=niColor.new(0,0,0),
        clone=function() materialClones=materialClones+1; return material(alpha,color) end}
end
local loaded,templates,sourceMaterials={},{},{}
local function updateProperties(node,alpha,depth)
    alpha=node.alphaProperty or alpha; depth=node.zBufferProperty or depth
    node.effectiveAlpha=alpha; node.effectiveDepth=depth
    node.effectiveVertex=node.vertexColorProperty or node.parent and node.parent.effectiveVertex
    node.effectiveFog=node.fogProperty or node.parent and node.parent.effectiveFog
    for _,child in pairs(node.children) do updateProperties(child,alpha,depth) end
end
local function shape(name,scale,radius,rotation)
    local node=F.node(name,"NiTriShape")
    node.materialProperty=material(name=="sphere" and 0 or 1,colors[name] or colors[name:sub(1,1)] or {0,0,0})
    node.scale=scale
    if name=="sphere" then node.alphaProperty={propertyFlags=1,testThreshold=0} end
    if rotation then node.rotation=rig.engineMatrix(rotation) end
    local update=node.update
    function node:update()
        update(self)
        self.worldBoundRadius=radius*self.worldTransform.scale
    end
    return node
end
local function mesh()
    local root=F.node("gizmo.nif")
    root.worldBoundRadius=60; root.worldBoundOrigin=tes3vector3.new()
    function root:updateProperties() self.propertiesUpdated=true end
    function root:clone() error("Do not reclone the fresh graph and its loaded sort accumulator") end
    root.vertexColorProperty={vertexMode=0,lightingMode=0}
    root.fogProperty={propertyFlags=0,fogDepth=.8}
    local rotate=F.node("rotate","NiSortAdjustNode"); rotate.scale=.2; root:attachChild(rotate)
    rotate.sortingMode=64; rotate.accumulator={type="NiAlphaAccumulator"}
    rotate.alphaProperty={propertyFlags=0,testThreshold=0}
    local collision=F.node("","NiCollisionSwitch"); rotate:attachChild(collision)
    collision.collisionActive=false
    collision:attachChild(shape("sphere",.95,173.49078))
    rotate:attachChild(shape("X",1.1,174.0058899))
    rotate:attachChild(shape("Y",1.05,174.0058899,v.axisAngle({0,0,1},math.pi/2)))
    rotate:attachChild(shape("Z",1,174.0058899,v.axisAngle({0,1,0},math.pi/2)))
    for _,name in ipairs({"X_move","Y_move","Z_move"}) do
        rotate:attachChild(shape(name,6.4,22.21453094))
    end
    -- Shared axis materials must not make a hovered arrow recolor its ring.
    rotate.children[6].materialProperty=rotate.children[3].materialProperty
    rotate.children[7].materialProperty=rotate.children[4].materialProperty
    root:attachChild(shape("node",2,1))
    return root
end
local createNode=niNode.new
niNode.new=function()
    local node=createNode()
    function node:updateEffects() self.effectsUpdated=true end
    function node:updateProperties()
        if self.name=="OAAB:MannequinPoseDesigner:Gizmo" then
            check(self.parent and self.children[1].parent==self,"Resolve properties only after attaching the complete graph")
        end
        updateProperties(self,self.parent and self.parent.effectiveAlpha,self.parent and self.parent.effectiveDepth)
        self.propertiesUpdated=true
    end
    return node
end
tes3.loadMesh=function(path,cached)
    check(cached==false,"Load fresh gizmo meshes")
    loaded[#loaded+1]=path; templates[1]=mesh()
    sourceMaterials[1]=templates[1].children[1].children[5].materialProperty
    return templates[1]
end
local zoom=2
local camera={worldUp=tes3vector3.new(0,0,1),worldTransform={translation=tes3vector3.new(0,-100,0)}}
function camera:worldPointToScreenPoint(p) return {x=p.x*zoom,y=p.z*zoom} end
function camera:windowPointToRay(p) return tes3vector3.new(p[1]/zoom,-100,p[2]/zoom),tes3vector3.new(0,1,0) end
tes3.getCamera=function() return camera end
local rayCalls,hit=0,nil
tes3.rayTest=function(args)
    rayCalls=rayCalls+1
    check(args.root.name=="OAAB:MannequinPoseDesigner:Gizmo" and args.useBackTriangles and args.maxDistance>0,
        "Picking tests only the gizmo's triangles, including their backs")
    return hit and {object=hit}
end
local parent=niNode.new(); parent.translation=tes3vector3.new(100,200,300)
parent.rotation=rig.engineMatrix(v.axisAngle({0,0,1},.8)); parent.scale=3; parent:update()
local self=g.create(parent)
check(#loaded==1 and loaded[1]=="pose\\h\\gizmo.nif" and self.root.parent==parent,"Load only the author's NIF under the existing handle branch")
check(self.mesh==templates[1] and self.root.propertiesUpdated,"Keep the freshly loaded render graph and update its final property inheritance")
check(materialClones==0,"Idle gizmos keep their authored materials without cloning or overriding them")
local rotate=self.mesh.children[1]
local sphere=rotate.children[1].children[1]
local boneShape=self.mesh.children[2]
local boneMaterial=boneShape.materialProperty
check(boneShape.appCulled and not self.byShape.node and #self.masks==1,
    "The bone node shape is hidden in the transform graph and never becomes an axis or mask")
check(rotate.RTTI.name=="NiSortAdjustNode" and rotate.scale==.2
    and self.components.rotate.y.shape.parent==rotate and self.components.rotate.y.shape.scale==1.05
    and self.components.move.x.shape.parent==rotate and self.components.move.x.shape.scale==6.4,
    "Discover rings and arrows beneath their shared sorting parent without replacing authored groups or scales")
for i,value in ipairs(v.axisAngle({0,0,1},math.pi/2)) do
    check(math.abs(rig.matrix(self.components.rotate.y.shape.rotation)[i]-value)<1e-7,"Retain the ring's authored axis rotation")
end
check(math.abs(self.radius-174.0058899*.2*1.1)<1e-7,"Screen sizing includes the nested rotation group's scale")
check(#self.masks==1 and self.masks[1]==sphere and not sphere.appCulled and not rotate.appCulled and not self.byShape.sphere,
    "The shared sorting parent stays active while the mask remains outside the interactive components")
local sortAlpha,sphereAlpha,accumulator,sphereMaterial=rotate.alphaProperty,sphere.alphaProperty,rotate.accumulator,sphere.materialProperty
check(self.components.rotate.x.shape.effectiveAlpha==sortAlpha and self.components.move.x.shape.effectiveAlpha==sortAlpha
    and sphere.effectiveAlpha==sphereAlpha,
    "The rings and arrows inherit the shared alpha property while the sphere retains its own blend property")
local collision=sphere.parent
local authoredChildren={unpack(rotate.children)}
local vertex,fog=self.mesh.vertexColorProperty,self.mesh.fogProperty
local function checkRotationGraph(visible)
    check(boneShape.appCulled and boneShape.materialProperty==boneMaterial,
        "Mode changes keep the separately cloned bone shape hidden with its authored material")
    check(not rotate.appCulled and not collision.appCulled and sphere.appCulled~=visible,
        "The sorting and collision parents stay active while the sphere follows ring visibility")
    for i,child in ipairs(authoredChildren) do
        check(rotate.children[i]==child,"Keep mask-first child traversal order for grouped alpha rendering")
    end
    for _,entry in pairs(self.components.rotate) do
        check(entry.shape.appCulled~=visible and entry.shape.effectiveAlpha==sortAlpha,
            "Every ring follows rotation visibility with the authored inherited alpha")
    end
    for _,entry in pairs(self.components.move) do
        check(entry.shape.appCulled==visible and not entry.shape.parent.appCulled and entry.shape.effectiveAlpha==sortAlpha,
            "Every arrow stays visible through the shared parent in movement mode")
    end
    for _,entry in pairs(self.byShape) do
        check(entry.shape.effectiveVertex==vertex and entry.shape.effectiveFog==fog,
            "Both modes retain the authored unlit vertex-color and disabled fog inheritance")
    end
end
local function checkAuthoredMaterials()
    for _,entry in pairs(self.byShape) do
        local source=colors[entry.shape.name] or colors[entry.shape.name:sub(1,1)]
        local diffuse,emissive=entry.material.diffuse,entry.material.emissive
        check(emissive.r==0 and emissive.g==0 and emissive.b==0 and entry.material.alpha==1
            and diffuse.r==source[1] and diffuse.g==source[2] and diffuse.b==source[3],
            "Authored diffuse, emissive and alpha values stay unchanged even when emission differs from diffuse")
        check(entry.shape.materialProperty==(self.highlighted==entry and entry.highlightMaterial or entry.material),
            "Only the hovered or dragged shape uses a temporary material; every idle shape keeps its original property")
    end
    check(sphere.materialProperty==sphereMaterial and sphereMaterial.alpha==0
        and sphereMaterial.emissive.r==0 and sphereMaterial.emissive.g==0 and sphereMaterial.emissive.b==0,
        "Highlighting handles never lights or changes the transparent sphere")
end
checkAuthoredMaterials()
local world={{translation={10,20,30},rotation=v.axisAngle({1,0,0},.4),scale=5}}
local s={selected=1,bones={{parent=0}},chains={},handles=true,mode="IK",cursor={20,60}}
g.update(self,s,world)
check(self.mode=="move" and not self.root.appCulled and not rotate.appCulled
    and not self.components.move.x.shape.appCulled,"Root G mode shows only the three authored arrows")
checkRotationGraph(false)
checkAuthoredMaterials()
local actual=props.nodeTransform(self.root)
check(v.length(v.sub(actual.translation,world[1].translation))<1e-7 and math.abs(actual.scale-35/self.radius)<1e-7,
    "A rotated/scaled scene parent preserves the world pivot and screen size")
for i,value in ipairs(actual.rotation) do check(math.abs(value-world[1].rotation[i])<1e-7,"The gizmo follows local world axes") end
local entry=self.components.move.y; hit=entry.shape
check(entry.material==self.components.rotate.y.material,"The authored Y arrow and ring share their source material")
check(g.update(self,s,world)=="y","Hover still reports the hit component")
local highlighted=entry.shape.materialProperty
check(highlighted~=entry.material and highlighted.alpha==1 and highlighted.emissive.r==1
    and highlighted.emissive.g==.85 and highlighted.diffuse.b==.25,"Hover highlights only a private copy of the hit component's material")
checkAuthoredMaterials()
hit=nil; g.update(self,s,world)
check(entry.shape.materialProperty==entry.material,"Moving off a handle restores the exact authored material property")
checkAuthoredMaterials()
s.drag={button=0,mode="IK",constraint={component="y"}}
check(g.update(self,s,world)=="y" and entry.shape.materialProperty==highlighted and materialClones==1,
    "Dragging keeps the component highlighted away from the cursor and reuses its private material")
s.handles=false; g.update(self,s,world)
check(entry.shape.materialProperty==entry.material and not self.highlighted,"Hiding handles clears the drag highlight and restores the authored property")
s.handles=true; s.drag=nil; g.update(self,s,world)
checkAuthoredMaterials()
check(sourceMaterials[1].emissive.r==0 and self.components.move.x.material==sourceMaterials[1],
    "Idle arrows retain the loaded NIF's exact source material without an emissive override")
hit=self.components.rotate.y.shape
check(not g.pick(self,s.cursor),"A hidden ring cannot select a movement constraint")
hit=self.components.move.z.shape
check(g.pick(self,s.cursor)=="z","Z_move selects the Z movement axis")
hit=nil
s.mode="Rotate"; g.update(self,s,world)
check(self.mode=="rotate" and self.components.move.x.shape.appCulled and not rotate.appCulled,"R reveals the author's three circles and their sphere together")
checkRotationGraph(true)
checkAuthoredMaterials()
hit=self.components.rotate.z.shape; g.update(self,s,world)
check(self.components.rotate.z.shape.materialProperty.emissive.r==1 and self.components.rotate.z.shape.materialProperty.emissive.g==.85,
    "A hovered ring uses amber emission without needing a scene light")
checkAuthoredMaterials()
s.mode="Move"; hit=nil; g.update(self,s,world)
check(self.components.rotate.z.shape.materialProperty==self.components.rotate.z.material and not self.highlighted,
    "Switching modes restores a highlighted ring before hiding it")
s.mode="Rotate"; g.update(self,s,world); checkAuthoredMaterials()
hit=self.components.rotate.x.shape; check(g.pick(self,s.cursor)=="x","X selects the X rotation axis"); hit=nil
hit=sphere; check(not sphere.appCulled and not g.pick(self,s.cursor),"The sphere renders with the circles without selecting a rotation axis"); hit=nil
check(rotate.alphaProperty==sortAlpha and sortAlpha.propertyFlags==0
    and rotate.sortingMode==64 and rotate.accumulator==accumulator,
    "Retain the rotation group's authored alpha property, sorting mode and accumulator")
check(sphere.alphaProperty==sphereAlpha and sphereAlpha.propertyFlags==1 and sphere.materialProperty==sphereMaterial
    and sphereMaterial.alpha==0 and not sphere.parent.collisionActive,
    "Preserve the transparent depth mask and its disabled collision switch")
for _,entry in pairs(self.byShape) do
    check(not entry.shape.zBufferProperty and not entry.shape.alphaProperty,
        "Shapes keep their authored depth behavior and inherited alpha properties")
end
local scale=actual.scale; zoom=4; g.update(self,s,world)
check(math.abs(props.nodeTransform(self.root).scale-scale/2)<1e-7,"Zoom preserves the gizmo's pixel size")
s.handles=false; g.update(self,s,world); local before=rayCalls
check(self.root.appCulled and not g.pick(self,s.cursor) and rayCalls==before,"V hides the gizmo and removes its hit targets")
s.handles=true; s.mode="IK"; s.bones[1].parent=2; g.update(self,s,world)
check(self.mode=="rotate","G uses direct rotation for ordinary joints")
s.chains[1]={}; g.update(self,s,world); check(self.mode=="move","IK tips use the movement gizmo")
checkRotationGraph(false)
s.mode="Rotate"; g.update(self,s,world)
check(not rotate.appCulled and not sphere.appCulled and rotate.alphaProperty==sortAlpha and sphere.alphaProperty==sphereAlpha
    and rotate.sortingMode==64,"Returning to rotation restores the mask with unchanged render state")
checkRotationGraph(true)
checkAuthoredMaterials()
s.selectedProp="p"; s.props={{id="p"}}; s.propScene={nodes={p=F.node("Prop")}}
s.propScene.nodes.p.translation=tes3vector3.new(4,5,6); s.propScene.nodes.p:update()
s.mode="Move"; g.update(self,s,world)
check(v.length(v.sub(props.nodeTransform(self.root).translation,{4,5,6}))<1e-7,"Prop gizmo tracks its actual world transform")
s.mode="Scale"; g.update(self,s,world); check(self.root.appCulled,"Uniform prop scaling hides the move/rotate controls")
s.mode="Move"; g.update(self,s,world); parent.appCulled=true; before=rayCalls
check(not g.pick(self,s.cursor) and rayCalls==before,"Modal/focus visibility on the parent also gates picking")
parent.appCulled=false
local originalRay=camera.windowPointToRay
camera.windowPointToRay=function() return nil end
before=rayCalls
check(not g.ray(s.cursor) and not g.pick(self,s.cursor) and rayCalls==before,"Unavailable camera rays leave picking and editing idle")
camera.windowPointToRay=originalRay
hit=self.components.move.x.shape; g.update(self,s,world)
check(self.highlighted==self.components.move.x,"Cleanup begins with an active arrow highlight")
g.destroy(self); g.destroy(self)
check(not self.root.parent and not g.pick(self,s.cursor),"Cleanup detaches every gizmo and is safe to repeat")
checkAuthoredMaterials()
print("PASS: "..count.." native gizmo load, materials, transforms, mode, visibility and cleanup assertions")
