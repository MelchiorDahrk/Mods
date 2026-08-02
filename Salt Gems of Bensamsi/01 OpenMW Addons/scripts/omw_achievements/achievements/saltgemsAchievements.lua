local saltgemsAchievements = {
    {
        type = "global_variable",
        name = "C.R.A.P.",
        description = "Kill 10 Ash Zombies with the Chorpite Rapid Activation Pounder.",
        variable = "md_ashgem_killcount",
        value = 10,
        operator = function(self, givenValue)
            return givenValue == self.value
        end,
        enableProgress = true,
        icon = "Icons\\md_ashgem\\v\\achievement_zombie.tga",
        bgColor = "purple",
        id = "md_ashgem_zombies",
        hidden = false
    },
}

return saltgemsAchievements