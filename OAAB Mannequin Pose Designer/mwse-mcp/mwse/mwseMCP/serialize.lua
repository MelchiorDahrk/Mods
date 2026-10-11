-- Result sanitizer: convert any Lua value into a JSON-safe structure BEFORE
-- handing it to json.encode (dkjson throws on raw userdata).
-- SSOT for the rules: docs/PROTOCOL.md -> "Result Sanitization".
--
-- Contract: primitives pass through; plain tables recurse under cycle/depth/
-- size caps; any userdata/function/thread becomes an opaque stub and is NEVER
-- deep-walked (so `return tes3.dataHandler` can't explode).

local serialize = {}

local DEFAULT_MAX_DEPTH = 8
local DEFAULT_MAX_BYTES = 256 * 1024

-- Best-effort type name from tostring, e.g. "tes3reference: 0x..." -> "tes3reference".
local function typeName(value)
	local ok, s = pcall(tostring, value)
	if not ok then return type(value) end
	return s:match("^(%a[%w_]*)") or type(value)
end

local function stub(value)
	local ok, s = pcall(tostring, value)
	local strVal = ok and s or ("<error: " .. tostring(s) .. ">")
	return { __type = typeName(value), __tostring = strVal }
end

function serialize.sanitize(value, opts)
	opts = opts or {}
	local maxDepth = opts.maxDepth or DEFAULT_MAX_DEPTH
	local maxBytes = opts.maxBytes or DEFAULT_MAX_BYTES
	local bytes = 0
	local seen = {}

	local function walk(v, depth)
		local t = type(v)
		if t == "nil" or t == "number" or t == "boolean" then
			return v
		elseif t == "string" then
			bytes = bytes + #v
			return v
		elseif t == "table" then
			if seen[v] then return "<cycle>" end
			if depth > maxDepth then return "<max-depth>" end
			seen[v] = true
			local out = {}
			for k, val in pairs(v) do
				if bytes > maxBytes then
					out.__truncated = true
					break
				end
				out[tostring(k)] = walk(val, depth + 1)
			end
			seen[v] = nil
			return out
		else
			-- userdata / function / thread
			return stub(v)
		end
	end

	return walk(value, 1)
end

return serialize
