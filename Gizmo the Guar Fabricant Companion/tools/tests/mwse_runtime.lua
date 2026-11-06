-- Deterministic API fixture. Executes the actual registered mod callbacks.
local callbacks, overrides, timers, globals, running = {}, {}, {}, {}, {}
local simulation, searches, visited, handles = 0, 0, 0, 0
local insideFollow, followCalls = false, 0
local statisticWrites = 0
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
 setStatistic=function(p)
  assert(p.reference==gizmo and p.statistic==gizmo.mobile.speed,'wrong actor/statistic written')
  assert(p.limit==false,'Speed must be allowed above 100')
  statisticWrites=statisticWrites+1
  p.statistic.base=p.value; p.statistic.current=p.value
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
  local filterObject=name=='scriptExecuted' and e.script or (e.reference and e.reference.object)
  if not options or not options.filter or (filterObject and filterObject.id:lower()==options.filter) then
   return fn(e)
  end
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

 -- Exercise the native-script boundary as well as the initial Follow request.
 -- A movement-event-only fix cannot pass these actual attribute assertions.
 local function speedIs(value, message)
  assert(gizmo.mobile.speed.base==value and gizmo.mobile.speed.current==value,message)
 end
 local function nativeTick(value, reference, scriptId)
  local ref=reference or gizmo
  if value then ref.mobile.speed.base=value; ref.mobile.speed.current=value end
  local e={reference=ref,script={id=scriptId or 'mdFG_script_gizmo'}}
  emit('scriptExecuted',e)
  assert(not e.claim,'native script event claimed from other mods')
 end
 gizmo.mobile.speed={base=20,current=20}
 gizmo.mobile.package=nil -- The native AI target may not be initialized at recruitment.
 player.mobile.speed={base=40,current=40}
 globals.mdFG_global_following.value=1
 running.mdFG_script_AIFollow=true
 hook('AIFollow'); speedIs(90,'initial Follow left Gizmo at Speed 20 instead of Player +50')
 assert(not running.mdFG_script_AIFollow,'Follow hook was not stopped')
 gizmo.mobile.package={type=3,targetActor=player.mobile}
 for _,distance in ipairs({100,299,300,600,899,900,1200}) do
  gizmo.position=vec(player.position.x-distance,0,0)
  nativeTick(distance<300 and 40 or 60)
  speedIs(90,'native distance rule overwrote Player +50')
 end
 player.mobile.speed.current=80 -- Fortified player; use current, not base Speed.
 nativeTick(); speedIs(130,'player Speed increase was not followed above 100')
 player.mobile.speed.current=30
 nativeTick(); speedIs(80,'player Speed decrease was not followed')
 player.mobile.speed.current=0
 nativeTick(); speedIs(50,'zero player Speed lost the +50 offset')
 player.mobile.speed.current=250
 nativeTick(100); speedIs(300,'high player Speed was capped or multiplied')
 local writes=statisticWrites
 nativeTick(); assert(statisticWrites==writes,'unchanged Speed caused redundant writes')
 gizmo.mobile.inCombat=true
 nativeTick(100); speedIs(300,'native combat cap broke the +50 rule during Follow')
 gizmo.mobile.inCombat=false
 nativeTick(20,nearest,'unrelated_script')
 nativeTick(20,imperfect,'mdFG_script_imperfect')
 assert(nearest.mobile.speed.current==20 and imperfect.mobile.speed.current==20,'unrelated actors changed')
 assert(player.mobile.speed.current==250 and player.mobile.speed.base==40,'player Speed changed')
 nativeTick(20,gizmo,'unrelated_script'); speedIs(20,'unrelated script triggered the update')
 globals.mdFG_global_following.value=0
 nativeTick(20); speedIs(20,'Guard/Patrol/Forage Speed was overwritten')
 globals.mdFG_global_following.value=1; gizmo.disabled=true
 nativeTick(20); speedIs(20,'disabled Gizmo was updated')
 gizmo.disabled=false; gizmo.mobile.health.current=0
 nativeTick(20); speedIs(20,'dead Gizmo was updated')
 gizmo.mobile.health.current=100
 local savedPlayer=tes3.player; tes3.player=nil
 nativeTick(20); speedIs(20,'missing player was not handled')
 tes3.player=savedPlayer
 loaded(); speedIs(300,'loaded Follow save did not synchronize Speed')
 globals.mdFG_global_following.value=0; running.mdFG_script_AIGuard=true
 gizmo.mobile.speed={base=20,current=20}; gizmo.mobile.package={type=0}
 player.mobile.inCombat=true
 hook('AIGuard'); speedIs(300,'Guard entering Follow did not synchronize Speed')
 player.mobile.inCombat=false
 assert(not callbacks.calcMoveSpeed,'old movement-speed multiplier is still registered')
 hook('imperfectFight') -- Prune the invalid fixture actor after the reload before timing.
 print('PASS MWSE Speed +50: recruitment, native overwrites, player changes, Guard, and reload')

 -- Execute the actual MWSE callbacks around the native scale state machine.
 -- Morrowind's scale setter formats to two decimals; a plain Lua number would
 -- hide the lost per-frame increments that caused the reported stuck state.
 local storedScale, scaleWrites, nativeScaleWrites = 1, 0, 0
 setmetatable(gizmo, {
  __index=function(_, key) if key=='scale' then return storedScale end end,
  __newindex=function(ref, key, value)
   if key=='scale' then
    storedScale=tonumber(string.format('%.2f',value)); scaleWrites=scaleWrites+1
   else rawset(ref,key,value) end
  end,
 })
 gizmo.context={direction=0,tempscale=0,currscale=1,timer=0}
 local scaleGlobal=tes3.findGlobal('mdFG_global_scale')
 local function nativeScaleTick(dt)
  local c=gizmo.context
  if not c then return end
  c.timer=c.timer+dt
  if c.timer<0.1 then return end
  c.timer=0
  if scaleGlobal.value==101 then c.direction=1; scaleGlobal.value=102
  elseif scaleGlobal.value==51 then c.direction=-1; scaleGlobal.value=52 end
  if c.direction~=0 then
   c.tempscale=0.3*dt*c.direction
   gizmo.scale=gizmo.scale+c.tempscale; nativeScaleWrites=nativeScaleWrites+1
   c.currscale=gizmo.scale
   if c.direction==-1 and c.currscale<=0.5 then
    c.direction=0; c.tempscale=0; scaleGlobal.value=50
   elseif c.direction==1 and c.currscale>=1 then
    c.direction=0; c.tempscale=0; scaleGlobal.value=100
   end
  end
 end
 local function frame(dt, paused, nativeOnly)
  if paused then return end -- simulate and MWScript both pause in menus.
  if not nativeOnly then emit('simulate',{delta=dt}) end
  nativeScaleTick(dt)
  if not nativeOnly then nativeTick() end
 end
 local function resetScale(value, state, direction)
  storedScale=value; scaleGlobal.value=state
  gizmo.context={direction=direction or 0,tempscale=0,currscale=value,timer=0}
  loaded()
 end
 local function finishScale(fps, target)
  local elapsed=0
  while scaleGlobal.value~=target*100 and elapsed<2 do
   frame(1/fps); elapsed=elapsed+1/fps
   assert(gizmo.scale>=0.5 and gizmo.scale<=1,'scale overshot endpoint')
  end
  assert(scaleGlobal.value==target*100 and gizmo.scale==target,
   'scale transformation did not finish at '..target..' ('..fps..' FPS)')
  assert(gizmo.modified,'scale changes were not marked for saving')
  assert(gizmo.context.direction==0 and gizmo.context.tempscale==0,'native scaling remained active')
  local writes=scaleWrites
  for _=1,10 do frame(1/fps) end
  assert(scaleWrites==writes,'completed transformation kept writing scale')
  return elapsed
 end

 -- Reproduce the old MWScript failure, then recover the same in-process save.
 resetScale(1,51)
 for _=1,1440 do frame(1/144,false,true) end
 assert(gizmo.scale==1 and scaleGlobal.value==52 and gizmo.context.direction==-1,
  'fixture did not reproduce native reduction stuck in process')
 loaded(); nativeScaleWrites=0
 finishScale(144,0.5)
 assert(nativeScaleWrites==0,'MWScript competed with the MWSE transformation')
 for _,fps in ipairs({10,30,60,144,360}) do
  resetScale(1,51)
  local elapsed=finishScale(fps,0.5)
  assert(math.abs(elapsed-0.5/0.3)<=1/fps+0.00001,'shrink speed depends on frame rate')
  scaleGlobal.value=101
  elapsed=finishScale(fps,1)
  assert(math.abs(elapsed-0.5/0.3)<=1/fps+0.00001,'growth speed depends on frame rate')
 end
 for _,case in ipairs({{0.82,52,-1,0.5},{0.64,102,1,1},{1,52,-1,0.5},{0.5,102,1,1}}) do
  resetScale(case[1],case[2],case[3]); finishScale(144,case[4])
 end
 resetScale(1,51)
 for _=1,60 do frame(1/144) end
 local beforeReload=gizmo.scale
 loaded()
 assert(gizmo.scale==beforeReload,'reload restarted the scale animation')
 finishScale(144,0.5)
 resetScale(0.5,101)
 for _=1,60 do frame(1/144) end
 loaded(); finishScale(144,1)

 resetScale(1,51)
 for _=1,600 do frame(1/60,true) end
 assert(gizmo.scale==1 and scaleGlobal.value==51,'dialogue pause consumed request')
 frame(0.2)
 local pausedScale=gizmo.scale
 for _=1,600 do frame(1/60,true) end
 assert(gizmo.scale==pausedScale and scaleGlobal.value==52,'menu advanced scaling')
 finishScale(144,0.5)
 resetScale(1,51); frame(0.3)
 scaleGlobal.value=101; finishScale(144,1) -- A replacement request starts from current size.
 resetScale(1,51); frame(3)
 assert(gizmo.scale==0.5 and scaleGlobal.value==50,'long frame failed to clamp shrink')
 scaleGlobal.value=101; frame(3)
 assert(gizmo.scale==1 and scaleGlobal.value==100,'long frame failed to clamp growth')
 resetScale(1,51)
 for _,change in ipairs({'disabled','dead','mobile','context'}) do
  local savedMobile,savedContext=gizmo.mobile,gizmo.context
  if change=='disabled' then gizmo.disabled=true
  elseif change=='dead' then gizmo.mobile.health.current=0
  elseif change=='mobile' then gizmo.mobile=nil
  else gizmo.context=nil end
  frame(0.5)
  assert(gizmo.scale==1 and (scaleGlobal.value==51 or scaleGlobal.value==52),'unavailable Gizmo scaled')
  gizmo.disabled=false; gizmo.mobile=savedMobile; gizmo.mobile.health.current=100; gizmo.context=savedContext
 end
 finishScale(144,0.5)
 -- No actor lookup or writes are needed for idle transformation states.
 local getReference=tes3.getReference
 tes3.getReference=function() error('idle scaling looked up a reference') end
 emit('simulate',{delta=1/60})
 tes3.getReference=getReference
 resetScale(1,51)
 tes3.getReference=function() return nil end
 emit('simulate',{delta=1/60})
 assert(scaleGlobal.value==51,'missing reference lost pending request')
 tes3.getReference=getReference; finishScale(144,0.5)
 assert(not overrides.mdFG_script_gizmo,'shared native controller was replaced')
 hook('imperfectFight') -- Prune the invalid fixture actor rebuilt by reload checks.
 print('PASS MWSE scale: native stall reproduced; shrink/grow at 10-360 FPS, saved requests, reload, pause, and endpoints')
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
