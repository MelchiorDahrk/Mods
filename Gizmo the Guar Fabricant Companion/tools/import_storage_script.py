"""Import a natively compiled Gizmo script and fix its three storage results.

Compile tools/mwscript/mdFG_script_gizmo.txt in the Construction Set or MWEdit
first. Pass the saved plugin here; only Gizmo's SCPT and the three upgrade INFO
result bodies are copied/edited in the core. Then rebuild the OpenMW patch.
"""
import argparse
from pathlib import Path
import re
import struct
from esp import records, field, string, encode_record

ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT / '00 Core/Fabricant Guar.ESP'
UPGRADES = {'8370743075113210': 100, '3004223443178475751': 150,
            '16709141131934011502': 200}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('compiled_plugin', type=Path)
    args = parser.parse_args()
    compiled = next(fs for tag, fs, *_ in records(args.compiled_plugin)
                    if tag == b'SCPT' and string(field(fs, b'SCHD')[:32]).lower() == 'mdfg_script_gizmo')
    source = string(field(compiled, b'SCTX')).replace('\r', '').strip()
    assert source == (ROOT / 'tools/mwscript/mdFG_script_gizmo.txt').read_text().strip(), 'compiled source is stale'
    header = struct.unpack('<32sIIIII', field(compiled, b'SCHD'))
    bytecode = field(compiled, b'SCDT')
    assert header[1:4] == (5, 1, 9), 'unexpected local variable counts'
    assert header[4:] == (len(bytecode), len(field(compiled, b'SCVR')))
    assert len(bytecode) > 2000 and bytecode.endswith(b'\x01\x01'), 'native compilation is incomplete'
    output, changed = [], set()
    for tag, fs, unknown, flags in records(CORE):
        if tag == b'SCPT' and string(field(fs, b'SCHD')[:32]).lower() == 'mdfg_script_gizmo':
            old = field(fs, b'SCVR').split(b'\0')[:-1]
            new = field(compiled, b'SCVR').split(b'\0')[:-1]
            assert new[-1] == b'storageStrength' and new[:-1] == [n for n in old if n != b'storageStrength'], 'local indexes changed'
            fs = compiled
            changed.add('mdFG_script_gizmo')
        elif tag == b'INFO' and string(field(fs, b'INAM')) in UPGRADES:
            id_ = string(field(fs, b'INAM'))
            result, count = re.subn(rb'(?m)^(?:ModStrength 50|SetStrength (?:100|150|200))\r?$',
                                    f'SetStrength {UPGRADES[id_]}\r'.encode(), field(fs, b'BNAM'))
            assert count == 1, 'unexpected storage result script'
            fs = [(k, result if k == b'BNAM' else v) for k, v in fs]
            changed.add(id_)
        output.append(encode_record(tag, fs, unknown, flags))
    assert changed == {'mdFG_script_gizmo', *UPGRADES}
    CORE.write_bytes(b''.join(output))
    print('Updated only Gizmo SCPT and three storage upgrade result scripts.')


if __name__ == '__main__':
    main()
