local config=require("MannequinPoseDesigner.config")
local M={}

function M.register()
    local template=mwse.mcm.createTemplate({name="OAAB Mannequin Pose Designer",config=config})
    template:saveOnClose("MannequinPoseDesigner",config)
    local page=template:createPage({label="Settings"})
    page:createOnOffButton({
        label="Enter Focus Mode by default",
        description="Start Create Pose and Edit Pose sessions in Focus Mode, hiding the surroundings and freezing time. Press F while editing to toggle Focus Mode. Changes apply the next time you open the designer.",
        configKey="focusModeByDefault",
    })
    page:createOnOffButton({
        label="Debug mode",
        description="Write diagnostic messages to mwse.log for troubleshooting. Changes take effect immediately. Leave this off during normal play.",
        configKey="debugMode",
    })
    template:createPage({label="Poses",noScroll=true,postCreate=function(self)
        require("MannequinPoseDesigner.mcm_poses").create(self)
    end})
    template:register()
end

return M
