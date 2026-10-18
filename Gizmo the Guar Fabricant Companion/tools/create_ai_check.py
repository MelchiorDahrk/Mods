"""Native activation, AI, command, and load checks in the isolated laboratory."""
from pathlib import Path
import create_gameplay_check as base
from esp import records, encode_record, plugin

ROOT, RUN = base.ROOT, base.RUN
cell = next(encode_record(t, fs, u, f) for t, fs, u, f in records(RUN / 'FG tests.esp') if t == b'CELL')
plugin(RUN / 'FG tests.esp', [cell], [ROOT / '00 Core/Fabricant Guar.ESP'])
(RUN / 'scripts/gameplay_actor.lua').write_text('''local self = require('openmw.self')
local types = require('openmw.types')
local I = require('openmw.interfaces')
local core = require('openmw.core')
return { engineHandlers = { onActive = function()
 local h = types.Actor.stats.dynamic.health(self); h.base = 1000000; h.current = 1000000
end }, eventHandlers = {
 FGTestHit = function(data)
  I.Combat.onHit({ attacker=data.attacker, successful=true, strength=0, damage={health=0}, sourceType='unspecified' })
 end,
 FGTestInspect = function()
  local p = I.AI.getActivePackage()
  local followingPlayer, forage = false, false
  I.AI.forEachPackage(function(package)
   if package.type=='Wander' and package.distance==1800 then forage=true end
  end)
  for _, target in ipairs(I.AI.getTargets('Follow')) do
   if types.Player.objectIsInstance(target) then followingPlayer = true end
  end
  core.sendGlobalEvent('FGTestInspected', { actor = self.object, type = p and p.type, target = p and p.target, distance = p and p.distance, followingPlayer = followingPlayer, forage = forage })
 end,
} }
''')
(RUN / 'scripts/gameplay_player.lua').write_text('''local I = require('openmw.interfaces')
local types = require('openmw.types')
local self = require('openmw.self')
return { engineHandlers = { onActive = function()
 local h = types.Actor.stats.dynamic.health(self); h.base = 1000000; h.current = 1000000
end, onFrame = function()
 if I.UI.getMode() == 'Dialogue' then print('FG TEST ordinary activation opened dialogue'); I.UI.setMode(nil) end
end }, eventHandlers = {
 FGTestEquip = function() types.Actor.setEquipment(self, { [types.Actor.EQUIPMENT_SLOT.CarriedRight] = 'mdfg_w_collector' }) end,
} }
''')
(RUN / 'scripts/gameplay_test.lua').write_text('''local world = require('openmw.world')
local core = require('openmw.core')
local types = require('openmw.types')
local util = require('openmw.util')
local player, gizmo, guar, imperfect, ally, enemy, g
local stage, elapsed = 0, 0
local inspected = {}
local reloaded = false
local function msg(s) print('FG TEST ' .. s) end
local function check(value, name) if not value then types.Player.sendMenuEvent(player,'FGTestQuit',{}); error('FG TEST FAIL ' .. name) end; msg('PASS ' .. name) end
local function inspect(actor) actor:sendEvent('FGTestInspect', {}) end
return { engineHandlers = {
 onSave = function() return { stage=stage, gizmo=gizmo, guar=guar, imperfect=imperfect, enemy=enemy } end,
 onLoad = function(data) stage,gizmo,guar,imperfect,enemy=data.stage,data.gizmo,data.guar,data.imperfect,data.enemy; reloaded=true; msg('loaded guard save') end,
 onPlayerAdded = function(p)
  player=p; g=world.mwscript.getGlobalVariables()
  if reloaded then return end
  world.createObject('in_hlaalu_room_center'):teleport(p.cell, util.vector3(0,0,0))
  p:teleport(p.cell,util.vector3(0,0,40))
  gizmo=world.getObjectByFormId(core.getFormId('Fabricant Guar.ESP',1))
  gizmo:teleport(p.cell,util.vector3(200,0,40))
  -- The normal post-summon greeting clears this flag. It is not an unlock.
  g.mdfg_global_new=0
  guar=world.createObject('guar'); guar:teleport(p.cell,util.vector3(-200,0,40))
  -- This empty test cell has no guaranteed floor collision. Suspend actors
  -- using the mod's own ability so distance checks are deterministic.
  for _, actor in ipairs({p, gizmo, guar}) do types.Actor.spells(actor):add('mdfg_ability_lev_real') end
  world.createObject('mdfg_w_collector'):moveInto(p)
 end,
 onUpdate = function(dt)
  elapsed=elapsed+dt
  if elapsed < 0.65 then return end
  elapsed=0
  if stage==0 then
   world.mwscript.getLocalScript(gizmo).variables.timer=-10000
   guar:activateBy(player); stage=1
  elseif stage==1 then
   check(g.mdfg_global_sample_guar==0,'no sample without collector equipped')
   player:sendEvent('FGTestEquip',{}); stage=2
  elseif stage==2 then guar:activateBy(player); stage=3
  elseif stage==3 then
   check(g.mdfg_global_sample_guar==1,'native activation samples equipped collector')
   g.mdfg_global_following=1; g.mdfg_global_muskatomizer=1; stage=4
  elseif stage==4 then inspect(guar); stage=5
  elseif stage==5 then
   check(inspected[guar.id].type=='Follow' and inspected[guar.id].target==player,'atomizer enabled during Follow')
   g.mdfg_global_following=0; g.mdfg_global_foraging=0
   gizmo:sendEvent('StartAIPackage',{type='Wander',distance=800})
   stage=6
  elseif stage==6 then
   enemy=world.createObject('rat'); enemy:teleport(player.cell,util.vector3(-200,200,40))
   types.Actor.spells(enemy):add('mdfg_ability_lev_real')
   enemy:sendEvent('StartAIPackage',{type='Combat',target=player}); stage=60
  elseif stage==60 then
   -- A newly active actor needs a report interval plus the controller tick.
   stage=7
  elseif stage==7 then inspect(gizmo); stage=8
  elseif stage==8 then
   check(g.mdfg_global_new==0 and g.mdfg_global_following==1 and inspected[gizmo.id].followingPlayer,'patrol joins rat combat after greeting')
   g.mdfg_global_following=0; g.mdfg_global_foraging=0
   gizmo:sendEvent('StartAIPackage',{type='Wander',distance=0})
   enemy:sendEvent('RemoveAIPackages','Combat'); stage=81
  elseif stage==81 then
   enemy:sendEvent('FGTestHit',{attacker=player}); stage=82
  elseif stage==82 then inspect(gizmo); stage=83
  elseif stage==83 then
   check(g.mdfg_global_following==1 and inspected[gizmo.id].followingPlayer,'player-initiated hit callback joins combat (injected hit)')
   g.mdfg_global_following=0
   gizmo:sendEvent('StartAIPackage',{type='Wander',distance=0}); stage=84
  elseif stage==84 then
   enemy:sendEvent('StartAIPackage',{type='Combat',target=player}); stage=841
  elseif stage==841 then stage=85
  elseif stage==85 then inspect(gizmo); stage=86
  elseif stage==86 then
   check(g.mdfg_global_new==0 and g.mdfg_global_following==1 and inspected[gizmo.id].followingPlayer,'guard joins rat combat after greeting')
   g.mdfg_global_following=0; g.mdfg_global_foraging=1
   gizmo:sendEvent('StartAIPackage',{type='Wander',distance=1800}); stage=9
  elseif stage==9 then inspect(gizmo); stage=10
  elseif stage==10 then
    msg('Forage inspection: flag='..g.mdfg_global_foraging..' active='..tostring(inspected[gizmo.id].type)..' distance='..tostring(inspected[gizmo.id].distance)..' retained='..tostring(inspected[gizmo.id].forage)..' following='..tostring(inspected[gizmo.id].followingPlayer))
    -- Native Combat may temporarily sit above Wander; assistance must neither
    -- erase the Forage command nor insert Follow over it.
    check(g.mdfg_global_foraging==1 and inspected[gizmo.id].forage and not inspected[gizmo.id].followingPlayer,'Forage command survives combat reports')
   enemy:sendEvent('RemoveAIPackages','Combat'); enemy.enabled=false
   guar:teleport(player.cell,util.vector3(-200,0,40))
   g.mdfg_global_imperfect=1
   imperfect=world.createObject('mdfg_imperfect'); imperfect:teleport(player.cell,util.vector3(-210,0,40))
   types.Actor.spells(imperfect):add('mdfg_ability_lev_real')
   stage=11
  elseif stage==11 then inspect(imperfect); stage=12
  elseif stage==12 then
   check(inspected[imperfect.id].type=='Combat' and inspected[imperfect.id].target==guar,'Imperfect nearest valid target')
   guar.enabled=false; stage=13
  elseif stage==13 then inspect(imperfect); stage=14
  elseif stage==14 then
   check(inspected[imperfect.id].type=='Combat' and inspected[imperfect.id].target~=guar,'Imperfect replaces disabled target')
   imperfect.enabled=false; g.mdfg_global_imperfect=0
   g.mdfg_global_following=0; g.mdfg_global_foraging=0
   gizmo:sendEvent('StartAIPackage',{type='Wander',distance=0})
   ally=world.createObject('guar'); ally:teleport(player.cell,util.vector3(100,100,40))
   types.Actor.spells(ally):add('mdfg_ability_lev_real')
   ally:sendEvent('StartAIPackage',{type='Follow',target=player})
   enemy.enabled=true; stage=141
  elseif stage==141 then
   enemy:sendEvent('StartAIPackage',{type='Combat',target=ally}); stage=1411
  elseif stage==1411 then stage=142
  elseif stage==142 then inspect(gizmo); stage=143
  elseif stage==143 then
   check(g.mdfg_global_following==1 and inspected[gizmo.id].followingPlayer,'guard joins combat targeting player ally')
   g.mdfg_global_following=0
   gizmo:sendEvent('StartAIPackage',{type='Wander',distance=0})
   stage=15
  elseif stage==15 then
   stage=16
   types.Player.sendMenuEvent(player,'FGTestSaveReload',{})
  elseif stage==16 and reloaded then
   enemy.enabled=true
   enemy:sendEvent('StartAIPackage',{type='Combat',target=player}); stage=161
  elseif stage==161 then stage=17
  elseif stage==17 then inspect(gizmo); stage=18
  elseif stage==18 then
   check(g.mdfg_global_following==1 and inspected[gizmo.id].followingPlayer,'guard state and combat monitoring rebuilt after load')
   msg('COMPLETE AI integration test')
   types.Player.sendMenuEvent(player,'FGTestQuit',{}); stage=19
  end
 end,
}, eventHandlers = { FGTestInspected = function(data) inspected[data.actor.id]=data end } }
''')
# Allow enough time for the sequential AI states.
p=RUN / 'scripts/test_menu.lua'
p.write_text(p.read_text().replace('> 16', '> 30').replace("'FG mid-revival'", "'FG guard state'"))
print('AI profile generated:', RUN)
