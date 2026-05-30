# OpenMW Lua API Map

This file maps the OpenMW Lua API pages that should be consulted for exact signatures, enums, and examples. Sources checked from the API reference and all linked pages under the Lua API section:

- API index: references/docs/api.md
- Overview: references/docs/overview.md

## Main packages

| Package | Context | Use for | Docs |
| --- | --- | --- | --- |
| `openmw.ambient` | menu, player | Background music, 2D sounds, voiceover for a given player | references/docs/openmw_ambient.md |
| `openmw.animation` | local | Animation controls | references/docs/openmw_animation.md |
| `openmw.async` | global, menu, local, load | Timers and callbacks | references/docs/openmw_async.md |
| `openmw.camera` | player | Camera controls | references/docs/openmw_camera.md |
| `openmw.content` | load | Content record manipulation during load | references/docs/openmw_content.md |
| `openmw.core` | global, menu, local, load | Common game objects, records, cells, time, constants, common functions | references/docs/openmw_core.md |
| `openmw.debug` | player | Debug utilities | references/docs/openmw_debug.md |
| `openmw.input` | menu, player | Keyboard, mouse, controller, actions, triggers | references/docs/openmw_input.md |
| `openmw.interfaces` | global, menu, local, load | Public interfaces of scripts and built-ins | API index entry plus individual interface pages below |
| `openmw.markup` | global, menu, local, load | YAML decode/load from VFS | references/docs/openmw_markup.md |
| `openmw.menu` | menu | Main menu and save management | references/docs/openmw_menu.md |
| `openmw.nearby` | local | Read-only nearby active world objects/cells | references/docs/openmw_nearby.md |
| `openmw.postprocessing` | player | Post-process shader controls | references/docs/openmw_postprocessing.md |
| `openmw.self` | local | Full access to attached object; actor controls; AI enablement | references/docs/openmw_self.md |
| `openmw.storage` | global, menu, local, load | Persistent storage between game sessions | references/docs/openmw_storage.md |
| `openmw.types` | global, local, player | Type-specific object, record, stats, inventory, actor, item helpers | references/docs/openmw_types.md |
| `openmw.ui` | menu, player | User interface layers, windows, widgets, messages, modes | references/docs/openmw_ui.md |
| `openmw.util` | global, menu, local, load | Vectors, transforms, colors, boxes, bit ops, math helpers | references/docs/openmw_util.md |
| `openmw.vfs` | global, menu, local, load | Read-only VFS file access | references/docs/openmw_vfs.md |
| `openmw.world` | global | Read-write game world access | references/docs/openmw_world.md |

## Auxiliary packages

These are built-in Lua helper libraries under `openmw_aux.*`.

| Package | Context | Use for | Docs |
| --- | --- | --- | --- |
| `openmw_aux.calendar` | global, menu, local | Game time calendar helpers | references/docs/openmw_aux_calendar.md |
| `openmw_aux.time` | global, menu, local | Timer helpers and repeated callbacks | references/docs/openmw_aux_time.md |
| `openmw_aux.ui` | menu, player | UI utility helpers | references/docs/openmw_aux_ui.md |
| `openmw_aux.util` | global, menu, local, load | Miscellaneous utility helpers | references/docs/openmw_aux_util.md |

## AI package event payloads

AI packages are started by sending events such as `StartAIPackage` to an actor. Check these pages for required fields.

| Package type | Use for | Docs |
| --- | --- | --- |
| `Combat` | Attack a target | references/docs/ai_combat.md |
| `Escort` | Escort an actor to a destination | references/docs/ai_escort.md |
| `Follow` | Follow another actor | references/docs/ai_follow.md |
| `Pursue` | Pursue a target | references/docs/ai_pursue.md |
| `Travel` | Travel to a destination | references/docs/ai_travel.md |
| `Wander` | Wander near current position | references/docs/ai_wander.md |

## Built-in interfaces

Access built-in interfaces with `require('openmw.interfaces').InterfaceName`.

| Interface | Context | Use for | Docs |
| --- | --- | --- | --- |
| `Activation` | global | Extend or override activation mechanics | references/docs/interface_activation.md |
| `AI` | local | Control basic NPC/creature AI | references/docs/interface_ai.md |
| `AnimationController` | local | Control NPC/creature animations | references/docs/interface_animation.md |
| `Camera` | player | Alter built-in camera behavior without overriding it | references/docs/interface_camera.md |
| `Combat` | local | Control NPC/creature combat | references/docs/interface_combat.md |
| `Controls` | player | Alter built-in player controls | references/docs/interface_controls.md |
| `Crimes` | global | Commit crimes | references/docs/interface_crimes.md |
| `GamepadControls` | player | Controller menu/cursor behavior | references/docs/interface_gamepadcontrols.md |
| `ItemUsage` | global | Extend or override item usage mechanics | references/docs/interface_item_usage.md |
| `MWUI` | menu, player | Morrowind-style UI templates | references/docs/interface_mwui.md |
| `Settings` | global, menu, player | Save, display, and track setting values | references/docs/interface_settings.md |
| `SkillProgression` | player | Override skill use and skill level-up behavior | references/docs/interface_skill_progression.md |
| `UI` | player | High-level UI modes interface | references/docs/interface_ui.md |

## UI widgets

Use these pages when creating `openmw.ui` layouts.

| Widget page | Use for | Docs |
| --- | --- | --- |
| Widget | Base widget properties and events | references/docs/widget.md |
| Container | Generic child container | references/docs/widget_container.md |
| Flex | Row/column child layout and grow/stretch rules | references/docs/widget_flex.md |
| Image | Image display widget | references/docs/widget_image.md |
| Text | Text display widget | references/docs/widget_text.md |
| TextEdit | Editable text input widget | references/docs/widget_textedit.md |

## Other linked reference pages

| Page | Use for | Docs |
| --- | --- | --- |
| Setting Renderers | Settings UI renderers such as textLine, checkbox, number, select, color, inputBinding | references/docs/setting_renderers.md |
| Engine Handlers | Complete handler availability and semantics | references/docs/engine_handlers.md |
| Events | Built-in events and event payloads | references/docs/events.md |
| Iterables | Iterable collection behavior | references/docs/iterables.md |
| Teal | Experimental typed declarations | references/docs/teal.md |

## Practical API selection

- Need to react to a key or controller input: player/menu script with `openmw.input` plus `onKeyPress`, `onKeyRelease`, or controller handlers.
- Need to display HUD or menus: player/menu script with `openmw.ui`, widget docs, and possibly `openmw_aux.ui` or `MWUI`.
- Need to alter camera behavior: player script with `openmw.camera` or `interfaces.Camera`.
- Need to change an NPC or item the script is attached to: local script with `openmw.self` and `openmw.types`.
- Need to scan nearby actors/items: active local/player script with `openmw.nearby`; do not use in inactive or save/load code.
- Need to spawn, move, or modify world objects outside the attached object: global script with `openmw.world`.
- Need to create/delete/edit records before game startup: load script with `openmw.content`.
- Need delayed work: `openmw.async`; use `openmw_aux.time` for convenience timers and repeated callbacks.
- Need persistent values independent of a single script's `onSave`: `openmw.storage`.
- Need VFS data files: `openmw.vfs` or `openmw.markup` for YAML.

