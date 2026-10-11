"""Check the production template output without relying on the Lua patch code."""
from pathlib import Path
import math
import re
import struct


def block_positions(data: bytes, kind: str):
    marker = struct.pack("<I", len(kind)) + kind.encode("ascii")
    return [match.end() for match in re.finditer(re.escape(marker), data)]


def node(data: bytes, name: str):
    target = name.encode("ascii")
    marker = struct.pack("<I", 6) + b"NiNode" + struct.pack("<I", len(target)) + target
    assert data.count(marker) == 1, name
    at = data.index(marker) + len(marker) + 10
    return struct.unpack_from("<13f", data, at)


root = Path(".work")
main = (root / "template.nif").read_bytes()
companion = (root / "xtemplate.nif").read_bytes()
kf = (root / "xtemplate.kf").read_bytes()
for data, nodes, shapes, keys in (
    (main, 61, 1, 35),
    (companion, 61, 1, 0),
    (kf, 0, 0, 35),
):
    assert len(block_positions(data, "NiNode")) == nodes
    assert len(block_positions(data, "NiTriShape")) == shapes
    assert len(block_positions(data, "NiKeyframeData")) == keys
    assert data.startswith(b"NetImmerse File Format, Version 4.0.0.2\n")

for data in (main, companion):
    transform = node(data, "Bip01")
    assert all(math.isclose(a, b, abs_tol=1e-5) for a, b in zip(transform[:3], (1, 0.5, 59)))
    assert math.isclose(transform[12], 1.0001, abs_tol=1e-5)
    assert node(data, "Bip01 L Hand")[0] == 17

for data in (main, kf):
    first = block_positions(data, "NiKeyframeData")[0]
    assert struct.unpack_from("<II", data, first) == (2, 1)
    position = first + 48
    assert struct.unpack_from("<II", data, position) == (2, 2)
    assert all(math.isclose(a, b, abs_tol=1e-5) for a, b in
               zip(struct.unpack_from("<3f", data, position + 12), (1, 0.5, 59)))
    scale = position + 88
    assert math.isclose(struct.unpack_from("<f", data, scale + 12)[0], 1.0001, abs_tol=1e-5)

print("PASS: independent full-template structure, bone transforms, and key values")
