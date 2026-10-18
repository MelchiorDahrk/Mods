"""Real-engine scope, stale-state, distant ally, native hit and churn regressions."""
import argparse
import shutil
from performance_openmw import CACHE, DATA, ENGINE, ROOT, prepare
from esp import records, encode_record, plugin
from run_openmw import run as run_engine


DRIVER = '''local core=require('openmw.core')
local world=require('openmw.world')
local types=require('openmw.types')
local util=require('openmw.util')
local player,gizmo,enemy,ally,victim,g
local phase,at,cycles,hits,mark=0,0,0,0,0
local enemyReports,nativeHit=0,false
local oldEpoch
local path='scripts/FabricantGuar/observer.lua'
local function check(v,s) assert(v,'FG TEST FAIL '..s); print('FG TEST PASS '..s) end
local function command(distance)
 g.mdfg_global_following=0; g.mdfg_global_foraging=distance==1800 and 1 or 0
 gizmo:sendEvent('StartAIPackage',{type='Wander',distance=distance})
end
local function nextPhase(value) phase=value; at=core.getSimulationTime() end
return {engineHandlers={
 onPlayerAdded=function(p)
  player=p; g=world.mwscript.getGlobalVariables()
  world.createObject('in_hlaalu_room_center'):teleport(p.cell,util.vector3(0,0,0))
  p:teleport(p.cell,util.vector3(0,0,40))
  gizmo=world.getObjectByFormId(core.getFormId('Fabricant Guar.ESP',1))
  gizmo:teleport(p.cell,util.vector3(200,0,40))
  enemy=world.createObject('fg_perf_rat'); enemy:teleport(p.cell,util.vector3(400,200,40))
  ally=world.createObject('fg_perf_guar'); ally:teleport(p.cell,util.vector3(12000,0,40))
  for _,a in ipairs({p,gizmo,enemy,ally}) do types.Actor.spells(a):add('mdfg_ability_lev_real') end
  ally:sendEvent('StartAIPackage',{type='Follow',target=p})
  g.mdfg_global_new=0; command(0)
  at=core.getSimulationTime()
 end,
 onUpdate=function(dt)
  if dt<=0 then return end
  local now=core.getSimulationTime(); local waited=now-at
  if waited>12 and phase~=99 then
   local failed=phase; phase=99
   types.Player.sendMenuEvent(player,'FGPerfQuit',{})
   error('FG TEST FAIL phase timeout '..failed)
  end
  local script=world.mwscript.getLocalScript(gizmo); if script then script.variables.timer=-10000 end
  if phase==0 and waited>2.5 then
   check(enemy:hasScript(path),'guard observes potential hit recipients')
   check(enemyReports==0,'unchanged empty actor produces no report replies')
   enemy:sendEvent('StartAIPackage',{type='Combat',target=ally}); nextPhase(1)
  elseif phase==1 and g.mdfg_global_following==1 then
   check((ally.position-player.position):length()>3000,'distant Follow ally retained after report TTL')
   check(waited<1,'distant ally assistance latency below one simulation second')
   print('FG LATENCY distant_ally '..waited)
   command(1800); nextPhase(2)
  elseif phase==2 and waited>1.5 then
   check(g.mdfg_global_following==0 and not enemy:hasScript(path),'Forage disables combat observers')
   enemy:sendEvent('StartAIPackage',{type='Wander',distance=0})
   gizmo:teleport(player.cell,util.vector3(3200,0,40)); command(0); nextPhase(3)
  elseif phase==3 and waited>0.75 then
   check(not enemy:hasScript(path),'Gizmo outside assistance radius leaves no observer')
   gizmo:teleport(player.cell,util.vector3(2900,0,40)); nextPhase(4)
  elseif phase==4 and enemy:hasScript(path) then
   check(true,'entering assistance radius restarts monitoring')
   core.sendGlobalEvent('FGHit',{actor=enemy,attacker=player,epoch=oldEpoch})
   core.sendGlobalEvent('FGCombatReport',{actor=enemy,targets={player},allied=false,epoch=oldEpoch})
   core.sendGlobalEvent('FGGuardFollowing',{actor=gizmo,epoch=oldEpoch})
   gizmo:sendEvent('FGAssist',{player=player,epoch=oldEpoch})
   nextPhase(40)
  elseif phase==40 and waited>0.75 then
   check(g.mdfg_global_following==0,'stale reports, hits, assistance and acknowledgements cannot override a later command')
   gizmo:teleport('FG unrelated laboratory',util.vector3(0,0,40)); nextPhase(5)
  elseif phase==5 and waited>0.75 then
   check(not enemy:hasScript(path),'unrelated interior disables monitoring')
   gizmo:teleport(player.cell,util.vector3(200,0,40)); nextPhase(6)
  elseif phase==6 and enemy:hasScript(path) then
   enemy:teleport(player.cell,util.vector3(5000,0,40))
   enemy:sendEvent('FGBehaviorDirect',{attacker=player}); nextPhase(7)
  elseif phase==7 and g.mdfg_global_following==1 then
   check(waited<0.5,'direct Combat.onHit and long-range player hit still assist')
   print('FG LATENCY direct_hit '..waited)
   enemy:sendEvent('StartAIPackage',{type='Wander',distance=0})
   nextPhase(8)
  elseif phase==8 and not enemy:hasScript(path) then
   command(0); nextPhase(9)
  elseif phase==9 and enemy:hasScript(path) then
   mark=hits
   enemy:sendEvent('FGBehaviorDirect',{attacker=player})
   nextPhase(10)
  elseif phase==10 and g.mdfg_global_following==1 and not enemy:hasScript(path) then
   check(hits==mark+1,'one direct callback in mode cycle '..(cycles+1))
   cycles=cycles+1
   enemy:sendEvent('StartAIPackage',{type='Wander',distance=0})
   if cycles<CYCLE_COUNT then nextPhase(8)
   else
    check(not player:hasScript(path) and not gizmo:hasScript(path),CYCLE_COUNT..' cycles leave no scoped observers')
    -- Drive Player's native weapon animation; this does not depend on the
    -- navigation/attack choices of a levitating laboratory creature.
    enemy.enabled=false
    player:teleport(player.cell,util.vector3(0,0,40),util.transform.rotateZ(0))
    victim=world.createObject('fg_perf_guar')
    victim:teleport(player.cell,util.vector3(0,100,40))
    types.Actor.spells(victim):add('mdfg_ability_lev_real')
    world.createObject('iron dagger'):moveInto(player)
    nextPhase(110)
   end
  elseif phase==110 and waited>0.25 then
   victim:addScript(path,{player=player,epoch=999999})
   victim:sendEvent('FGBehaviorPassive',{})
   player:sendEvent('FGBehaviorAttack',{})
   nextPhase(11)
  elseif phase==11 and nativeHit then
   check(true,'native player melee traverses scoped Combat interface')
   player:sendEvent('FGBehaviorStop',{})
   victim:removeScript(path)
   victim.enabled=false
   nextPhase(12)
  elseif phase==12 and waited>0.75 then
   check(not player:hasScript(path) and not victim:hasScript(path),'native-hit observer removes cleanly')
   print('FG TEST COMPLETE scoped behavior and '..CYCLE_COUNT..' mode transitions')
   types.Player.sendMenuEvent(player,'FGPerfQuit',{})
   nextPhase(13)
  end
 end,
},eventHandlers={
 FGCombatReport=function(data)
  if not oldEpoch then oldEpoch=data.epoch end
  if data.actor==enemy then enemyReports=enemyReports+1 end
 end,
 FGHit=function(data)
  if data.actor==enemy then hits=hits+1 end
  if data.actor==victim and data.epoch==999999 then nativeHit=true end
 end,
}}
'''


def main():
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument('--cycles', type=int, default=100)
    parser.add_argument('--threads', type=int, choices=(0, 1), default=0)
    args = parser.parse_args()
    source = prepare('candidate', 'guard', 0, False, ENGINE, 3, 1)
    dest = CACHE / 'behavior'
    dest.mkdir(parents=True, exist_ok=True)
    for name in ('FG performance.esp', 'settings.cfg'):
        shutil.copy2(source / name, dest / name)
    settings = dest / 'settings.cfg'
    settings.write_text(settings.read_text().replace('lua num threads = 0', f'lua num threads = {args.threads}'))
    shutil.copytree(source / 'mod', dest / 'mod', dirs_exist_ok=True)
    (dest / 'scripts').mkdir(exist_ok=True)
    body = [encode_record(t, fs, u, f) for t, fs, u, f in records(source / 'FG performance.esp') if t != b'TES3']
    import struct
    body.append(encode_record(b'CELL', [(b'NAME', b'FG unrelated laboratory\0'),
                                      (b'DATA', struct.pack('<III', 1, 0, 0))]))
    plugin(dest / 'FG performance.esp', body, [DATA / 'Morrowind.esm', ROOT / '00 Core/Fabricant Guar.ESP'])
    cfg = (source / 'openmw.cfg').read_text().replace(source.as_posix(), dest.as_posix())
    cfg = cfg.replace('content=FG performance.omwscripts', 'content=FG behavior.omwscripts')
    (dest / 'openmw.cfg').write_text(cfg)
    (dest / 'FG behavior.omwscripts').write_text('GLOBAL: scripts/behavior_global.lua\nPLAYER,CREATURE: scripts/behavior_actor.lua\nMENU: scripts/perf_menu.lua\n')
    (dest / 'scripts/perf_menu.lua').write_text("local menu=require('openmw.menu')\nreturn {eventHandlers={FGPerfQuit=function() menu.quit() end}}\n")
    (dest / 'scripts/behavior_actor.lua').write_text('''local self=require('openmw.self')
local types=require('openmw.types')
local I=require('openmw.interfaces')
local attack,elapsed=false,0
return {engineHandlers={onActive=function()
 local h=types.Actor.stats.dynamic.health(self); h.base=1000000; h.current=1000000
end,onFrame=types.Player.objectIsInstance(self) and function(dt)
 if not attack then return end
 elapsed=elapsed+dt
 types.Actor.setStance(self,types.Actor.STANCE.Weapon)
 self.controls.use=(elapsed%1.5<0.6) and 1 or 0
end or nil},eventHandlers={FGBehaviorDirect=function(data)
 I.Combat.onHit({attacker=data.attacker,successful=true,strength=0,damage={health=0},sourceType='unspecified'})
end,
FGBehaviorPassive=function() self:enableAI(false) end,
FGBehaviorAttack=function()
 types.Actor.setEquipment(self,{[types.Actor.EQUIPMENT_SLOT.CarriedRight]='iron dagger'})
 attack=true; elapsed=0
end,
FGBehaviorStop=function() attack=false; self.controls.use=0 end,
}}
''')
    (dest / 'scripts/behavior_global.lua').write_text(f'local CYCLE_COUNT={args.cycles}\n'+DRIVER)
    raise SystemExit(run_engine(ENGINE, dest, timeout=100))


if __name__ == '__main__':
    main()
