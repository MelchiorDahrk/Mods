-- Live event capture for mwseMCP.
--
-- Engine events and agent-defined events share one fixed-size sequence ring.
-- Projectors deliberately return primitive-only tables so pollEvents can encode
-- them without walking MWSE userdata.

local events = {}

local CAPACITY = 512
local ring = {}
local count = 0
local highSeq = 0
local projectorsRegistered = false
local objectMeta = { __jsontype = "object" }

local function refId(ref)
	if not ref or not ref.object then return nil end
	return ref.object.id
end

local function mobileRefId(mobile)
	return refId(mobile and mobile.reference)
end

local projectors = {
	cellChanged = function(e)
		local cell = e and e.cell
		local previousCell = e and e.previousCell
		return {
			cell = cell and cell.name,
			cellId = cell and cell.id,
			previousCell = previousCell and previousCell.name,
		}
	end,
	activate = function(e)
		return {
			activator = refId(e and e.activator),
			target = refId(e and e.target),
		}
	end,
	combatStart = function(e)
		return {
			actor = mobileRefId(e and e.actor),
			target = mobileRefId(e and e.target),
		}
	end,
	combatStop = function(e)
		return {
			actor = mobileRefId(e and e.actor),
		}
	end,
	damaged = function(e)
		return {
			target = refId(e and e.reference),
			attacker = refId(e and e.attackerReference),
			damage = e and e.damage,
			killingBlow = e and e.killingBlow,
			source = e and e.source,
		}
	end,
	menuEnter = function(e)
		local menu = e and e.menu
		return { menu = menu and menu.name }
	end,
	menuExit = function()
		return {}
	end,
}

function events.push(kind, data)
	if type(kind) ~= "string" or kind == "" then
		error("bridge.emit requires a non-empty event kind (string)", 2)
	end
	if data == nil then data = {} end
	if type(data) ~= "table" then
		error("bridge.emit requires event data to be a table", 2)
	end
	-- dkjson otherwise encodes an empty Lua table as [], but event data is always
	-- an object. Non-empty projected tables are objects too, so mark them all.
	if getmetatable(data) == nil then setmetatable(data, objectMeta) end

	highSeq = highSeq + 1
	local item = {
		seq = highSeq,
		kind = kind,
		time = os.time(),
		data = data,
	}
	ring[((highSeq - 1) % CAPACITY) + 1] = item
	count = math.min(count + 1, CAPACITY)
	return highSeq
end

function events.poll(since)
	if since == nil then
		return { events = {}, cursor = highSeq, dropped = 0 }
	end

	local lowestRetained = highSeq - count + 1
	local dropped = math.max(0, lowestRetained - since - 1)
	local firstSeq = math.max(since + 1, lowestRetained)
	local result = {}

	for seq = firstSeq, highSeq do
		result[#result + 1] = ring[((seq - 1) % CAPACITY) + 1]
	end

	return {
		events = result,
		cursor = highSeq,
		dropped = dropped,
	}
end

function events.registerProjectors(log)
	if projectorsRegistered then return end
	projectorsRegistered = true

	for eventName, projector in pairs(projectors) do
		event.register(eventName, function(e)
			local ok, projected = pcall(projector, e)
			if ok then
				events.push(eventName, projected)
			elseif log then
				log(string.format("projector '%s' failed: %s", eventName, tostring(projected)))
			end
		end)
	end
end

return events
