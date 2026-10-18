-- Deterministic API fixture. Executes the actual registered mod callbacks.
local callbacks, overrides, timers, globals, running = {}, {}, {}, {}, {}
local simulation, searches, visited, handles = 0, 0, 0, 0
local insideFollow, followCalls = false, 0
local Vec={}; Vec.__index=Vec
local function vec(x,y,z) return setmetatable({x=x,y=y,z=z},Vec) end
function Vec:distance(b) local x,y,z=self.x-b.x,self.y-b.y,self.z-b.z; return math.sqrt(x*x+y*y+z*z) end
function Vec:copy() return vec(self.x,self.y,self.z) end
local refs={}
local function actor(id,x,kind,object)
 local ref={object=object or {id=id,objectType=kind or 1},position=vec(x,0,0),orientation=vec(0,0,0),disabled=false,deleted=false,valid=true,data={}}
 ref.mobile={health={current=100},inCombat=false,package={type=0},canMove=true,
  encumbrance={current=0,base=250},speed={base=40,current=40},moveSpeed=200}
 ref.mobile.aiData={getActivePackage=function() return ref.mobile.package end}
 function ref:isValid() return self.valid end
 refs[#refs+1]=ref; return ref
end
local player=actor('player',5000,2)
local gizmo=actor('mdFG_gizmo',4500)
local imperfect=actor('mdFG_Imperfect',0)
actor('samebase',5,1,imperfect.object)
local nearest=actor('rat',20)
local nextNearest=actor('other',30)
local guar=actor('guar_feral',5100)
for i=1,SCENERY do refs[#refs+1]={object={id='rock_'..i,objectType=3},position=vec(i+100,0,0)} end
for i=1,100 do actor('npc_'..i,200+i,2) end
local cell={}
function cell:iterateReferences(filter)
 local n=0
 return function()
  while true do
   n=n+1; local ref=refs[n]; if not ref then return end
   if not filter or ref.object.objectType==1 or ref.object.objectType==2 then visited=visited+1; return ref end
  end
 end
end
for _,ref in ipairs(refs) do ref.cell=cell end
tes3={objectType={creature=1,npc=2},player=player,
 isModActive=function() return true end,
 getActiveCells=function() return {cell} end,
 getReference=function(id) if id:lower()=='mdfg_gizmo' then return gizmo elseif id:lower()=='mdfg_imperfect' then return imperfect else return player end end,
 findGlobal=function(id) if not globals[id] then globals[id]={value=0} end; return globals[id] end,
 makeSafeObjectHandle=function(ref)
  return {getObject=function() handles=handles+1; if ref.valid then return ref end end}
 end,
 setAIFollow=function(p)
  followCalls=followCalls+1
  local package={type=3,target=p.target,targetActor=p.target.mobile}; p.reference.mobile.package=package
  if not insideFollow then
   insideFollow=true
   p.reference.mobile.package={type=1,target=p.target}
   for _,fn in ipairs(callbacks.combatStarted or {}) do fn({actor=p.reference.mobile}) end
   p.reference.mobile.package=package
   insideFollow=false
  end
 end,
 showRepairServiceMenu=function() end,messageBox=function() end,positionCell=function() end,
}
mwscript={hasItemEquipped=function() return false end,
 stopScript=function(p) running[p.script]=false end,
 scriptRunning=function(p) return running[p.script] or false end,
 startCombat=function(p) searches=searches+1; LAST_TARGET=p.target end,
 disable=function() end,enable=function() end,
}
mwse={overrideScript=function(name,fn) overrides[name]=fn end}
event={register=function(name,fn,options)
 callbacks[name]=callbacks[name] or {}
 table.insert(callbacks[name],function(e)
  if not options or not options.filter or
   (e.reference and e.reference.object.id:lower()==options.filter) then return fn(e) end
 end)
end}
timer={simulate=1,active=1,expired=2}
function timer.start(p)
 local t={callback=p.callback,duration=p.duration,next=simulation+p.duration,iterations=p.iterations or 1,state=1}
 function t:cancel() self.state=2 end
 timers[#timers+1]=t; return t
end
function timer.delayOneFrame(fn) return timer.start{duration=0.01,callback=fn} end
local function emit(name,data) for _,fn in ipairs(callbacks[name] or {}) do fn(data or {}) end end
local function hook(name) overrides['mdFG_script_'..name]({reference=player}) end
local function advance(duration)
 local untilTime=simulation+duration
 while simulation+0.000001<untilTime do
  simulation=simulation+0.01
  if running.mdFG_script_AIGuard then hook('AIGuard') end
  local current={}; for i,t in ipairs(timers) do current[i]=t end
  for _,t in ipairs(current) do
   if t.state==1 and simulation+0.000001>=t.next then
    t.callback(); if t.iterations==1 then t.state=2 else t.next=t.next+t.duration end
   end
  end
 end
end
local function loaded()
 for _,t in ipairs(timers) do t:cancel() end
 emit('loaded')
end
assert(loadfile(MODULE))()
emit('initialized')
for _,ref in ipairs(refs) do if ref.mobile then emit('mobileActivated',{reference=ref}) end end
loaded()
hook('imperfectFight'); assert(LAST_TARGET==nearest,'nearest target changed')
nearest.disabled=true; hook('imperfectFight'); assert(LAST_TARGET==nextNearest,'disabled target was selected')
nearest.disabled=false; nearest.mobile.health.current=0
hook('imperfectFight'); assert(LAST_TARGET==nextNearest,'dead target was selected')
nearest.mobile.health.current=100
imperfect.mobile.inCombat=true; local before=searches; hook('imperfectFight'); assert(searches==before,'valid combat target replaced')
imperfect.mobile.inCombat=false
running.mdFG_script_AIGuard=true
player.mobile.inCombat=false; hook('AIGuard'); advance(0.2)
assert(not globals.mdFG_global_following or globals.mdFG_global_following.value==0,'peaceful guard followed')
local beforeGuard=followCalls
player.mobile.inCombat=true; emit('combatStarted',{actor=player.mobile}); advance(0.1)
assert(followCalls==beforeGuard+1,'reentrant combatStarted duplicated Guard Follow')
assert(globals.mdFG_global_following.value==1 and not running.mdFG_script_AIGuard,'guard did not join combat')
assert(gizmo.mobile.package.target==player,'guard Follow target changed')
player.mobile.inCombat=false
globals.mdFG_global_MuskAtomizer.value=1
loaded(); advance(1.1)
assert(guar.mobile.package.target==player,'loaded atomizer did not attract guar')
running.mdFG_script_AIGuard=true; globals.mdFG_global_following.value=0
loaded(); player.mobile.inCombat=true; advance(0.1)
assert(globals.mdFG_global_following.value==1,'saved running Guard command lost')
player.mobile.inCombat=false
globals.mdFG_global_MuskAtomizer.value=0; loaded()
guar.mobile.package={type=0}
globals.mdFG_global_MuskAtomizer.value=1; advance(1.2)
local toggleFixed=guar.mobile.package.target==player
if CANDIDATE then
 assert(toggleFixed,'enabling atomizer during Follow did not start it')
 local spawned=actor('new_rat',10); spawned.cell=cell
 emit('mobileActivated',{reference=spawned}); hook('imperfectFight'); assert(LAST_TARGET==spawned,'new actor missing from cache')
 spawned.valid=false; hook('imperfectFight'); assert(LAST_TARGET==nearest,'invalid safe handle was not pruned')
 emit('mobileDeactivated',{reference=nearest}); nearest.disabled=true
 hook('imperfectFight'); assert(LAST_TARGET==nextNearest,'deactivated actor retained')
 nearest.disabled=false; emit('cellChanged'); hook('imperfectFight'); assert(LAST_TARGET==nearest,'cell rebuild lost actor')

 -- Native Follow writes Speed 40 nearby and Player Speed * 1.5 farther away.
 -- Its attribute changes are not a guarantee of matching actual movement speed.
 -- Exercise the real registered MWSE movement callback with engine speed inputs.
 local function movement(ref, speed)
  local e={reference=ref,mobile=ref.mobile,speed=speed,type=0}
  emit('calcMoveSpeed',e)
  assert(not e.claim,'movement event claimed from other mods')
  return e.speed
 end
 local oldPosition=gizmo.position
 gizmo.position=vec(player.position.x-200,0,0)
 gizmo.mobile.package={type=3,targetActor=player.mobile}
 globals.mdFG_global_following.value=1
 assert(movement(gizmo,40)==200,'nearby Gizmo cannot keep up with player walking')
 player.mobile.moveSpeed=400
 assert(movement(gizmo,40)==400,'nearby Gizmo cannot keep up with player running')
 gizmo.position=vec(player.position.x-600,0,0)
 assert(movement(gizmo,75)==600,'trailing Gizmo cannot catch up before the native teleport')
 assert(movement(gizmo,800)==800,'faster native or modded movement was reduced')
 assert(movement(nearest,40)==40,'unrelated actor speed changed')
 assert(movement(player,400)==400,'player speed changed')
 assert(movement(imperfect,40)==40,'Imperfect speed changed')
 assert(movement(gizmo,0)==0,'zero movement speed was overridden')
 gizmo.mobile.inCombat=true
 assert(movement(gizmo,40)==40,'combat speed changed')
 gizmo.mobile.inCombat=false; gizmo.mobile.canMove=false
 assert(movement(gizmo,40)==40,'immobilized Gizmo was accelerated')
 gizmo.mobile.canMove=true; gizmo.mobile.encumbrance.current=251
 assert(movement(gizmo,40)==40,'overencumbered Gizmo was accelerated')
 gizmo.mobile.encumbrance.current=0; gizmo.disabled=true
 assert(movement(gizmo,40)==40,'disabled Gizmo was accelerated')
 gizmo.disabled=false; gizmo.mobile.health.current=0
 assert(movement(gizmo,40)==40,'dead Gizmo was accelerated')
 gizmo.mobile.health.current=100; globals.mdFG_global_following.value=0
 assert(movement(gizmo,40)==40,'non-Follow command speed changed')
 globals.mdFG_global_following.value=1; gizmo.mobile.package={type=0}
 assert(movement(gizmo,40)==40,'Wander speed changed with a stale Follow global')
 gizmo.mobile.package={type=3,targetActor=nearest.mobile}
 assert(movement(gizmo,40)==40,'Follow targeting another actor was accelerated')
 gizmo.mobile.package=nil
 assert(movement(gizmo,40)==40,'missing AI package was not handled')
 gizmo.mobile.package={type=3,targetActor=player.mobile}
 player.mobile.moveSpeed=0
 assert(movement(gizmo,75)==75,'immobile player slowed Gizmo')
 player.mobile.moveSpeed=200; loaded()
 assert(movement(gizmo,75)==300,'movement fix did not survive save/load')
 assert(gizmo.mobile.speed.base==40 and gizmo.mobile.speed.current==40,
  'movement correction modified the saved Speed attribute')
 gizmo.position=oldPosition
 hook('imperfectFight') -- Prune the invalid fixture actor after the reload before timing.
 print('PASS MWSE following movement: pace, catch-up, exclusions, and reload')
end
local times,visits,lookups={},{},{}
for trial=1,3 do
 visited,handles=0,0
 local started=os.clock()
 for n=1,ITERATIONS do hook('imperfectFight') end
 times[trial]=os.clock()-started; visits[trial]=visited; lookups[trial]=handles
end
RESULT=string.format('{"seconds":[%.9f,%.9f,%.9f],"reference_visits":[%d,%d,%d],"handle_lookups":[%d,%d,%d],"toggle_fixed":%s}',
 times[1],times[2],times[3],visits[1],visits[2],visits[3],lookups[1],lookups[2],lookups[3],tostring(toggleFixed))
