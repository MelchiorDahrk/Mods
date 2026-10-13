"""Exercise capture, draft export, import and skinning with both authored bodies.

The native scene API is a fixture; PyFFI reads the actual graphs and skin weights.
This verifies file compatibility, not live actor assembly or the game's renderer.
"""
from pathlib import Path
import hashlib
import math
import os
import sys

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / 'tools'))
from read_preview_models import N, NiCollisionSwitch, load, rotation, set_transform
from run_lua_tests import create_runtime

oaab_root = Path(globals().get('OAAB_ROOT', ROOT.parent.parent / 'OAAB_Data'))
race_root = ROOT.parent / 'OAAB Mannequin Race'
if __name__ == '__main__':
    if len(sys.argv) > 1: oaab_root = Path(sys.argv[1])
    if len(sys.argv) > 2: race_root = Path(sys.argv[2])
models = [base / '00 Core/meshes/oaab/b/mannequin.nif' for base in (oaab_root, race_root)]
hashes = {path: hashlib.sha256(path.read_bytes()).digest() for path in models}
lua = create_runtime()
lua.execute(b'''
    package.path='./MWSE/mods/?.lua;'..package.path
    tes3={}
    fixture=dofile('tests/preview_fixture.lua').install()
    tes3.niType.NiKeyframeController='NiKeyframeController'
    rig=require('MannequinPoseDesigner.rig')
    library=require('MannequinPoseDesigner.library')
    blend=require('MannequinPoseDesigner.blend')
    previewScene=require('MannequinPoseDesigner.preview_scene')
    math3d=require('MannequinPoseDesigner.math3d')
    function edit(bones)
        for _,bone in ipairs(bones) do
            if bone.name=='Bip01 Spine2' or bone.name=='Bip01 L UpperArm' then
                bone.rotation=math3d.mul(bone.rotation,math3d.axisAngle({0,1,0},0.4))
            end
        end
    end
''')
rig, library = lua.globals().rig, lua.globals().library
node_factory = lua.globals().fixture[b'node']
vector, matrix = lua.globals().tes3vector3[b'new'], lua.globals().tes3matrix33[b'new']
work = ROOT / '.work/mannequin-variants'
work.mkdir(parents=True, exist_ok=True)
library[b'templateRoot'] = os.fsencode(ROOT / 'MWSE/mods/MannequinPoseDesigner/templates')
assemblies = []
current_body = models[0]

def read_mesh(file, cache):
    assert cache is False
    path = current_body if file == b'oaab/b/mannequin.nif' else (
        oaab_root / '00 Core/meshes' / os.fsdecode(file) if file.startswith(b'oaab/')
        else work / 'Data Files/meshes' / os.fsdecode(file))
    data = load(path)
    nodes = {}
    for block in data.blocks:
        if not isinstance(block, N.NiAVObject): continue
        kind = b'NiCollisionSwitch' if isinstance(block, NiCollisionSwitch) else (
            b'NiNode' if isinstance(block, N.NiNode) else b'NiTriShape')
        native = node_factory(kind)
        native[b'name'] = block.name
        native[b'translation'] = vector(*block.translation.as_list())
        native[b'rotation'] = matrix(*rotation(block))
        native[b'scale'] = block.scale
        native[b'appCulled'] = bool(block.flags & 1)
        native[b'controller'] = lua.eval(b"function(kind) return kind and {isInstanceOfType=function(_,wanted) return wanted==kind end} end")(
            b'NiKeyframeController' if isinstance(block.controller, N.NiKeyframeController) else None)
        nodes[id(block)] = native
    for block in data.blocks:
        if isinstance(block, N.NiNode):
            parent = nodes[id(block)]
            for child in block.children:
                if child: parent[b'attachChild'](parent, nodes[id(child)])
    assemblies.append((data, nodes))
    return nodes[id(data.roots[0])]

lua.globals().tes3[b'loadMesh'] = read_mesh
lua.globals().tes3[b'getFileExists'] = lambda file: True

def signature(bones):
    return [(b[b'name'], b[b'parent'], list(b[b'translation'].values()),
             list(b[b'rotation'].values()), b[b'scale']) for b in bones.values()]

def compare(a, b):
    assert len(a) == len(b) == 35
    for left, right in zip(a.values(), b.values()):
        assert left[b'name'] == right[b'name'] and left[b'parent'] == right[b'parent']
        for field in (b'translation', b'rotation'):
            assert all(math.isclose(x, y, abs_tol=2e-5) for x, y in
                       zip(left[field].values(), right[field].values()))
        assert math.isclose(left[b'scale'], right[b'scale'], abs_tol=2e-5)

captured, bundles = [], []
try:
    os.chdir(work)
    for model in models:
        current_body = model
        body = read_mesh(b'oaab/b/mannequin.nif', False)
        bones, _ = rig[b'capture'](body)
        assert len(bones) == 35
        captured.append(signature(bones))
        geometries = [block for block in assemblies[-1][0].blocks if isinstance(block, N.NiGeometry)]
        assert len(geometries) == (35 if model == models[1] else 34)
        neck = next((block for block in geometries if block.name == b'Tri Neck'), None)
        if model == models[1]:
            assert neck and neck.skin_instance, 'Separated neck retains its skin'
            baseline, _ = neck.get_skin_deformation()
            baseline = [vertex.as_list() for vertex in baseline]
        # The editor's initial draft must save before any edits occur.
        initial = library[b'write'](bones, None, lua.table())
        compare(bones, library[b'read'](initial))
        lua.globals().edit(bones)
        saved = library[b'write'](bones, None, lua.table())
        imported = library[b'read'](saved)
        compare(bones, imported)
        path = work / 'Data Files/meshes' / os.fsdecode(saved)
        bundles.append(tuple(p.read_bytes() for p in
                             (path, path.with_name('x' + path.name),
                              path.with_name('x' + path.stem + '.kf'))))
        # Stock blends align with either body using the real hierarchies.
        for name in ('mann_relax', 'mann_contrapposto', 'mann_adlocutio', 'mann_adlocutio2'):
            aligned = lua.globals().blend[b'align'](library[b'read'](f'oaab/k/{name}.nif'.encode()), bones)
            assert len(aligned) == 35
        _, info = lua.globals().previewScene[b'build'](saved)
        preview_bones, _ = rig[b'capture'](info[b'body'])
        compare(imported, preview_bones)
        data, nodes = assemblies[-1]
        for block in data.blocks:
            if isinstance(block, N.NiAVObject): set_transform(block, nodes[id(block)])
        if model == models[1]:
            neck = next(block for block in data.blocks if isinstance(block, N.NiGeometry) and block.name == b'Tri Neck')
            posed, _ = neck.get_skin_deformation()
            assert len(posed) == len(baseline)
            assert all(math.isfinite(value) for vertex in posed for value in vertex.as_list())
            assert any(abs(x-y) > 0.1 for vertex, original in zip(posed, baseline)
                       for x,y in zip(vertex.as_list(), original)), 'Separated neck follows upper-body posing'
        print(f'PASS: {model}: 35-bone capture, initial/edited draft round trips, four stock blends and posed body')
    assert captured[0] == captured[1], 'Both bodies have identical skeletal transforms and parent relationships'
    assert bundles[0] == bundles[1], 'Either body produces the same portable NIF/xNIF/KF pose bundle'
    for path, digest in hashes.items():
        assert hashlib.sha256(path.read_bytes()).digest() == digest, 'Source mannequin meshes remain unchanged'
    print('PASS: both mannequin variants share portable poses; separate neck skin follows the pose; source files unchanged')
finally:
    os.chdir(ROOT)
