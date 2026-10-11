local controls=require("MannequinPoseDesigner.controls")
local dialog=require("MannequinPoseDesigner.dialog")
local M={close=dialog.close}
local menuId="OAAB:MannequinPoseDesigner:Reset"
local targets={
    {id="bone",label="Reset Bone",control="resetBone"},
    {id="limb",label="Reset Limb",control="resetLimb"},
    {id="entire",label="Reset Entire Pose",control="resetPose"},
}

function M.open(boneName,onReset,onClose)
    local prompt=dialog.create(menuId)
    if not prompt then return end
    local menu=prompt.menu
    menu:createLabel({text="Reset Options"}).borderBottom=6
    menu:createLabel({text="Selected: "..boneName}).borderBottom=8
    for _,target in ipairs(targets) do
        local choice=target
        local button=menu:createButton({text=choice.label})
        button.width=300
        button:register(tes3.uiEvent.mouseClick,function()
            if not prompt.menu then return end
            M.close(prompt)
            onReset(choice.id)
        end)
        menu:createLabel({text=controls.input(choice.control)}).borderBottom=6
    end
    menu:createLabel({text="Restores transforms from session start."}).borderTop=6
    menu:createLabel({text="Limb includes the selected bone and descendants."})
    menu:createLabel({text="Example: knee and foot; thigh stays posed."})
    local cancel=menu:createButton({text="Cancel"})
    cancel.borderTop=8
    cancel:register(tes3.uiEvent.mouseClick,function() M.close(prompt) end)
    dialog.activate(prompt,menuId,onClose)
    return prompt
end

return M
