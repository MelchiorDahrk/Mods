local dialog=require("MannequinPoseDesigner.dialog")
local M={close=dialog.close}
local menuId="OAAB:MannequinPoseDesigner:Ground"
local targets={{id="left",label="Ground Left Foot"},{id="right",label="Ground Right Foot"},{id="both",label="Ground Both Feet"}}

function M.open(onGround,onClose)
    local prompt=dialog.create(menuId)
    if not prompt then return end
    local menu=prompt.menu
    menu:createLabel({text="Ground Feet"}).borderBottom=6
    menu:createLabel({text="Flatten feet, keeping their Z heading."}).borderBottom=6
    for _,target in ipairs(targets) do
        local choice=target
        local button=menu:createButton({text=choice.label})
        button.width=300
        button:register(tes3.uiEvent.mouseClick,function()
            if not prompt.menu then return end
            M.close(prompt)
            onGround(choice.id)
        end)
    end
    menu:createLabel({text="Moves the root vertically to the original ground."}).borderTop=6
    menu:createLabel({text="Both feet: lowers the higher foot with IK."})
    local cancel=menu:createButton({text="Cancel"})
    cancel.borderTop=8
    cancel:register(tes3.uiEvent.mouseClick,function() M.close(prompt) end)
    dialog.activate(prompt,menuId,onClose)
    return prompt
end
return M
