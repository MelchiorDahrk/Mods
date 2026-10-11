"""Check the shipped empty UI canvas's TES3 stream, links and identity transform."""
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parent.parent
target = ROOT / 'meshes/pose/h/pose_preview.nif'
data = target.read_bytes()
offset = 0

def take(format):
    global offset
    value = struct.unpack_from(format, data, offset)
    offset += struct.calcsize(format)
    return value

def string():
    global offset
    length, = take('<I')
    value = data[offset:offset + length]
    offset += length
    return value

header = b'NetImmerse File Format, Version 4.0.0.2\n'
assert data.startswith(header)
offset = len(header)
assert take('<II') == (0x04000002, 1)
assert string() == b'NiNode'
assert string() == b'OAAB Pose Preview Canvas'
assert take('<iiH') == (-1, -1, 12)  # no extra data/controller
assert take('<3f') == (0, 0, 0)
assert take('<9f') == (1, 0, 0, 0, 1, 0, 0, 0, 1)
assert take('<f') == (1,)
assert take('<3f') == (0, 0, 0)
assert take('<4I') == (0, 0, 0, 0)  # no properties, bounds, children, effects
assert take('<II') == (1, 0)  # single root references the only block
assert offset == len(data), 'Unconsumed canvas bytes'
print('PASS: TES3 empty UI canvas stream, identity transforms, no geometry/controllers, and root links')
