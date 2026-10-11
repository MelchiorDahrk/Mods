"""Run the real Lua viewer against actual NIF graphs/weights, without the game.

Native graph operations/UI are a fixture. The body, skeletons, visibility flags,
vertices, weights and skin deformation come from the installed files, read by
PyFFI. This can establish assembly/framing, not the engine's final UI image.
"""
from pathlib import Path
import hashlib
import math
import os
import sys

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / 'tools'))
sys.path.insert(0, str(ROOT / '.work/lua-test-deps'))
from read_preview_models import N, NiCollisionSwitch, load, rotation, set_transform
from lupa.luajit21 import LuaRuntime

MESHES = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('D:/Games/Morrowind/Data Files/meshes')
os.chdir(ROOT)
lua = LuaRuntime(encoding=None, unpack_returned_tuples=True)
lua.execute(b'''
    package.path='./MWSE/mods/?.lua;'..package.path
    tes3={uiEvent={destroy='destroy'}}
    fixture=dofile('tests/preview_fixture.lua').install()
    mwse={log=function(...) print(string.format(...)) end}
    function canvasParent()
        local p={}
        function p:updateLayout() end
        function p:createNif(args)
            assert(args.path=='pose/h/pose_preview.nif')
            local canvas=assert(io.open('meshes/'..args.path,'rb'),'UI path must resolve beneath Meshes')
            canvas:close()
            local e={events={}}
            function e:register(name,fn) self.events[name]=fn end
            function e:destroy() if self.events.destroy then self.events.destroy() end end
            return fixture.canvas(e)
        end
        return p
    end
''')
fixture = lua.globals().fixture
node_factory = fixture[b'node']
vector = lua.globals().tes3vector3[b'new']
matrix = lua.globals().tes3matrix33[b'new']
assemblies = []
hashes = {}

def read_mesh(file, cache):
    assert cache is False, 'Viewer must bypass the native mesh cache'
    path = MESHES / file.decode()
    hashes.setdefault(path, hashlib.sha256(path.read_bytes()).digest())
    data = load(path)
    nodes = {}
    for block in data.blocks:
        if isinstance(block, N.NiAVObject):
            kind = b'NiCollisionSwitch' if isinstance(block, NiCollisionSwitch) else b'NiNode' if isinstance(block, N.NiNode) else b'NiTriShape'
            native = node_factory(kind)
            native[b'name'] = block.name
            native[b'translation'] = vector(*block.translation.as_list())
            native[b'rotation'] = matrix(*rotation(block))
            native[b'scale'] = block.scale
            native[b'appCulled'] = bool(block.flags & 1)
            if kind == b'NiCollisionSwitch': native[b'collisionActive'] = False
            nodes[id(block)] = native
    for block in data.blocks:
        if isinstance(block, N.NiNode):
            parent = nodes[id(block)]
            for child in block.children:
                if child: parent[b'attachChild'](parent, nodes[id(child)])
    for block in data.blocks:
        if isinstance(block, N.NiGeometry):
            def deform(geometry=block):
                for item in data.blocks:
                    if isinstance(item, N.NiAVObject): set_transform(item, nodes[id(item)])
                vertices, _ = geometry.get_skin_deformation()
                return lua.table_from([lua.table_from(v.as_list()) for v in vertices])
            nodes[id(block)][b'deform'] = deform
    assemblies.append((file, data, nodes))
    return nodes[id(data.roots[0])]

lua.globals().tes3[b'loadMesh'] = read_mesh
def file_exists(file):
    relative = file.decode()[7:]
    base = ROOT / 'meshes' if relative == 'pose/h/pose_preview.nif' else MESHES
    return (base / relative).is_file()
lua.globals().tes3[b'getFileExists'] = file_exists
viewer = lua.eval(b'require("MannequinPoseDesigner.preview")')
files = ['oaab/k/' + name for name in ['mann_relax.nif', 'mann_contrapposto.nif', 'mann_adlocutio.nif', 'mann_adlocutio2.nif']]
files += ['pose/k/' + p.name for p in sorted((MESHES / 'pose/k').glob('*.nif')) if not p.name.lower().startswith('x')]
signatures = []
for name in files:
    before = len(assemblies)
    canvas, motion = viewer[b'create'](lua.globals().canvasParent(), name.encode(), 188, 210)
    assert len(assemblies) == before + 2, 'Viewer must load the pose and mannequin body'
    pose, body = assemblies[-2:]
    assert body[0] == b'oaab/b/mannequin.nif'
    source = {b.name.lower(): b for b in pose[1].blocks if isinstance(b, N.NiNode) and
              (b.name.lower() == b'bip01' or b.name.lower().startswith(b'bip01 ') or b.name.lower() in (b'weapon bone', b'shield bone'))}
    matched = 0
    for b in body[1].blocks:
        if isinstance(b, N.NiNode) and b.name.lower() in source:
            a = source[b.name.lower()]
            for x, y in zip(rotation(a) + a.translation.as_list() + [a.scale], rotation(b) + b.translation.as_list() + [b.scale]):
                assert math.isclose(x, y, abs_tol=1e-5), 'Body bones must reproduce the actual pose'
            matched += 1
    assert matched == len(source) == 35
    assert sum(b.data.num_vertices for b in body[1].blocks if isinstance(b, N.NiGeometry)) >= 5000
    view = canvas[b'sceneNode'][b'children'][1]
    assert 0 < view[b'scale'] < 100
    for _, data, nodes in (pose, body):
        root_node = nodes[id(data.roots[0])]
        assert root_node[b'controller'] is None
        for block in data.blocks:
            if isinstance(block, NiCollisionSwitch):
                assert not nodes[id(block)][b'collisionActive'], 'Visual collision switches must be restored after fitting'
    signatures.append(tuple(rotation(source[b'bip01 l upperarm']) + source[b'bip01 l hand'].translation.as_list()))
    canvas[b'destroy'](canvas)
    print(f'PASS: {name}: actual 35-bone pose/body assembly, skinned bounds and embedded geometry')
assert len(set(signatures[:4])) == 4, 'Stock poses must remain visually distinct'
for path, digest in hashes.items():
    assert hashlib.sha256(path.read_bytes()).digest() == digest, 'Preview browsing must not write source NIFs'
assert all(not next(iter(light[b'affected'].items()), None) for light in fixture[b'lights'].values())
print(f'PASS: real Lua viewer assembled {len(files)} installed poses; source hashes unchanged and light links released')
