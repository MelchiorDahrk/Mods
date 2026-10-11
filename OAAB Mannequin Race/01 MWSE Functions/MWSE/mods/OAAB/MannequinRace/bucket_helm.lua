local armorId = "ABmann_a_BucketHelm"
local buckets = {
	misc_com_bucket_01 = true,
	misc_com_bucket_01_float = true,
}

local function isMannequin(player)
	return player and player.object.race
		and player.object.race.id:lower() == "ab_mannequin"
end

event.register(tes3.event.equip, function(e)
	if e.reference ~= tes3.player or not isMannequin(tes3.player)
		or e.item.objectType ~= tes3.objectType.miscItem
		or not buckets[e.item.id:lower()] then return end

	local bucketId = e.item.id
	-- The equip caller still holds the original item. Block its default action
	-- and wait one frame before changing inventory, including while in menus.
	timer.frame.delayOneFrame(function()
		local player = tes3.player
		if not isMannequin(player) then return end
		local armor = tes3.getObject(armorId)
		if not armor or armor.objectType ~= tes3.objectType.armor then
			mwse.log("[OAAB Mannequin Race] Missing bucket armor: %s", armorId)
			return
		end
		local removed = tes3.removeItem({
			reference = player, item = bucketId, count = 1, playSound = false,
		})
		if removed ~= 1 then return end
		tes3.addItem({ reference = player, item = armor, count = 1, playSound = false })
		tes3.equip({ reference = player, item = armor, selectBestCondition = true })
	end)
	return false
end)
