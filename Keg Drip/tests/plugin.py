"""Validate the shared TES3 plugin, including its vanilla no-save script."""
import struct
from pathlib import Path


def chunks(data, header):
    offset = 0
    while offset < len(data):
        tag, size, *_ = header.unpack_from(data, offset)
        start = offset + header.size
        assert start + size <= len(data), f"Truncated {tag!r}"
        yield tag, data[start:start + size]
        offset = start + size
    assert offset == len(data)


root = Path(__file__).resolve().parent.parent
records = list(chunks((root / '00 Core/Keg Drip.ESP').read_bytes(), struct.Struct('<4sIII')))
header = dict(chunks(records[0][1], struct.Struct('<4sI')))[b'HEDR']
assert struct.unpack_from('<I', header, 296)[0] == len(records) - 1
objects, scripts = {}, {}
for kind, body in records[1:]:
    fields = dict(chunks(body, struct.Struct('<4sI')))
    if kind == b'ACTI':
        objects[fields[b'NAME'].rstrip(b'\0')] = fields
    elif kind == b'SCPT':
        scripts[fields[b'SCHD'][:32].rstrip(b'\0')] = fields

puddle = objects[b'kegPuddle']
assert puddle[b'MODL'] == b'e\\kegPuddle.nif\0'
assert (root / '00 Core/Meshes/e/kegPuddle.nif').is_file()
script = scripts[puddle[b'SCRI'].rstrip(b'\0')]
assert script[b'SCDT'] == bytes.fromhex('5f110101')  # DontSaveObject; End
assert struct.unpack_from('<5I', script[b'SCHD'], 32) == (0, 0, 0, 4, 0)
assert script[b'SCTX'].decode('ascii').split() == [
    'Begin', 'kegPuddleNoSave', 'DontSaveObject', 'End', 'kegPuddleNoSave',
]
effects = {
    b'furn_com_kegstand_dr': b'f\\furn_com_kegstand_dr.nif',
    b'furn_de_kegstand_dr': b'f\\furn_de_kegstand_dr.nif',
    b'furn_winekeg00_dr': b'f\\furn_winekeg00_dr.nif',
    b'hf_furn_kegstand_01_dr': b'hf\\f\\hf_furn_kegstand_01_dr.nif',
    b'hr_furn_kegstand_01_dr': b'hr\\f\\hr_furn_kegstand_01_dr.nif',
    b'sky_furn_n_m_keg_01_dr': b'sky\\f\\sky_furn_n_m_keg_01_dr.nif',
}
assert set(objects) == set(effects) | {b'kegPuddle'}
for record_id, mesh in effects.items():
    assert objects[record_id][b'MODL'] == mesh + b'\0'
    path = root / '00 Core/Meshes' / mesh.decode('ascii').replace('\\', '/')
    assert path.is_file(), path
    assert path.with_name('x' + path.name).is_file(), path
    assert path.with_name('x' + path.stem + '.kf').is_file(), path
assert [(kind, body) for kind, body in records if kind == b'STAT'] == []
print('PASS ESP: six drip records and animation assets, record sizes/count, kegPuddle mesh, attached DontSaveObject source and bytecode')
