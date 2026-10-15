-- The activators contain only the drip. Never hide or modify the source keg.
local kegs = {
    ["f\\furn_com_kegstand.nif"] = { id = "furn_com_kegstand_dr", offset = tes3vector3.new(0, -54.4, -64) },
    ["f\\furn_de_kegstand.nif"] = { id = "furn_de_kegstand_dr", offset = tes3vector3.new(0, -54.4, -64) },
    ["f\\furn_winekeg00.nif"] = { id = "furn_winekeg00_dr", offset = tes3vector3.new(0, -43.4, -69.5) },
    ["hf\\f\\hf_furn_kegstand_01.nif"] = { id = "hf_furn_kegstand_01_dr", offset = tes3vector3.new(0, -54.4, -64) },
    ["hr\\f\\hr_furn_kegstand_01.nif"] = { id = "hr_furn_kegstand_01_dr", offset = tes3vector3.new(0, -54.4, -64) },
    ["sky\\f\\sky_furn_n_m_keg_01.nif"] = { id = "sky_furn_n_m_keg_01_dr", offset = tes3vector3.new(0, -54.4, -64) },
}
local effectIds = {}
for _, keg in pairs(kegs) do effectIds[keg.id] = true end

local radius = 22
local minimumUp = math.cos(math.rad(5))
local puddleId = "kegPuddle"
local puddleGrowth = 1 / 60 -- One minute of uncovered dripping to reach full size.
local up = tes3vector3.new(0, 0, 1)
local elapsed = 1
local refreshPending = false

local function normalizeMesh(mesh)
    return mesh and mesh:lower():gsub("/", "\\"):gsub("^meshes\\", "")
end

local function available(ref)
    return not ref.disabled and not ref.deleted
end

local function hasReceiver(landing, receivers)
    for _, receiver in ipairs(receivers) do
        if receiver.position:distance(landing) <= radius then return true end
    end
    return false
end

local function samePlacement(effect, keg)
    return effect.position:distance(keg.position) < 0.01
        and effect.orientation:distance(keg.orientation) < 0.001
        and math.abs(effect.scale - keg.scale) < 0.001
end

local function clearPuddles(cell)
    local wasModified = cell.modified
    for ref in cell:iterateReferences(tes3.objectType.activator) do
        if not ref.deleted and ref.object.id:lower() == puddleId:lower() then
            ref:delete()
            ref.modified = false
        end
    end
    cell.modified = wasModified
end

local function refreshCell(cell, dt)
    local receivers, effects, puddles, used = {}, {}, {}, {}
    for ref in cell:iterateReferences(tes3.objectType.misc) do
        local mesh = normalizeMesh(ref.object.mesh)
        if available(ref) and mesh and (mesh:find("bucket", 1, true) or mesh:find("bowl", 1, true)) then
            receivers[#receivers + 1] = ref
        end
    end
    for ref in cell:iterateReferences(tes3.objectType.activator) do
        if not ref.deleted then
            local id = ref.object.id:lower()
            if effectIds[id] then effects[#effects + 1] = ref
            elseif id == puddleId:lower() then puddles[#puddles + 1] = ref end
        end
    end

    local wasModified = cell.modified
    for keg in cell:iterateReferences() do
        local definition = kegs[normalizeMesh(keg.object.mesh)]
        local rotation
        if definition and available(keg) and keg.sceneNode then
            rotation = tes3matrix33.new()
            local o = keg.orientation
            rotation:fromEulerXYZ(o.x, o.y, o.z)
        end
        if rotation and (rotation * up).z >= minimumUp then
            local effect
            for _, candidate in ipairs(effects) do
                if not used[candidate] and available(candidate)
                    and candidate.object.id:lower() == definition.id and samePlacement(candidate, keg) then
                    effect = candidate
                    break
                end
            end
            if not effect then
                effect = tes3.createReference {
                    object = definition.id,
                    cell = cell,
                    position = keg.position,
                    orientation = keg.orientation,
                    scale = keg.scale,
                    updateCollisionGroups = false,
                }
                effect.modified = false
            end
            used[effect] = true
            if effect.sceneNode and not effect.tempData.kegDripAnimated then
                tes3.setAnimationTiming { reference = effect, timing = math.random() * 2.5 }
                effect.tempData.kegDripAnimated = true
            end
            local landing = keg.position + rotation * (definition.offset * keg.scale)
            local covered = hasReceiver(landing, receivers)
            local puddle
            for _, candidate in ipairs(puddles) do
                local delta = candidate.position - landing
                if not used[candidate] and available(candidate)
                    and delta.x * delta.x + delta.y * delta.y < 0.25
                    and delta.z < 32 * keg.scale and delta.z > -4096 then
                    puddle = candidate
                    break
                end
            end
            if not covered and not puddle then
                -- Ignore the visual effects, including existing puddles, so the
                -- ray always reaches the surface rather than an earlier decal.
                local ignore = { keg, effect }
                for _, ref in ipairs(puddles) do ignore[#ignore + 1] = ref end
                local hit = tes3.rayTest {
                    position = landing + up * (32 * keg.scale),
                    direction = -1 * up,
                    maxDistance = 4096,
                    ignore = ignore,
                    returnNormal = true,
                }
                if hit and hit.normal and hit.normal.z > 0.05 then
                    local normal = hit.normal
                    puddle = tes3.createReference {
                        object = puddleId,
                        cell = cell,
                        position = hit.intersection + normal * 0.1,
                        orientation = tes3vector3.new(-math.asin(normal.y), math.atan2(normal.x, normal.z), 0),
                        scale = 0.01,
                        updateCollisionGroups = false,
                    }
                end
            end
            if puddle then
                used[puddle] = true
                if not covered then puddle.scale = math.min(1, puddle.scale + dt * puddleGrowth) end
                puddle.modified = false
            end
        end
    end
    -- Includes duplicates and effects whose source keg disappeared or moved.
    for _, puddle in ipairs(puddles) do effects[#effects + 1] = puddle end
    for _, effect in ipairs(effects) do
        if not used[effect] then
            effect:delete()
            effect.modified = false
        end
    end
    cell.modified = wasModified
end

local function refresh(dt)
    if not tes3.player then return end
    for _, cell in ipairs(tes3.getActiveCells()) do refreshCell(cell, dt or 0) end
    elapsed = 0
end

local function requestRefresh()
    if refreshPending then return end
    refreshPending = true
    -- Wait until the whole cell, including buckets and bowls, has loaded.
    timer.delayOneFrame(function()
        refreshPending = false
        refresh()
    end)
end

event.register("referenceSceneNodeCreated", function(e)
    local ref = e.reference
    if effectIds[ref.object.id:lower()] then
        ref.tempData.kegDripAnimated = nil
    elseif kegs[normalizeMesh(ref.object.mesh)] then
        requestRefresh()
    end
end)
event.register("cellChanged", requestRefresh)
event.register("cellActivated", function(e)
    clearPuddles(e.cell)
    requestRefresh()
end)
event.register("cellDeactivated", function(e) clearPuddles(e.cell) end)
event.register("loaded", function()
    for _, cell in ipairs(tes3.getActiveCells()) do clearPuddles(cell) end
    requestRefresh()
end)
event.register("simulate", function(e)
    elapsed = elapsed + e.delta
    if elapsed >= 1 then refresh(elapsed) end
end)
