local core = require('openmw.core')
local types = require('openmw.types')
local util = require('openmw.util')
local world = require('openmw.world')
local sources, receivers, animated = {}, {}, {}
local rayHits, leavingPuddles = {}, {}
local growingPuddle, initialScale
local stage, elapsed = 'spawn', 0
local ids = {furn_com_kegstand_dr=true, furn_de_kegstand_dr=true, furn_winekeg00_dr=true}
local function check(value, message)
    assert(value, 'KEG DRIP TEST FAILED: '..message)
end
local function effects(cell)
    local list = {}
    for _, object in ipairs(cell:getAll(types.Activator)) do
        if object:isValid() and object.count > 0 and ids[object.recordId] then list[#list+1] = object end
    end
    return list
end
local function puddles(cell)
    local list = {}
    for _, object in ipairs(cell:getAll(types.Activator)) do
        if object:isValid() and object.count > 0 and object.recordId == 'kegpuddle' then list[#list+1] = object end
    end
    return list
end
local function puddleAt(source)
    local landing = source.object.position + source.object.rotation * (source.offset * source.object.scale)
    for _, puddle in ipairs(puddles(source.object.cell)) do
        local delta = puddle.position - landing
        if delta.x * delta.x + delta.y * delta.y < 0.25 then return puddle end
    end
end
local function verify(expected, probe)
    local cell = sources[1].object.cell
    local list = effects(cell)
    check(#list == expected, 'expected '..expected..' effects, got '..#list)
    for _, source in ipairs(sources) do
        check(source.object:isValid() and source.object.enabled, 'original keg was disabled or removed')
        check(types.Static.objectIsInstance(source.object), 'original keg type changed')
        check((source.object.position-source.position):length() < 0.001, 'original keg moved')
        if source.drips then
            local found
            for _, effect in ipairs(list) do
                if (effect.position-source.position):length() < 0.01 then
                    check(effect.recordId==source.effect, 'wrong effect model')
                    check(math.abs(effect.scale-source.object.scale)<0.001, 'scale mismatch')
                    check((effect.rotation*util.vector3(0,1,0)-source.object.rotation*util.vector3(0,1,0)):length()<0.001, 'rotation mismatch')
                    found = true
                    if probe ~= false then
                        if not effect:hasScript('scripts/KegDripSmoke/probe.lua') then effect:addScript('scripts/KegDripSmoke/probe.lua') end
                        effect:sendEvent('KegDripSmokeProbe', {})
                    end
                end
            end
            check(found, 'missing effect at source')
        end
    end
end
local function spawn()
    local player = world.players[1]
    local cases = {
        {'furn_com_kegstand', 'furn_com_kegstand_dr', util.vector3(0,-54.4,-64), true},
        {'furn_de_kegstand', 'furn_de_kegstand_dr', util.vector3(0,-54.4,-64), true},
        {'kd_test_winekeg',
            'furn_winekeg00_dr', util.vector3(0,-43.4,-69.5), true},
        {'furn_com_kegstand', 'furn_com_kegstand_dr', util.vector3(0,-54.4,-64), true},
        {'furn_de_kegstand', 'furn_de_kegstand_dr', util.vector3(0,-54.4,-64), false},
    }
    for i, case in ipairs(cases) do
        local object = world.createObject(case[1])
        local position = util.vector3(1000*i,0,1500)
        local rotation = util.transform.rotateZ(0.6*i)
        if i==5 then rotation = util.transform.rotateX(math.pi/2) end
        object:setScale(1.25)
        object:teleport(player.cell, position, {rotation=rotation, onGround=false})
        sources[#sources+1] = {object=object, position=position, effect=case[2], drips=case[4], offset=case[3]}
        local floor = world.createObject('in_dae_room_l_floor_01')
        floor:teleport(player.cell, position+util.vector3(0,0,-300), {onGround=false})
        local bucket = world.createObject(i==2 and 'misc_com_wood_bowl_01' or 'misc_com_bucket_01')
        local offset = i==4 and util.vector3(100,0,0) or util.vector3(0,0,0)
        bucket:teleport(player.cell, position+rotation*(case[3]*1.25)+offset, {onGround=false})
        receivers[#receivers+1] = bucket
    end
    print('KEG DRIP TEST: API revision '..core.API_REVISION..', spawned four upright kegs and one tilted exclusion')
end
return {
    eventHandlers = {
        KegDripSmokeAnimated = function(id) animated[id] = true end,
        KegDripGround = function(data) rayHits[data.effect.id] = data end,
    },
    engineHandlers = {
        onUpdate = function(dt)
            if dt==0 or not world.players[1] then return end
            elapsed = elapsed+dt
            local delay = (stage=='initial' or stage=='receiver-removed') and 2.5 or 1.5
            if elapsed < delay then return end
            elapsed = 0
            local ok, message = pcall(function()
                if stage=='spawn' then spawn(); stage='initial'
                elseif stage=='initial' then
                    verify(4)
                    check(puddleAt(sources[4]), 'uncovered keg did not form a puddle')
                    puddleAt(sources[4]):setScale(0.8)
                    world.players[1]:sendEvent('KegDripSmokeSave', {})
                    stage='await-load'
                elseif stage=='loaded' then
                    verify(4, false)
                    local puddle = puddleAt(sources[4])
                    check(not puddle or puddle.scale < 0.2, 'puddle survived save/load')
                    leavingPuddles = puddles(sources[1].object.cell)
                    world.players[1]:teleport('Balmora, South Wall Cornerclub', util.vector3(0,0,128))
                    stage='away'
                elseif stage=='away' then
                    for _, puddle in ipairs(leavingPuddles) do
                        check(not puddle:isValid() or puddle.count == 0, 'puddle survived cell unload')
                    end
                    world.players[1]:teleport(sources[1].object.cell, util.vector3(0,0,128))
                    stage='returned'
                elseif stage=='returned' then
                    verify(4)
                    receivers[1]:remove()
                    stage='receiver-removed'
                elseif stage=='receiver-removed' then
                    verify(4)
                    growingPuddle = puddleAt(sources[1])
                    check(growingPuddle and growingPuddle.scale > 0 and growingPuddle.scale < 0.2, 'removed bucket did not start a small puddle')
                    local foundRay = false
                    for _, hit in pairs(rayHits) do
                        if (hit.position-growingPuddle.position):length() < 0.01 then foundRay = true end
                    end
                    check(foundRay, 'puddle was not placed at a physics ray intersection')
                    initialScale = growingPuddle.scale
                    stage='growth'
                elseif stage=='growth' then
                    check(growingPuddle.scale > initialScale and growingPuddle.scale < 0.2, 'puddle did not grow slowly')
                    growingPuddle:setScale(0.99)
                    stage='cap'
                elseif stage=='cap' then
                    check(growingPuddle.scale == 1, 'puddle did not cap at scale 1.0')
                    local list=effects(sources[1].object.cell)
                    local duplicate=world.createObject(list[1].recordId)
                    duplicate:setScale(list[1].scale)
                    duplicate:teleport(list[1].cell,list[1].position,{rotation=list[1].rotation,onGround=false})
                    stage='duplicate'
                elseif stage=='duplicate' then
                    verify(4, false)
                    check(growingPuddle.scale == 1, 'puddle grew beyond scale 1.0')
                    local count=0
                    for _ in pairs(animated) do count=count+1 end
                    check(count>=3, 'not all three models passed animation probes')
                    world.players[1]:teleport(world.getExteriorCell(40,40), util.vector3(40*8192+4096,40*8192+4096,100))
                    stage='exterior-spawn'
                elseif stage=='exterior-spawn' then
                    sources={}
                    for x=40,41 do
                        local cell=world.getExteriorCell(x,40)
                        local position=util.vector3(x*8192+4096,40*8192+4096,200)
                        local object=world.createObject('furn_com_kegstand')
                        object:teleport(cell,position,{onGround=false})
                        local bucket=world.createObject('misc_com_bucket_01')
                        bucket:teleport(cell,position+util.vector3(0,-54.4,-64),{onGround=false})
                        sources[#sources+1]={object=object,position=position}
                    end
                    stage='exterior-verify'
                elseif stage=='exterior-verify' then
                    for _, source in ipairs(sources) do
                        check(source.object.enabled and types.Static.objectIsInstance(source.object), 'exterior source changed')
                        local list=effects(source.object.cell)
                        check(#list==1 and (list[1].position-source.position):length()<0.01, 'exterior or adjacent cell drip missing')
                    end
                    print('KEG DRIP TEST PASSED: source preservation, transforms, animation, continuous dripping, raycast puddles, growth/cap, save/load, cell cleanup, duplicates, adjacent exterior cells')
                    core.quit(); stage='done'
                end
            end)
            if not ok then print(tostring(message)); core.quit(); stage='done' end
        end,
        onSave = function() return {sources=sources, receivers=receivers} end,
        onLoad = function(data)
            sources=data.sources; receivers=data.receivers; animated={}; stage='loaded'; elapsed=0
        end,
    },
}
