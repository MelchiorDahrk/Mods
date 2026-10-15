-- Run from the repository root with Lua 5.1+ or LuaJIT.
local vector = {}
vector.__index = vector
local function v(x, y, z) return setmetatable({x=x, y=y, z=z}, vector) end
function vector.__add(a, b) return v(a.x+b.x, a.y+b.y, a.z+b.z) end
function vector.__sub(a, b) return v(a.x-b.x, a.y-b.y, a.z-b.z) end
function vector.__mul(a, b)
    if type(a) == 'number' then a, b = b, a end
    return v(a.x*b, a.y*b, a.z*b)
end
function vector:length() return math.sqrt(self.x*self.x+self.y*self.y+self.z*self.z) end
function vector:distance(other) return (self-other):length() end
local rotation = {}
rotation.__index = rotation
local function r(x, y, z) return setmetatable({x=x or 0, y=y or 0, z=z or 0}, rotation) end
function rotation:fromEulerXYZ(x, y, z) self.x, self.y, self.z = x, y, z end
function rotation.__mul(a, b)
    if a.apply then return a.apply(b) end
    local cx, sx, cy, sy, cz, sz = math.cos(a.x), math.sin(a.x), math.cos(a.y), math.sin(a.y), math.cos(a.z), math.sin(a.z)
    local x, y, z = b.x, cx*b.y-sx*b.z, sx*b.y+cx*b.z
    x, z = cy*x+sy*z, -sy*x+cy*z
    return v(cz*x-sz*y, sz*x+cz*y, z)
end

local definitions = {
    {'f/Furn_Com_Kegstand.NIF', 'furn_com_kegstand_dr', v(0, -54.4, -64)},
    {'meshes\\f\\FURN_DE_KEGSTAND.NIF', 'furn_de_kegstand_dr', v(0, -54.4, -64)},
    {'f/furn_winekeg00.nif', 'furn_winekeg00_dr', v(0, -43.4, -69.5)},
}

local function run(runtime)
    local cells, serial, creates, animations = {}, 0, 0, 0
    local groundZ, groundNormal, missRay, rays = -20, v(0,0,1), false, {}
    local globalEvents
    local handlers, callbacks = {}, {}
    local function queue(callback) callbacks[#callbacks+1]=callback end
    local function cell(exterior, x, y)
        local c = {objects={}, modified=false, isExterior=exterior, gridX=x, gridY=y}
        cells[#cells+1] = c
        function c:getAll(kind)
            local result = {}
            for _, object in ipairs(self.objects) do
                if object.kind == kind and not object.deleted then result[#result+1] = object end
            end
            return result
        end
        function c:iterateReferences(kind)
            local list, i = self:getAll(kind), 0
            return function() i=i+1; return list[i] end
        end
        return c
    end
    local here, away = cell(false), cell(false)
    local function object(c, kind, mesh, pos, angles, scale, id)
        serial = serial+1
        local o = {kind=kind, id='ref'..serial, recordId=id or 'record'..serial, enabled=true, disabled=false,
            deleted=false, count=1, position=pos or v(0,0,0), orientation=angles or v(0,0,0),
            rotation=r(angles and angles.x, angles and angles.y, angles and angles.z), scale=scale or 1,
            cell=c, sceneNode={appCulled=false}, tempData={}, scripts={}, modified=false}
        o.object = {id=o.recordId, objectType=kind, mesh=mesh}
        function o:isValid() return not self.deleted end
        function o:remove() self.count=0; self.deleted=true end
        function o:delete() self:remove(); self.modified=true; self.cell.modified=true end
        function o:setScale(value)
            if runtime=='OpenMW' then queue(function() self.scale=value end)
            else self.scale=value end
        end
        function o:addScript(path) self.scripts[path]=true end
        function o:hasScript(path) return self.scripts[path] end
        function o:sendEvent(name, data)
            queue(function()
                package.loaded['openmw.self']={object=self, cell=self.cell, scale=self.scale}
                local script=assert(loadfile('01 OpenMW/scripts/KegDrip/effect.lua'))()
                script.eventHandlers[name](data)
            end)
        end
        function o:teleport(destination, position, options)
            self.cell=destination; self.position=position; self.rotation=options.rotation
            assert(options.onGround == false)
            destination.objects[#destination.objects+1]=self
        end
        if c then c.objects[#c.objects+1]=o end
        return o
    end
    local player = {cell=here}
    local activeCells = {here}
    local function flush()
        local pending=callbacks; callbacks={}
        for _, callback in ipairs(pending) do callback() end
    end
    local function create(id)
        creates=creates+1
        return object(nil, 'activator', nil, nil, nil, nil, id)
    end
    local function load()
        if runtime == 'MWSE' then
            tes3vector3={new=v}; tes3matrix33={new=r}
            timer={delayOneFrame=queue}
            event={register=function(name, callback) handlers[name]=callback end}
            tes3={player=player, objectType={static='static', misc='misc', activator='activator'},
                getActiveCells=function() return activeCells end,
                createReference=function(options)
                    local o=create(options.object)
                    o.cell=options.cell; o.position=options.position; o.orientation=options.orientation; o.scale=options.scale
                    o.cell.objects[#o.cell.objects+1]=o; o.cell.modified=true
                    assert(options.updateCollisionGroups == false)
                    return o
                end,
                setAnimationTiming=function(options)
                    assert(options.timing >= 0 and options.timing <= 2.5)
                    animations=animations+1
                end,
                rayTest=function(options)
                    assert(options.direction.z==-1 and options.maxDistance==4096 and options.returnNormal)
                    assert(options.ignore[1].kind=='static' and options.ignore[2].kind=='activator')
                    rays[#rays+1]=options.position
                    if missRay then return nil end
                    return {intersection=v(options.position.x,options.position.y,groundZ),normal=groundNormal}
                end}
            assert(loadfile('01 MWSE/MWSE/mods/KegDrip/main.lua'))()
        else
            local function kind(name)
                return {objectIsInstance=function(o) return o.kind==name end,
                    record=function(o) return {model=o.object.mesh} end}
            end
            local types={Static=kind('static'), Activator=kind('activator'), Miscellaneous=kind('misc')}
            -- The engine uses type objects as getAll's argument.
            for _, c in ipairs(cells) do
                local old=c.getAll
                function c:getAll(t)
                    if t==types.Static then t='static' elseif t==types.Activator then t='activator'
                    elseif t==types.Miscellaneous then t='misc' end
                    return old(self,t)
                end
            end
            package.loaded['openmw.types']=types
            package.loaded['openmw.util']={vector3=v, transform={identity=r(), rotate=function(angle,axis)
                local normalAxis=axis*(1/axis:length())
                return setmetatable({apply=function(p)
                    local cross=v(normalAxis.y*p.z-normalAxis.z*p.y,normalAxis.z*p.x-normalAxis.x*p.z,normalAxis.x*p.y-normalAxis.y*p.x)
                    local dot=normalAxis.x*p.x+normalAxis.y*p.y+normalAxis.z*p.z
                    return p*math.cos(angle)+cross*math.sin(angle)+normalAxis*(dot*(1-math.cos(angle)))
                end},rotation)
            end}}
            package.loaded['openmw.animation']={playBlended=function() end}
            package.loaded['openmw.core']={sendGlobalEvent=function(name,data)
                queue(function() globalEvents[name](data) end)
            end}
            package.loaded['openmw.nearby']={COLLISION_TYPE={World=1,HeightMap=2},castRay=function(from,to,options)
                assert(to.x==from.x and to.y==from.y and to.z==from.z-4096)
                assert(options.ignore.kind=='static' and options.collisionType==3)
                rays[#rays+1]=from
                if missRay then return {hit=false} end
                return {hit=true,hitPos=v(from.x,from.y,groundZ),hitNormal=groundNormal}
            end}
            package.loaded['openmw.world']={players={player}, createObject=create,
                getExteriorCell=function(x,y)
                    for _, c in ipairs(cells) do
                        if c.isExterior and c.gridX==x and c.gridY==y then return c end
                    end
                    return cell(true,x,y)
                end}
            local script=assert(loadfile('01 OpenMW/scripts/KegDrip/global.lua'))()
            handlers=script.engineHandlers; globalEvents=script.eventHandlers
        end
    end
    load()
    local function tick(dt)
        if runtime=='MWSE' then handlers.simulate({delta=dt or 1.1}) else handlers.onUpdate(dt or 1.1) end
        flush(); flush()
    end
    local function settle() tick(); tick() end -- OpenMW round trip for local raycasts.
    local sources, receivers = {}, {}
    local function pair(index, options)
        options=options or {}
        local definition=definitions[index]
        local c=options.cell or here
        local angles=options.angles or v(0,0,math.pi/2)
        local keg=object(c,'static',definition[1],v(serial*200,0,128),angles,options.scale or 1.5)
        local landing=keg.position+keg.rotation*(definition[3]*keg.scale)
        local bucket=object(c,'misc',options.mesh or 'm/Mod_BuCkEt.nif',landing+(options.delta or v(0,0,0)))
        sources[#sources+1]=keg; receivers[#receivers+1]=bucket
        return keg, bucket
    end
    for i=1,3 do pair(i) end
    local tilted=pair(1,{angles=v(math.pi/4,0,0)})
    local upside=pair(1,{angles=v(math.pi,0,0)})
    local distant=pair(1,{delta=v(22.1,0,0)})
    local wrong=pair(1,{mesh='m/plate.nif'})
    local disabledKeg=pair(1); disabledKeg.disabled=true; disabledKeg.enabled=false
    local _, disabledBucket=pair(1); disabledBucket.disabled=true; disabledBucket.enabled=false
    local deletedKeg=pair(1); deletedKeg.deleted=true
    local _, deletedBucket=pair(1); deletedBucket.deleted=true
    local boundary=pair(1,{delta=v(22,0,0),mesh='m/mod_BOWL.nif'})
    object(here,'static',nil,v(0,0,0))
    object(here,'misc',nil,v(0,0,0))
    object(here,'static','f/unrelated.nif',v(0,0,0))
    local function effects(c, puddles)
        local result={}
        for _, o in ipairs(c.objects) do
            if o.kind=='activator' and o.count>0 and (o.recordId:lower()=='kegpuddle')==(puddles or false) then
                result[#result+1]=o
            end
        end
        return result
    end
    local function assertSources()
        for _, keg in ipairs(sources) do
            assert(not keg.sceneNode.appCulled and not keg.modified, 'source keg was changed')
            assert(keg.object.objectType=='static', 'source keg was replaced')
        end
        assert(disabledKeg.disabled and not disabledKeg.enabled)
        assert(deletedKeg.deleted)
    end
    settle()
    assert(#effects(here)==8, runtime..': eligibility or exclusions failed')
    assert(#effects(here,true)==4, runtime..': uncovered kegs did not form puddles')
    for _, keg in ipairs({sources[1],sources[2],sources[3],boundary}) do
        local matched=false
        for _, effect in ipairs(effects(here)) do
            if effect.position:distance(keg.position)<0.01 then
                matched=true; assert(effect.scale==keg.scale)
                if runtime=='MWSE' then assert(effect.orientation==keg.orientation)
                else assert(effect.rotation==keg.rotation and effect:hasScript('scripts/KegDrip/effect.lua')) end
            end
        end
        assert(matched,'missing transformed drip')
    end
    assertSources()
    assert(not here.modified, 'MWSE changed clean cell state')
    for _, puddle in ipairs(effects(here,true)) do
        assert(math.abs(puddle.position.z-(groundZ+0.1))<0.001, 'puddle not at ray intersection')
        assert(puddle.scale>0 and puddle.scale<0.1, 'puddle did not start small')
    end
    for _=1,10 do tick() end
    assert(creates==12,'duplicates during repeated refresh')
    if runtime=='MWSE' then assert(animations==8,'animations restarted every scan') end
    local oldPuddle=effects(here,true)[1]
    assert(oldPuddle.scale>0.1 and oldPuddle.scale<1,'puddle did not grow slowly')
    local before=creates
    if runtime=='MWSE' then
        -- DontSaveObject is attached by the ESP; loading also clears cached refs.
        handlers.loaded(); flush()
    else
        handlers.onSave()
        assert(#effects(here,true)==0,'puddles still exist at save serialization')
        load(); handlers.onLoad()
    end
    settle()
    assert(#effects(here)==8 and creates==before+4,'drips duplicated or puddles not reset on load')
    assert(oldPuddle.deleted,'puddle survived reload')
    local leaving=effects(here,true)[1]
    if runtime=='MWSE' then handlers.cellDeactivated({cell=here}) end
    player.cell=away; activeCells={away}; tick()
    assert(#effects(here,true)==0 and leaving.deleted,'puddle survived cell unload')
    player.cell=here; activeCells={here}
    if runtime=='MWSE' then handlers.cellActivated({cell=here}); flush() end
    settle()
    assert(#effects(here)==8 and #effects(here,true)==4,'cell re-entry did not restart puddles')
    local existing=effects(here)[1]
    object(here,'activator',nil,existing.position,existing.orientation,existing.scale,existing.recordId).rotation=existing.rotation
    tick(); assert(#effects(here)==8,'legacy duplicate not cleaned')
    local p=effects(here,true)[1]
    object(here,'activator',nil,p.position,p.orientation,p.scale,p.recordId).rotation=p.rotation
    tick(); assert(#effects(here,true)==4,'duplicate puddle not cleaned')
    local firstDrip=effects(here)[1]
    receivers[1].disabled=true; receivers[1].enabled=false
    groundNormal=v(0.3,0.4,math.sqrt(0.75))
    settle(); assert(#effects(here)==8 and #effects(here,true)==5,'removed receiver stopped drip or failed to form puddle')
    assert(firstDrip==effects(here)[1],'removing receiver recreated drip')
    local landing=sources[1].position+sources[1].rotation*(definitions[1][3]*sources[1].scale)
    local under
    for _, puddle in ipairs(effects(here,true)) do
        if math.abs(puddle.position.x-landing.x)<0.5 then under=puddle end
    end
    assert(under and math.abs(under.position.y-landing.y)<0.5,'ray ignored rotated/scaled tap offset')
    local normal=runtime=='MWSE' and r(under.orientation.x,under.orientation.y,under.orientation.z)*v(0,0,1) or under.rotation*v(0,0,1)
    assert((normal-groundNormal):length()<0.001,'puddle not aligned to sloped ground')
    receivers[1].disabled=false; receivers[1].enabled=true
    local paused=under.scale
    tick(5); assert(under.scale==paused and #effects(here)==8,'restored receiver did not pause puddle growth')
    receivers[1].position=receivers[1].position+v(100,0,0)
    tick(); assert(under.scale>paused and #effects(here)==8,'moving receiver did not resume growth')
    tick(120); assert(under.scale==1,'puddle did not cap at exactly 1.0')
    tick(120); assert(under.scale==1,'puddle exceeded 1.0')
    sources[2].disabled=true; sources[2].enabled=false
    tick(); assert(#effects(here)==7,'disabled keg still drips')
    here.modified=true
    receivers[3].deleted=true
    missRay=true
    settle(); assert(#effects(here)==7 and #effects(here,true)==5 and here.modified,'ray miss stopped drip, spawned puddle, or lost modified cell state')
    missRay=false
    settle(); assert(#effects(here,true)==6,'failed raycast was not retried')
    assertSources()
    print('PASS '..runtime..': continuous drips, ground raycasts, slopes, growth/cap, receiver changes, temporary puddles, duplicates, source preservation')
end
run('MWSE')
run('OpenMW')

local plays={}
package.loaded['openmw.self']={}
package.loaded['openmw.animation']={playBlended=function(object,group,options)
    assert(group=='idle' and options.loops>0 and options.startPoint>=0 and options.startPoint<=1 and options.forceLoop)
    plays[#plays+1]=options
end}
local effect=assert(loadfile('01 OpenMW/scripts/KegDrip/effect.lua'))().engineHandlers
effect.onActive(); effect.onActive()
assert(#plays==2 and plays[1].startPoint~=plays[2].startPoint)
print('PASS OpenMW animation: idle loop and independent phases on activation')
