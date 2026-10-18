"""Run actual MWSE Lua modules in an API fixture; not native engine FPS timings."""
import argparse
import ctypes
import json
from pathlib import Path
from performance_openmw import CACHE, ROOT


def execute(lua, module, scenery, iterations, candidate):
    code = f'MODULE={json.dumps(module.as_posix())}\nSCENERY={scenery}\nITERATIONS={iterations}\nCANDIDATE={str(candidate).lower()}\n'
    code += (ROOT / 'tools/tests/mwse_runtime.lua').read_text()
    state = lua.luaL_newstate()
    lua.luaL_openlibs(state)
    try:
        error = lua.luaL_loadstring(state, code.encode()) or lua.lua_pcall(state, 0, 0, 0)
        if error:
            raise AssertionError(lua.lua_tolstring(state, -1, None).decode())
        lua.lua_getfield(state, -10002, b'RESULT')
        return json.loads(lua.lua_tolstring(state, -1, None).decode())
    finally:
        lua.lua_close(state)


def main():
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument('--lua-dll', type=Path, default=Path('D:/Games/OpenMW/OpenMW 0.51.0 Dev/lua51.dll'))
    parser.add_argument('--iterations', type=int, default=1000)
    args = parser.parse_args()
    lua = ctypes.CDLL(str(args.lua_dll))
    lua.luaL_newstate.restype = ctypes.c_void_p
    for name in ('luaL_openlibs', 'lua_close'):
        getattr(lua, name).argtypes = [ctypes.c_void_p]
    lua.luaL_loadstring.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
    lua.lua_pcall.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int]
    lua.lua_getfield.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_char_p]
    lua.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
    lua.lua_tolstring.restype = ctypes.c_char_p
    samples = []
    for scenery in (0, 5000, 20000):
        for candidate in (False, True):
            module = (ROOT if candidate else CACHE / 'baseline') / '01 MWSE/MWSE/mods/FabricantGuar/main.lua'
            result = execute(lua, module, scenery, args.iterations, candidate)
            result.update(variant='candidate' if candidate else 'baseline', scenery=scenery, iterations=args.iterations)
            samples.append(result)
            print(result, flush=True)
    out = CACHE / 'mwse-fixture.json'
    out.write_text(json.dumps({'boundary': 'Lua API fixture; not native Morrowind runtime', 'samples': samples}, indent=2))
    print('PASS MWSE behavioral fixture and algorithm comparison:', out)


if __name__ == '__main__':
    main()
