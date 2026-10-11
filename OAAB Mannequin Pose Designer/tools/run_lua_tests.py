"""Run offline checks in LuaJIT, with a real-filesystem bridge for LuaFileSystem."""
import os
import runpy
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / '.work/lua-test-deps'))
from lupa.luajit21 import LuaRuntime

API = Path(r'D:\Games\Morrowind\Repositories\OAAB_Data\01 MWSE Functions\MWSE\mods\OAAB\Mannequins\poses.lua')

def run(script, arguments):
    os.chdir(ROOT)
    lua = LuaRuntime(encoding=None, unpack_returned_tuples=True)

    def attributes(path, key=None):
        target = Path(os.fsdecode(path))
        if not target.exists():
            return None
        mode = b'directory' if target.is_dir() else b'file'
        if key == b'mode':
            return mode
        stat = target.stat()
        return lua.table_from({b'mode': mode, b'modification': int(stat.st_mtime), b'size': stat.st_size})

    def change_dir(path):
        os.chdir(os.fsdecode(path))
        return True

    def make_dir(path):
        Path(os.fsdecode(path)).mkdir()
        return True

    def directory(path):
        return lua.table_from([b'.', b'..'] + [os.fsencode(p.name) for p in Path(os.fsdecode(path)).iterdir()])

    lua.globals().test_fs = lua.table_from({
        b'attributes': attributes,
        b'chdir': change_dir,
        b'mkdir': make_dir,
        b'currentdir': lambda: os.fsencode(os.getcwd()),
        b'directory': directory,
    })
    lua.execute(b'''
        -- MWSE supports __pairs on its sparse native arrays.
        local nativePairs=pairs
        pairs=function(value)
            local mt=getmetatable(value)
            if mt and mt.__pairs then return mt.__pairs(value) end
            return nativePairs(value)
        end
        package.loaded.lfs = {
            attributes=test_fs.attributes, chdir=test_fs.chdir,
            mkdir=test_fs.mkdir, currentdir=test_fs.currentdir,
            dir=function(path)
                local entries=test_fs.directory(path)
                local index=0
                return function() index=index+1; return entries[index] end
            end,
        }
    ''')
    lua.globals().arg = lua.table_from([os.fsencode(a) for a in arguments])
    lua.globals().arg[0] = os.fsencode(script)
    lua.execute(b'assert(loadfile(arg[0]))()', name=os.fsencode(script))

if __name__ == '__main__':
    json_library = Path(r'D:\Games\Morrowind\Data Files\MWSE\core\lib\dkjson.lua')
    if len(sys.argv) > 1:
        API = Path(sys.argv[1]).resolve()
    if len(sys.argv) > 2:
        json_library = Path(sys.argv[2]).resolve()
    sources = list((ROOT / 'MWSE').rglob('*.lua')) + list((ROOT / 'tests').rglob('*.lua')) + [API]
    sources.append(API.with_name('pose_props.lua'))
    run('tests/syntax.lua', sources)
    tests = sorted(p for p in (ROOT / 'tests').glob('*.lua')
                   if p.name != 'syntax.lua' and not p.stem.endswith('_fixture'))
    for test in tests:
        run(str(test), [API, json_library])
    os.chdir(ROOT)
    runpy.run_path(str(ROOT / 'tests/verify_template.py'))
    runpy.run_path(str(ROOT / 'tests/verify_gizmos.py'))
    runpy.run_path(str(ROOT / 'tests/verify_preview_host.py'))
    runpy.run_path(str(ROOT / 'tests/verify_focus_grid.py'))
