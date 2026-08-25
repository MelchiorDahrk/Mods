--[[
    Mortal Ties
--]]

if not tes3.isModActive("Mortal Ties.esp")
    and not tes3.isModActive("Mortal Ties.esm")
then
    return
end

event.register("initialized", function()
    for _, path in ipairs({
        "mdMT.achievements.interop",
        "mdMT.essentialindicators.interop",
        "mdMT.ssqn.interop",
        "mdMT.tooltipscomplete.interop",
    }) do
        local success, errorMessage = pcall(function()
            dofile(path)
        end)

        if not success then
            print(errorMessage)
        end
    end
end)