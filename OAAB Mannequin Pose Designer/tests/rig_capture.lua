package.path="./MWSE/mods/?.lua;"..package.path
local rig=require("MannequinPoseDesigner.rig")
tes3={niType={NiNode="NiNode"}}
local function matrix()
    return {x={x=1,y=0,z=0},y={x=0,y=1,z=0},z={x=0,y=0,z=1}}
end
local function node(name,children)
    return {name=name,children=children or {},translation={x=0,y=0,z=0},rotation=matrix(),scale=1,
        isInstanceOfType=function(_,kind) return kind=="NiNode" end}
end
local root=node("Root")
local bip=node("Bip01")
local arm=node("Bip01 L UpperArm")
local hand=node("Bip01 L Hand")
local duplicate=node("Bip01 L Hand")
local mesh={isInstanceOfType=function() return false end}
-- A regular Lua table cannot expose nil values through pairs. This proxy
-- deliberately models the NI::TArray iterator yielding vacant slots.
local function sparse(values)
    return setmetatable({}, {__pairs=function()
        local index=0
        return function()
            index=index+1
            if index<=#values then return index,values[index] end
        end
    end})
end
root.children=sparse({nil,bip})
bip.children=sparse({nil,arm,mesh})
arm.children=sparse({nil,hand})
hand.children=sparse({nil,duplicate})
local found=rig.find(root,"Bip01 L Hand")
assert(found==hand,"Search should skip vacant slots and find live bones")
local bones,nodes=rig.capture(root)
assert(#bones==3 and #nodes==3,"Capture should skip vacant slots and duplicate body-part bones")
assert(bones[1].name=="Bip01" and bones[2].parent==1 and bones[3].parent==2,"Preserve skeletal hierarchy")
assert(rig.bind(root,bones)[3]==hand,"Rebinding should also tolerate sparse children")
print("PASS: sparse NiNode child slots and duplicate bone capture")
