local dataInstalled, data = pcall(require, "Essential Indicators.data")

if dataInstalled then

    local addToSideTable = {
        ["sinyaramen"] = { entry = "mdmt_vilandon", index = 100 },
        ["dhaunayne aundae"] = { entry = "mdmt_vilandon", index = 85 },
        ["skinkintreesshade"] = { entry = "mdmt_vilandon", index = 60 },
        ["mdmt_vilandon"] = { entry = "mdmt_vilandon", index = 50 },
        ["tusamircil"] = { entry = "mdmt_vilandon", index = 10 },
    }

    local addToQuestItemTable = {
        ["mdmt_c_ringsinyaramen"] = { entry = "mdmt_vilandon", index = 100 },
        ["mdmt_w_silverbladecorroded"] = { entry = "mdmt_vilandon", index = 85 },
        ["mdmt_sc_sealedletter"] = { entry = "mdmt_vilandon", index = 80 },
    }


    local function merge(target, additions)
        for key, value in pairs(additions) do
            if target[key] == nil then
                target[key] = value
            else
                mwse.log("[Essential Indicator Interop] Warning: key '%s' already exists in the target table", key)
            end
        end
    end

    merge(data.vanillaTable, addToVanillaTable)
    merge(data.extendedTable, addToExtendedTable)
    merge(data.guildTable, addToGuildTable)
    merge(data.sideTable, addToSideTable)
    merge(data.questItemTable, addToQuestItemTable)
end