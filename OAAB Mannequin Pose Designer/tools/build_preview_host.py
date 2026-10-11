"""Build the empty TES3 NiNode used as a native UI canvas (no pose geometry)."""
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parent.parent
TARGET = ROOT / 'meshes/pose/h/pose_preview.nif'

def string(value):
    data = value.encode('ascii')
    return struct.pack('<I', len(data)) + data

def build():
    header = b'NetImmerse File Format, Version 4.0.0.2\n' + struct.pack('<II', 0x04000002, 1)
    node = string('OAAB Pose Preview Canvas') + struct.pack('<iiH', -1, -1, 12)
    node += struct.pack('<3f9ff3f', 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0)
    node += struct.pack('<4I', 0, 0, 0, 0)  # properties, bounds, children, effects
    return header + string('NiNode') + node + struct.pack('<II', 1, 0)

if __name__ == '__main__':
    TARGET.parent.mkdir(parents=True, exist_ok=True)
    TARGET.write_bytes(build())
    print(f'Built {TARGET} ({TARGET.stat().st_size} bytes)')
