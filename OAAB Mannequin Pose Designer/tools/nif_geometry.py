"""Read static TES3 geometry for QA/preview, without rewriting the source NIF.

Bool fields in NetImmerse 4.0.0.2 are 32-bit. UV sets are set-major then
vertex-major. This reader covers the author's node/shape/material/data blocks.
"""
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parent.parent


class Reader:
    def __init__(self, data): self.data, self.offset = data, 0
    def value(self, fmt):
        fmt = '<' + fmt
        size = struct.calcsize(fmt)
        result = struct.unpack_from(fmt, self.data, self.offset)
        self.offset += size
        return result[0] if len(result) == 1 else result
    def string(self):
        size = self.value('I'); end = self.offset + size
        result = self.data[self.offset:end].decode('utf-8'); self.offset = end
        return result
    def links(self): return [self.value('i') for _ in range(self.value('I'))]
    def net(self): return dict(name=self.string(), extra=self.value('i'), controller=self.value('i'))
    def av(self):
        block = self.net()
        block.update(flags=self.value('H'), translation=self.value('3f'), rotation=self.value('9f'),
                     scale=self.value('f'), velocity=self.value('3f'), properties=self.links())
        assert not self.value('I'), 'Bounding-volume blocks are unsupported'
        return block


def read(path=ROOT/'meshes/pose/h/gizmo.nif'):
    data = Path(path).read_bytes()
    header = b'NetImmerse File Format, Version 4.0.0.2\n'
    assert data.startswith(header)
    stream = Reader(data); stream.offset = len(header)
    assert stream.value('I') == 0x04000002
    blocks = []
    for _ in range(stream.value('I')):
        kind = stream.string()
        if kind in ('NiNode','NiSortAdjustNode','NiCollisionSwitch'):
            block = stream.av(); block.update(children=stream.links(), effects=stream.links())
            if kind == 'NiSortAdjustNode': block.update(sorting_mode=stream.value('i'), sub_sorter=stream.value('i'))
        elif kind == 'NiTriShape':
            block = stream.av(); block.update(data=stream.value('i'), skin=stream.value('i'))
        elif kind == 'NiMaterialProperty':
            block = stream.net(); block['flags'] = stream.value('H')
            for name in ('ambient','diffuse','specular','emissive'): block[name] = stream.value('3f')
            block.update(glossiness=stream.value('f'), alpha=stream.value('f'))
        elif kind == 'NiAlphaProperty':
            block = stream.net(); block.update(flags=stream.value('H'), threshold=stream.value('B'))
        elif kind == 'NiVertexColorProperty':
            block = stream.net(); block.update(flags=stream.value('H'), vertex_mode=stream.value('I'), lighting_mode=stream.value('I'))
        elif kind == 'NiFogProperty':
            block = stream.net(); block.update(flags=stream.value('H'), fog_depth=stream.value('f'), fog_color=stream.value('3f'))
        elif kind == 'NiAlphaAccumulator':
            block = {}
        elif kind == 'NiTriShapeData':
            count = stream.value('H')
            block = dict(vertices=[stream.value('3f') for _ in range(count)] if stream.value('I') else [])
            block['normals'] = [stream.value('3f') for _ in range(count)] if stream.value('I') else []
            block.update(center=stream.value('3f'), radius=stream.value('f'))
            block['colors'] = [stream.value('4f') for _ in range(count)] if stream.value('I') else []
            uv_count = stream.value('H'); has_uv = stream.value('I')
            block['uv_sets'] = [[stream.value('2f') for _ in range(count)] for _ in range(uv_count)] if has_uv else []
            triangle_count = stream.value('H'); assert stream.value('I') == 3*triangle_count
            block['triangles'] = [stream.value('3H') for _ in range(triangle_count)]
            block['shared_normals'] = [[stream.value('H') for _ in range(stream.value('H'))]
                                       for _ in range(stream.value('H'))]
        else:
            raise ValueError(f'Unsupported static gizmo block: {kind}')
        block['type'] = kind; blocks.append(block)
    roots = stream.links()
    assert stream.offset == len(data), 'Unconsumed NIF bytes'
    return blocks, roots


def shapes(path=ROOT/'meshes/pose/h/gizmo.nif'):
    blocks, roots = read(path)
    assert len(roots) == 1 and blocks[roots[0]]['type'] == 'NiNode'
    result=[]
    def visit(index,parent):
        block=blocks[index]
        r=block['rotation']; pr=parent['rotation']
        rotation=tuple(sum(pr[3*i+k]*r[3*k+j] for k in range(3)) for i in range(3) for j in range(3))
        translation=tuple(parent['translation'][i]+parent['scale']*sum(pr[3*i+k]*block['translation'][k] for k in range(3)) for i in range(3))
        transform=dict(rotation=rotation,translation=translation,scale=parent['scale']*block['scale'])
        if block['type']=='NiTriShape':
            shape=dict(block,world=transform)
            result.append((shape,blocks[block['data']],[blocks[j] for j in block['properties']]))
        else:
            for child in block['children']:
                if child>=0: visit(child,transform)
    visit(roots[0],dict(rotation=(1,0,0,0,1,0,0,0,1),translation=(0,0,0),scale=1))
    return result
