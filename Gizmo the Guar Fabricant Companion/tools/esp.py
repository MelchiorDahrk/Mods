"""Small lossless TES3 record reader/writer for plugin builds and checks."""
import re
import struct
from pathlib import Path


def unpack(data):
    pos = 0
    while pos < len(data):
        tag, size = struct.unpack_from('<4sI', data, pos)
        end = pos + 8 + size
        assert end <= len(data), (tag, pos, size)
        yield tag, data[pos + 8:end]
        pos = end
    assert pos == len(data)


def records(path):
    data = Path(path).read_bytes()
    pos = 0
    while pos < len(data):
        tag, size, unknown, flags = struct.unpack_from('<4sIII', data, pos)
        end = pos + 16 + size
        assert end <= len(data)
        yield tag, list(unpack(data[pos + 16:end])), unknown, flags
        pos = end
    assert pos == len(data)


def field(fields, tag):
    return next(v for k, v in fields if k == tag)


def string(value):
    return value.rstrip(b'\0').decode('cp1252')


def encode_record(tag, fields, unknown=0, flags=0):
    body = b''.join(struct.pack('<4sI', k, len(v)) + v for k, v in fields)
    return struct.pack('<4sIII', tag, len(body), unknown, flags) + body


def script(name, source):
    # OpenMW compiles SCTX itself. Never ship stale vanilla bytecode.
    names = {kind: re.findall(r'^\s*' + kind + r'\s+(\w+)\s*$', source, re.M | re.I)
             for kind in ('short', 'long', 'float')}
    table = b''.join(n.encode('ascii') + b'\0' for ns in names.values() for n in ns)
    header = struct.pack('<32sIIIII', name.encode('ascii'), *(len(ns) for ns in names.values()), 0, len(table))
    fields = [(b'SCHD', header)]
    if table:
        fields.append((b'SCVR', table))
    fields.extend([(b'SCDT', b''), (b'SCTX', source.replace('\n', '\r\n').encode('cp1252'))])
    return encode_record(b'SCPT', fields)


def plugin(path, body, masters):
    header = struct.pack('<fI32s256sI', 1.3, 0, b'Melchior Dahrk',
                         b'Fabricant Guar OpenMW Lua compatibility; requires OpenMW 0.51.0.', len(body))
    fields = [(b'HEDR', header)]
    for master in masters:
        master = Path(master)
        fields.extend([(b'MAST', master.name.encode('cp1252') + b'\0'),
                       (b'DATA', struct.pack('<Q', master.stat().st_size))])
    Path(path).write_bytes(encode_record(b'TES3', fields) + b''.join(body))
