require("OAAB.MannequinRace.repair")

local spellId = "ABmann_pw_StrikeAPose"
local stateKey = "oaabMannequinRaceStrikePose"
local poseFiles = {
	"oaab/k/mann_contrapposto.nif",
	"oaab/k/mann_adlocutio.nif",
	"oaab/k/mann_adlocutio2.nif",
}

local function getState()
	local player = tes3.player
	if not player then
		return nil
	end
	player.data[stateKey] = player.data[stateKey] or {}
	return player.data[stateKey]
end

local function isOurSource(source)
	return source and source.id and string.lower(source.id) == string.lower(spellId)
end

local function activeInstance()
	local mobile = tes3.mobilePlayer
	if not mobile then
		return nil
	end
	for _, effect in pairs(mobile.activeMagicEffectList) do
		local instance = effect.instance
		if instance and instance:isValid() and isOurSource(instance.source) then
			return instance
		end
	end
	return nil
end

local function applyPose(state)
	local player = tes3.player
	if not player or not player.sceneNode or not state.active then
		return
	end
	tes3.loadAnimation({ reference = player, file = state.poseFile })
	-- Reassert the full-body idle after changes to the player's animation tree.
	-- Paralysis prevents movement from interrupting it with the sneak cycle.
	tes3.playAnimation({
		reference = player,
		group = tes3.animationGroup.idle,
		loopCount = -1,
	})
end

local function applyParalysis(state, mobile)
	if not state.paralysisApplied then
		-- This is the MWSE equivalent of SetParalysis 1. Keep the increment
		-- separate from spell effects so cancelling the power can undo only it.
		mobile.paralyze = mobile.paralyze + 1
		state.paralysisApplied = true
	elseif mobile.paralyze < 1 then
		-- A load can reconstruct effect attributes before our saved Lua state.
		mobile.paralyze = 1
	end
end

local function startPose()
	local state = getState()
	local mobile = tes3.mobilePlayer
	if not state or not mobile then
		return
	end
	if not state.active then
		state.poseFile = poseFiles[math.random(#poseFiles)]
		state.wasSneaking = mobile.isSneaking
		state.wasForceSneak = mobile.forceSneak
		state.wasAttackDisabled = mobile.attackDisabled
		state.wasJumpingDisabled = mobile.jumpingDisabled
		state.wasMagicDisabled = mobile.magicDisabled
	end
	state.active = true
	state.breakEnabled = false
	mobile.forceSneak = true
	mobile.isSneaking = true
	mobile.attackDisabled = true
	mobile.jumpingDisabled = true
	mobile.magicDisabled = true
	applyParalysis(state, mobile)
	applyPose(state)
	state.breakEnabled = true
end

local function stopPose(broken)
	local state = getState()
	local mobile = tes3.mobilePlayer
	if not state or not state.active or not mobile then
		return
	end
	local player = tes3.player
	if player and player.sceneNode then
		tes3.loadAnimation({ reference = player })
		tes3.playAnimation({ reference = player, group = 0 })
	end
	if state.paralysisApplied then
		mobile.paralyze = math.max(0, mobile.paralyze - 1)
	end
	mobile.attackDisabled = state.wasAttackDisabled == true
	mobile.jumpingDisabled = state.wasJumpingDisabled == true
	mobile.magicDisabled = state.wasMagicDisabled == true
	mobile.forceSneak = state.wasForceSneak == true
	mobile.isSneaking = not broken and state.wasSneaking == true
	state.active = false
	state.poseFile = nil
	state.breakEnabled = nil
	state.wasSneaking = nil
	state.wasForceSneak = nil
	state.wasAttackDisabled = nil
	state.wasJumpingDisabled = nil
	state.wasMagicDisabled = nil
	state.paralysisApplied = nil
end

local function retireInstance(instance)
	local effects = {}
	for _, active in pairs(tes3.mobilePlayer.activeMagicEffectList) do
		if active.instance == instance and active.effectInstance then
			effects[#effects + 1] = active.effectInstance
		end
	end
	for _, effect in ipairs(effects) do
		effect.state = tes3.spellState.ending
	end
	instance.state = tes3.spellState.ending
end

local function breakPose()
	local state = getState()
	if state then
		state.breakPending = true
	end
	local instance = activeInstance()
	if instance then
		-- Ending this one cast retires all five effects without touching any
		-- unrelated spell that happens to use the same magic effects.
		retireInstance(instance)
	end
	stopPose(true)
end

event.register(tes3.event.magicEffectAdded, function(e)
	local state = getState()
	if e.target == tes3.player and isOurSource(e.source)
		and state and not state.active and not state.breakPending then
		startPose()
	end
end)

event.register(tes3.event.simulated, function()
	local state = getState()
	if not state then
		return
	end
	local instance = activeInstance()
	if state.breakPending then
		if instance then
			retireInstance(instance)
		else
			state.breakPending = nil
		end
		return
	end
	if state.active then
		if not instance then
			stopPose(false)
		elseif state.breakEnabled and tes3.worldController.inputController:keybindTest(
			tes3.keybind.sneak, tes3.keyTransition.downThisFrame) then
			breakPose()
		elseif not tes3.mobilePlayer.isSneaking then
			breakPose()
		else
			applyParalysis(state, tes3.mobilePlayer)
			state.breakEnabled = true
		end
	elseif instance then
		startPose()
	end
end)

event.register(tes3.event.loaded, function()
	local state = getState()
	if not state then
		return
	end
	if activeInstance() then
		if state.active then
			local mobile = tes3.mobilePlayer
			mobile.forceSneak = true
			mobile.isSneaking = true
			mobile.attackDisabled = true
			mobile.jumpingDisabled = true
			mobile.magicDisabled = true
			applyParalysis(state, mobile)
			applyPose(state)
			state.breakEnabled = true
		elseif not state.breakPending then
			startPose()
		end
	elseif state.active then
		stopPose(false)
	end
end)

event.register(tes3.event.cellChanged, function()
	local state = getState()
	if state and state.active then
		timer.frame.delayOneFrame(function()
			applyPose(state)
		end)
	end
end)
