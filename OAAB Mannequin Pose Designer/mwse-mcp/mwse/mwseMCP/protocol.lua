-- Wire-protocol mirror. SSOT: docs/PROTOCOL.md.
-- Keep in lockstep with src/protocol.ts; bump VERSION on any breaking change.

local protocol = {}

protocol.VERSION = 1

protocol.Op = {
	hello = "hello",
	eval = "eval",
	getState = "getState",
	showMessage = "showMessage",
	pollEvents = "pollEvents",
	reloadModule = "reloadModule",
	reset = "reset",
}

-- NDJSON: one compact object per line, never pretty-printed.
function protocol.encodeLine(value)
	return json.encode(value) .. "\n"
end

return protocol
