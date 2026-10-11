local core = require("openmw.core")
local I = require("openmw.interfaces")
local types = require("openmw.types")
local world = require("openmw.world")

local armorId = "abmann_a_buckethelm"
local buckets = {
	misc_com_bucket_01 = true,
	misc_com_bucket_01_float = true,
}

I.ItemUsage.addHandlerForType(types.Miscellaneous, function(item, actor)
	if not item:isValid() or not buckets[item.recordId]
		or not types.Player.objectIsInstance(actor)
		or types.NPC.record(actor).race:lower() ~= "ab_mannequin" then return end
	if item.count < 1 or item.parentContainer ~= actor then return false end
	if not types.Armor.records[armorId] then
		print("[OAAB Mannequin Race] Missing bucket armor: " .. armorId)
		return false
	end

	local armor = world.createObject(armorId, 1)
	armor:moveInto(actor)
	item:remove(1)
	-- Use the normal armor equip action after moving the replacement into the
	-- inventory. Force equip avoids toggling an already worn bucket helmet off.
	core.sendGlobalEvent("UseItem", { object = armor, actor = actor, force = true })
	return false
end)

return {}
