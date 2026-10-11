"""Verify the authored TES3 hierarchy, bone marker and six interactive axes."""
import hashlib
import math
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT/'tools'))
from nif_geometry import read, shapes

path = ROOT/'meshes/pose/h/gizmo.nif'
assert hashlib.sha256(path.read_bytes()).hexdigest() == '93d411bbf5f0789067ddadddcef5bcbd52999772b4ae5c006b6ca259facaf572', 'The authored mesh was modified'
blocks, roots = read(path)
assert len(blocks) == 27 and len(roots) == 1
root = blocks[roots[0]]
assert root['translation'] == (0,0,0) and root['scale'] == 1
assert len(root['children']) == 2
assert blocks[root['children'][1]]['name'] == 'node'
vertex, fog = [blocks[i] for i in root['properties']]
assert vertex['type'] == 'NiVertexColorProperty' and vertex['vertex_mode'] == vertex['lighting_mode'] == 0
assert fog['type'] == 'NiFogProperty' and fog['flags'] == 0
rotate = blocks[root['children'][0]]
assert rotate['type'] == 'NiSortAdjustNode' and rotate['name'] == 'rotate'
assert math.isclose(rotate['scale'], .2, abs_tol=1e-7) and len(rotate['children']) == 7
assert [blocks[i]['name'] for i in rotate['children'][1:]] == ['X','Y','Z','X_move','Y_move','Z_move']
assert rotate['sorting_mode'] == 64
assert blocks[rotate['properties'][0]]['type'] == 'NiAlphaProperty'
assert blocks[rotate['properties'][0]]['flags'] == 0
assert blocks[rotate['sub_sorter']]['type'] == 'NiAlphaAccumulator'
collision = blocks[rotate['children'][0]]
assert collision['type'] == 'NiCollisionSwitch'
assert collision['flags'] == 0
assert blocks[collision['children'][0]]['name'] == 'sphere'
entries = shapes(path)
assert {s['name'] for s,_,_ in entries} == {'X','Y','Z','X_move','Y_move','Z_move','sphere','node'} and len(entries) == 8
by_name = {s['name']: s for s,_,_ in entries}
assert all(by_name[axis]['properties'] == by_name[axis+'_move']['properties'] for axis in 'XYZ'), 'Arrows and rings share their authored axis materials'
assert len({s['data'] for s,_,_ in entries if s['name'] in 'XYZ'}) == 1, 'Rings share data and use node rotations'
for shape, data, properties in entries:
    name = shape['name']; moving = name.endswith('_move'); masking = name == 'sphere'; marker = name == 'node'
    assert shape['controller'] == shape['extra'] == shape['skin'] == -1
    assert shape['translation'] == shape['world']['translation'] == (0,0,0)
    assert len(data['vertices']) == (240 if marker else 550 if masking else 42 if moving else 608)
    assert len(data['normals']) == (0 if marker else len(data['vertices']))
    assert len(data['triangles']) == (80 if marker else 972 if masking else 22 if moving else 1152)
    assert len(data['uv_sets']) == (0 if marker else 1) and not data['colors']
    for vector in data['vertices'] + data['normals']:
        assert all(math.isfinite(value) for value in vector)
    for triangle in data['triangles']:
        assert all(0 <= index < len(data['vertices']) for index in triangle)
    for vertex in data['vertices']:
        assert sum((a-b)**2 for a,b in zip(vertex,data['center'])) <= data['radius']**2 * 1.000001
    if marker:
        assert shape['scale'] == shape['world']['scale'] == 2 and data['center'] == (0,0,0)
        assert math.isclose(data['radius'], 1, abs_tol=1e-6)
        assert len(properties) == 1 and properties[0]['type'] == 'NiMaterialProperty'
        assert properties[0]['diffuse'] == properties[0]['emissive'] == (1,1,1) and properties[0]['alpha'] == 1
        continue
    if masking:
        assert math.isclose(shape['world']['scale'], .19, abs_tol=1e-7)
        assert [p['type'] for p in properties] == ['NiMaterialProperty','NiAlphaProperty']
        assert properties[0]['alpha'] == 0 and properties[1]['flags'] == 1
        continue
    axis = 'XYZ'.index(name[0])
    transform = shape['world']; r = transform['rotation']; scale = transform['scale']
    vertices = [tuple(scale*sum(r[3*i+j]*p[j] for j in range(3)) for i in range(3)) for p in data['vertices']]
    extents = [(min(v[i] for v in vertices), max(v[i] for v in vertices)) for i in range(3)]
    if moving:
        assert math.isclose(shape['scale'],6.4,abs_tol=1e-6)
        assert math.isclose(scale,1.28,abs_tol=1e-7)
        assert math.isclose(extents[axis][1],44.09303665*1.28,abs_tol=1e-5)
        assert all(max(abs(a),abs(b)) < 2.970 for i,(a,b) in enumerate(extents) if i != axis)
    else:
        assert math.isclose(shape['scale'],(1.1,1.05,1)[axis],abs_tol=1e-7)
        assert math.isclose(scale,(.22,.21,.2)[axis],abs_tol=1e-7)
        assert max(abs(v) for v in extents[axis]) < .7
        assert all(34 < abs(a) < 39 and 34 < b < 39 for i,(a,b) in enumerate(extents) if i != axis)
    assert len(properties) == 1 and properties[0]['type'] == 'NiMaterialProperty'
    material = properties[0]
    assert material['diffuse'][axis] > max(c for i,c in enumerate(material['diffuse']) if i != axis)
    assert material['diffuse'] == material['emissive'] and material['alpha'] == 1
print('PASS: updated gizmo SHA-256, node bone marker, shared sorting group, nested transforms, six axes, unlit/fog properties, alpha mask, triangles, UVs, bounds and materials')
