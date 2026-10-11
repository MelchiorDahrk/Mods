package.path="./MWSE/mods/?.lua;"..package.path
local count=0
local function check(ok,why) assert(ok,why); count=count+1 end
tes3={player={},objectType={}}
for _,name in ipairs({"weapon","ammunition","armor","clothing","book","miscItem","ingredient","alchemy","apparatus","lockpick","probe","repairItem","light"}) do tes3.objectType[name]=name end
if arg[2] then
    local library=arg[2]:gsub("\\","/"):match("^(.*)/dkjson%.lua$")
    tes3.objectType=dofile(assert(library).."/tes3/objectType.lua")
end
local inventory,mode,closedMenu
local nativeMenu={destroy=function() closedMenu=true end}
tes3ui={showInventorySelectMenu=function(args) inventory=args end,
    findMenu=function(id) check(id=="MenuInventorySelect","Close only the native inventory picker"); return nativeMenu end,
    leaveMenuMode=function() mode=false end}
local menu=require("MannequinPoseDesigner.props_menu")
check(not menu.open and not menu.attachments and not menu.bones,"Prop commands use the sidebar without separate menus")
local picked,exits=0,0
local inv=menu.inventory(function(item) picked=picked+1; check(item.id=="test","Native callback supplies inventory source") end,function() exits=exits+1 end)
check(inventory.reference==tes3.player and inventory.leaveMenuMode and inventory.title=="Add Prop","Native inventory picker uses player inventory and the Add title")
for _,kind in ipairs({"weapon","ammunition","armor","clothing","book","miscItem","ingredient","repairItem"}) do
    check(inventory.filter({item={objectType=tes3.objectType[kind],mesh="item.nif"}}),"Allow ordinary mesh-bearing inventory class: "..kind)
end
check(not inventory.filter({item={objectType=tes3.objectType.light,mesh="light.nif"}}) and not inventory.filter({item={objectType=tes3.objectType.miscItem}}),"Exclude lights and missing meshes")
inventory.callback({item={id="test"},count=50}); inventory.callback({item={id="test"}})
check(picked==1 and exits==1 and inv.closed,"One visual prop is selected without transferring any inventory count")
inv=menu.inventory(function() error("Cancelled picker must not add") end,function() exits=exits+1 end)
inventory.callback({}); check(inv.closed and exits==2,"Inventory cancellation releases editor input")
tes3ui.showInventorySelectMenu=function(args) args.noResultsCallback() end
inv=menu.inventory(function() error("No inventory must not add") end,function() exits=exits+1 end)
check(inv.closed and exits==3,"Synchronous no-results callback does not leave a modal editor lock")
tes3ui.showInventorySelectMenu=function(args) inventory=args; mode=true end
inv=menu.inventory(function() error("Closed picker must not add") end,function() exits=exits+1 end,"Replace Prop")
check(inventory.title=="Replace Prop" and inventory.leaveMenuMode and inventory.filter({item={objectType=tes3.objectType.book,mesh="book.nif"}}),
    "Replacement reuses native item filtering and menu lifecycle with its own title")
inv.close(); inv.close()
check(closedMenu and not mode and inv.closed and exits==4,"Editor exit closes the inventory picker exactly once")
print("PASS: "..count.." inventory filtering, selection and modal lifecycle assertions")
