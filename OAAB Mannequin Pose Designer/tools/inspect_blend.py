"""Run with Blender --background --factory-startup --disable-autoexec FILE --python THIS.
Reads the reference without evaluating embedded scripts or saving the blend file.
"""
import bpy
import json
from pathlib import Path

def tes3_name(name):
    for suffix,side in ((".L","L"),(".R","R")):
        if name.endswith(suffix) and name.startswith("Bip01 "):
            return "Bip01 "+side+" "+name[6:-2]
    return name

data={"source":"arp-body_retargeted.blend","armatures":[],"tes3_bones":[],"ik_constraints":[]}
for obj in bpy.data.objects:
    if obj.type!='ARMATURE': continue
    data['armatures'].append({"name":obj.name,"bone_count":len(obj.pose.bones)})
    for bone in obj.pose.bones:
        if obj.name=='Bip01':
            data['tes3_bones'].append({"blender":bone.name,"tes3":tes3_name(bone.name),"parent":tes3_name(bone.parent.name) if bone.parent else 'Bip01'})
        for constraint in bone.constraints:
            if constraint.type=='IK':
                data['ik_constraints'].append({"armature":obj.name,"bone":bone.name,"target":constraint.subtarget,"pole":constraint.pole_subtarget,"chain_length":constraint.chain_count,"pole_angle":constraint.pole_angle})
out=Path(__file__).resolve().parents[1]/'docs'/'rig_reference.json'
out.parent.mkdir(exist_ok=True)
out.write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
print(f'Inspected {len(data["tes3_bones"])} TES3 bones and {len(data["ik_constraints"])} IK constraints; wrote {out}')
