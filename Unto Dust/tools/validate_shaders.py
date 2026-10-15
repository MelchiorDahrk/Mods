"""Validate shader packaging, Lua behavior, and (on Windows) HLSL compilation.

python tools/validate_shaders.py --lua-library "D:/Games/OpenMW/OpenMW 0.51.0 Dev/lua51.dll"
"""
import argparse
import ctypes
import os
from pathlib import Path

from build_shaders import build, ROOT


def validate_assets():
    manifest = (ROOT / '00 OpenMW/UntoDust.omwscripts').read_text().splitlines()
    assert manifest == ['PLAYER: scripts/UntoDust/player.lua',
                        'GLOBAL: scripts/UntoDust/global.lua',
                        'MENU: scripts/UntoDust/menu.lua']
    for entry in manifest:
        assert (ROOT / '00 OpenMW' / entry.split(': ', 1)[1]).is_file()
    for module in ('cellLists.lua', 'cellPicker.lua'):
        assert (ROOT / '00 OpenMW/scripts/UntoDust' / module).is_file()
    virtual_list = ROOT / '00 OpenMW/scripts/UntoDust/virtual_list'
    for module in ('init.lua', 'styles.lua', 'extras/init.lua', 'extras/extended.lua',
                   'extras/list_state.lua', 'extras/font_color.lua', 'LICENSE', 'README.md'):
        assert (virtual_list / module).is_file(), f'Missing virtual-list dependency: {module}'
    assert (ROOT / '00 OpenMW/scripts/UntoDust/settings.lua').is_file()
    assert (ROOT / '00 OpenMW/l10n/UntoDust/en.yaml').is_file()
    for variant in ('01 Default Dust', '01 Denser Dust'):
        assert not (ROOT / variant).exists(), 'Obsolete density installer remains'
    for folder in ('00 MWSE', '00 OpenMW'):
        assert not list((ROOT / folder).rglob('*.nif')), 'Legacy mesh in installer'
        assert list((ROOT / folder).rglob('*.dds')) == [ROOT / folder / 'Textures/UntoDust/dust.dds'], \
            'Installer must contain exactly the static dust texture'
        assert not list((ROOT / folder).rglob('density.lua')), 'Obsolete density override remains'
    print('PASS packaging: shader builds, manifest, OpenMW settings/localization, no density installers')


def run_lua(library_path):
    lua = ctypes.CDLL(str(library_path))
    lua.luaL_newstate.restype = ctypes.c_void_p
    lua.luaL_openlibs.argtypes = [ctypes.c_void_p]
    lua.luaL_loadfile.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
    lua.lua_pcall.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int]
    lua.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
    lua.lua_tolstring.restype = ctypes.c_char_p
    lua.lua_close.argtypes = [ctypes.c_void_p]
    for test in ('tests/openmw.lua', 'tests/mwse.lua', 'tests/openmw_cells.lua'):
        state = lua.luaL_newstate()
        assert state
        try:
            lua.luaL_openlibs(state)
            status = lua.luaL_loadfile(state, test.encode())
            if status == 0:
                status = lua.lua_pcall(state, 0, 0, 0)
            if status != 0:
                raise RuntimeError(lua.lua_tolstring(state, -1, None).decode())
        finally:
            lua.lua_close(state)


def compile_hlsl():
    if os.name != 'nt':
        print('SKIP HLSL compilation: requires Windows d3dcompiler_47.dll')
        return
    compiler = ctypes.WinDLL('d3dcompiler_47.dll')
    compile_shader = compiler.D3DCompile
    compile_shader.argtypes = [ctypes.c_void_p, ctypes.c_size_t, ctypes.c_char_p,
                               ctypes.c_void_p, ctypes.c_void_p, ctypes.c_char_p,
                               ctypes.c_char_p, ctypes.c_uint, ctypes.c_uint,
                               ctypes.POINTER(ctypes.c_void_p), ctypes.POINTER(ctypes.c_void_p)]
    compile_shader.restype = ctypes.c_long
    effect_source = (ROOT / '00 MWSE/shaders/XEshaders/UntoDust.fx').read_bytes()
    # Compile the pixel entry point; technique annotations are MGE metadata.
    source = effect_source.split(b'technique T0')[0]
    code, errors = ctypes.c_void_p(), ctypes.c_void_p()

    def method(blob, index, result_type, *args):
        vtable = ctypes.cast(blob, ctypes.POINTER(ctypes.POINTER(ctypes.c_void_p))).contents
        return ctypes.WINFUNCTYPE(result_type, ctypes.c_void_p, *args)(vtable[index])

    result = compile_shader(source, len(source), b'UntoDust.fx', None, None,
                            b'dust', b'ps_3_0', 0, 0, ctypes.byref(code), ctypes.byref(errors))
    diagnostics = ''
    if errors:
        pointer = method(errors, 3, ctypes.c_void_p)(errors)
        diagnostics = ctypes.string_at(pointer).decode(errors='replace')
        method(errors, 2, ctypes.c_ulong)(errors)
    if code:
        method(code, 2, ctypes.c_ulong)(code)
    if result < 0:
        raise RuntimeError('HLSL compilation failed:\n' + diagnostics)
    print('PASS MGE XE HLSL: compiled dust entry point for ps_3_0')
    if diagnostics:
        print(diagnostics)

    # D3DX also validates the actual .fx container and its technique/pass.
    try:
        d3dx = ctypes.WinDLL('d3dx9_43.dll')
    except OSError:
        print('SKIP complete FX compilation: d3dx9_43.dll unavailable')
        return
    create = d3dx.D3DXCreateEffectCompiler
    create.argtypes = [ctypes.c_char_p, ctypes.c_uint, ctypes.c_void_p,
                       ctypes.c_void_p, ctypes.c_uint,
                       ctypes.POINTER(ctypes.c_void_p), ctypes.POINTER(ctypes.c_void_p)]
    create.restype = ctypes.c_long
    effect_compiler, effect, errors = ctypes.c_void_p(), ctypes.c_void_p(), ctypes.c_void_p()
    result = create(effect_source, len(effect_source), None, None, 0,
                    ctypes.byref(effect_compiler), ctypes.byref(errors))
    if result >= 0:
        # ID3DXEffectCompiler::CompileEffect follows ID3DXBaseEffect and
        # SetLiteral/GetLiteral at COM vtable index 59.
        result = method(effect_compiler, 59, ctypes.c_long, ctypes.c_uint,
                        ctypes.POINTER(ctypes.c_void_p), ctypes.POINTER(ctypes.c_void_p))(
                            effect_compiler, 0, ctypes.byref(effect), ctypes.byref(errors))
    diagnostics = ''
    if errors:
        diagnostics = ctypes.string_at(method(errors, 3, ctypes.c_void_p)(errors)).decode(errors='replace')
        method(errors, 2, ctypes.c_ulong)(errors)
    if effect:
        method(effect, 2, ctypes.c_ulong)(effect)
    if effect_compiler:
        method(effect_compiler, 2, ctypes.c_ulong)(effect_compiler)
    if result < 0:
        raise RuntimeError('D3DX effect compilation failed:\n' + diagnostics)
    print('PASS MGE XE FX: complete effect, technique, and pixel shader compiled with D3DX9')
    if diagnostics:
        print(diagnostics)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--lua-library', type=Path, required=True)
    args = parser.parse_args()
    library = args.lua_library.absolute()
    os.chdir(ROOT)
    build(check=True)
    validate_assets()
    run_lua(library)
    compile_hlsl()
