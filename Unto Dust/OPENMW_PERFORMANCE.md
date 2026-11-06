# OpenMW cell-transition stutter — 2026-11-05

Fixed the mod-induced hitch immediately after cell loading by keeping Unto Dust's
post-processing pass resident and changing its density uniform instead of the
shader chain. In two paired real-engine runs (60 warmed transitions per version),
the median post-load peak fell from **18.537 ms to 5.223 ms (71.8%)**. The no-mod
control measured 5.279 ms. Normal synchronous cell loading remains: the median
maximum across the complete transition window was 36.636 ms before and 36.212 ms
after. This is a fix for the additional rendering hitch, not a claim to eliminate
OpenMW's own loading pause.

The fixed player script and generated OMWFX were also installed into
`D:/Games/Morrowind/Data Files`, after checking that both existing files matched
the measured baseline. Installed files were verified byte-for-byte against the
workspace outputs. Original runtime files remain in
`.validation-cache/performance-baseline/00 OpenMW`.

## Cause and change

`updateShader()` previously called `shader:enable(1)` in every eligible destination
cell, including tomb-to-tomb travel, and `shader:disable()` elsewhere. In the
installed OpenMW revision, the Lua enable binding queues a renderer action even
when the shader is already enabled. The renderer removes/reinserts the shader and
rebuilds the chain's dispatch/pass state. Changes therefore affect the other
shaders in the chain too. This is visible in the exact-revision
[Lua binding](https://github.com/OpenMW/openmw/blob/1409c532c8f8fcc8c3bb33fe67f2fa8d76d8dc8d/apps/openmw/mwlua/postprocessingbindings.cpp#L110-L134)
and [renderer implementation](https://github.com/OpenMW/openmw/blob/1409c532c8f8fcc8c3bb33fe67f2fa8d76d8dc8d/apps/openmw/mwrender/postprocessor.cpp#L555-L758).
The API comment about repeated enable calls being harmless does not match this
revision's implementation. This diagnosis concerns pass-state rebuilding, not
recompiling the dust technique's GLSL source.

The fix installs the pass at position 1 only when missing, including after a saved
game is loaded. Cell eligibility, density zero, blacklist/whitelist edits, and
reactivation now control `dustDensity` without removing/reinserting the pass.
The shader starts at density zero and immediately returns the input scene when
inactive, before depth sampling, ray reconstruction, or dust traversal. Dust
animation still pauses while inactive. An inactive pass retains a fullscreen
scene-copy cost; it is not free. Active dust appearance and its traversal are
unchanged.

## Measurements

Hardware/runtime: NVIDIA GeForce RTX 5090 Laptop GPU, driver 610.62,
OpenMW 0.51.0 development revision `1409c532c8`, Lua API 111. Main comparison:
2560×1440, requested 16× antialiasing, VSync off, windowed, post-processing and
transparent postpass enabled. The user's eight-effect chain and shader settings
were read into isolated configs:
`ssao_hq,underwater_interior_effects,underwater_effects,clouds,godrays,bloomlinear,hdr,FollowerAA`.
Tests used Morrowind.esm and the installed Data Files/assets plus these shader
directories, not the entire modded plugin load order or a user save.

| Run | Median post-load peak (ms) | Post-load intervals >16.67 ms | Median whole-window maximum (ms) | Median settled interval (ms) |
| --- | ---: | ---: | ---: | ---: |
| Before 1 | 19.479 | 34 | 37.744 | 3.917 |
| After 1 | 5.038 | 0 | 35.127 | 3.939 |
| Before 2 | 17.856 | 31 | 34.791 | 3.753 |
| After 2 | 5.807 | 1 | 37.134 | 3.784 |
| No mod control | 5.279 | 0 | 34.833 | 3.718 |

Each row contains 30 warmed transitions. Across both paired runs, post-load
intervals exceeding a 60 Hz frame budget fell from **65 to 1** out of 1,140
sampled post-load intervals per version. The small settled-time differences
should not be interpreted as an FPS improvement or a precise GPU-cost estimate.

The initial 1280×720 tests with no other effects did **not** reproduce a clear
mod-induced secondary hitch: post-load peaks were 4.897 ms before and 4.780 ms
after. Their whole-window maxima were 34.251 and 37.216 ms respectively. These
negative results are retained alongside the main results, rather than using
the initial loading pause to claim an improvement.

Method: the global test script records wall-clock intervals between `onUpdate`
callbacks with `core.getRealTime()`. The first interval after a teleport includes
the synchronous load/unload pause. The **post-load peak** is the maximum of the
next 19 intervals; this separate window captures the deferred rendering hitches.
The **whole-window maximum** covers all intervals during the one-second stay,
including the initial loading pause. **Settled** samples begin after those first
20 intervals. These are engine callback intervals, not GPU timer or display
presentation measurements. Logging is identical in both versions and occurs
once per transition, not per frame.

Each launch starts in Andrano, warms up for three seconds, then repeats this route
six times with approximately one second per stop:

1. Andrano → Samarys Ancestral Tomb (dust → dust).
2. Samarys → Andrano (dust → dust).
3. Andrano → Balmora, Caius Cosades' House (dust → clear).
4. House → Andrano (clear → dust).
5. Andrano → exterior at (-17000, -58000, 1000) (dust → clear).
6. Exterior → Andrano (clear → dust).

The first circuit is excluded from the warm statistics but preserved in the raw
data. Runs were serial, in before/after/before/after/control order. User settings
and saves were not modified by the tests.

Durable results: [summary JSON](performance/2026-11-05-openmw/summary.json) and
[per-transition CSV](performance/2026-11-05-openmw/transitions.csv), including the
individual 19 post-load intervals. Full engine logs, configs, and all sampled
intervals are under `.validation-cache/performance/<run>/`.

Baseline SHA-256:

- `player.lua`: `b0343e7d3174311d7036c6075d462d20fe4e2bc8a366640e2a255725fd289508`
- `UntoDust.omwfx`: `05f81883a9fe66ded2fd2ceeaecfc76d7132e69759c9c6b0f5f1ba16ccd6feb4`

## Reproduce and validate

From the mod root, with a fresh label for each run:

```powershell
python tools/benchmark_openmw.py --engine 'D:/Games/OpenMW/OpenMW 0.51.0 Dev' --data 'D:/Games/Morrowind/Data Files' --shader-profile 'C:/Users/ejmon/Documents/My Games/OpenMW' --label repeat-after
```

For the saved baseline add
`--mod '.validation-cache/performance-baseline/00 OpenMW'`; for the control add
`--without-mod`. Omitting `--shader-profile` uses the minimal 1280×720 setup.
The profile option imports only `PostProcessingShaders` data directories,
resolution, antialiasing, chain, and shaders.yaml. Adapt those paths for other
installations. Each run uses a new isolated config/data directory and quits
automatically. The runner rejects engine failures and retains raw samples.

Validation completed:

- All three Lua suites: cell filters, density values, persistence, picker, and
  10,000-cell catalogue. New assertions reject chain mutations across cell,
  settings, and reactivation changes and verify restoration after engine removal.
- Real OpenMW smoke test: compiled/resident shader, one chain instance, both
  camera modes, cell transitions, MCM storage updates and save/load persistence.
  OpenMW exposes no uniform getter; visual eligibility is checked by the Lua
  suite, rather than inferred from resident chain membership.
- GPU suite: dust rendering, texture/mips, density, animation, occlusion and
  parallax; an additional test compiles the actual OpenMW fragment and verifies
  that zero density copies a color-gradient scene with unset camera uniforms.
- Both generated shader sources match their templates; packaging checks and
  packaged texture equality passed. Git whitespace validation passed.

The aggregate `build_shaders.py --check` command reaches and passes both generated
shader checks but then fails because this checkout already lacks
`legacy/00 MWSE/Textures/dust/tx_alpha_dust000.dds`. The existing packaged textures
were unchanged and verified separately. No legacy asset was invented to conceal
that pre-existing build limitation. OpenMW 0.49 and other GPUs were not tested.
