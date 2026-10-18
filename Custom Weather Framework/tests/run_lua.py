"""Run the weather framework tests with Lua 5.1/LuaJIT using OpenMW's DLL.

python tests/run_lua.py --lua-dll "D:/Games/OpenMW/OpenMW 0.51.0 Dev/lua51.dll"
On other systems: lua tests/openmw_spec.lua
"""
import argparse
import ctypes
import os
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--lua-dll", required=True, type=Path)
    args = parser.parse_args()
    os.chdir(Path(__file__).resolve().parents[1])
    dll = ctypes.CDLL(str(args.lua_dll.resolve()))
    pointer = ctypes.c_void_p
    dll.luaL_newstate.restype = pointer
    dll.luaL_openlibs.argtypes = [pointer]
    dll.luaL_loadfile.argtypes = [pointer, ctypes.c_char_p]
    dll.lua_pcall.argtypes = [pointer, ctypes.c_int, ctypes.c_int, ctypes.c_int]
    dll.lua_tolstring.argtypes = [pointer, ctypes.c_int, pointer]
    dll.lua_tolstring.restype = ctypes.c_char_p
    dll.lua_settop.argtypes = [pointer, ctypes.c_int]
    dll.lua_close.argtypes = [pointer]
    state = dll.luaL_newstate()
    try:
        dll.luaL_openlibs(state)
        for path in (*Path("00 OpenMW").rglob("*.lua"), *Path("00 MWSE").rglob("*.lua")):
            if dll.luaL_loadfile(state, str(path).encode()) != 0:
                raise RuntimeError(dll.lua_tolstring(state, -1, None).decode())
            dll.lua_settop(state, 0)
        print("All OpenMW and MWSE Lua files compile.", flush=True)
        for script in (b"tests/color_spec.lua", b"tests/regionfiles_spec.lua", b"tests/openmw_spec.lua", b"tests/editor_spec.lua", b"tests/mwse_spec.lua"):
            # Each suite must also work on its own, without another suite's mocks.
            dll.lua_close(state)
            state = dll.luaL_newstate()
            dll.luaL_openlibs(state)
            if dll.luaL_loadfile(state, script) or dll.lua_pcall(state, 0, 0, 0):
                raise RuntimeError(dll.lua_tolstring(state, -1, None).decode())
    finally:
        dll.lua_close(state)


if __name__ == "__main__":
    main()
