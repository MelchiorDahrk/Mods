-- mwseMCP — MWSE side of the MCP bridge.
--
-- Binds a non-blocking localhost TCP server, accepts a single client (newest
-- wins), and during enterFrame: accepts, drains complete request lines into a
-- job queue, then processes the batch queued as of this frame (capped).
--
-- Wire SSOT: docs/PROTOCOL.md. Agent contract: docs/AGENT_USAGE.md.

local socket = require("socket")
local protocol = require("mwseMCP.protocol")
local serialize = require("mwseMCP.serialize")
local events = require("mwseMCP.events")
local prototyping = require("mwseMCP.prototyping")

local config = {
	host = "127.0.0.1",
	port = 31415,
	maxJobsPerFrame = 16,
}

local server -- listening master socket
local client -- single active client (or nil)
local rxBuffer = "" -- partial-line accumulator for the active client
local jobQueue = {} -- requests received, drained each frame

-- Stable agent-facing helpers. Projector hooks are internal and intentionally
-- not tracked here, so mw_reset only clears agent-created experiments.
_G.bridge = _G.bridge or {}
_G.bridge.emit = events.push
_G.bridge.registerHook = prototyping.registerHook
_G.bridge.reload = prototyping.reload
_G.bridge.reset = prototyping.reset

local function info(fmt, ...)
	mwse.log("[mwseMCP] " .. string.format(fmt, ...))
end

-- mwse.version is an integer formatted AAABBBCCC (major/minor/patch, forward-
-- padded). Render it as a readable semver string for the handshake greeting.
local function mwseVersionString()
	local v = mwse.version
	if type(v) ~= "number" then return "unknown" end
	local major = math.floor(v / 1000000)
	local minor = math.floor(v / 1000) % 1000
	local patch = v % 1000
	return string.format("%d.%d.%d", major, minor, patch)
end

-- ---------------------------------------------------------------------------
-- Transport
-- ---------------------------------------------------------------------------

local function dropClient()
	if client then client:close() end
	client = nil
	rxBuffer = ""
end

local function send(value)
	if not client then return end
	-- TODO: non-blocking send can return partial counts; responses are small so
	-- we treat a non-nil return as success for now. Harden if large results appear.
	local ok, err = client:send(protocol.encodeLine(value))
	if not ok then
		info("send failed (%s); dropping client", tostring(err))
		dropClient()
	end
end

local function acceptNew()
	local incoming = server:accept()
	if not incoming then return end
	incoming:settimeout(0)
	if client then
		info("displacing existing client (newest wins)")
		dropClient()
	end
	client = incoming
	rxBuffer = ""
	-- Greeting line first, before anything else.
	send({
		op = protocol.Op.hello,
		protocolVersion = protocol.VERSION,
		mwse = mwseVersionString(),
	})
	info("client connected")
end

local function pump()
	if not client then return end
	while true do
		local line, err, partial = client:receive("*l", rxBuffer)
		if line then
			rxBuffer = ""
			local ok, req = pcall(json.decode, line)
			if ok and type(req) == "table" and req.id and req.op then
				jobQueue[#jobQueue + 1] = req
			else
				info("ignoring malformed line")
			end
		else
			rxBuffer = partial or rxBuffer
			if err == "closed" then
				info("client disconnected")
				dropClient()
			end
			-- "timeout" (and anything else): nothing more to read this frame.
			break
		end
	end
end

-- ---------------------------------------------------------------------------
-- Op handlers. Each returns (ok, payload): on ok the payload is the result, on
-- failure it's an { phase, message, traceback? } error object.
-- ---------------------------------------------------------------------------

local handlers = {}

-- Project a tes3statistic down to the two fields the agent cares about. `base`
-- is the normal maximum (`current` can exceed it under a fortify effect).
local function statOf(s)
	if not s then return nil end
	return { current = s.current, base = s.base }
end

-- tes3globalVariable -> its numeric value (nil-safe; 0 is a valid value).
local function globalValue(g)
	if not g then return nil end
	return g.value
end

function handlers.eval(params)
	local source = params and params.source
	if type(source) ~= "string" then
		return false, { phase = "bridge", message = "eval requires params.source (string)" }
	end
	local chunk, compileErr = load(source, "=agentEval")
	if not chunk then
		return false, { phase = "compile", message = tostring(compileErr) }
	end
	local result
	local ok, tb = xpcall(function() result = chunk() end, debug.traceback)
	if not ok then
		local first = tostring(tb):match("^[^\n]*") or tostring(tb)
		return false, { phase = "runtime", message = first, traceback = tostring(tb) }
	end
	return true, serialize.sanitize(result)
end

function handlers.getState()
	-- Every field is guarded: before a save loads (main menu) most of these are nil.
	local state = {}

	local cell = tes3.getPlayerCell and tes3.getPlayerCell()
	if cell then
		state.cell = { id = cell.id, name = cell.name }
	end

	local player = tes3.player
	if player and player.position then
		local p = player.position
		state.position = { x = p.x, y = p.y, z = p.z }
	end

	local mobile = tes3.mobilePlayer
	if mobile then
		state.facing = mobile.facing -- radians, compass-style (North = 0)
		state.inCombat = mobile.inCombat
		state.vitals = {
			health = statOf(mobile.health),
			magicka = statOf(mobile.magicka),
			fatigue = statOf(mobile.fatigue),
		}
	end

	state.menuMode = tes3.menuMode and tes3.menuMode() or false

	local wc = tes3.worldController
	if wc then
		state.time = {
			hour = globalValue(wc.hour),
			day = globalValue(wc.day), -- 1-based
			month = globalValue(wc.month), -- 0-based (Morning Star = 0)
			year = globalValue(wc.year),
			daysPassed = globalValue(wc.daysPassed),
		}
	end

	local weather = tes3.getCurrentWeather and tes3.getCurrentWeather()
	if weather then
		state.weather = { index = weather.index, name = weather.name }
	end

	return true, serialize.sanitize(state)
end

function handlers.showMessage(params)
	local message = params and params.message
	if type(message) ~= "string" then
		return false, { phase = "bridge", message = "showMessage requires params.message (string)" }
	end
	if params.modal then
		-- A modal box needs at least one button for the user to dismiss it.
		tes3.messageBox({ message = message, buttons = { "OK" } })
	else
		-- No buttons => the non-modal toast-style notification.
		tes3.messageBox({ message = message })
	end
	return true, { shown = true }
end

function handlers.pollEvents(params)
	local since = params and params.since
	if since ~= nil and (type(since) ~= "number" or since < 0 or since ~= math.floor(since)) then
		return false, { phase = "bridge", message = "pollEvents requires params.since to be a non-negative integer" }
	end
	return true, events.poll(since)
end

function handlers.reloadModule(params)
	local name = params and params.name
	if type(name) ~= "string" or name == "" then
		return false, { phase = "bridge", message = "reloadModule requires params.name (non-empty string)" }
	end

	local ok, tb = xpcall(function() prototyping.reload(name) end, debug.traceback)
	if not ok then
		local first = tostring(tb):match("^[^\n]*") or tostring(tb)
		return false, { phase = "runtime", message = first, traceback = tostring(tb) }
	end
	return true, { reloaded = true }
end

function handlers.reset()
	prototyping.reset()
	return true, { cleared = true }
end

-- ---------------------------------------------------------------------------
-- Dispatch + frame loop
-- ---------------------------------------------------------------------------

local function dispatch(req)
	local handler = handlers[req.op]
	if not handler then
		send({ id = req.id, ok = false, error = { phase = "bridge", message = "unknown op '" .. tostring(req.op) .. "'" } })
		return
	end
	local ok, payload = handler(req.params)
	if ok then
		-- dkjson omits a nil-valued key, which would drop `result` entirely; map a
		-- nil result to the json.null sentinel so the wire matches PROTOCOL.md
		-- ("nil -> null"). Confirmed live: json.encode({ x = json.null }) -> {"x":null}.
		if payload == nil then payload = json.null end
		send({ id = req.id, ok = true, result = payload })
	else
		send({ id = req.id, ok = false, error = payload })
	end
end

local function onFrame()
	if not server then return end
	acceptNew()
	pump()

	local batch = jobQueue
	jobQueue = {}
	for i = 1, #batch do
		if i > config.maxJobsPerFrame then
			-- Requeue the remainder for next frame so one flood can't stall the frame.
			for j = i, #batch do
				jobQueue[#jobQueue + 1] = batch[j]
			end
			break
		end
		dispatch(batch[i])
	end
end

-- ---------------------------------------------------------------------------
-- Startup
-- ---------------------------------------------------------------------------

local function start()
	local s, err = socket.bind(config.host, config.port)
	if not s then
		info("FAILED to bind %s:%d (%s)", config.host, config.port, tostring(err))
		return
	end
	s:settimeout(0)
	server = s
	info("listening on %s:%d", config.host, config.port)
	event.register("enterFrame", onFrame)
end

event.register("initialized", function()
	events.registerProjectors(function(message) info("%s", message) end)
	start()
	info("initialized (protocol v%d)", protocol.VERSION)
end)
