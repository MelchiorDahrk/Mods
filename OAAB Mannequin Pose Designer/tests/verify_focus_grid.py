"""Independently parse TES3 NiLines grids, including radial alpha and segment flags."""
import math
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / 'tools'))
from nif_geometry import Reader

def verify(path, expected_count):
    data = path.read_bytes()
    header = b'NetImmerse File Format, Version 4.0.0.2\n'
    assert data.startswith(header)
    r = Reader(data)
    r.offset = len(header)
    assert r.value('I') == 0x04000002 and r.value('I') == 10
    assert r.string() == 'NiNode'
    root = r.av()
    assert root['properties'] == [1, 2, 3, 4]
    assert r.links() == [5, 6, 7, 8] and r.links() == []
    assert r.string() == 'NiVertexColorProperty'
    r.net()
    assert r.value('H') == 0 and r.value('I') == 1 and r.value('I') == 0
    assert r.string() == 'NiAlphaProperty'
    r.net()
    assert r.value('H') == 8429 and r.value('B') == 0
    assert r.string() == 'NiMaterialProperty'
    r.net()
    assert r.value('H') == 1 and r.value('12f') == (1,) * 12
    assert r.value('f') == 0 and r.value('f') == 0.5
    assert r.string() == 'NiZBufferProperty'
    r.net()
    assert r.value('H') == 1
    rotations = [(1,0,0,0,1,0,0,0,1), (0,-1,0,1,0,0,0,0,1),
                 (-1,0,0,0,-1,0,0,0,1), (0,1,0,-1,0,0,0,0,1)]
    for rotation in rotations:
        assert r.string() == 'NiLines'
        lines = r.av()
        assert lines['extra'] == lines['controller'] == -1
        assert lines['rotation'] == rotation and lines['translation'] == (0,0,0) and lines['scale'] == 1
        assert lines['properties'] == [] and r.value('i') == 9 and r.value('i') == -1
    # Keep the shared data last to retain the native loading crash safeguard.
    assert r.string() == 'NiLinesData'
    count = r.value('H')
    assert count == expected_count and count <= 32767 and r.value('I') == 1
    vertices = [r.value('3f') for _ in range(count)]
    assert r.value('I') == 0
    center, radius = r.value('3f'), r.value('f')
    segments = 16
    row_vertices = 2 * segments
    g = count // segments - 2
    assert center == (0, g / 2, 0) and radius > 0
    assert r.value('I') == 1
    colors = [r.value('4f') for _ in range(count)]
    assert r.value('H') == 0 and r.value('I') == 0
    flags = [r.value('B') for _ in range(count)]
    rows = count // row_vertices
    # Independent segment pairs; the original outermost row stays disabled.
    assert flags == [1, 0] * (segments * (rows - 1)) + [0] * row_vertices
    samples = {}
    for row in range(rows):
        start = row_vertices * row
        line = vertices[start:start + row_vertices]
        line_colors = colors[start:start + row_vertices]
        assert all(v[1:] == (2 * row, 0) for v in line)
        width = line[0][0]
        assert width >= 0 and line[-1][0] == (0 if row == 0 else -width)
        length = width if row == 0 else 2 * width
        assert math.isclose(width, math.sqrt(g * g - (2 * row) ** 2), rel_tol=1e-7, abs_tol=1e-6)
        assert math.isclose(math.hypot(width, 2 * row), g, rel_tol=1e-7)
        for segment in range(segments):
            a, b = line[2 * segment:2 * segment + 2]
            assert math.isclose(a[0], width - length * segment / segments, rel_tol=1e-7, abs_tol=1e-5)
            assert math.isclose(b[0], width - length * (segment + 1) / segments, rel_tol=1e-7, abs_tol=1e-5)
            if segment:
                assert a == line[2 * segment - 1]  # No gaps between pairs.
        for vertex, color in zip(line, line_colors):
            distance = math.hypot(vertex[0], vertex[1])
            t = min(distance / g, 1)
            alpha = 0.2 * (1 - t * t * (3 - 2 * t))
            assert color[:3] == (1, 1, 1) and math.isclose(color[3], alpha, abs_tol=1e-7)
            assert distance <= g * 1.000001, 'Grid vertex protrudes beyond the circle'
        assert math.isclose(line_colors[0][3], 0, abs_tol=1e-7)
        if row:
            assert math.isclose(line_colors[-1][3], 0, abs_tol=1e-7)
        for vertex, color in zip(line, line_colors):
            if vertex[0] == 0:
                samples[vertex[1]] = color[3]
        if row:
            for i in range(row_vertices):
                assert line_colors[i] == line_colors[-1 - i]
    # The falloff is centered at the world origin and declines toward the rim.
    assert math.isclose(samples[0], 0.2, abs_tol=1e-7) and samples[g] == 0
    assert all(samples[y] >= samples[y + 2] for y in range(0, g, 2))
    if g % 2 == 0 and g // 2 in samples:
        assert math.isclose(samples[g // 2], 0.1, abs_tol=1e-7)
    assert all(math.dist(vertex, center) <= radius * 1.000001 for vertex in vertices)
    # Combine all four rotated sets. No segment may be drawn twice, especially
    # along the two center axes where duplicate alpha blending looked thicker.
    drawn = set()
    world_rows = [set(), set()]
    for rotation in rotations:
        def rotate(vertex):
            return tuple(sum(rotation[3 * row + column] * vertex[column]
                             for column in range(3)) for row in range(3))
        for i in range(0, count, 2):
            if flags[i]:
                key = tuple(sorted((rotate(vertices[i]), rotate(vertices[i + 1]))))
                assert key not in drawn, 'Overlapping grid segment'
                drawn.add(key)
                a, b = key
                if a[1] == b[1]:
                    world_rows[1].add(a[1])
                elif a[0] == b[0]:
                    world_rows[0].add(a[0])
                else:
                    raise AssertionError('A grid segment bridges different rows')
    expected_rows = list(range(-g + 2, g, 2))
    for offsets in world_rows:
        assert sorted(offsets) == expected_rows
        assert all((b - a) * 8 == 16 for a, b in zip(expected_rows, expected_rows[1:]))
    assert r.links() == [0] and r.offset == len(data)


# The typical radius doubles from g=12 to g=24 without changing grid spacing.
verify(ROOT / '.work/focus-grid.nif', 416)
verify(ROOT / '.work/focus-grid-minimum.nif', 288)
verify(ROOT / '.work/focus-grid-maximum.nif', 32736)
print('PASS: independent grid NIF parse at minimum, typical and maximum sizes; exact circle clipping, uniform 16-unit spacing through the rim, radial alpha and no overlapping center lines')
