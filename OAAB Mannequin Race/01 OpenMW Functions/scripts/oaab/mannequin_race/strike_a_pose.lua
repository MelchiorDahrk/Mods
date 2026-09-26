local animation = require("openmw.animation")
local async = require("openmw.async")
local camera = require("openmw.camera")
local core = require("openmw.core")
local input = require("openmw.input")
local self = require("openmw.self")
local types = require("openmw.types")

local spellId = "abmann_pw_strikeapose"
-- OAAB_Data's OpenMW animation package supplies these additional KF groups.
local poses = {
	{ id = "contrapposto", group = "mnc1" },
	{ id = "adlocutio", group = "mna1" },
	{ id = "adlocutio2", group = "mna2" },
}
local poseById = {}
for _, pose in ipairs(poses) do
	poseById[pose.id] = pose
end

local state = {}
local needsResume = false
local breakReady = false
local warnedMissingGroup = false
local warnedPlayFailure = false
local warnedNotVisible = false
local paralyzeEffect = core.magic.EFFECT_TYPE.Paralyze

local function activeSpell()
	local active = types.Actor.activeSpells(self)
	for _, spell in pairs(active) do
		if spell.id and string.lower(spell.id) == spellId then
			return spell, active
		end
	end
	return nil, active
end

local function paralysisMagnitude()
	return types.Actor.activeEffects(self):getEffect(paralyzeEffect).magnitude
end

local function applyParalysis(resuming)
	if not state.paralysisApplied or (resuming and paralysisMagnitude() < 1) then
		-- Add one point of paralysis, then remove precisely that point on exit.
		types.Actor.activeEffects(self):modify(1, paralyzeEffect)
		state.paralysisApplied = true
	end
end

local function removeParalysis()
	if state.paralysisApplied then
		if paralysisMagnitude() > 0 then
			types.Actor.activeEffects(self):modify(-1, paralyzeEffect)
		end
		state.paralysisApplied = nil
	end
end

local function enterPosePreview()
	if state.cameraModeBeforePose == nil then
		state.cameraModeBeforePose = camera.getMode()
	end
	-- Preview is OpenMW's mouse-controlled third-person view, unlike Vanity.
	if camera.getMode() ~= camera.MODE.Preview then
		camera.setMode(camera.MODE.Preview, true)
	end
end

local function leavePosePreview()
	if state.cameraModeBeforePose ~= nil
		and camera.getMode() == camera.MODE.Preview
		and state.cameraModeBeforePose ~= camera.MODE.Preview then
		camera.setMode(state.cameraModeBeforePose, true)
	end
	state.cameraModeBeforePose = nil
end

local function isPlaying(group)
	local ok, playing = pcall(animation.isPlaying, self, group)
	return ok and playing == true
end

local function ownsLowerBody(group)
	local ok, active = pcall(animation.getActiveGroup, self, animation.BONE_GROUP.LowerBody)
	return ok and active == group, active
end

local function cancelPose()
	for _, pose in ipairs(poses) do
		pcall(animation.cancel, self, pose.group)
	end
end

local function applyPose()
	local pose = poseById[state.poseId]
	if not pose then
		return
	end
	if isPlaying(pose.group) then
		local visible, active = ownsLowerBody(pose.group)
		if visible then
			return
		end
		if not warnedNotVisible then
			warnedNotVisible = true
			print(string.format("[OAAB Mannequin Race] Pose %s is playing but lower body uses %s; retrying the scripted layer.",
				pose.group, tostring(active)))
		end
	end
	local ok, hasGroup = pcall(animation.hasGroup, self, pose.group)
	if not ok or not hasGroup then
		if not warnedMissingGroup then
			warnedMissingGroup = true
			print(string.format("[OAAB Mannequin Race] Pose group %s unavailable (%s). Check OAAB_Data OpenMW Functions and 'use additional anim sources'.",
				pose.group, ok and "not loaded" or tostring(hasGroup)))
		end
		return
	end
	cancelPose()
	local options = {
		startKey = "start",
		stopKey = "stop",
		loops = 0,
		forceLoop = false,
		autoDisable = false,
	}
	if animation.BLEND_MASK and animation.BLEND_MASK.All ~= nil then
		options.blendMask = animation.BLEND_MASK.All
	end
	if animation.PRIORITY and animation.PRIORITY.Scripted ~= nil then
		options.priority = animation.PRIORITY.Scripted
	end
	local played, reason = pcall(animation.playBlended, self, pose.group, options)
	if not played and not warnedPlayFailure then
		warnedPlayFailure = true
		print(string.format("[OAAB Mannequin Race] Could not play pose group %s: %s", pose.group, tostring(reason)))
	end
end

local function startPose()
	breakReady = false
	state.poseId = poses[math.random(#poses)].id
	state.wasSneaking = self.controls.sneak == true
	state.cameraModeBeforePose = camera.getMode()
	self.controls.sneak = true
	enterPosePreview()
	applyParalysis()
	applyPose()
end

local function stopPose(broken)
	if not state.poseId then
		return
	end
	breakReady = false
	cancelPose()
	removeParalysis()
	leavePosePreview()
	self.controls.sneak = not broken and state.wasSneaking == true
	state.poseId = nil
	state.wasSneaking = nil
end

local function removePower()
	local spell, active = activeSpell()
	if spell and spell.temporary then
		active:remove(spell.activeSpellId)
	end
end

local function breakPose()
	if not state.poseId then
		return
	end
	state.breakPending = true
	removePower()
	stopPose(true)
end

input.registerActionHandler("Sneak", async:callback(function(pressed)
	-- Paralysis prevents movement while the bound Sneak action remains the
	-- player's way to end the pose and dispel the power.
	if pressed and state.poseId and breakReady then
		breakPose()
	end
end))

return {
	engineHandlers = {
		onLoad = function(data)
			state = data or {}
			needsResume = true
			breakReady = false
		end,
		onSave = function()
			return state
		end,
		onActive = function()
			needsResume = true
			breakReady = false
		end,
		onUpdate = function()
			local spell = activeSpell()
			if state.breakPending then
				if spell then
					removePower()
				else
					state.breakPending = nil
				end
				return
			end
			if needsResume then
				needsResume = false
				if state.poseId and spell then
					self.controls.sneak = true
					enterPosePreview()
					applyParalysis(true)
					applyPose()
				elseif state.poseId then
					stopPose(false)
				end
			end
			if spell and not state.poseId then
				startPose()
			elseif not spell and state.poseId then
				stopPose(false)
			elseif state.poseId then
				breakReady = true
				-- Read the bound Sneak action above for cancellation, then keep
				-- the crouched state while the power is active.
				self.controls.sneak = true
				applyPose()
			end
		end,
	},
}
