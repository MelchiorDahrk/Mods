-- A temporary armor item lets the native repair menu handle tools, rolls,
-- sounds, and Armorer experience. Only its repaired condition becomes health.
local itemId = "ABmann_player_repair"
local raceId = "ab_mannequin"
local item, itemData, lastCondition

local function health()
	local player, mobile = tes3.player, tes3.mobilePlayer
	if not player or not mobile or not player.object.race
		or player.object.race.id:lower() ~= raceId then
		return nil
	end
	return mobile.health
end

local function clear()
	item, itemData, lastCondition = nil, nil, nil
	local object = tes3.getObject(itemId)
	if tes3.player and object then
		local count = tes3.getItemCount({ reference = tes3.player, item = object })
		if count > 0 then
			tes3.removeItem({ reference = tes3.player, item = object, count = count })
		end
	end
end

local function sync()
	local stat = health()
	if not stat or not itemData then return end
	-- Round the missing health up, so even a fractional injury is repairable.
	item.maxCondition = math.max(1, math.ceil(stat.base))
	itemData.condition = math.max(0, item.maxCondition - math.ceil(math.max(0, stat.base - stat.current)))
	lastCondition = itemData.condition
end

local function collectRepair()
	local stat = health()
	if not stat or not itemData then return end
	local restored = math.max(0, itemData.condition - lastCondition)
	if restored > 0 and stat.current > 0 and stat.current < stat.base then
		tes3.modStatistic({ reference = tes3.player, statistic = stat,
			current = math.min(restored, stat.base - stat.current) })
	end
	sync()
end

event.register(tes3.event.equip, function(e)
	if e.item.id:lower() == itemId:lower() then return false end
	if e.reference ~= tes3.player or e.item.objectType ~= tes3.objectType.repairItem then return end
	local stat = health()
	if not stat or stat.current <= 0 or stat.current >= stat.base then return end
	-- equip runs before the native menu populates its inventory list, including
	-- when the tool was selected through a quick key.
	if itemData then collectRepair() else clear() end
	item = tes3.createObject({ id = itemId, objectType = tes3.objectType.armor })
	item.name = tes3.player.object.name
	item.icon = "oaab\\u\\mannequin_head.tga"
	item.weight, item.value, item.armorRating = 0, 0, 0
	item.slot = tes3.armorSlot.helmet
	item.maxCondition = math.max(1, math.ceil(stat.base))
	if not itemData then
		tes3.addItem({ reference = tes3.player, item = item, count = 1 })
		itemData = tes3.addItemData({ to = tes3.player, item = item })
		-- Retain itemData when the native repair fills its condition completely.
		itemData.data.oaabMannequinRepair = true
	end
	sync()
end)

event.register(tes3.event.repair, function(e)
	if e.item ~= item or e.itemData ~= itemData then return end
	-- Read the result after all repair handlers and the native repair complete.
	-- Failed repairs never increase condition and therefore never grant health.
	timer.frame.delayOneFrame(collectRepair)
end)

event.register(tes3.event.enterFrame, function()
	if not itemData then return end
	local menu = tes3ui.findMenu("MenuRepair")
	if not menu or not menu.visible then
		collectRepair()
		clear()
	else
		collectRepair()
	end
end)

-- Saved games must never retain an inventory copy of the repair representation.
event.register(tes3.event.loaded, clear)
