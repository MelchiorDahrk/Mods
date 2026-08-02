local sb_achievements = include("sb_achievements.interop")

if sb_achievements == nil then
    return
end

local iconPath = "Icons\\md_ashgem\\v\\"

local cats = {
    misc = sb_achievements.registerCategory("Miscellaneous")
}

sb_achievements.registerAchievement {
    id = "md_ashgem_zombies",
    category = cats.misc,
    conditionType = sb_achievements.conditionType.progressAmount,
    progress = function()
        return tes3.getGlobal("md_ashgem_killcount")
    end,
    progressMax = function()
        return 10
    end,
    icon = iconPath .. "achievement_zombie.tga",
    colour = sb_achievements.colours.yellow,
    title = "C.R.A.P.", desc = "Kill 10 Ash Zombies with the Chorpite Rapid Activation Pounder."
}