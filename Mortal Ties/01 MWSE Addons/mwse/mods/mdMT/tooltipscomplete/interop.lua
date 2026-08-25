local tooltipsComplete = include("Tooltips Complete.interop")
if tooltipsComplete == nil then
    return
end

local tooltipData = {
    -- Books:
    { id = "mdmt_bk_vilandonjournal", description = "A withered old journal with red stains on the later pages.", itemType = "book" },
    { id = "mdmt_sc_sealedletter", description = "An emotional letter from a forlorn great grandson.", itemType = "book" },

    -- Clothing:
    { id = "mdmt_c_ringsinyaramen", description = "A gold ring bearing the crest of a sunbird.", itemType = "clothing" },
    { id = "extravagant_ring_aund_uni", description = "A gold ring bearing the crest of a sunbird.", itemType = "clothing" },

    -- Weapons:
    { id = "mdmt_w_silverblade", description = "A silver saber with the name 'Vilandon' engraved on the hilt.", itemType = "weapon" },
    { id = "mdmt_w_silverbladecorroded", description = "A corroded silver blade.", itemType = "weapon" }
}
    
for _, data in ipairs(tooltipData) do
    tooltipsComplete.addTooltip(data.id, data.description, data.itemType)
end
