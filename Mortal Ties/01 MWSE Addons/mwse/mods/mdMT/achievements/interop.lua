local sb_achievements = include("sb_achievements.interop")

if sb_achievements == nil then
    return
end

local iconPath = "Icons\\mdMT\\v\\"

    local cats = {
        misc = sb_achievements.registerCategory("Miscellaneous")
    }

sb_achievements.registerAchievement {
    id = "mdMT_Pacifist",
    category = cats.misc,
    conditionType = sb_achievements.conditionType.progressAmount,
    progress = function()
        return tes3.getGlobal("mdMT_Pacifist")
    end,
    progressMax = function()
        return 1
    end,
    icon = iconPath .. "achievement_pacifist.tga",
    colour = sb_achievements.colours.yellow,
    title = "Way of the Sunbird", desc = "Complete Mortal Ties without killing any hostile characters."
}