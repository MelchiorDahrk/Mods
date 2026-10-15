# Shader validation

Unto Dust 2.0 replaces the particle meshes in both engines. The common source is
`shaders/dust.glsl`; engine wrappers live beside it. Rebuild the installable GLSL
and HLSL with `python tools/build_shaders.py` after changing these files.
The same command copies the original `tx_alpha_dust000.dds` into each engine's
`Textures/UntoDust/dust.dds`. This single 256 x 256 DXT5 texture includes alpha
and nine mip levels; no flipbook is installed. The shader intersects each ray
with a slowly rotating world-space flake, sampling the image's color and alpha
with explicit LOD. Independent rotations take roughly 50-100 seconds per axis.

The OpenMW wrapper uses the documented 0.49
[post-processing API](https://openmw.readthedocs.io/en/openmw-0.49.0/reference/lua-scripting/openmw_postprocessing.html)
and [OMWFX format](https://openmw.readthedocs.io/en/openmw-0.49.0/reference/postprocessing/omwfx.html).
The MWSE wrapper uses
[mge.shaders](https://mwse.github.io/MWSE/types/mgeShadersConfig/) and
[shader handles](https://mwse.github.io/MWSE/types/mgeShaderHandle/).
OpenMW cells use `isExterior`, rather than the MWSE `isInterior` property.

Run from the mod root, adjusting installation paths:

```powershell
python tools/build_shaders.py --check
python tools/validate_shaders.py --lua-library "D:/Games/OpenMW/OpenMW 0.51.0 Dev/lua51.dll"
./tools/run_openmw_smoke_test.ps1 -OpenMWDirectory "D:/Games/OpenMW/OpenMW 0.51.0 Dev" -MorrowindData "D:/Games/Morrowind/Data Files"
```

`validate_openmw.py` forwards to the new shader validator for compatibility.
The Lua library must have the same architecture as Python. On Windows the
validator also compiles the MGE pixel entry point with `d3dcompiler_47.dll`,
targeting `ps_3_0`. When `d3dx9_43.dll` is available, it also compiles the complete
FX effect, technique, and pass using D3DX9. Both compilation checks passed locally.
These checks do not run MGE XE.
The Lua suites can also run directly with Lua 5.1/LuaJIT from the mod root.

Checks cover burial keywords, case handling, exclusions, nil cells/players,
load/reactivation, stable shader-chain state over 600 frames, time uniforms,
MCM registration, live density changes without simulation updates, 0/default/max
values, persistent configuration, and missing MGE/shader handling. Packaging
checks reject obsolete density directories and modules.
Test OpenMW cells reject undocumented property accesses.
Both Lua suites run the same cell-filter cases from `tests/cell_filters.lua`:
exact names, case and surrounding whitespace, semicolon/newline separation,
commas and Lua-pattern characters in names, blacklist priority over the whitelist
and burial keywords, live edits and clearing while paused, empty/invalid lists,
exterior exclusion, zero density, and persistence across script contexts. Set
values support cell names containing semicolons. MWSE tests also check native
exclusions pages, complete interior enumeration, transfer variables, Reset,
arrow direction, and migration of older text settings. `tests/openmw_cells.lua`
exercises the real picker renderer callbacks: complete world enumeration,
literal search, empty-query prompts, bounded broad-search results, Add/Remove,
Clear, independent list searches, selected cells remaining visible through
search changes, and removal of unavailable cells. OpenMW uses a single-column
search-first layout, with headings above the controls and no pagination.

For a GPU rendering test, run `tools/validate_dust_rendering.py` with a Python
environment containing NumPy and Pillow. It compiles the common GLSL on a hidden
Windows OpenGL context and verifies nonzero output, increasing density, drift,
depth occlusion, camera parallax, negative coordinates, and axis-aligned rays.
It uploads the packaged compressed texture and mip levels, and checks tumbling
and the edge-on silhouette while following a mote's drifting center.
It writes synthetic previews to `.validation-cache/rendering`; those images are
shader test output, not game screenshots. `textured-closeup.png` and
`tumbling.gif` show a magnified flake.

The engine smoke test enables post-processing and the packaged mod in isolated
configuration and saves under `.validation-cache/MCM`. It checks that the
actual shader compiled, that exactly one instance is enabled in matching cells,
that the native Settings group is registered with permanent storage, that menu
writes at 0/32/85 percent update the enabled state, and that transitions, both
camera modes, and save/load retain the correct state and density. It also checks
custom picker registration and complete cell catalogue delivery, whitelist
activation in an ordinary interior, blacklist exclusion of a burial cell and a
whitelisted cell, clearing exclusions, and restoration of both lists and their
effects after save/load. Runtime testing uses the locally installed
OpenMW 0.51.0 development build, revision `1409c532c8`, Lua API revision 111.
OpenMW 0.49.0 and a live MGE XE session have not been tested. The mod uses a
global script to enumerate all interiors and a menu script to register its
cell-picker renderer. Both contexts are available in OpenMW 0.49.0.
The log check rejects OpenGL compilation/link failures and missing texture
messages, including warnings: a Lua shader handle's enabled state alone does
not prove the GPU program compiled.

The shader visits at most 20 grid cells per pixel, with a 768-unit cutoff.
Lighting is an approximation from scene brightness. It does not evaluate local
lights or cast shadows. Occlusion follows the engine's available depth buffer;
transparent surfaces may not occlude consistently. GPU cost scales with screen
resolution and visible depth, so this conversion does not imply a performance
improvement over mesh particles. Cross-engine appearance is not pixel-identical.

Archived particle meshes and textures are preserved under `legacy` and are not
installed as a particle system. Only the static source image is copied into the
shader packages. `tools/build_openmw_meshes.py --check` still checks those old meshes.
