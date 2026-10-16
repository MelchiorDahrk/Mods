"""Static packaging, patch scope, determinism, and optional Lua syntax checks."""
import argparse
import ast
import ctypes
import hashlib
from pathlib import Path
import re
import struct
import xml.etree.ElementTree as ET
from esp import records, field, string
from build_openmw_patch import build

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--lua-dll', type=Path, help='64-bit Lua 5.1/LuaJIT DLL (e.g. OpenMW lua51.dll)')
    args = parser.parse_args()
    core = ROOT / '00 Core/Fabricant Guar.ESP'
    assert hashlib.sha256(core.read_bytes()).hexdigest() == '08f6e9c860b1715b86e51f1b785253724237bf55457ed55717bdfc85c5fec807'
    core_records = list(records(core))
    gizmo = next(fs for tag, fs, *_ in core_records if tag == b'SCPT'
                 and string(field(fs, b'SCHD')[:32]).lower() == 'mdfg_script_gizmo')
    source = string(field(gizmo, b'SCTX')).replace('\r', '').strip()
    assert source == (ROOT / 'tools/mwscript/mdFG_script_gizmo.txt').read_text().strip()
    header = struct.unpack('<32sIIIII', field(gizmo, b'SCHD'))
    assert header[1:4] == (5, 1, 9)
    assert header[4:] == (len(field(gizmo, b'SCDT')), len(field(gizmo, b'SCVR')))
    assert field(gizmo, b'SCDT').endswith(b'\x01\x01'), 'native script compilation is incomplete'
    assert field(gizmo, b'SCVR').split(b'\0')[:-1] == [name.encode() for name in (
        'Companion', 'Topics', 'g_health_ratio', 'g_magicka_ratio', 'g_fatigue_ratio', 'instance',
        'direction', 'ftemp', 'timer', 'currscale', 'tempscale', 'xPos', 'yPos', 'zPos', 'storageStrength')]
    for id_, strength in (('8370743075113210', 100), ('3004223443178475751', 150),
                          ('16709141131934011502', 200)):
        result = next(field(fs, b'BNAM') for tag, fs, *_ in core_records
                      if tag == b'INFO' and string(field(fs, b'INAM')) == id_)
        assert f'SetStrength {strength}'.encode() in result and b'ModStrength' not in result
    patch = ROOT / '01 OpenMW/Fabricant Guar - OpenMW.esp'
    before = patch.read_bytes()
    build()
    assert patch.read_bytes() == before, 'compatibility ESP was not rebuilt deterministically'
    recs = list(records(patch))
    allowed = {b'TES3', b'SCPT', b'CONT', b'DIAL', b'INFO'}
    assert len(recs) == 14 and all(tag in allowed for tag, *_ in recs)
    assert not any(tag == b'GLOB' for tag, *_ in recs)
    names = [string(field(fs, b'SCHD')[:32]) for tag, fs, *_ in recs if tag == b'SCPT']
    assert len(names) == 8
    assert set(names) == {'mdFG_script_' + s for s in ('AIFollow', 'AIGuard', 'imperfectFight',
        'RepairModule', 'SummonGizmo', 'gizmoKey', 'MatrixModule', 'imperfect')}
    assert {string(field(fs, b'INAM')) for tag, fs, *_ in recs if tag == b'INFO'} == {
        '2324171041221531644', '474631467945721504'}
    for tag, fs, *_ in recs:
        if tag == b'SCPT':
            schd = field(fs, b'SCHD')
            assert len(schd) == 52 and field(fs, b'SCDT') == b''
            source = string(field(fs, b'SCTX'))
            assert source.lower().lstrip().startswith('begin ')
    config = ET.parse(ROOT / 'fomod/ModuleConfig.xml').getroot()
    image = config.find('moduleImage')
    assert (ROOT / image.get('path').replace('\\', '/')).is_file()
    for entry in config.iter():
        source = entry.get('source')
        if source:
            assert (ROOT / source.replace('\\', '/')).exists(), source
    groups = config.findall('.//group')
    engine = next(g for g in groups if g.get('name') == 'Game Engine')
    texture = next(g for g in groups if g.get('name') == 'Texture Resolution')
    assert engine.get('type') == texture.get('type') == 'SelectExactlyOne'
    required = list(config.find('requiredInstallFiles'))
    for e in engine.findall('./plugins/plugin'):
        for t in texture.findall('./plugins/plugin'):
            files = {}
            for entry in required + list(e.find('files')) + list(t.find('files')):
                source = ROOT / entry.get('source').replace('\\', '/')
                destination = Path(entry.get('destination').replace('\\', '/'))
                items = source.rglob('*') if source.is_dir() else [source]
                for item in items:
                    if item.is_file():
                        dest = destination / item.relative_to(source) if source.is_dir() else destination
                        files[dest.as_posix().lower()] = item
            if e.get('name').startswith('OpenMW'):
                assert 'fabricant guar.omwscripts' in files and 'fabricant guar - openmw.esp' in files
                assert not any(p.startswith('mwse/') for p in files)
            else:
                assert 'mwse/mods/fabricantguar/main.lua' in files
                assert 'fabricant guar-metadata.toml' in files
                assert 'fabricant guar.omwscripts' not in files
            assert len([p for p in files if p.startswith('textures/')]) == 13
            print(f'PASS install {e.get("name")} / {t.get("name")}: {len(files)} files')
    directory = ROOT / '01 OpenMW'
    for line in (directory / 'Fabricant Guar.omwscripts').read_text().splitlines():
        if line.strip() and not line.startswith('#'):
            flags, path = line.split(':', 1)
            assert (directory / path.strip()).is_file(), path
    for path in directory.rglob('*.lua'):
        for name in re.findall(r"require\(['\"](scripts\.[^'\"]+)['\"]\)", path.read_text()):
            assert (directory / (name.replace('.', '/') + '.lua')).is_file(), name
    for path in (ROOT / 'tools').glob('*.py'):
        ast.parse(path.read_text(), filename=str(path))
    if args.lua_dll:
        lua = ctypes.CDLL(str(args.lua_dll))
        lua.luaL_newstate.restype = ctypes.c_void_p
        lua.luaL_loadfile.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
        lua.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
        lua.lua_tolstring.restype = ctypes.c_char_p
        lua.lua_close.argtypes = [ctypes.c_void_p]
        for path in directory.rglob('*.lua'):
            state = lua.luaL_newstate()
            result = lua.luaL_loadfile(state, str(path).encode())
            error = lua.lua_tolstring(state, -1, None) if result else None
            lua.lua_close(state)
            assert not result, (path, error)
            print('PASS Lua syntax:', path.name)
    else:
        print('SKIP Lua syntax (supply --lua-dll); engine integration is a separate check.')
    print('PASS core checksum, deterministic ESP, minimal record scope, manifest, imports, and Python syntax')


if __name__ == '__main__':
    main()
