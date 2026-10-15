"""Render the shared GLSL on a hidden Windows OpenGL context.

Requires numpy and Pillow (available in the Codex bundled Python runtime).
Writes synthetic GPU previews under .validation-cache/rendering, and checks
density, animation, depth occlusion, parallax, and axis-aligned rays.
This is an offscreen shader test, not a screenshot of either game engine.
"""
import ctypes as c
from ctypes import wintypes as w
import os
from pathlib import Path
import struct

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent


def main():
    if os.name != 'nt':
        raise RuntimeError('This test uses Windows WGL')
    user, gdi, gl = c.WinDLL('user32'), c.WinDLL('gdi32'), c.WinDLL('opengl32')
    user.CreateWindowExW.argtypes = [w.DWORD, w.LPCWSTR, w.LPCWSTR, w.DWORD,
                                    c.c_int, c.c_int, c.c_int, c.c_int,
                                    w.HWND, w.HMENU, w.HINSTANCE, c.c_void_p]
    user.CreateWindowExW.restype = w.HWND
    user.GetDC.argtypes, user.GetDC.restype = [w.HWND], w.HDC
    user.ReleaseDC.argtypes = [w.HWND, w.HDC]
    user.DestroyWindow.argtypes = [w.HWND]
    width, height = 960, 540
    window = user.CreateWindowExW(0, 'STATIC', 'Unto Dust offscreen test', 0x80000000,
                                  0, 0, width, height, None, None, None, None)
    assert window, 'Could not create hidden render surface'
    dc = user.GetDC(window)

    class PixelFormat(c.Structure):
        _fields_ = [('size', w.WORD), ('version', w.WORD), ('flags', w.DWORD)] + [
            (name, c.c_ubyte) for name in (
                'type', 'color', 'red', 'redShift', 'green', 'greenShift',
                'blue', 'blueShift', 'alpha', 'alphaShift', 'accum', 'accumRed',
                'accumGreen', 'accumBlue', 'accumAlpha', 'depth', 'stencil',
                'aux', 'layer', 'reserved')
        ] + [('layerMask', w.DWORD), ('visibleMask', w.DWORD), ('damageMask', w.DWORD)]

    pixel = PixelFormat(size=c.sizeof(PixelFormat), version=1, flags=0x25, color=32)
    gdi.ChoosePixelFormat.argtypes = [w.HDC, c.POINTER(PixelFormat)]
    gdi.SetPixelFormat.argtypes = [w.HDC, c.c_int, c.POINTER(PixelFormat)]
    fmt = gdi.ChoosePixelFormat(dc, c.byref(pixel))
    assert fmt and gdi.SetPixelFormat(dc, fmt, c.byref(pixel))
    gl.wglCreateContext.argtypes, gl.wglCreateContext.restype = [w.HDC], c.c_void_p
    gl.wglMakeCurrent.argtypes = [w.HDC, c.c_void_p]
    gl.wglDeleteContext.argtypes = [c.c_void_p]
    gl.wglGetProcAddress.argtypes, gl.wglGetProcAddress.restype = [c.c_char_p], c.c_void_p
    context = gl.wglCreateContext(dc)
    assert context and gl.wglMakeCurrent(dc, context)

    def function(name, result, *args):
        pointer = gl.wglGetProcAddress(name.encode())
        if pointer:
            return c.WINFUNCTYPE(result, *args)(pointer)
        fn = getattr(gl, name)
        fn.argtypes, fn.restype = args, result
        return fn

    uint, integer, floating, pointer = c.c_uint, c.c_int, c.c_float, c.c_void_p
    create_shader = function('glCreateShader', uint, uint)
    shader_source = function('glShaderSource', None, uint, integer, c.POINTER(c.c_char_p), pointer)
    compile_shader = function('glCompileShader', None, uint)
    shader_info = function('glGetShaderiv', None, uint, uint, c.POINTER(integer))
    shader_log = function('glGetShaderInfoLog', None, uint, integer, pointer, c.c_char_p)
    create_program = function('glCreateProgram', uint)
    attach = function('glAttachShader', None, uint, uint)
    link = function('glLinkProgram', None, uint)
    program_info = function('glGetProgramiv', None, uint, uint, c.POINTER(integer))
    use = function('glUseProgram', None, uint)
    location = function('glGetUniformLocation', integer, uint, c.c_char_p)
    uniform1 = function('glUniform1f', None, integer, floating)
    uniform_int = function('glUniform1i', None, integer, integer)
    uniform3 = function('glUniform3f', None, integer, floating, floating, floating)
    gen_textures = function('glGenTextures', None, integer, c.POINTER(uint))
    bind_texture = function('glBindTexture', None, uint, uint)
    texture_parameter = function('glTexParameteri', None, uint, uint, integer)
    compressed_image = function('glCompressedTexImage2D', None, uint, integer, uint,
                                integer, integer, integer, integer, pointer)
    viewport = function('glViewport', None, integer, integer, integer, integer)
    draw = function('glDrawArrays', None, uint, integer, integer)
    read = function('glReadPixels', None, integer, integer, integer, integer, uint, uint, pointer)

    def shader(kind, source):
        result = create_shader(kind)
        data = c.c_char_p(source.encode())
        shader_source(result, 1, c.byref(data), None)
        compile_shader(result)
        status = integer()
        shader_info(result, 0x8B81, c.byref(status))
        if not status.value:
            log = c.create_string_buffer(8192)
            shader_log(result, len(log), None, log)
            raise RuntimeError(log.value.decode())
        return result

    vertex = '''#version 330 compatibility
    out vec2 uv;
    void main() {
        vec2 p = vec2((gl_VertexID << 1) & 2, gl_VertexID & 2);
        uv = p; gl_Position = vec4(p * 2.0 - 1.0, 0.0, 1.0);
    }'''
    fragment = '''#version 330 compatibility
    in vec2 uv; out vec4 color;
    uniform vec3 eye, forward, right, up;
    uniform float depth, seconds, density, spread, mask;
    uniform sampler2D dustTexture;
    vec4 dustSampleTexture(vec2 coord, float lod) {
        return textureLod(dustTexture, coord, lod);
    }
    ''' + (ROOT / 'shaders/dust.glsl').read_text() + '''
    void main() {
        vec2 xy = (uv * 2.0 - 1.0) * vec2(1.77777778, 1.0) * spread;
        vec3 ray = normalize(forward + right * xy.x + up * xy.y);
        vec4 motes = dustMotes(eye, ray, depth, spread / 270.0, seconds, density);
        vec3 scene = mix(vec3(0.07, 0.065, 0.055), vec3(0.22, 0.19, 0.14), uv.y);
        color = vec4(mix(dustComposite(scene, motes), vec3(motes.a), mask), 1.0);
    }'''
    try:
        program = create_program()
        attach(program, shader(0x8B31, vertex))
        attach(program, shader(0x8B30, fragment))
        link(program)
        status = integer()
        program_info(program, 0x8B82, c.byref(status))
        assert status.value, 'Failed to link GPU test program'
        use(program)
        # Upload the packaged DXT5 mip chain exactly as the engine loads it.
        texture = uint()
        gen_textures(1, c.byref(texture))
        bind_texture(0x0DE1, texture.value)
        texture_parameter(0x0DE1, 0x2801, 0x2703)  # trilinear minification
        texture_parameter(0x0DE1, 0x2800, 0x2601)  # linear magnification
        for axis in (0x2802, 0x2803):
            texture_parameter(0x0DE1, axis, 0x812F)  # clamp to edge
        dds = (ROOT / '00 OpenMW/Textures/UntoDust/dust.dds').read_bytes()
        assert dds[:4] == b'DDS ' and dds[84:88] == b'DXT5'
        tex_height, tex_width = struct.unpack_from('<2I', dds, 12)
        mip_count = struct.unpack_from('<I', dds, 28)[0]
        position = 128
        for level in range(mip_count):
            size = max(1, (tex_width + 3) // 4) * max(1, (tex_height + 3) // 4) * 16
            data = c.create_string_buffer(dds[position:position + size])
            compressed_image(0x0DE1, level, 0x83F3, tex_width, tex_height, 0, size, data)
            position += size
            tex_width, tex_height = max(1, tex_width // 2), max(1, tex_height // 2)
        assert position == len(dds), 'Incomplete texture mip chain'
        uniform_int(location(program, b'dustTexture'), 0)
        viewport(0, 0, width, height)

        def render(density=0.85, depth=768.0, seconds=0.0, eye=(1376, 7552, 14752),
                   forward=(0, 1, 0), right=(1, 0, 0), up=(0, 0, 1), spread=0.6, mask=1.0):
            for name in ('density', 'depth', 'seconds', 'spread', 'mask'):
                uniform1(location(program, name.encode()), locals()[name])
            for name in ('eye', 'forward', 'right', 'up'):
                uniform3(location(program, name.encode()), *locals()[name])
            draw(0x0004, 0, 3)
            data = np.empty((height, width, 4), dtype=np.uint8)
            read(0, 0, width, height, 0x1908, 0x1401, data.ctypes.data)
            return data[::-1, :, :3].copy()

        default = render(density=0.32)
        denser = render()
        assert np.count_nonzero(default) > 0, 'No dust rendered'
        assert (denser >= default).all(), 'Denser removed existing motes'
        assert np.count_nonzero(denser) > np.count_nonzero(default), 'Density did not add motes'
        assert not render(depth=0).any(), 'Dust rendered through a near occluder'
        assert not render(density=0).any(), 'Dust rendered at zero density'
        assert np.abs(render(seconds=10).astype(int) - denser).sum() > 100, 'Dust did not drift'
        assert np.abs(render(eye=(1400, 7552, 14752)).astype(int) - denser).sum() > 100, 'No camera parallax'
        for axis in ((1, 0, 0), (-1, 0, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1)):
            right = (0, 1, 0) if axis[0] else (1, 0, 0)
            up = (0, 1, 0) if axis[2] else (0, 0, 1)
            assert render(forward=axis, right=right, up=up).any(), 'No dust on axis-aligned ray field'

        # Aim at a known mote from two positions, including a negative grid cell.
        cell = np.array((-3, 7, -2), dtype=np.float32)
        p = (cell * np.array((0.1031, 0.1030, 0.0973), dtype=np.float32)) % 1
        p += np.dot(p, p[[1, 0, 2]] + np.float32(33.33))
        seed = ((p[[0, 0, 1]] + p[[1, 0, 0]]) * p[[2, 1, 0]]) % 1
        center = (cell + 0.2 + seed * 0.6 + np.sin(seed * np.float32(6.2831853)) * 0.08) * 96
        for offset in ((0, -100, 0), (-60, -80, 0)):
            offset = np.array(offset)
            eye = center + offset
            forward = -offset / np.linalg.norm(offset)
            lit = render(density=1, depth=106, eye=eye, forward=forward, spread=0.035)
            blocked = render(density=1, depth=90, eye=eye, forward=forward, spread=0.035)
            assert lit.any(), 'World-space mote moved with camera'
            assert not blocked.any(), 'Mote visible behind wall'

        output = ROOT / '.validation-cache/rendering'
        output.mkdir(parents=True, exist_ok=True)
        Image.fromarray(render(density=0.32, mask=0)).save(output / 'default.png')
        Image.fromarray(render(mask=0)).save(output / 'denser.png')
        Image.fromarray(denser).save(output / 'opacity.png')

        # Track one mote's drifting center with a fixed camera orientation.
        # Any changing silhouette here comes from 3D tumbling, not translation.
        speed = ((1 - seed) * np.array((0.065, 0.075, 0.060)) +
                 seed * np.array((0.115, 0.125, 0.105)))
        speed *= np.where(seed[[2, 0, 1]] >= 0.5, 1, -1)
        def axes(seconds):
            s, co = np.sin(seed * 6.2831853 + seconds * speed), np.cos(seed * 6.2831853 + seconds * speed)
            axis_u = np.array((co[2] * co[1], s[2] * co[1], -s[1]))
            axis_v = np.array((co[2] * s[1] * s[0] - s[2] * co[0],
                               s[2] * s[1] * s[0] + co[2] * co[0], co[1] * s[0]))
            return axis_u, axis_v

        axis_u, axis_v = axes(0)
        normal = np.cross(axis_u, axis_v)

        def closeup(seconds=0, mask=0):
            drift = np.sin(seed * 6.2831853 + seconds * np.array((0.31, 0.23, 0.17))) * 0.08
            center = (cell + 0.2 + seed * 0.6 + drift) * 96
            return render(density=1, depth=106, seconds=seconds, eye=center + normal * 100,
                          forward=-normal, right=axis_u, up=axis_v, spread=0.027, mask=mask)

        initial, turned = closeup(mask=1), closeup(seconds=8, mask=1)
        assert np.count_nonzero(initial) > 500, 'Textured flake did not render in closeup'
        assert np.abs(turned.astype(int) - initial).sum() > 10000, 'No tumbling with drift removed'
        # The silhouette must actually foreshorten as the plane approaches edge-on.
        face_coverage = initial[:, :, 0].sum()
        edge_time = min(range(61), key=lambda t: abs(np.dot(normal, np.cross(*axes(t)))))
        assert closeup(seconds=float(edge_time), mask=1)[:, :, 0].sum() < face_coverage * 0.2, \
            'Flake does not turn edge-on'
        Image.fromarray(closeup()).save(output / 'textured-closeup.png')
        frames = [Image.fromarray(closeup(seconds=t)).resize((480, 270)) for t in np.arange(0, 24, 0.5)]
        frames[0].save(output / 'tumbling.gif', save_all=True, append_images=frames[1:],
                       duration=500, loop=0)
        print('PASS GPU rendering: texture/mips, both densities, drift, depth occlusion, parallax, negative coordinates, axis rays, 3D tumble and edge-on silhouette')
        print(f'Nonzero pixels: Default={np.count_nonzero(default[:, :, 0])}, Denser={np.count_nonzero(denser[:, :, 0])}')
        print(f'Synthetic previews: {output}')
    finally:
        gl.wglMakeCurrent(None, None)
        gl.wglDeleteContext(context)
        user.ReleaseDC(window, dc)
        user.DestroyWindow(window)


if __name__ == '__main__':
    main()
