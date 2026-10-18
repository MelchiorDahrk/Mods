"""Build the small, analytic DDS gradients used by both native UI implementations."""
import colorsys
import math
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[1]


def dds(width, height, pixel):
    header = [124, 0x100F, height, width, width * 4, 0, 0] + [0] * 11
    header += [32, 0x41, 0, 32, 0xFF0000, 0xFF00, 0xFF, 0xFF000000]
    header += [0x1000, 0, 0, 0, 0]
    data = bytearray(b'DDS ' + struct.pack('<31I', *header))
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixel(x, y)
            data.extend(round(max(0, min(1, c)) * 255) for c in (b, g, r, a))
    return data


def sv(x, y):
    s, v = x / 255, 1 - y / 255
    alpha = 1 - s * v
    white = v * (1 - s) / alpha if alpha else 0
    return white, white, white, alpha


def ring(x, y):
    distance = math.hypot(x - 7.5, y - 7.5)
    alpha = max(0, min(1, min(distance - 4, 7.5 - distance)))
    shade = 1 if distance < 6 else 0
    return shade, shade, shade, alpha


textures = {
    'sv.dds': dds(256, 256, sv),
    'hue.dds': dds(16, 256, lambda x, y: (*colorsys.hsv_to_rgb(y / 255, 1, 1), 1)),
    'cursor.dds': dds(16, 16, ring),
}
for edition in ('00 OpenMW', '00 MWSE'):
    folder = ROOT / edition / 'textures/customweather'
    folder.mkdir(parents=True, exist_ok=True)
    for name, content in textures.items():
        (folder / name).write_bytes(content)
