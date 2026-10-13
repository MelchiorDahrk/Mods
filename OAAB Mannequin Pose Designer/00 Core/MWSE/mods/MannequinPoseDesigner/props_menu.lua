-- Native inventory selection for Add / Replace Prop; no inventory is modified.
local M={}
function M.inventory(onItem,onClose,title)
    local prompt={inventory=true,closed=false}
    local function finish(e)
        if prompt.closed then return end; prompt.closed=true
        if onClose then onClose() end
        if e and e.item then onItem(e.item) end
    end
    local allowed={weapon=true,ammunition=true,armor=true,clothing=true,book=true,miscItem=true,ingredient=true,
        alchemy=true,apparatus=true,lockpick=true,probe=true,repairItem=true}
    tes3ui.showInventorySelectMenu({reference=tes3.player,title=title or "Add Prop",leaveMenuMode=true,
        noResultsText="No inventory items with usable prop meshes.",noResultsCallback=function() finish() end,
        filter=function(e)
            local item=e.item
            if not item then return false end
            for name in pairs(allowed) do
                local typeId=tes3.objectType[name]
                if typeId and item.objectType==typeId then return type(item.mesh)=="string" and item.mesh~="" end
            end
            return false
        end,callback=finish})
    prompt.close=function()
        local menu=tes3ui.findMenu("MenuInventorySelect")
        if menu then menu:destroy(); tes3ui.leaveMenuMode() end
        finish()
    end
    return prompt
end
return M
