"""Rebuild archived particle meshes in legacy/ (unused by the shader mod).

The original NiBSPArrayControllers have black initial colors. OpenMW uses those
colors for particles, so give them a neutral white color. Raise the root by 128
units because OpenMW attaches VFX at the player's feet, rather than the camera.
All other data, including density, textures, motion and controllers, is retained.
"""

import argparse
from pathlib import Path
import struct


ROOT = Path(__file__).absolute().parent.parent / "legacy"
VARIANTS = ("01 Default Dust", "01 Denser Dust")


def convert(mesh):
    assert mesh.startswith(b"NetImmerse File Format, Version 4.0.0.2\n")
    result = bytearray(mesh)
    name = b"AttachDust"
    marker = struct.pack("<I", len(name)) + name
    assert mesh.count(marker) == 1
    root = mesh.index(marker) + len(marker)
    assert struct.unpack_from("<iiH", mesh, root) == (-1, -1, 10)
    assert struct.unpack_from("<3f", mesh, root + 10) == (0, 0, 0)
    struct.pack_into("<f", result, root + 18, 128)

    name = b"NiBSPArrayController"
    marker = struct.pack("<I", len(name)) + name
    assert mesh.count(marker) == 3
    start = 0
    for target in (6, 28, 50):
        controller = mesh.index(marker, start) + len(marker)
        # NiTimeController: next link, flags, frequency, phase, start, stop, target.
        assert struct.unpack_from("<iH4fi", mesh, controller) == (-1, 8, 1, 0, 0, 8, target)
        # Followed by six floats for speed/angles, a normal, then initial RGBA.
        color = controller + 26 + 24 + 12
        assert struct.unpack_from("<4f", mesh, color) == (0, 0, 0, 0)
        struct.pack_into("<4f", result, color, 1, 1, 1, 1)
        start = color + 16
    return bytes(result)


def build(check=False):
    for variant in VARIANTS:
        directory = ROOT / variant / "Meshes/Dust"
        converted = convert((directory / "dust.nif").read_bytes())
        destination = directory / "dust_openmw.nif"
        if check:
            assert destination.read_bytes() == converted, f"Rebuild {destination}"
        else:
            destination.write_bytes(converted)
        print(f"PASS {variant}: OpenMW mesh {'verified' if check else 'built'}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    build(parser.parse_args().check)
