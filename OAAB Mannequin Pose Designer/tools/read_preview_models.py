"""Read TES3 preview assets for offline QA; nothing is serialized or saved.

PyFFI supplies the graph links, skin weights and independent skin deformation.
Its legacy XML reader needs a scoped 4.0.0.2 triangle-data adapter for these OAAB
assets, plus the TES3 NiCollisionSwitch type (same layout as NiNode).
"""
from pathlib import Path
import collections
import inspect
import struct
import sys
import time

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / '.work/nif-deps'))
try:
    import _distutils_hack
    _distutils_hack.add_shim()
except ImportError:
    pass
if not hasattr(time, 'clock'):
    time.clock = time.perf_counter
if not hasattr(inspect, 'getargspec'):
    ArgSpec = collections.namedtuple('ArgSpec', 'args varargs keywords defaults')
    def getargspec(function):
        spec = inspect.getfullargspec(function)
        return ArgSpec(spec.args, spec.varargs, spec.varkw, spec.defaults)
    inspect.getargspec = getargspec
from pyffi.formats.nif import NifFormat as N

def triangle_data(self, stream, data):
    assert data.version == 0x04000002
    def read(format):
        return struct.unpack('<' + format, stream.read(struct.calcsize('<' + format)))
    self.num_vertices, = read('H')
    self.has_vertices = bool(read('I')[0]); self.vertices.update_size()
    if self.has_vertices:
        for vertex in self.vertices: vertex.x, vertex.y, vertex.z = read('3f')
    self.has_normals = bool(read('I')[0]); self.normals.update_size()
    if self.has_normals:
        for normal in self.normals: normal.x, normal.y, normal.z = read('3f')
    self.center.x, self.center.y, self.center.z, self.radius = read('4f')
    self.has_vertex_colors = bool(read('I')[0]); self.vertex_colors.update_size()
    if self.has_vertex_colors:
        for color in self.vertex_colors: color.r, color.g, color.b, color.a = read('4f')
    self.num_uv_sets, = read('H')
    self.has_uv = bool(read('I')[0]); self.uv_sets.update_size()
    for uv_set in self.uv_sets:
        for uv in uv_set: uv.u, uv.v = read('2f')
    self.num_triangles, = read('H'); self.num_triangle_points, = read('I')
    assert self.num_triangle_points == 3 * self.num_triangles
    self.triangles.update_size()
    for triangle in self.triangles: triangle.v_1, triangle.v_2, triangle.v_3 = read('3H')
    self.num_match_groups, = read('H'); self.match_groups.update_size()
    for group in self.match_groups:
        group.num_vertices, = read('H'); group.vertex_indices.update_size()
        for i in range(group.num_vertices): group.vertex_indices[i] = read('H')[0]

class NiCollisionSwitch(N.NiNode):
    pass

def load(path):
    # Do not change parsing for other NIF versions or other QA scripts.
    previous_read = N.NiTriShapeData.read
    previous_switch = getattr(N, 'NiCollisionSwitch', None)
    N.NiTriShapeData.read = triangle_data
    N.NiCollisionSwitch = NiCollisionSwitch
    try:
        data = N.Data()
        with Path(path).open('rb') as stream:
            data.read(stream)
            assert stream.read() == b'', 'Unconsumed model bytes'
        assert data.version == 0x04000002 and len(data.roots) == 1
        return data
    finally:
        N.NiTriShapeData.read = previous_read
        if previous_switch is None: del N.NiCollisionSwitch
        else: N.NiCollisionSwitch = previous_switch

def rotation(node):
    # PyFFI uses row vectors; MWSE and this project's math use column vectors.
    return [getattr(node.rotation, f'm_{col}{row}') for row in range(1, 4) for col in range(1, 4)]

def set_transform(node, native):
    for row in range(1, 4):
        for col in range(1, 4):
            setattr(node.rotation, f'm_{col}{row}', native[b'rotation'][(row - 1) * 3 + col])
    for axis in ('x', 'y', 'z'): setattr(node.translation, axis, native[b'translation'][axis.encode()])
    node.scale = native[b'scale']
