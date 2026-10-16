"""Rebuild the narrowly scoped OpenMW compatibility ESP; never writes the core ESP."""
from pathlib import Path
import struct
from esp import records, field, string, script, plugin, encode_record

ROOT = Path(__file__).resolve().parents[1]
CORE = ROOT / '00 Core/Fabricant Guar.ESP'
OUT = ROOT / '01 OpenMW/Fabricant Guar - OpenMW.esp'


def build():
    original = list(records(CORE))
    sources = {string(field(fs, b'SCHD')[:32]).lower(): string(field(fs, b'SCTX')).replace('\r', '')
               for tag, fs, _, _ in original if tag == b'SCPT'}
    overrides = {}
    for name in ('AIFollow', 'AIGuard', 'imperfectFight'):
        id_ = 'mdFG_script_' + name
        overrides[id_] = f'Begin {id_}\nStopScript {id_}\nEnd\n'
    for name in ('RepairModule', 'SummonGizmo'):
        id_ = 'mdFG_script_' + name
        overrides[id_] = f'Begin {id_}\nlong pending\nset pending to ( pending + 1 )\nStopScript {id_}\nEnd\n'

    # Inventory scripts also run during dialogue in OpenMW. Only report an
    # unavailable form when the whistle is used, consuming the event first.
    # Preserve the existing locals so saved whistle instances remain compatible.
    src = sources['mdfg_script_gizmokey']
    start = src.index('if ( mdFG_global_dead == 1 )')
    end = src.index('If ( status == 10 )', start)
    src = src[:start] + '''if ( MenuMode )
    return
endif

if ( OnPCEquip == 1 )
    set OnPCEquip to 0
    set status to 0
    if ( mdFG_global_dead == 1 )
        MessageBox "Gizmo is dead."
        return
    endif
    if ( mdFG_global_matrixform == 1 )
        MessageBox "Gizmo does not respond while entangled."
        return
    endif
    if ( mdFG_global_imperfect == 1 )
        MessageBox "Gizmo does not respond while transformed."
        return
    endif
    set status to 10
endif

''' + src[end:]
    overrides['mdFG_script_gizmoKey'] = src

    # These two callers can delete themselves before a global hook is read.
    # Keep their requests and references alive until Lua acknowledges them.
    src = sources['mdfg_script_matrixmodule']
    src = src.replace('short button', 'short omwSummon\nshort omwRevive\nshort button', 1)
    begin = src.index('if ( OnPCAdd')
    src = src[:begin] + '''; Lua stages inventory before allowing native resurrection.
if ( omwSummon == 2 )
    "mdFG_gizmo"->Resurrect
    set omwSummon to 3
    return
endif
if ( omwSummon == 4 )
    set untangle to 0
    set omwSummon to 0
    Disable
    SetDelete 1
    return
endif
if ( omwSummon != 0 )
    return
endif

''' + src[begin:]
    src = src.replace('set mdFG_global_dead to 0', 'set omwRevive to 1')
    start = src.index('if ( untangle == 1 )')
    src = src[:start] + '''if ( untangle == 1 )
    ; Per-reference request: Lua captures this matrix's destination, not Player's.
    set omwSummon to 1
endif

End
'''
    overrides['mdFG_script_MatrixModule'] = src
    src = sources['mdfg_script_imperfect']
    src = src.replace('float ftemp', 'short omwSummon\n\nfloat ftemp', 1)
    src = src.replace('StartScript mdFG_script_imperfectFight', '; Combat is managed by actor-local OpenMW Lua.')
    start = src.index('; imperfect form')
    end = src.index('; following', start)
    src = src[:start] + '''; Keep the source alive until Lua has captured and accepted its position.
if ( omwSummon == 4 )
    Disable
    SetDelete 1
    return
endif
if ( mdFG_global_imperfect == 2 )
    if ( omwSummon == 0 )
        set omwSummon to 1
    endif
    return
endif

''' + src[end:]
    overrides['mdFG_script_imperfect'] = src
    body = [script(k, v) for k, v in overrides.items()]
    # Empty, disabled transaction storage, created only during resurrection.
    body.append(encode_record(b'CONT', [(b'NAME', b'mdFG_omw_revival_store\0'),
        (b'FNAM', b'Gizmo revival inventory\0'), (b'CNDT', struct.pack('<f', 1000000)),
        (b'FLAG', struct.pack('<I', 8))]))
    topic = None
    for tag, fs, unknown, flags in original:
        if tag == b'DIAL':
            topic = (fs, unknown, flags)
        if tag == b'INFO' and string(field(fs, b'INAM')) in ('2324171041221531644', '474631467945721504'):
            body.append(encode_record(b'DIAL', *topic))
            patched = [(k, v.replace(b'"[Cancel] 1000', b'"[Cancel]" 1000').replace(
                b'Player->AddItem" mdFG_integral" 1', b'Player->AddItem "mdFG_integral" 1') if k == b'BNAM' else v)
                       for k, v in fs]
            body.append(encode_record(tag, patched, unknown, flags))
    # The greeting compiles but a runtime AddItem check fails to award its item.
    # Use the sizes already declared by the core, so rebuilding is portable.
    header = original[0][1]
    deps = [(k, v) for k, v in header if k in (b'MAST', b'DATA')]
    hedr = struct.pack('<fI32s256sI', 1.3, 0, b'Melchior Dahrk',
        b'Fabricant Guar Lua compatibility for OpenMW 0.51.0.', len(body))
    OUT.write_bytes(encode_record(b'TES3', [(b'HEDR', hedr)] + deps +
        [(b'MAST', CORE.name.encode() + b'\0'), (b'DATA', struct.pack('<Q', CORE.stat().st_size))]) + b''.join(body))
    print(f'Built {OUT.name}: {len(body)} overrides/support records, {OUT.stat().st_size} bytes')


if __name__ == '__main__':
    build()
