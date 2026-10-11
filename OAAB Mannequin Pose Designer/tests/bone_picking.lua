package.path="./MWSE/mods/?.lua;"..package.path
local picking=require("MannequinPoseDesigner.bone_picking")
local count=0
local function check(ok,message) assert(ok,message); count=count+1 end
local s={selected=1,selectable={1,2},handles=true,cursor={100,0},screen={[1]={x=0,y=0},[2]={x=100,y=0},[3]={x=100,y=0}}}
check(picking.pick(s)==2,"Only selectable projected bones compete for picking")
s.cursor={117.999,0}
check(picking.pick(s)==2,"The existing 18-pixel radius reaches just inside its boundary")
s.cursor={118,0}
check(not picking.pick(s),"The radius boundary remains excluded")
s.cursor={50,0}
check(not picking.pick(s),"Distant nodes do not acquire hover or selection")
s.screen[2]={x=20,y=0}; s.cursor={10,0}
check(picking.pick(s)==1,"Equal distances resolve in selectable order")
s.cursor={11,0}
check(picking.pick(s)==2,"The nearer distinct node wins")
s.screen[2]={x=0.000001,y=0}; s.cursor={6,0}
check(picking.pick(s)==1,"An overlapping Pelvis cannot steal ROOT's hover or selection")
s.selected=2; s.cursor={-6,0}
check(picking.pick(s)==2,"Tab-selected Pelvis retains the shared pivot")
s.screen[2]=nil
check(picking.pick(s)==1,"An unprojected bone cannot retain the shared pivot")
s.handles=false
check(not picking.pick(s),"Hidden handles cannot be hovered or clicked")
s.handles=true; s.selectedProp="prop"
check(picking.pick(s)==1,"Prop selection keeps bone targets available")
s.selectedProp=nil; s.screen=nil
check(not picking.pick(s),"Missing projections leave hover and selection idle")
s.screen={[1]={x=0,y=0},[2]={x=100,y=0}}; s.selected=1; s.cursor={4,0}
s.props={{id="a"},{id="b"}}; s.propScreen={a={x=0,y=0},b={x=0.000001,y=0}}; s.selectedProp="a"
check(picking.prop(s)=="a","The selected prop keeps its overlapping pivot")
local bone,prop=picking.target(s)
check(not bone and prop=="a","An active prop wins its shared bone pivot")
bone,prop=picking.target(s,true)
check(bone==1 and not prop,"Shift prefers the attachment bone at a shared pivot")
s.selectedProp="b"; check(picking.prop(s)=="b","A cycled duplicate remains selectable at the shared pivot")
s.propScreen.a={x=10,y=0}; s.propScreen.b={x=30,y=0}; s.cursor={0,0}
bone,prop=picking.target(s); check(bone==1 and not prop,"The nearest distinct bone wins")
s.cursor={10,0}; bone,prop=picking.target(s); check(not bone and prop=="a","The nearest prop node wins")
s.handles=false; check(not picking.prop(s),"Hidden prop nodes cannot be picked")
s.handles=true; s.propScreen={}; check(not picking.prop(s),"Unprojected prop nodes are not selectable")
print("PASS: "..count.." shared bone radius, overlap, visibility and prop-selection assertions")
