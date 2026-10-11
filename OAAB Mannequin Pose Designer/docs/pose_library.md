# Visual pose library

The library belongs entirely to Mannequin Pose Designer. OAAB_Data pose API v6
adds a generic `handled` flag to its existing `OAAB:mannequinPoseMenu` event.
Without a replacement listener, OAAB builds its existing menu as before. The
designer handles that event and opens its library on the following frame. If
opening fails, it closes partial UI and asks OAAB to show its original menu.

On entry, the library selects the mannequin's active pose and opens the page
containing it in the filtered, sorted catalog. A mannequin without a saved
selection starts on Relaxed. This only sets the library selection; it does not
apply a pose. Later page changes and refreshes preserve browsing navigation,
and an explicitly retained page takes precedence when returning from deletion.

The library uses up to four columns and two rows, displaying eight poses per
page on larger viewports. Its content width is capped at 1240 pixels, with a
240-pixel category sidebar. Category buttons use the sidebar's available width
and reserve room for their delete controls; long labels wrap. Smaller viewports
retain two or three columns and one row when vertical space is limited.
Category widths include the native buttons' external margins, keeping every
border inside the scroll area. The grid reserves its full row count so Previous
and Next stay in place on short or empty pages. Card names fit one line using
the native font measurement and end in `...` when shortened; the selected
details retain the full name. The footer contains no Refresh button. Metadata
changes still refresh automatically, and reopening discovers
externally installed poses.

Library buttons use MGE XE's `menu_thin_border.nif` style, with zero outer
margins and one-pixel padding. The grid measures the same styled button when
reserving card rows for pagination.

## Initial code investigation

1. **Discovery.** Custom poses are loose main NIFs directly under
   `Data Files/meshes/pose/k`. Filenames use the pose ID directly, without an
   added prefix. Timestamp-style `p[a-z0-9]+.nif` exports remain supported. Geometry, skin and
   keyframe-controller checks exclude animation companions and unusable files.
   OAAB supplies its four stock poses and registered poses through menu entries.
2. **Authoritative NIF.** The main `<id>.nif` contains the skeleton, constant pose
   keys, a hidden skinned shadow and any embedded props. It is the portable pose
   and source of descriptive metadata. It does **not** supply the visible mannequin
   body. That skin is in `oaab/b/mannequin.nif`, including head and body parts.
   A preview loads both and applies the main pose's bone transforms to the body.
3. **Companions.** `x<id>.nif` and `x<id>.kf` are the engine's animation companions.
   Existing bundles keep working. Main-only custom imports remain browsable;
   missing companions are generated when applying/editing them, never during
   browsing. Descriptive metadata is written only to the main NIF.
4. **Names and filenames.** Exports use an explicit stable ID, independently of
   the display name stored in the main NIF. Poses without descriptive metadata
   use filename-derived labels.
5. **OAAB ownership.** The current OAAB stock identities are exactly
   `oaab/k/mann_relax.nif`, `mann_contrapposto.nif`, `mann_adlocutio.nif`, and
   `mann_adlocutio2.nif`. They cannot match the custom mutation whitelist. They
   load through MWSE even when installed in a BSA. Additional registered poses
   outside the custom directory are also treated as read-only.
6. **Reopening.** Apply the saved custom file through OAAB, then start a session
   with that file as `editFile`. The editor captures the live skeleton and normal
   Save replaces that bundle. Save As exports the current edits with a new ID.
7. **Extra data.** MWSE exposes `niStringExtraData.new(string)`, `.string`, `.next`
   and `NiObjectNET:addExtraData`. TES3's NetImmerse 4.0 extra data has no `name`
   member, so a stable string prefix identifies this entry instead. Changes are
   serialized with `saveBinary` to a staged copy and reloaded before publication.
8. **UI rendering.** Following the supplied `fishing/ui/PreviewPane.lua` reference,
   `createNif()` loads a bundled empty UI canvas and `tes3.loadMesh(pose.file,
   false)` attaches the actual main NIF beneath it alongside an uncached
   `oaab/b/mannequin.nif`. Its matching 35-bone skeleton receives the pose's local
   transforms; the skeleton-parent frames are aligned for imported root transforms.
   Controllers on these private instances are removed to keep that pose fixed.
   The main NIF retains its embedded prop graph and hidden shadow. A centered, fixed-size block
   hosts each canvas. A private wrapper applies the viewing angle, scale and
   centering while preserving the authored pose graph and native UI transform.
   Controller evaluation and `createBoundingBox({accurateSkinned=true, ...})`
   measure posed geometry, including props and authored root transforms. Vertex
   color/depth properties and a private light set up rendering. Collision branches
   are culled on the uncached instance. During measurement, collision-disabled
   visual switches are temporarily enabled because MWSE otherwise excludes their
   prop geometry from bounds; their flags are restored afterward. No image
   generation is involved.
9. **Compatibility and performance.** Optional bad metadata falls back safely.
   Native metadata meshes are not retained. Descriptors and file-validity checks
   are cached by file modification time/size, with explicit refresh and mutation
   invalidation. Live previews are limited to the visible page and created one
   per frame; stale callbacks cannot create scenes in destroyed UI.

## Modules and persistence

| Module | Responsibility |
| --- | --- |
| `main.lua` | Optional OAAB menu replacement and lifecycle registration |
| `catalog.lua` | Normalize records, source/category/search filters, sorting |
| `library_menu.lua` | Cards, pagination, selection, actions and bounded preview lifetime |
| `preview.lua` | Native UI canvas, actual mesh attachment, posed bounds, scene lighting and cleanup |
| `preview_scene.lua` | Pose/body assembly, bone matching, frame alignment and prop-aware bounds |
| `pose_metadata.lua` | Safe parsing, validation, graph lookup and staged NIF updates |
| `metadata_prompt.lua` | User-entered names/IDs and descriptive fields; retry on failure |
| `text_repeat.lua` | Held Backspace timing, native caret editing and focused-field lifetime |
| `library.lua` | Discovery, bundle transactions, ID reservation and source copying |
| `session.lua` | Save Changes, Save As and saved-pose editing integration |

The metadata string is `OAAB:PoseMetadata:` followed by a JSON object containing
only these fields:

```json
{"id":"guardlean","name":"Guard Leaning on Spear","description":"Relaxed guard stance.","category":"Standing"}
```

The helper searches linked extra-data lists and child nodes, guards cycles, and
updates the existing identified entry or adds one. Other extra data and geometry
are preserved. No metadata database, thumbnail metadata or runtime properties
are serialized into this entry.

Missing/malformed metadata never triggers a repair or write. Invalid optional
fields fall back individually. A usable metadata-less pose has a filename-derived
label, empty description and an empty category, shown as Uncategorized.
Editing its metadata is the action that adds an extra-data entry.

The library search and all metadata fields explicitly repeat Backspace after a 0.4-second delay, at
0.05-second intervals. Both a paragraph widget and its internal text child are
watched. The original native event is replayed with its source, widget and caret
target intact, without depending on the engine generating repeated key events.
Each menu owns and unregisters its frame/key-release handlers. Native text-update
and text-cleared events refresh search results as the query is erased. Focus changes,
hidden/disabled controls, modifiers and closing cancel a held repeat; typing in
other menus cannot inherit it. Offline checks start with one physical key press
and advance frames to verify repeated caret deletion, multiline text, cadence,
release and cleanup, including search filtering, pagination and suspending the
library for a metadata dialog. Native in-game behavior still requires confirmation.

New IDs start with an ASCII letter or number and contain only ASCII letters,
numbers, underscores or hyphens. The 19-character limit leaves room for the
`pose/k/x` prefix and extension within Morrowind's 31-character animation path
limit. An ID's spelling is used verbatim; collisions are checked case-insensitively
against metadata IDs, filename-derived IDs and all reserved bundle paths,
including orphaned companions. They are errors, not overwrite
requests. Publication rechecks paths after staging and rolls back on failure.

Existing IDs stay fixed during metadata edits. Names can be up to 120 characters,
descriptions 2,000, and categories 80 characters.
Display names may repeat. Categories are user-defined.
Each named category has an adjacent X. Confirmation clears its category field
from every custom main NIF across the full library, independent of the current
source, search, or page. Uncategorized is permanent, and categories containing
read-only OAAB/registered poses have a disabled X. The mutation rechecks the
current files and read-only membership, stages and reloads all affected NIFs,
then publishes them together with rollback on failure. IDs, names, descriptions,
partial imported metadata, geometry, props, and companion files
are preserved. Removing the active category resets that filter to All categories;
cancel/failure retains it. Source, search, sort, and browsing selection survive
the confirmation dialog.
Manually installed duplicate IDs remain separate records and show their paths;
they still prevent creating another pose with that ID.

Normal pose Save patches the existing custom main NIF, preserving its geometry
and extra data. Editable prop definitions use a separate `NiStringExtraData`
entry prefixed `OAAB:PoseProps:`, distinct from portable descriptive metadata.
A shared NIF carries both geometry and editable definitions; individual
prop operations still require the source item meshes. Older geometry-only poses
can use Save As and have their skeleton edited while preserving embedded props.
Deletion removes the custom bundle after explicit confirmation. Other mannequins
still referencing a deleted file need a new pose assigned.

## Preview verification

The packaged `meshes/pose/h/pose_preview.nif` is an empty
NiNode with no pose geometry, metadata or controllers. It is a UI canvas, not a
thumbnail. `tools/build_preview_host.py` reproduces it; there is no dependency on
Fishing or Crafting Framework. Each canvas owns its mesh and light. Destroying it
removes the private light's effect/affected-node links and disables its rotation
controller. The library's existing frame handler advances only the selected
preview at 24 degrees per second. A fixed fit covers the whole yaw sweep, with
rotation around the posed bounds' centre; authored transforms remain intact.

Offline LuaJIT checks cover parsing, graph preservation, real filesystem/template
transactions with mocked native serialization, collisions,
read-only guards, library actions, scene counts, stale timers and existing editor
regressions. They do **not** establish native rendering appearance or native NIF
serialization correctness. In-game verification is left to the user. In
particular, framing/orientation and the engine's treatment of posed skin/controllers
still need confirmation; the preview module is the single adjustment point.

The first 0.3.0 game screenshot showed the title and pose count but a blank body.
Its container rows had no width and its grid/detail blocks had no expanding height,
so native clipping hid their children. Version 0.3.1 assigns explicit widths and
automatic content heights, sizes scroll content independently of its fixed viewport,
and refreshes scrollbar limits after layout. The offline layout fixture now rejects
the 0.3.0 archive and checks visible controls, cards and dialogs at 640x480 through
2560x1440, including the reported screenshot resolution.

The 0.3.1 screenshot confirms the library controls and cards display, while the
model views remain blank. Version 0.3.2 replaces direct pose-NIF UI scaling with
the supplied Fishing viewer's empty-canvas/mesh-attachment approach described
above. Offline checks cover attachment of the actual main mesh, posed bounds,
embedded props, imported root transforms, rendering setup, simultaneous scenes,
cleanup and partial failures. The shipped empty canvas is checked structurally
and parsed independently with PyFFI. Native preview appearance still requires
the user's in-game verification. Creation logs the file, viewport, posed extent
and scale in `MWSE.log` to help diagnose any remaining rendering issue.

Version 0.3.3 fixes the actual missing-body failure from the 0.3.2 test. All cards
reported `Pose has invalid preview bounds`: only the culled shadow was available,
and disabled prop switches were skipped by native bounds traversal. The source
NIF was incorrectly assumed to contain visible mannequin geometry. The corrected
assembly combines the pose with the visible body, following OAAB's direct playback
approach to copying transforms and refreshing bones before body skin.

`tests/verify_preview_models.py` runs the real Lua viewer against parsed NIF
graphs and PyFFI skin deformation, using the actual vertices/weights. It verifies
all 11 currently installed poses, matching 35-bone body transforms, finite framing,
unchanged file hashes and released lights. The triangle-data reader has a scoped
TES3 adapter; no meshes are saved. Native UI rendering still requires the
user's game test. To repeat this offline check with PyFFI and LuaJIT/Lupa available:
`python tests/verify_preview_models.py "D:/Games/Morrowind/Data Files/meshes"`.

Version 0.3.4 corrects the UI canvas path. The 0.3.3 game test confirms the posed
body renders, but the engine looked beneath `Meshes/MWSE/...` for the canvas and
substituted `Marker_Error.NIF`. The canvas now ships in
`meshes/pose/h/pose_preview.nif`; `createNif` receives `pose/h/pose_preview.nif`.
An existence check prevents the error marker fallback for incomplete installs.
The offline viewer fixture resolves the UI path against the real mesh directory,
and archive verification checks that this exact asset is shipped there.

## Focused in-game checklist

1. Install the API compatibility archive and designer archive, then restart.
   With the designer disabled, Change Pose must show OAAB's original menu. With
   it enabled, full mannequins must open the library; dress stands remain excluded.
2. Open the pose library and compare the four stock poses and an imported
   pose with embedded props. Verify distinct poses, framing, readable lighting
   and unchanged source NIFs after browsing and closing the library.
3. Browse more than one page. Search by name, ID, description and category;
   confirm results change with each typed/deleted character and clearing restores
   them, combine filters, cycle sorting, and try an empty result. Select another
   card and confirm only that preview rotates. Watch a full 15-second turn with
   long props/offset poses and check stable centering, scale and clipping. Check 2/3/4 columns,
   1/2 rows, long names, categories and details at your UI scale. Rapidly change
   pages/filter, open dialogs and close the library; check MWSE.log for stale UI
   errors. Only the current page should have live previews.
   Hold Backspace in search: the query must erase at the caret, results and page
   counts must update with each deletion, and clearing must restore all results.
   Release, move focus or open Edit Metadata while holding it; deletion must stop.
4. Create `guardlean` with a long display name. Verify `guardlean.nif`,
   `xguardlean.nif` and `xguardlean.kf`. Inspect the main NIF's string extra data;
   it should contain only the four portable fields. Repeat that ID and a case-only
   variant, plus invalid/too-long IDs: each must report an error and preserve input
   without changing an existing file. Repeated display names with new IDs are valid.
   Hold Backspace in each field, including the ID, and confirm deletion repeats
   at the caret without affecting other fields or editor shortcuts.
5. Edit metadata and save: name/description/category change, ID/filenames and
   animation companions stay fixed. Reopen/restart and check persistence.
   Copy the NIF to another installation and verify its descriptions travel.
6. Browse a metadata-less pose and one with malformed optional metadata. Both must
   remain usable without being rewritten. Add metadata through Edit Metadata;
   its ID and path should stay fixed. Install two files with the same
   metadata ID: both remain listed with separate paths.
7. Test every OAAB pose: Apply is available; Duplicate, Edit Pose,
   Edit Metadata and Delete are absent. Apply, choose Create pose, use Save As with
   a new ID, and compare all stock files' hashes before/after. Also test OAAB
   installed from a BSA if that is your setup.
8. Edit a custom pose and use normal Save/Ctrl+S: the same ID and bundle update.
   Save As asks for a new name/ID, exports the current edits, and selects the new
   bundle while preserving the saved source. Duplicate is absent from the save menu.
   Repeat with embedded props and editable definitions, including an imported
   geometry-only pose without prop metadata.
9. Cancel and confirm Delete; delete the last pose on a page and the selected pose.
   Check page clamping and selected-mannequin fallback to Relaxed. Load a save,
   change cells or remove the mannequin during library/dialog activity: UI and
   queued previews must close safely. On an unwritable custom output, verify save
   failure preserves the original bundle and permits retry/cancel.
10. Assign multiple custom poses to a category, then click its X. Cancel first;
    confirm that nothing changes. Confirm deletion while search/source/page filters
    hide some members: every affected pose must become Uncategorized and the
    deleted category must stay absent after reopening/restarting. Inspect the
    main NIF metadata and confirm IDs, descriptions, props and companion
    hashes remain intact. Try a category shared with a read-only registered pose;
    its X must be disabled. Uncategorized has no X.

## Native API sources

- [NiStringExtraData](https://mwse.github.io/MWSE/types/niStringExtraData/)
- [NiObjectNET and addExtraData](https://mwse.github.io/MWSE/types/niObjectNET/)
- [UI createNif](https://mwse.github.io/MWSE/types/tes3uiElement/#createnif)
- [UI scaleMode](https://mwse.github.io/MWSE/types/tes3uiElement/#scalemode)
- [Paragraph input widget](https://mwse.github.io/MWSE/types/tes3uiParagraphInput/)
- [Local configuration](https://mwse.github.io/MWSE/apis/mwse/#mwsesaveconfig)
