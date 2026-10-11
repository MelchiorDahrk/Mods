local dialog=require("MannequinPoseDesigner.dialog")
local M={close=dialog.close}
local menuId="OAAB:MannequinPoseDesigner:Symmetry"
local modes={
    {id="off",label="Off"},
    {id="entire",label="Full Symmetry"},
    {id="arms",label="Arms Only"},
    {id="legs",label="Legs Only"},
}

function M.open(initial,onSelect,onClose)
    local prompt=dialog.create(menuId)
    if not prompt then return end
    local menu=prompt.menu
    menu:createLabel({text="Symmetry Mode"}).borderBottom=6
    local current="Off"
    for _,mode in ipairs(modes) do if mode.id==initial then current=mode.label end end
    menu:createLabel({text="Current: "..current}).borderBottom=8
    for _,mode in ipairs(modes) do
        local choice=mode
        local button=menu:createButton({text=choice.label})
        button.width=300
        button:register(tes3.uiEvent.mouseClick,function()
            if not prompt.menu then return end
            M.close(prompt)
            onSelect(choice.id)
        end)
    end
    menu:createLabel({text="Edits mirror to the opposite limb."}).borderTop=6
    menu:createLabel({text="Full includes both arms and legs."})
    menu:createLabel({text="Choose Off to edit sides independently."})
    local cancel=menu:createButton({text="Cancel"})
    cancel.borderTop=8
    cancel:register(tes3.uiEvent.mouseClick,function() M.close(prompt) end)
    dialog.activate(prompt,menuId,onClose)
    return prompt
end

return M
