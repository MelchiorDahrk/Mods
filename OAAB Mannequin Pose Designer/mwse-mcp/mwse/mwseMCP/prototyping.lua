-- Agent-owned live prototyping state and cleanup.
--
-- Hooks registered through bridge.registerHook are tagged with the module being
-- required, allowing reloads to remove only that module's old callbacks.

local prototyping = {}

local function newAgent()
	return { modules = {}, questState = {}, hooks = {} }
end

local function ensureAgent()
	if type(_G.Agent) ~= "table" then
		_G.Agent = newAgent()
	end
	if type(_G.Agent.modules) ~= "table" then _G.Agent.modules = {} end
	if type(_G.Agent.questState) ~= "table" then _G.Agent.questState = {} end
	if type(_G.Agent.hooks) ~= "table" then _G.Agent.hooks = {} end
	return _G.Agent
end

-- Match MWSE's require() identity rules from core/initialize.lua. Without this,
-- clearing a mixed-case package.loaded key leaves the real lowercase cache entry
-- intact and require() returns the old module without executing it again.
local function moduleKey(name)
	return name:gsub("[/\\]", "."):lower()
end

local function unregisterMatching(predicate)
	local agent = ensureAgent()
	for i = #agent.hooks, 1, -1 do
		local hook = agent.hooks[i]
		if predicate(hook) then
			if hook.event and hook.fn then
				event.unregister(hook.event, hook.fn)
			end
			table.remove(agent.hooks, i)
		end
	end
end

function prototyping.registerHook(eventName, fn)
	if type(eventName) ~= "string" or eventName == "" then
		error("bridge.registerHook requires a non-empty event name (string)", 2)
	end
	if type(fn) ~= "function" then
		error("bridge.registerHook requires a callback (function)", 2)
	end

	local agent = ensureAgent()
	event.register(eventName, fn)
	agent.hooks[#agent.hooks + 1] = {
		event = eventName,
		fn = fn,
		module = agent.loadingModule,
	}
	return fn
end

function prototyping.reload(name)
	if type(name) ~= "string" or name == "" then
		error("bridge.reload requires a non-empty module name (string)", 2)
	end

	local key = moduleKey(name)
	unregisterMatching(function(hook) return hook.module == key end)
	package.loaded[key] = nil

	local agent = ensureAgent()
	agent.loadingModule = key
	local ok, result = xpcall(function() return require(key) end, debug.traceback)
	ensureAgent().loadingModule = nil

	if not ok then
		-- A module may register hooks before failing later in its body. Remove
		-- those partial registrations so a failed reload cannot leak callbacks.
		unregisterMatching(function(hook) return hook.module == key end)
		error(result, 0)
	end

	return result
end

function prototyping.reset()
	unregisterMatching(function() return true end)
	_G.Agent = newAgent()
end

ensureAgent()

return prototyping
