# mwseMCP — Agent Usage Guide

You are driving a **live, running** instance of Morrowind through MWSE. Lua you send executes for real, on the next frame, against the actual game. There is no sandbox. Treat it like pairing with a mod author at their keyboard.

## The one rule: ground before you guess

**This is real MWSE. Verify every field and method name against the API before you use it — do not guess.**

Use `mw_lookup_api` to search the complete, version-exact MWSE API reference. It returns structured results with descriptions, signatures, parameters, and source paths. For a deeper look at any result, follow up with `mw_read_file` on the returned `path`.

| You want… | Do |
|---|---|
| Find a function or type | `mw_lookup_api({ query: "positionCell" })` |
| Check a type's fields | `mw_lookup_api({ query: "tes3reference", category: "field" })` |
| List **all** members of a type/lib | `mw_lookup_api({ query: "tes3mobileActor", members: true })` |
| Find event details | `mw_lookup_api({ query: "cellChanged" })` |
| Keyword search | `mw_lookup_api({ query: "equip item" })` |
| Deeper read | `mw_read_file({ path: "<path from result>" })` |

The stubs are also readable directly:

| You want… | Read |
|---|---|
| A type's fields/methods (e.g. `tes3reference`) | `Data Files/MWSE/core/meta/class/<type>.lua` |
| An event's payload (e.g. `activate`) | `Data Files/MWSE/core/meta/event/<Name>.lua` |
| A namespace's functions (e.g. `tes3.getReference`) | `Data Files/MWSE/core/meta/lib/<lib>.lua` |

Guessing field names (`mobile.health.current` vs `.currentHealth`) wastes iterations and produces confusing `runtime` errors. One `mw_lookup_api` first is faster than three failed evals.

## Project, don't dump

The bridge serializes only what you **return**. Userdata (references, cells, mobiles, the god-objects) come back as opaque stubs — they are **never** deep-walked. So return exactly the primitive fields you need:

```lua
-- GOOD: explicit projection of primitives
local p = tes3.player
return { cell = p.cell.id, x = p.position.x, y = p.position.y, z = p.position.z }

-- USELESS: returns a stub, no data
return tes3.player
```

This keeps responses small, predictable, and shaped the way you asked.

## Tools

- `mw_lookup_api({ query, limit?, category?, members? })` — search the installed MWSE API reference. Handles exact symbols (`tes3.positionCell`), type members (`tes3reference.scale`), events (`cellChanged`), dotted paths (`mge.shaders.load`), and keyword queries (`equip item`). Returns compact structured results with source paths for deeper reads. Pass `members: true` with a type/lib name to get its full member list (direct + inherited, each inherited one tagged with `from`) in one call — cheaper than reading the stub; add `category: "field"` or `"function"` to narrow it. Use this before guessing any API name.
- `mw_eval_lua({ source })` — run Lua; returns the sanitized return value or a `{ phase, message, traceback }` error. Synchronous: you get the result back in one call.
- `mw_get_state()` — a quick curated snapshot (cell, position, vitals, menu mode, combat, time, weather). Use it to orient before acting.
- `mw_show_message({ message, modal? })` — visible in-game confirmation. Great for narrating what you're doing while testing.
- `mw_poll_events({ since? })` — observe live events. Pass back the returned `cursor` as `since`; a non-zero `dropped` means you missed some. First call (no `since`) starts you "from now."
- `mw_wait_for_event({ kind?, where?, since?, timeoutMs? })` — **block in one call until a matching event fires**, instead of polling `mw_poll_events` across several messages (which re-sends the whole transcript each turn and wastes context). The server polls the game for you and returns as soon as a match arrives. Filter by `kind` (string or list) and/or shallow `where` equality on the event's `data` (e.g. `{ cell: "Balmora" }`). Returns `{ matched, timedOut, events, cursor, dropped, waitedMs }`; on `matched:false`/`timedOut:true` nothing fired in time. Pass `since` (a prior `cursor`) to compose with `mw_poll_events`; omit it to wait only for events from now on. Default timeout 30s (max 300s) — keep it under your harness's tool-call timeout.
- `mw_read_file({ path })` / `mw_write_file({ path, content })` — paths are **relative to the Morrowind root**, so they begin with `Data Files/` (e.g. `Data Files/MWSE/core/meta/lib/tes3.lua`). You can read broadly (other mods + the `core/meta` API stubs under `Data Files/MWSE/`); you can only write under `Data Files/MWSE/mods/AgentGenerated/` and `Data Files/shaders/XEshaders/AgentGenerated/`.
- `mw_reload_module({ name })` — hot-reload an agent-generated module (canonicalizes the module name using MWSE's lowercase rules, unregisters its tracked hooks, then re-requires it).
- `mw_reset()` — the emergency brake: unregisters every tracked hook and wipes `_G.Agent`.

## Live prototyping conventions

All agent state lives under one namespace, with one cleanup path:

```lua
_G.Agent = { modules = {}, questState = {}, hooks = {} }
```

- **Register every event handler via `bridge.registerHook(eventName, fn)`** — never raw `event.register` — so `mw_reset()` can unregister it. Leaked hooks are the most common way a prototype "won't stop happening."
- Emit your own events with `bridge.emit(kind, data)`; they land in the same buffer you read with `mw_poll_events`. Keep `data` to a plain table of primitives/nested plain tables. This is how you watch your own quest logic fire.
- Keep generated files under the `AgentGenerated/` directories; never write outside them.
- MGE XE loads a generated shader with an extensionless name relative to
  `XEshaders`, for example
  `mge.shaders.load({ name = "AgentGenerated/MyShader" })`. Nested folders are
  supported by the installed MGE XE; forward slashes are the documented
  convention.
- For custom menus, sliders, UI events, shader bindings, and cleanup gotchas,
  read [`MWSE_UI_QUICK_REFERENCE.md`](MWSE_UI_QUICK_REFERENCE.md) before
  implementing.

## Working style

- Query state before acting; show a message box when you change something visible.
- Prefer small, return-a-value evals over large monolithic scripts.
- Avoid irreversible save changes unless explicitly asked — assume the author is on a disposable dev save, but don't abuse it.
- If an eval errors, read the `traceback`, then read the relevant `core/meta` stub before retrying.
