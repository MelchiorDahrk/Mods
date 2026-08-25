local mortalTiesAchievements = {
    {
        type = "global_variable",
        name = "Way of the Sunbird",
        description = "Complete Mortal Ties without killing any hostile characters.",
        variable = "mdMT_Pacifist",
        value = 1,
        operator = function(self, givenValue)
            return givenValue == self.value
        end,
        enableProgress = true,
        icon = "Icons\\mdMT\\v\\achievement_pacifist.tga",
        bgColor = "yellow",
        id = "mdMT_Pacifist",
        hidden = false
    },
}

return mortalTiesAchievements