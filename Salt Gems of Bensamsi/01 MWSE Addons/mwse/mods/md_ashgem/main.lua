--[[
    Salt Gems of Bensamsi
--]]

if not tes3.isModActive("Salt Gems of Bensamsi.ESP")
then
    return
end

event.register("initialized", function()
    for _, path in ipairs({
        "md_ashgem.ssqn.interop",
        "md_ashgem.achievements.interop",
        "md_ashgem.tooltipscomplete.interop",
    }) do 
        local success, errorMessage = pcall(function() dofile(path) end)
        if not success then
            print(errorMessage)
        end
    end
end)