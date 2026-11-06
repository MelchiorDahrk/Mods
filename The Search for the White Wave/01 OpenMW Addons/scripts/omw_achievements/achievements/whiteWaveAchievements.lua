local whiteWaveAchievements = {
    {
        type = "global_variable",
        name = "Unkind to Ravens",
        description = "Scare away 3 ravens.",
        variable = "mdWW_RavenTracker",
        value = 3,
        operator = function(self, givenValue)
            return givenValue ~= nil and givenValue >= self.value
        end,
        enableProgress = true,
        icon = "Icons\\mdww\\v\\achievement_raven.tga",
        bgColor = "blue",
        id = "mdww_raven",
        hidden = false
    },
    {
        type = "global_variable",
        name = "What Lies Beneath",
        description = "Find the Cleaver of Skarveth.",
        variable = "mdWW_CleaverTracker",
        value = 1,
        operator = function(self, givenValue)
            return givenValue == self.value
        end,
        icon = "Icons\\mdww\\v\\achievement_cleaver.tga",
        bgColor = "blue",
        id = "mdww_cleaver",
        hidden = true
    },
}

return whiteWaveAchievements
