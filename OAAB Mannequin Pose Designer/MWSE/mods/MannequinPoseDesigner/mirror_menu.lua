local dialog=require("MannequinPoseDesigner.dialog")
local M={close=dialog.close}
local menuId="OAAB:MannequinPoseDesigner:MirrorPose"
local targets={{id="entire",label="Entire Pose"},{id="arms",label="Arms"},{id="legs",label="Legs"}}
local mirrorLabels={entire="Mirror Entire Pose",arms="Mirror Arms",legs="Mirror Legs"}

function M.open(initial,onAction,onClose)
    local prompt=dialog.create(menuId)
    if not prompt then return end
    local menu=prompt.menu
    prompt.scope=mirrorLabels[initial] and initial or "entire"
    menu:createLabel({text="Mirror Pose / Mirror Limb"}).borderBottom=6
    local targetLabel=menu:createLabel({text=""})
    local choices=menu:createBlock({})
    choices.flowDirection=tes3.flowDirection.leftToRight
    choices.autoWidth=true; choices.autoHeight=true
    choices.borderBottom=8
    local mirrorButton
    local function select(target)
        prompt.scope=target.id
        targetLabel.text="Target: "..target.label
        mirrorButton.text=mirrorLabels[target.id]
        menu:updateLayout()
    end
    for _,target in ipairs(targets) do
        local choice=target
        choices:createButton({text=choice.label}):register(tes3.uiEvent.mouseClick,function()
            if prompt.menu then select(choice) end
        end)
    end
    local function command(label,action)
        local button=menu:createButton({text=label})
        button.width=300
        button:register(tes3.uiEvent.mouseClick,function()
            if not prompt.menu then return end
            local scope=prompt.scope
            M.close(prompt)
            onAction(action,scope)
        end)
        return button
    end
    mirrorButton=command("Mirror Entire Pose","swap")
    command("Copy Left -> Right","leftToRight")
    command("Copy Right -> Left","rightToLeft")
    menu:createLabel({text="Mirror swaps both sides."}).borderTop=6
    menu:createLabel({text="Entire Pose also mirrors the torso."})
    menu:createLabel({text="Copy keeps the source side and torso."})
    local cancel=menu:createButton({text="Cancel"})
    cancel.borderTop=8
    cancel:register(tes3.uiEvent.mouseClick,function() M.close(prompt) end)
    dialog.activate(prompt,menuId,onClose)
    for _,target in ipairs(targets) do if target.id==prompt.scope then select(target); break end end
    return prompt
end

return M
