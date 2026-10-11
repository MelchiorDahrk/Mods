local function initialize()
    local ok,poses=pcall(require,"OAAB.Mannequins.poses")
    if not ok or not poses.apiVersion or poses.apiVersion<6 then
        mwse.log("[OAAB Pose Designer] Requires OAAB_Data pose API v6. Install the included compatibility archive.")
        return
    end
    local session=require("MannequinPoseDesigner.session")
    local menu=require("MannequinPoseDesigner.library_menu")
    session.register()
    local fallback=false
    event.register("OAAB:mannequinPoseMenu",function(e)
        if fallback or e.handled or not poses.canPose(e.reference) then return end
        local handle=tes3.makeSafeObjectHandle(e.reference)
        local entries=e.entries
        e.handled=true
        timer.frame.delayOneFrame(function()
            if not handle:valid() then return end
            local reference=handle:getObject()
            if reference.deleted or not poses.canPose(reference) then return end
            local opened,err=pcall(menu.open,reference,poses,entries)
            if not opened then
                menu.close()
                mwse.log("[OAAB Pose Library] Could not open: %s",tostring(err))
                fallback=true
                local restored,problem=pcall(poses.showMenu,reference)
                fallback=false
                if not restored then mwse.log("[OAAB Pose Library] Fallback: %s",tostring(problem)) end
            end
        end)
    end,{priority=-1000})
    event.register("enterFrame",menu.update)
    for _,name in ipairs({"load","cellChanged"}) do event.register(name,menu.close) end
end
event.register("initialized",initialize)
