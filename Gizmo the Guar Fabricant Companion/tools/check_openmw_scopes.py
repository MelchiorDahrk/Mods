"""Prove removable Combat interface ownership and migrate a real baseline save."""
from pathlib import Path
import argparse
import subprocess

from performance_openmw import CACHE, ENGINE, prepare
from run_openmw import run as run_engine


def create():
    run = prepare('control', 'guard', 0, False, ENGINE, 3, 1)
    # Keep this profile separate from performance timing runs.
    import shutil
    dest = CACHE / 'scope-check'
    if not dest.exists():
        shutil.copytree(run, dest)
    cfg = (run / 'openmw.cfg').read_text().replace(run.as_posix(), dest.as_posix())
    cfg = cfg.replace('content=FG performance.omwscripts', 'content=FG scope.omwscripts')
    (dest / 'openmw.cfg').write_text(cfg)
    (dest / 'FG scope.omwscripts').write_text('GLOBAL: scripts/scope_global.lua\nMENU: scripts/scope_menu.lua\nCREATURE: scripts/scope_helper.lua\nCUSTOM: scripts/scope_observer.lua\nCUSTOM: scripts/scope_other.lua\n')
    (dest / 'scripts/scope_observer.lua').write_text('''local core=require('openmw.core')
local self=require('openmw.self')
local interface={}
return {interfaceName='Combat',interface=interface,
 engineHandlers={onInterfaceOverride=function(base)
  for k,v in pairs(base) do interface[k]=v end
  interface.onHit=function(data)
   core.sendGlobalEvent('FGScopeDelivered',{actor=self.object})
   return base.onHit(data)
  end
 end},}
''')
    (dest / 'scripts/scope_other.lua').write_text('''local interface={}
return {interfaceName='Combat',interface=interface,
 engineHandlers={onInterfaceOverride=function(base)
  for k,v in pairs(base) do interface[k]=v end
  interface.onHit=function(data) return base.onHit(data) end
 end},}
''')
    (dest / 'scripts/scope_helper.lua').write_text('''local I=require('openmw.interfaces')
return {eventHandlers={FGScopeDirect=function(data) I.Combat.onHit(data) end}}
''')
    (dest / 'scripts/scope_global.lua').write_text('''local core=require('openmw.core')
local world=require('openmw.world')
local types=require('openmw.types')
local util=require('openmw.util')
local player, actor
local phase,cycle,deliveries,elapsed=0,0,0,0
local expected=0
local function hit(event) actor:sendEvent(event,{attacker=player,successful=true,strength=0,damage={health=0},sourceType='unspecified'}) end
local function check(v,s) assert(v,'FG TEST FAIL '..s); print('FG TEST PASS '..s) end
return {engineHandlers={
 onPlayerAdded=function(p)
  player=p; p:teleport(p.cell,util.vector3(0,0,40))
  types.Actor.spells(p):add('mdfg_ability_lev_real')
  actor=world.createObject('fg_perf_rat'); actor:teleport(p.cell,util.vector3(300,0,40))
  types.Actor.spells(actor):add('mdfg_ability_lev_real')
 end,
 onUpdate=function(dt)
  elapsed=elapsed+dt; if elapsed<0.03 then return end; elapsed=0
  if phase==0 then
   actor:addScript('scripts/scope_observer.lua')
   if not actor:hasScript('scripts/scope_other.lua') then actor:addScript('scripts/scope_other.lua') end
   phase=1
  elseif phase==1 then hit('FGScopeDirect'); expected=expected+1; phase=2
  elseif phase==2 then
   assert(deliveries==expected,'FG TEST FAIL duplicate/missing direct callback')
   hit('Hit'); expected=expected+1; phase=3
  elseif phase==3 then
   assert(deliveries==expected,'FG TEST FAIL duplicate/missing Hit event')
   actor:removeScript('scripts/scope_observer.lua'); phase=4
  elseif phase==4 then hit('FGScopeDirect'); hit('Hit'); phase=5
  elseif phase==5 then
   assert(deliveries==expected,'FG TEST FAIL callback survived removal')
   cycle=cycle+1
   if cycle<100 then phase=0
   else
    check(not actor:hasScript('scripts/scope_observer.lua'),'100 attach/detach cycles beneath another Combat interface: direct callbacks, Hit events, no retained deliveries')
    print('FG TEST COMPLETE scope ownership')
    types.Player.sendMenuEvent(player,'FGScopeQuit',{}); phase=6
   end
  end
 end,
},eventHandlers={FGScopeDelivered=function(data) if data.actor==actor then deliveries=deliveries+1 end end}}
''')
    (dest / 'scripts/scope_menu.lua').write_text("local menu=require('openmw.menu')\nreturn {eventHandlers={FGScopeQuit=function() menu.quit() end}}\n")
    return dest


def main():
    run = create()
    raise SystemExit(run_engine(ENGINE, run, timeout=45))


if __name__ == '__main__':
    main()
