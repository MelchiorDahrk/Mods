local types = require("openmw.types")
local world = require("openmw.world")
local I = require("openmw.interfaces")

local records = {}
local session

local function clear()
	if session and session.item:isValid() then session.item:remove() end
	session = nil
end

local function begin(data)
	clear()
	local player = data.player
	if not types.Player.objectIsInstance(player) then return end
	local npc = types.NPC.record(player)
	local stat = types.Actor.stats.dynamic.health(player)
	local maximum = stat.base + stat.modifier
	local reply = { token = data.token, tool = data.tool }
	if npc.race:lower() == "ab_mannequin" and stat.current > 0 and stat.current < maximum
		and data.tool and data.tool:isValid() and types.Repair.objectIsInstance(data.tool) then
		local maxCondition = math.max(1, math.ceil(maximum))
		local key = npc.name .. ":" .. maxCondition
		local recordId = records[key]
		if not recordId then
			local record = world.createRecord(types.Armor.createRecordDraft({
				name = npc.name, icon = "icons/oaab/u/mannequin_head.tga",
				type = types.Armor.TYPE.Helmet, health = maxCondition,
				weight = 0, value = 0, baseArmor = 0,
			}))
			recordId = record.id
			records[key] = recordId
		end
		local item = world.createObject(recordId)
		local condition = math.max(0, maxCondition - math.ceil(maximum - stat.current))
		types.Item.itemData(item).condition = condition
		item:moveInto(player)
		session = { item = item, token = data.token }
		reply.item, reply.condition = item, condition
		reply.maximum = maximum
	end
	player:sendEvent("OAABMannequinRepairReady", reply)
end

-- The representation cannot be worn, including during the brief interval
-- between closing the menu and the global cleanup event.
I.ItemUsage.addHandlerForType(types.Armor, function(item)
	for _, id in pairs(records) do
		if item.recordId == id then return false end
	end
end)

return {
	engineHandlers = {
		onSave = function() return { records = records, session = session } end,
		onLoad = function(data)
			records = data and data.records or {}
			session = data and data.session
		end,
		onPlayerAdded = clear,
	},
	eventHandlers = {
		OAABMannequinRepairBegin = begin,
		OAABMannequinRepairEnd = function(data)
			if session and session.token == data.token then clear() end
		end,
	},
}
