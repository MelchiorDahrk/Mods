local core = require("openmw.core")
local I = require("openmw.interfaces")
local self = require("openmw.self")
local types = require("openmw.types")

local token = 0
local session

local function isRepairMode()
	return I.UI.getMode() == I.UI.MODE.Repair
end

local function hasRepairMode()
	for _, mode in ipairs(I.UI.modes) do
		if mode == I.UI.MODE.Repair then return true end
	end
	return false
end

local function request(tool)
	token = token + 1
	session = { token = token, tool = tool, pending = true }
	core.sendGlobalEvent("OAABMannequinRepairBegin", {
		player = self, token = token, tool = tool,
	})
end

local function collectRepair()
	if not session or not session.item or not session.item:isValid() then return end
	local condition = types.Item.itemData(session.item).condition
	local restored = math.max(0, condition - session.condition)
	session.condition = condition
	local stat = types.Actor.stats.dynamic.health(self)
	local maximum = stat.base + stat.modifier
	local current = stat.current
	if types.NPC.record(self).race:lower() == "ab_mannequin"
		and restored > 0 and current > 0 and current < maximum then
		current = math.min(maximum, current + restored)
		stat.current = current
	end
	-- Return the new value directly: stat writes take effect after this update.
	return current, maximum
end

local function finish()
	if not session then return end
	collectRepair()
	core.sendGlobalEvent("OAABMannequinRepairEnd", { token = session.token })
	session = nil
end

return {
	engineHandlers = {
		onLoad = function() session = nil end,
		-- onUpdate stops while paused; onFrame continues in the repair menu.
		onFrame = function()
			if not session then return end
			if not hasRepairMode() then finish(); return end
			if not isRepairMode() then return end
			if session.pending then return end
			local current, maximum = collectRepair()
			local expected = current and math.max(0, math.ceil(maximum) - math.ceil(math.max(0, maximum - current)))
			if current and (session.condition ~= expected or maximum ~= session.maximum
				or types.NPC.record(self).race:lower() ~= "ab_mannequin") then
				-- External healing/damage or Fortify Health changes the represented
				-- condition. Rebuild without crediting that change as a repair.
				request(session.tool)
			end
		end,
	},
	eventHandlers = {
		UiModeChanged = function(data)
			-- Query the current stack: refreshing the native list can queue more
			-- than one mode event before they are delivered.
			if not hasRepairMode() then finish(); return end
			if not isRepairMode() then return end
			if session then return end
			local stat = types.Actor.stats.dynamic.health(self)
			if types.NPC.record(self).race:lower() == "ab_mannequin"
				and stat.current > 0 and stat.current < stat.base + stat.modifier then
				request(data.arg)
			end
		end,
		OAABMannequinRepairReady = function(data)
			if not session or session.token ~= data.token or not hasRepairMode() then
				core.sendGlobalEvent("OAABMannequinRepairEnd", { token = data.token })
				return
			end
			session.pending = false
			session.item, session.condition = data.item, data.condition
			session.maximum = data.maximum
			-- OpenMW's native inventory view snapshots its list on open. Refresh
			-- after the global script has inserted the temporary armor. This also
			-- covers repair tools opened via quick keys, not just inventory use.
			if isRepairMode() and data.tool and data.tool:isValid() and data.tool.count > 0 then
				I.UI.removeMode(I.UI.MODE.Repair)
				I.UI.addMode(I.UI.MODE.Repair, { target = data.tool })
			end
		end,
	},
}
