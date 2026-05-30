# Dahrk's Super-Sized Storage for OpenMW

This folder contains an OpenMW Lua conversion of the MWSE script.

The original MWSE version runs once at initialization and multiplies every container record capacity by 100.

## How It Works

OpenMW does not expose a stable Lua API for rewriting all loaded container records in place. This version uses a `GLOBAL` script instead:

- When a placed container becomes active, the script creates a generated container record from that container's original record.
- The generated record copies the original model/name/script/flags and uses `weight * 100` as its capacity.
- The script creates a replacement object, copies lock/key/trap state, moves the original contents into it, teleports it to the original position, and removes the original placed container.
- Containers with zero capacity are left unchanged.
- Containers with MWScript/local script state are left unchanged.
- Containers with an exposed ref-persist/persistent flag are left unchanged.

Install by adding this folder as a data path and enabling the script manifest:

```ini
data="path/to/00 OpenMW"
content=DahrksSuperSizedStorage.omwscripts
```

## Notes

This is a runtime object conversion rather than a direct content-record edit. It should cover mod-added placed containers as their cells become active. Scripted and persistent references are skipped to avoid breaking quest or mod state.
