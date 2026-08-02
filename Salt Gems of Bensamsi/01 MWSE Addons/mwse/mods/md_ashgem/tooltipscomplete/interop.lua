local tooltipsComplete = include("Tooltips Complete.interop")
if tooltipsComplete == nil then
    return
end

local tooltipData = {
    -- Books:
    { id = "md_ashgem_note_directions", description = "A stale, but notably unpleasant odor emanates from the paper.", itemType = "book" },

    -- Keys:
    { id = "md_ashgem_key_bensamsi", description = "Key to the upper levels of the Bensamsi cavern.", itemType = "key" },

    -- Weapons:
    { id = "md_ashgem_chorpa_hammer", description = "A wooden pole with a chorpa crystal crudely fastened to the end.", itemType = "weapon" },
    { id = "md_ashgem_chorpa_hammer_v2", description = "A long metal bar with a chorpa crystal carefully attached to the end.", itemType = "weapon" }
}
    
for _, data in ipairs(tooltipData) do
    tooltipsComplete.addTooltip(data.id, data.description, data.itemType)
end
