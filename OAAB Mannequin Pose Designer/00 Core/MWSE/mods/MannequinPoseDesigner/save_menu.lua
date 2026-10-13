local dialog=require("MannequinPoseDesigner.dialog")
local M={close=dialog.close}
local menuId="OAAB:MannequinPoseDesigner:Save"
local actions={
    {id="changes",label="Save Changes",hint="Replace this saved pose and finish editing."},
    {id="as",label="Save As",hint="Save current edits with a new name and stable ID."},
    {id="rename",label="Edit Metadata",hint="Edit the name, description and category; keep the ID."},
}
function M.open(label,onAction,onClose)
    local prompt=dialog.create(menuId)
    if not prompt then return end
    local menu=prompt.menu
    menu:createLabel({text="Editing: "..label}).borderBottom=8
    for _,entry in ipairs(actions) do
        local action=entry
        local button=menu:createButton({text=action.label})
        button.width=320
        button:register(tes3.uiEvent.mouseClick,function()
            if not prompt.menu then return end
            M.close(prompt)
            onAction(action.id)
        end)
        menu:createLabel({text=action.hint}).borderBottom=8
    end
    menu:createLabel({text="Save Changes also updates other mannequins using this pose."}).borderTop=4
    menu:createButton({text="Cancel"}):register(tes3.uiEvent.mouseClick,function() M.close(prompt) end)
    dialog.activate(prompt,menuId,onClose)
    return prompt
end
return M
