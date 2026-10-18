--[[
	Mod: Fabricant Guar Companion
	Author: Melchior Dahrk
--]]

local mdFG_global_MuskAtomizer
local mdFG_global_following
local mdFG_global_Sample_Guar
local mdFG_global_imperfect
local mdFG_global_dead


-- Active actor and guar detection; reference handles are never saved.

local guarReferences, actorReferences = {}, {}
local controllerTimer
local guardPending = false
local checkGuard

local function distanceSquared(a, b)
    local x, y, z = a.x - b.x, a.y - b.y, a.z - b.z
    return x*x + y*y + z*z
end

local function living(ref)
    return ref and not ref.disabled and not ref.deleted and ref.mobile
        and ref.mobile.health.current > 0
end

local function isGuar(object)
	local id = object.id:lower()
	return id:find("guar") and not id:find("guar%a")
end

local function onRefCreated(e)
    local ref = e.reference
    local kind = ref.object.objectType
    if kind ~= tes3.objectType.creature and kind ~= tes3.objectType.npc then return end
    local handle = tes3.makeSafeObjectHandle(ref)
    actorReferences[ref] = handle
    if isGuar(ref.object) then guarReferences[ref] = handle end
end

local function onRefDeleted(e)
	guarReferences[e.reference], actorReferences[e.reference] = nil, nil
end

local function rebuildActors()
    guarReferences, actorReferences = {}, {}
    for _, cell in pairs(tes3.getActiveCells()) do
        for ref in cell:iterateReferences({ tes3.objectType.creature, tes3.objectType.npc }) do
            onRefCreated({ reference = ref })
        end
    end
    if tes3.player then onRefCreated({ reference = tes3.player }) end
end


-- Musk Atomizer

local atomizerTimer

local function followPlayer(ref)
	if not living(ref) then return end
	local aiData = ref.mobile.aiData
	if not aiData then return end

	local aiPackage = aiData:getActivePackage()
	if not aiPackage then return end

	if aiPackage.type ~= 3 then
		tes3.setAIFollow{reference=ref, target=tes3.player}
	end
end

local function collectMuskSample(e)
	local object = e.target.object
	if (mwscript.hasItemEquipped{reference=tes3.player, item="mdFG_w_collector"}
		and object.objectType == tes3.objectType.creature
		and mdFG_global_Sample_Guar.value == 0
		and e.activator == tes3.player
		and isGuar(object)
		)
	then
		mdFG_global_Sample_Guar.value = 1
		tes3.messageBox("[Guar musk sample collected.]")
	end
end

local function muskAtomizerTick()
	if (mdFG_global_following.value == 1) and (mdFG_global_MuskAtomizer.value == 1) then
        local position = tes3.player.position
        for key, handle in pairs(guarReferences) do
            local ref = handle:getObject()
            if not ref then guarReferences[key], actorReferences[key] = nil, nil
            elseif living(ref) and distanceSquared(ref.position, position) < 1024 * 1024 then
                followPlayer(ref)
            end
        end
	end
end

local function muskAtomizerStart()
	if atomizerTimer then
		atomizerTimer:cancel()
        atomizerTimer = nil
	end
	if (mdFG_global_following.value == 1) and (mdFG_global_MuskAtomizer.value == 1) then
		atomizerTimer = timer.start{duration=1, iterations=-1, type=timer.simulate, callback=muskAtomizerTick}
	end
end


-- Imperfect Aggro

local function getClosestCombatTarget(ref, distance)
    local closestRef
    local best = distance * distance
    local position = ref.position
    for key, handle in pairs(actorReferences) do
        local otherRef = handle:getObject()
        if not otherRef then actorReferences[key], guarReferences[key] = nil, nil
        elseif otherRef.object ~= ref.object and living(otherRef) then
            local squared = distanceSquared(position, otherRef.position)
            if squared < best then closestRef, best = otherRef, squared end
        end
    end
    return closestRef
end

local function mdFG_script_imperfectFight()
	mwscript.stopScript{script="mdFG_script_imperfectFight"}

	local imperfect = tes3.getReference("mdFG_Imperfect")
	if not living(imperfect) or imperfect.mobile.inCombat == true then
		return
	end

	local closestRef = getClosestCombatTarget(imperfect, 1000)
	if closestRef then
		mwscript.startCombat{reference=imperfect, target=closestRef}
	end
end


-- Gizmo Guards

checkGuard = function()
    if not guardPending then return end
    if not mwscript.scriptRunning{script="mdFG_script_AIGuard"} then guardPending = false; return end
    local gizmo, player = tes3.getReference("mdFG_gizmo"), tes3.player
    if living(gizmo) and living(player) and player.mobile.inCombat
        and distanceSquared(gizmo.position, player.position) < 3000 * 3000 then
        -- Starting Follow can synchronously emit combatStarted through native
        -- AI or another mod. Consume this request before calling back into AI.
        guardPending = false
        followPlayer(gizmo)
        mdFG_global_following.value = 1
        mwscript.stopScript{script="mdFG_script_AIGuard"}
    end
end

local function mdFG_script_AIGuard()
    -- Leave the original running-script flag intact for existing/new saves.
    -- Subsequent override calls do no reference lookup or distance work.
    if not guardPending then guardPending = true; checkGuard() end
end

local function startController()
    if controllerTimer then controllerTimer:cancel() end
    atomizerTimer = nil -- MWSE cancels simulation timers before loaded.
    guardPending = mwscript.scriptRunning{script="mdFG_script_AIGuard"}
    rebuildActors()
    muskAtomizerStart()
    local atomizerEnabled = mdFG_global_following.value == 1 and mdFG_global_MuskAtomizer.value == 1
    controllerTimer = timer.start{duration=0.1, iterations=-1, type=timer.simulate, callback=function()
        checkGuard()
        local enabled = mdFG_global_following.value == 1 and mdFG_global_MuskAtomizer.value == 1
        if enabled ~= atomizerEnabled then atomizerEnabled = enabled; muskAtomizerStart() end
    end}
end


-- Override Scripts

local function mdFG_script_RepairModule()
	tes3.showRepairServiceMenu()
	mwscript.stopScript{script="mdFG_script_RepairModule"}
end

local function mdFG_script_AIFollow()
	muskAtomizerStart()
	mwscript.stopScript{script="mdFG_script_AIFollow"}
end

local function mdFG_script_SummonGizmo(e)
    local pos = e.reference.position:copy()
    local ori = e.reference.orientation:copy()
    local cell = e.reference.cell
    timer.delayOneFrame(function()
        local ref = tes3.getReference("mdFG_gizmo")
        if not ref then return end
        tes3.positionCell{reference=ref, position=pos, orientation=ori, cell=cell}
        mwscript.disable{reference=ref}
        mwscript.enable{reference=ref}
    end)
    mwscript.stopScript{script="mdFG_script_SummonGizmo"}
end

-- Mod Initialization

event.register("initialized", function()
	if tes3.isModActive("Fabricant Guar.ESP") then
		-- register events
		event.register("loaded", startController)
        event.register("cellChanged", rebuildActors)
        event.register("combatStarted", function() checkGuard() end)
		event.register("activate", collectMuskSample)
		event.register("mobileActivated", onRefCreated)
		event.register("mobileDeactivated", onRefDeleted)
		-- override scripts
		mwse.overrideScript("mdFG_script_RepairModule", mdFG_script_RepairModule)
		mwse.overrideScript("mdFG_script_AIFollow", mdFG_script_AIFollow)
		mwse.overrideScript("mdFG_script_imperfectFight", mdFG_script_imperfectFight)
		mwse.overrideScript("mdFG_script_AIGuard", mdFG_script_AIGuard)
		mwse.overrideScript("mdFG_script_SummonGizmo", mdFG_script_SummonGizmo)
		-- cache globals
		mdFG_global_MuskAtomizer = tes3.findGlobal("mdFG_global_MuskAtomizer")
		mdFG_global_Sample_Guar = tes3.findGlobal("mdFG_global_Sample_Guar")
		mdFG_global_following = tes3.findGlobal("mdFG_global_following")
		mdFG_global_imperfect = tes3.findGlobal("mdFG_global_imperfect")
		mdFG_global_dead = tes3.findGlobal("mdFG_global_dead")
	end
end)
