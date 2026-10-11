# Implementation notes

`main.lua` registers a listener for `OAAB:mannequinPoseMenu` after initialization.
The existing OAAB interaction/ownership code remains responsible for access. API
v6's generic `handled` flag suppresses the stock UI while `library_menu.lua` opens
a deferred replacement. OAAB retains its original menu with no handler. The
library and metadata code are entirely in Pose Designer. Editor entry revalidates
the chosen saved identity after closing the library. OAAB's selected `poseFile`
is committed only after export and direct pose application succeed. See
[pose_library.md](pose_library.md) for the full design and verification boundaries.

`controls.lua` holds the six ordered help categories, control descriptions,
scan-code names, shortcut display formatting, and quick-guide context lists.
`session.lua` resolves keyboard keys through this catalog while retaining its
existing modifier precedence, drag gates, and modal ownership. Reset-menu
shortcut labels use the same catalog. Mouse gestures remain in the existing
input handlers; the catalog describes them without replacing transform logic.

Handle picking visits the selectable bones in order, choosing the nearest pivot
within 18 screen pixels. If the selected pivot is within one pixel of that
candidate and still within click range, it retains selection. Stock Bip01 and
Pelvis transforms place both markers at effectively the same point; this matches
the selected marker's rendering priority and prevents root drags becoming pelvis
rotations. Tab / Shift+Tab still select either bone independently.

`gizmos.lua` loads the authored `pose/h/gizmo.nif` under the bone handle root, so focus
visibility and normal session cleanup cover the complete controls branch. It
recursively discovers components without flattening the source hierarchy.
It uses the fresh, uncached scene directly, retains the authored handle materials, and
resolves inherited properties after attaching the complete graph. It sizes its circle radius to 70 pixels using the
transformed source shape bounds and camera projection. The six interactive
NiTriShapes map `X_move/Y_move/Z_move` to movement axes and `X/Y/Z` to rotation
axes. The nested `rotate` NiSortAdjustNode retains its sorting mode, accumulator,
alpha property, and scale. Both arrows and rings are children of that sorting
node; arrow scales of 6.4 combine with the group's 0.2 scale. Its `sphere` stays active in rotation mode as a
transparent depth mask, with its original material, alpha property and
NiCollisionSwitch ancestry; it is excluded from the handle map. Mode visibility
culls the inactive mode's shapes and toggles the sphere with the rings, while
the shared `rotate` sorting node and collision switch stay active in both modes.
The mask-first child order and grouped render pass stay intact. The root's
unlit NiVertexColorProperty and disabled NiFogProperty remain inherited.
No alpha or depth properties are injected or
replaced. Idle arrows and rings use their exact original material properties,
including the authored diffuse and emissive colors. Hover/drag temporarily
assigns a private material copy with amber diffuse/emissive colors to only the
active component. Leaving it, switching modes, hiding controls, or cleanup
restores its original material property. The copies are created on first use
and reused, leaving material alpha intact. The sphere's material,
including its zero alpha and zero emission, is never changed.
A camera `windowPointToRay` and a
`tes3.rayTest` restricted to that branch pick actual component triangles;
gizmo hits retain the selected joint and take priority over bone marker selection.
V and modal visibility gate both drawing and picking.
The `node` NiTriShape stays culled in this graph and outside the axis and mask
maps; `markers.lua` clones it separately for every selectable bone.

`gizmo_picking.lua` adds a six-pixel screen-space tolerance for rotation rings
after an exact triangle miss. It caches read-only source vertices and unique
mesh edges, retains each shape's complete world transform, and finds the nearest
projected edge. Projected bounding boxes skip distant cursors. The closest-edge
ray recovers the correct 3D point under perspective; intersections against the
authored sphere's triangles reject masked back arcs. Direct ring hits are also
checked against that mask. Exact hits take priority over fuzzy ones, and ties
use depth and a stable axis order. Hover and drag entry share the same picker.
Movement arrows keep exact picking. No collision or render geometry is added,
scaled, or edited. Offline tests cover both sides of the tolerance, zoom,
overlapping rings, hidden modes, fuzzy hover/drag, and masked arcs in orthographic
and perspective views.
Triangle access uses the installed MWSE API's `vertices` field. Optional picking-data initialization
is protected: a failure is logged and falls back to exact handle picking,
preserving editor startup, the sphere's rendering, and the source NIF.

`gizmo_math.lua` freezes the starting world frame and uses ray/plane intersections
for dragging. Arrow deltas project onto the selected axis, and ring angles use signed successive arm vectors
around the physical local axis. Angles accumulate complete revolutions. Fine
adjustment scales each increment without slowing the pointer. Singular rays
and behind-camera intersections leave the pose unchanged. Root translation
converts world deltas through the skeleton parent frame; IK targets feed the
existing solver, locks and symmetry. Props convert through their attachment
parent. Root camera following waits until mouse-up during constrained movement
to avoid including the previous pose delta in the next ray. Each drag shares
existing history and checkpoint handling; a click with no movement restores
its prior undo/redo lists. The gizmos are outside the actor skeleton and never
enter pose exports.

`tools/nif_geometry.py` reads the authored NIF's static TES3 node, shape, data,
and material, vertex-color and fog blocks for offline QA. `tests/verify_gizmos.py` checks the current authored
file hash, the `node` marker and all six axis names, shared sorting ancestry, nested transforms, sorting and masking
properties, axis directions, geometry indices, UVs, bounds and materials.
The integration never rewrites or reclones the loaded NIF graph or its accumulator.
Temporary highlight copies allow circles and arrows to highlight independently
even when they share the same authored material. Idle rendering never overrides
that material's emission or other values.

`overlay.lua` displays the friendly bone name with the unchanged node name
underneath, live mode/axis/angle, Focus and Symmetry status, and no more than
eight quick controls. The effective left drag selects rotation, root movement,
IK target, or IK pole context; right/middle drags select viewing context. A blend
preview shows its four dialog controls and percentage on the left, retaining
hidden editing handles and cursor while the native blend dialog owns input.
Quick-control IDs stay in the Lua catalog; native UI labels receive only their
text, visibility, and layout properties. MWSE rejects arbitrary fields on these
elements. The overlay test models that restriction and checks rendered shortcut
text instead of attaching test metadata to native labels.

H toggles `session.expandedControls`; `overlay.lua` replaces the quick rows with
all six categories inside the existing transparent Controls help-layer menu.
The menu, right-hand status block, cursor, and scene handles are reused. Its
horizontal layout contains a left sidebar, empty spacer, and right sidebar,
using [`childAlignY=0.5`](https://mwse.github.io/MWSE/types/tes3uiElement/#childaligny)
to center each expanded side vertically within the taller side's height.
Expanded sidebars are at most 460 pixels wide
and 32% of the available viewport width; the spacer reserves the central work
area. Transform, Selection, Edit, and Save / Exit occupy the left, balancing the
live status, Modifiers, and View on the right. The existing menu spans the
viewport with 12-pixel outer margins. After measuring content, `positionY` sets
the expanded menu's top edge at half its own height, centering the menu on the
screen. Combined with child alignment, each side's vertical midpoint stays at
the screen midpoint even when their heights differ. The top is clamped to half
the viewport height minus the margin when content exceeds the available height.
Compact controls retain their top anchor at the right edge with `childAlignY=0`;
Blend uses that top anchor on the left beside its modal dialog.

Within each category, auto-sized horizontal rows align gold shortcut labels
beside white action descriptions with a 12-pixel gap, keeping both at the top
when one wraps. Notes have separate auto-sized rows. MWSE's
[`wrapText`](https://mwse.github.io/MWSE/types/tes3uiElement/#wraptext) sets
proportional height, so row containers keep that sizing local to their text.
`controls.full()` groups related numpad orbit/zoom pairs and excludes entries
marked `dialogOnly`. The three blend-menu controls (pose lists, slider, and
Use blend) remain in that dialog's quick guide; B stays in the expanded
Modifiers category. Other editor shortcuts and explanatory notes remain
represented.
The content determines the sidebar height; there is no separate help window,
fixed-height viewport, scrollbar, hit rectangle, or help-specific mouse handler.
All text passes mouse input through, retaining the default pose, orbit, pan, and
wheel zoom behavior. H or Esc collapses the same sidebar, with the existing
consumed-Esc guard preventing a held key from cancelling the session. Modal
dialogs retain their input ownership, hide the controls as before, and restore
the expansion setting afterward. Blend temporarily uses its compact guide.
Expanded controls keep per-frame lifecycle checks and are cleaned up with the
original overlay on every exit path; toggling them changes no pose history,
locks, or checkpoints. The strict native UI fixture tracks actual child order,
word wrapping, and top-edge descendant coordinates. It checks all visible
labels against all four viewport edges (including Save / Exit), rather than
using menu height alone as evidence that content is on screen.

Pose API v3 accepts an optional `deleteCallback(reference, page)` on menu entries.
When present, it builds a native modal menu with an X beside each deletable entry;
menus without deletable entries retain the existing message box. Selection, page
navigation, and deletion callbacks resolve safe handles after the menu closes.
The designer confirms deletion before removing the exact custom NIF and its two
companions, then reopens the same page (clamped if the last page was removed).
Stock files, draft paths, and paths outside the custom library are refused. A
selected pose is changed to Relaxed before its files are removed; a failed removal
is reported and restores the original selection while the main NIF still exists.
The designer still initializes with pose API v2 and supplies creation/selection
entries, omitting only the v3 delete callbacks when that API update is absent.

`rig.lua` discovers the actor's Bip01 branch and named skeletal nodes at runtime.
Equipment geometry and duplicate skeletons inside attached body parts are not
exported. It captures local transforms in parent-first order. World transforms are
computed using the live skeleton parent's frame, so world yaw, non-unit scale, and
reference position do not enter the serialized animation. Scene replacement ends
the session before stale actor nodes are accessed.

The supplied `arp-body_retargeted.blend` contains 34 TES3 deform/attachment bones
on the `Bip01` armature, 249 bones on the Auto-Rig Pro `rig`, and a separate 66-bone
`Rig`. Inspection found eight two-bone IK constraints (including no-stretch
variants), with hand/foot targets and arm/leg poles. The implementation follows
that two-bone target/pole behavior; it does not embed Blender's control rig, stretch
systems, foot-roll mechanism, or constraints into Morrowind. The runtime hierarchy
is authoritative. Blender's `.L` / `.R` suffixes map to TES3's `Bip01 L ...` /
`Bip01 R ...` names. `tools/inspect_blend.py` reproduces the recorded inspection.

`math3d.lua` is engine-independent. Analytic two-bone IK preserves segment lengths,
clamps unreachable and singular targets, and preserves the effector's orientation.
Direct rotation defaults to the camera's viewing direction, expressed in the
selected bone's world frame and applied to its local transform. Rotated ancestors,
reference viewing yaw, and scale therefore preserve screen-plane rotation.
Holding X/Y/Z temporarily uses that local bone axis; key release restores the
previous held axis or camera rotation for the next drag. Ctrl+Z/Y remain history
shortcuts. Every result is orthonormalized before applying IK locks.

Rotation drag state lives in `session.lua`'s existing `s.drag`. Mouse-down projects
the selected joint with the same native `worldPointToScreenPoint` API as the
handles, saves its screen coordinates and local rotation, and freezes the axis.
Matrices are row-major with column vectors, and `rig.world` composes parent *
bone. Local X/Y/Z are already bone-local; Camera uses transpose(starting world
rotation) * camera forward to convert its world axis into that starting frame.
The result is startRotation * axisAngle(frozen local axis, effective angle).
For local axes facing the viewer, a frozen sign makes clockwise mouse travel
rotate clockwise as seen from that view. Edge-on axes use a fixed sign too;
their projected motion cannot define a circular screen direction.

MWSE screen Y points up. The mouse angle is atan2(jointY - cursorY, cursorX -
jointX), so clockwise travel adds positive angle. Every mouse event adds the
shortest incremental arc, correcting deltas beyond +/-pi by one full turn.
The total remains unwrapped across multiple revolutions; Ctrl scales only that
new increment by 0.15. The pointer uses raw mouse movement and viewport bounds.
Each frame rebuilds the selected rotation from the copied starting matrix, then
uses the existing lock/symmetry/application path and one undo/checkpoint per drag.
The overlay shows the frozen axis and effective accumulated degrees.

An angle within four pixels of the pivot is undefined. Leaving that radius
establishes a baseline; crossing it, including a single event whose segment
passes through it, retains the current rotation and rebases the angle. A joint
outside the camera view cannot begin an angular drag. As with any sampled angular
input, travel exceeding 180 degrees between events is ambiguous and follows the
shortest arc. Camera and Local are the editor's existing rotation spaces; it has
no separate World or Parent rotation mode. Camera navigation, translation,
IK, and NIF serialization keep their existing transform conventions.

IK locks hold effector position and orientation in the live skeleton parent's
frame, so camera navigation leaves the pose and its anchors fixed. After
each pose edit, the locked chains compensate with analytic IK. An explicitly
rotated upper bone stays fixed while its lower joint aims at the anchor. An
explicitly rotated lower bone retains its local bend while the upper joint aims
the fixed chain shape. These cases use the nearest point on the remaining reach
sphere; unrestricted chains use the ordinary two-bone reach limits. Forced moves
rebase the position anchor to avoid returning toward an obsolete target. Direct
effector edits update its position/facing anchor; pole edits retain the anchor.
Single-bone resets also enforce the remaining locks. Limb and entire-pose resets
rebase affected locks to the restored pose. Undo/redo snapshots include deep copies
of both bone transforms and lock anchors, and locks are never serialized into
the NIF. The vector alignment calculation uses atan2 of the cross-product length
and dot product to retain small corrective rotations without losing precision
near parallel directions.

`rig.reset` restores local translation, rotation, and scale from `s.initial`
for a single bone, the selected bone's descendant branch, or the entire skeleton.
Capture order is parent-first, so limb membership propagates through parent
indices and includes hidden controls and attachment offsets without selecting
ancestors or siblings. The result owns separate arrays and reports every targeted
index for lock rebasing. Entire-pose reset restores the exact initial asymmetry
and bypasses live symmetry; bone and limb resets follow the active symmetry
scope. Explicit descendant targets are passed to `mirror.follow`, so even an
already-restored source joint reflects onto its independently posed counterpart.

`reset_menu.lua` supplies the Shift+Backspace selector with Reset Bone, Reset
Limb, and Reset Entire Pose choices and their shortcuts: Backspace,
Ctrl+Backspace, and Ctrl+Shift+Backspace. Menu commands and shortcuts share one
session path with one undo snapshot, immediate pose application, and one draft
checkpoint. Enabled locks within a reset branch adopt the resulting anchors;
old anchors cannot undo the reset. Cancel/Escape leaves the pose and history
unchanged. Pending and active reset menus own input, hide the overlay, preserve
focus, and receive per-frame lifecycle checks even without simulation updates.
Cleanup closes them and guards late callbacks against modifying ended sessions.

`mirror.lua` reflects TES3 anatomical coordinates independently of the editing
camera and reference placement. The skeleton parent's left/right axis is X,
Bip01's is local Y, and the other skeletal bones use local Z. A local translation
is reflected in its parent's coordinates; a rotation is multiplied by the parent
reflection on the left and the bone reflection on the right, preserving positive
determinant and bone facing. Paired names are matched case-insensitively, and all
sources come from the unchanged input pose so two-way swaps cannot overwrite
their second source. Entire-pose mirroring also reflects central bones; directional
copy modifies only the destination's paired limbs. Arms include the clavicle
branch and fingers, and legs include thigh/calf/foot branches. Missing counterparts
are skipped. Weapon/Shield Bone retain their local offsets and inherit hand edits.

`mirror_menu.lua` supplies the M modal with Entire Pose, Arms, and Legs targets,
Mirror and both Copy directions. Deferred menu activation follows the name
dialog's input ownership pattern. Pending and active mirror menus suppress
editor input, hide the overlay, preserve focus, and close during every session
cleanup path. The chosen target is remembered within the session. Each command
captures one undo snapshot, applies the pose, and writes one checkpoint. Lock
flags remain on their existing sides; anchors whose tip or ancestor changed are
rebased to the resulting pose. Solving against old anchors would undo the explicit
mirror command, so only subsequent manual edits run lock compensation. Undo/redo
restores the pose and anchors together. Geometry checks read the bundled Relaxed
skeleton and verify joint positions and axes against geometric plane reflection,
including shifted roots, torso twists, non-unit scales, and arbitrary reference frames.

`symmetry_menu.lua` supplies the S selector with Off, Full Symmetry, Arms Only,
and Legs Only. The mode starts Off each session and appears in the compact
overlay status. Selection changes an editing setting without rewriting the pose or
adding history/checkpoints. Its modal follows the mirror menu's deferred input
ownership and lifecycle guards, preserving focus and blocking editor input
until it closes.

`mirror.follow` applies the same anatomical reflection to the selected bone
and changed joints in its source-side limb branch after manual edits and source
lock compensation. Only their paired destinations change; unrelated opposite
joints, other limbs, central bones, and equipment offsets retain their local
transforms. Full covers both arms and legs, while scoped modes filter by limb.
Drags and Backspace resets rebase affected destination lock anchors after
reflection, so old destination anchors cannot cancel the mirrored edit. Each
ordinary edit snapshot/checkpoint already contains both sides and their anchors;
undo/redo restores them together without changing the symmetry setting. Turning
the reference and moving the camera do not enter this path. Offline regressions
cover real-skeleton transforms, both source sides, IK targets/poles, direct
locked-joint edits, missing pairs, scope isolation, resets, history, and cleanup.

`blend_menu.lua` supplies the B dialog with two independently scrolling default
and custom pose lists and a native 0–100 slider (`PartScrollBar_changed`, read through
`slider.widget.current`). It sits at the right of the view for live preview.
Native scroll panes have proportional sizing defaults, so the dialog clears
those fields and sets fixed viewport dimensions with matching minimum/maximum
sizes. The separate scroll content container grows vertically to contain each
choice; scrollbar limits are refreshed after layout. Position changes receive
a subsequent layout pass so the menu scene moves before any user interaction,
including after modal activation. The UI regression fixture models these
defaults and checks visible list heights and rendered coordinates.
`library.blendList` prepends the four OAAB defaults, labeled `(Default)`, to the
custom list. `library.list` continues to list only saved custom files for the
ordinary pose-menu extension. The blend-specific defaults match OAAB's stock
paths without requiring a pose API update. Whitelisted defaults are loaded
directly through `tes3.loadMesh`, which also resolves BSA assets; custom imports
retain their loose-file geometry validation. Both kinds validate the skeleton
and bone keyframe controllers. `tests/default_poses.lua` reads OAAB's actual
stock NIF blocks into engine-shaped node fixtures and verifies capture, parent
matching, endpoints, and exportable midpoint transforms for all sixteen pairs.
`library.read` captures and validates local skeletal transforms from the main
NIF without applying an animation or creating companions. A dialog caches the
two loaded sources; slider changes never re-read them or accumulate edits.
`blend.align` matches case-insensitive bone and parent names against the live
skeleton, retaining its index order and rejecting incompatible skeletons.
`blend.apply` lerps local translation and scale and converts row-major rotation
matrices to normalized w/x/y/z quaternions for shortest-arc slerp. Negative dot
products flip the second quaternion's sign; near-identical inputs use normalized
linear interpolation. Exact 0/100 endpoints copy the source transforms.

Preview applies the result directly and rebases all enabled lock anchors without
running IK or symmetry over the blend. The native dialog owns edit input while
the editor retains the camera, frozen focus updates, animation suppression, and
scene lifecycle checks. Use blend records the pre-dialog bones/locks as one undo
snapshot and writes one checkpoint. Cancel/escape/external destruction restores
that snapshot without changing undo, redo, or drafts. Cleanup discards late
callbacks. Load and topology errors stay in the dialog and disable acceptance
until a successful preview. The ordinary name/save path exports an accepted blend.

`nif.lua` patches the three bundled OAAB Relaxed animation templates. It keeps
the template geometry, skin data, attachment nodes, text keys, controller flags,
and key timing intact, and replaces the 35 bone transforms and constant key values.
Serializing the live actor scene would capture equipment, effects, engine
controllers, and reference transforms.

The main NIF carries local transforms and matching animation keys, allowing a
recipient to rebuild the companions from that file alone. Local transforms are
authoritative when importing these static pose files. Files without mannequin
geometry are withheld from the pose menu because they are not safe animation
overrides. No general-purpose NIF parser or arbitrary animation editor is claimed.

Saved bundles live in `meshes/pose/k`. Create pose
uses Save As; Edit Pose retains `s.editFile` independently of the starting pose
and current edit buffer. Enter opens `save_menu.lua` for saved-pose editing,
with Save Changes, Save As, and Edit Metadata. Ctrl+S saves changes only in
custom Edit Pose sessions. Enter opens Save As directly for new sessions; there
is no separate Save As hotkey. Modified S presses other than plain Ctrl+S are
consumed without a save or symmetry action. All four baseline OAAB file identities
are recognized regardless of case or slash direction and refuse Edit Pose entry.
Ctrl+S on a baseline or implicit Relaxed starting point shows an error directing
the user to Enter / Save As, without writing, changing selection or closing the
editor. New sessions from custom sources likewise require Save As first.

Portable descriptive fields now use `pose_metadata.lua` and the main NIF's
`NiStringExtraData`; poses without descriptive metadata use filename-derived
labels. IDs and filenames remain fixed when metadata changes. Creation and Save As
ask for explicit new IDs and refuse collisions. Names can be equal.
`metadata_prompt.lua` handles all four fields, fixes IDs during metadata edits,
and keeps input intact on validation or write failure. Save As exports the current
edit buffer under a new identity. Metadata changes remain committed if a
later skeleton-edit session is canceled.

The short ID input uses content-sized width inside a fixed, clickable border.
Morrowind's native `PartTextInput` key handler checks the input's laid-out width
plus its horizontal borders against the parent's inner width when a character
limit is enabled. `widthProportional=1` makes that check fail even with empty
text, so this single-line field uses `autoWidth=true`. Long names, descriptions,
and categories use wrapped paragraph inputs, whose widget exposes only a
character limit. The single-line guard was confirmed in the installed
engine's handler at `0x64ADE0` (width rejection at `0x64B2CC`), after the MWSE log
confirmed menu mode, keyboard focus, and key delivery were all working.
All animation paths, including the
X-prefixed companion filenames, fit Morrowind's 31-character model path limit.
The complete output is staged first, then existing files move to temporary
backups and companions publish before the main NIF. Save Changes
retain those backups until direct pose application and binding succeed. Failures
roll the files back and restore OAAB's prior selection while retaining the edit
buffer. New-pose application failures remove only the new bundle. Metadata edits
update only the main NIF. Bundle deletion removes the main NIF and its animation
companions.

Editable prop definitions now use a separate `NiStringExtraData` entry with the
`OAAB:PoseProps:` prefix and version-1 JSON payload. New saves, copies and drafts
embed the definitions. Deleting all props writes an empty embedded list.
Invalid embedded versions or definitions stop editing rather than discarding data.
The offline suite covers
metadata coexistence, source-free draft checkpoints, duplication and
serialization/application rollback.
[MWSE's uncached mesh loader](https://mwse.github.io/MWSE/apis/tes3/#tes3loadmesh)
reads changed NIFs even when the same path was previously loaded. OAAB API v4's
`refreshFile(file, except)` refreshes other loaded users after a committed
replacement; earlier API versions update those users when they next reload/select
their saved path. Editor draft paths remain unique.
Undo history is transient editor state. Only the finished NIF path persists in
OAAB's existing reference/item data.

`session.lua` owns control flags while active and retains the original camera
transforms and player visibility until the first camera update after exit. Both
player scene nodes remain culled while that update is pending, so an externally
paused exit does not reveal arms at the designer camera. The editor consumes its
Escape press independently of the active session: claiming `keyDown` only stops
lower-priority Lua callbacks, while the game's later
[`keybindTested`](https://mwse.github.io/MWSE/events/keybindTested/) must remain
blocked for `tes3.keybind.escape` after cleanup. Key-up schedules release on a
real-frame timer so native release tests are also consumed. A fresh press after
key-up belongs to gameplay; token identity prevents an old timer from releasing
a newer session's consumed Escape. Modal menus keep their own Escape handling.
This lets focus restore its scene and lighting without entering the pause menu.
A rapid restart inherits the
pending original transforms and visibility; load, cell changes, and restoration
errors release any pending visibility without applying a stale camera. Animation
evaluation is skipped for the edited mannequin and the captured transforms are
applied after simulation. Entry and completed edits checkpoint to NIF bundles
without replacing the current animation; successful completion releases the editor and uses
OAAB's pose API to apply the saved NIF's bone transforms directly. Morrowind
rejects native animation replacement on the mannequin NPCs in the current game
setup, including OAAB's built-in alternate poses. The API reapplies static
transforms after simulation and suspends that playback during editing.

`orbit.lua` owns engine-independent spherical navigation. `s.orbit` stores target,
distance, yaw, pitch, the mannequin's initial front yaw, zoom limits, and a separate
pan offset. Front is skeleton-parent +Y and anatomical right is +X, transformed
through the captured parent frame. The pivot starts at root X/Y and the midpoint
of skeletal heights, then follows deliberate root translation. Limb edits do not
move it. Neither keyboard navigation nor right drag writes reference or bone
transforms, pose history, or NIF checkpoints.

Camera position is target + panOffset + distance * {cos(yaw)cos(pitch),
sin(yaw)cos(pitch), sin(pitch)}. Forward points back along that radius. Screen-up
is {-cos(yaw)sin(pitch), -sin(yaw)sin(pitch), cos(pitch)}, a perpendicular unit
vector through both poles. Yaw and pitch wrap modulo 2*pi; the rendered frame is
continuous at those boundaries. Vertical orbit remains continuous past +/-90
degrees. No camera Euler angles are read. Opposite view adds pi to yaw and negates
pitch, negating the radius while preserving screen-up. Canonical snaps assign
absolute yaw/pitch and retain distance. Right drag retains the current focus at
target + panOffset and the same distance after screen or depth panning. After pan,
numpad orbit/snap/opposite navigation rebases to the actual camera radius about
the mannequin. Numpad zoom removes pan while preserving the viewing direction.

Orbit keys step by pi/12. Zoom multiplies/divides distance by 0.9, bounded by the
initial mannequin's bounding sphere plus eight world units (at least 25) and a
maximum scaled to the initial framing (at least 700). Initial framing leaves
room to zoom in. `enterFrame.delta` schedules held-key repeats after 0.3 seconds
at 0.1-second intervals; large frame delays are capped to avoid catch-up bursts.
Duplicate key-down events are latched, and raw `inputController:isKeyDown` repairs
lost releases. Repeat is independent of simulation and works with focus enabled.

The shared control catalog resolves physical numpad scan codes, including `add`
and `subtract`. [keyDown.element](https://mwse.github.io/MWSE/events/keyDown/)
and the menu input controller's `textInputFocus` protect keyboard-owning controls.
Both pointers can outlive a menu's active state. The guard walks the focused
element and its parents, ignoring ownership if any element is hidden or disabled.
It does not clear another menu's retained focus. Accepted and UI-captured numpad
presses are logged with scan code/action or focused element ID/type.
Modal/ordinary menu mode and active drags also gate navigation; taking UI focus
clears held repeats. Ctrl selects the opposite canonical view only on 1/3/7;
other modifiers do not activate navigation. Bone-editing shortcuts keep their
existing handlers. Real-frame focus rendering and normal `cameraControl` use
the same orbit state and `lookAt` frame.

The session uses [tes3ui.suppressTooltip](https://mwse.github.io/MWSE/apis/tes3ui/#tes3uisuppresstooltip)
on entry to immediately hide existing reticle object labels and prevent new ones.
The render callback refreshes suppression even when focus is off or the name
dialog is open. Common cleanup releases suppression on save, cancel, loading,
reference/cell changes, and startup or editing errors; failed saves retain it
while the editor remains active.

`markers.lua` loads `pose\\h\\gizmo.nif` with `tes3.loadMesh`, whose path is
relative to meshes, and recursively finds its named `node` NiTriShape. It clones
only that shape into a temporary group under the world scene root, preserving
its complete authored scale and rotation without copying arrows, rings, or the
sorting accumulator. It centers the marker using its own bounds before placing
each instance at a bone's world position. Inverting the group's world transform handles transformed
scene parents. Camera projection of a one-unit offset determines the scale for
a 12-pixel diameter, 16 pixels when selected, or 18 pixels when hovered.
`bone_picking.lua` shares the existing 18-pixel selection radius and overlapping
ROOT/Pelvis preference between clicks and hover. All selectable nodes are
projected before resolving hover, so camera or pose changes refresh feedback
even while the cursor is stationary. Hover uses a brighter pale gold tint and
pauses during any drag, hidden handles, and modal menus. The
gizmo update returns its active component so its hit takes priority over bone
hover, matching click priority without an additional ray test.
Per-shape material clones provide
a white, cyan IK, green locked, amber active, blue selected-inactive, or pale gold hovered emissive tint without changing
the source material or another handle. Each shape receives a runtime `NiZBufferProperty` with
an always-pass test and depth writes disabled, plus an alpha property so the
renderer schedules the marker after opaque world geometry. The hovered handle,
or otherwise the selected handle, renders last in its group when joints coincide. The temporary group is
hidden during modal menus and detached on cleanup. Missing geometry or unusable
bounds fails visibly instead of creating an empty widget.

The unsuccessful UI NIF widgets are no longer used. `createHelpLayerMenu` creates
a fixed frame on the element itself, so deleting its children does not remove
its background. Plain top-level blocks lack the menu scene node and did not
render the pointer or controls in the user's game. Controls and cursor now use
native help-layer menus with border children removed and the menu's own alpha
set to zero. Child labels and the cursor image have alpha one. The cursor image
uses `textures\\tx_cursor.tga`, the stock texture referenced by `cursor.nif`, at
32x32 pixels. The stock NIF's quad extends from X=-8 to X=24 and Z=-32 to Z=0.
The menu is placed eight pixels left of the selection point, with its top edge
at the selection point's Y, matching the arrow's original hotspot. Native frame
minimum dimensions are removed. The engine resolves the installed texture,
including its DDS replacement, without bundling or changing an asset.
Bone markers use only scene geometry. Creation replaces an existing controls
or cursor menu. The authored gizmo NIF remains unchanged on disk.
The controls panel
lists the current bone and mode; H switches between full and compact lists.

F toggles focus mode for the current session. `focus.lua` captures HUD visibility, AI, sky/world,
simulation speed, scene culling, native water, master volume, and MGE background render settings. It keeps
`worldDisabled=false` so the live mannequin can render; ToggleWorld hides that
mannequin and does not suppress MGE XE's separate distant-land renderer. Scene
isolation keeps the mannequin's entire subtree, the bone marker group, cameras, UI, light
sources, and their ancestor paths, and culls unrelated branches. The mannequin's
body-part/outfit visibility and the overlay's modal handle visibility are retained.
MWSE normally returns fresh smart-pointer userdata for scene nodes. Lua table
keys compare wrapper identity, whereas `==` compares the native pointer. Protected
ancestor paths therefore use equality searches instead of userdata keys. The mask
caches snapshots by numeric child slot and checks node equality before reuse;
moved nodes reuse their original snapshot. It verifies the mannequin's ancestors
remain visible before activation completes. An activation log records the model,
snapshot count, and availability of the native water and MGE interfaces.
`tes3.dataHandler.worldLandscapeRoot` is masked separately from the object scene,
including its descendants so direct cell/geometry render passes also see culled
shapes. It retains the original flag of each node, including terrain already
hidden in interiors, and observes replacement terrain roots on subsequent frames.
`mge.render.distantLand`, `distantStatics`, `distantWater`, and `grass` are disabled
only when the MGE interface is enabled. `tes3.dataHandler.waterController.waterShown`
is disabled and the native `waterPlane` and `rippleNode` are culled, including nodes
outside the world root; disabling MGE water alone can reveal native fallback water.
The weather controller's [sceneSunBase](https://mwse.github.io/MWSE/types/tes3weatherController/#scenesunbase),
`sceneSunVis`, and `sceneSunGlare` are masked separately, including their descendants.
These sun disc/glare roots can render outside the world tree despite `skyDisabled`.
Each frame observes replacement nodes and repairs weather-driven visibility resets;
the shared visibility snapshots preserve originally hidden nodes and avoid duplicate
snapshots when sun roots overlap or belong to the world tree. The sky light is retained.
MGE XE's stock `Sunshafts.fx` independently draws rays and an additional sun disc
in its post-processing `combine` pass (`sundisc=1`). The installed MGE log confirmed
that shader was loaded and replacing standard Morrowind sunglare; culling native
geometry therefore did not remove the shader-generated sun. Focus looks up the
loaded shader with [mge.shaders.find](https://mwse.github.io/MWSE/types/mgeShadersConfig/#find),
captures its original [enabled](https://mwse.github.io/MWSE/types/mgeShaderHandle/#enabled)
state before writing, and disables it each render. Lookup repeats by name so the
code does not depend on Lua handle identity or retain handles from a rebuilt chain.
Absent shaders are not loaded; shaders appearing during focus are observed then.
`mge.render.noMWSunglare=true` also suppresses native glare. Cleanup restores its
original flag and the Sunshafts setting independently, leaving other shaders intact.
Sky rendering is disabled and simulation
time is frozen. The `render` event reapplies isolation after engine scene updates,
including newly attached background siblings, without walking hidden subtrees.
Repeated key-down events are ignored until F is released. Each setting is
restored independently on toggle-off or session cleanup, including partial
activation failures; failed saves retain the editing state. The name dialog
receives F normally. Focus state and its shortcut remain visible in the compact guide.
Focus uses the geometry algorithm from CSSE's
[updateGridGeometry](https://github.com/MWSE/MWSE/blob/master/CSSE/RenderWindowWidgets.cpp#L106).
`focus_grid.lua` selects a vertex count from the mannequin's world bound
radius and 16-unit spacing. It doubles the previously rounded grid radius,
with a minimum radius of eight spaces and CSSE's
32767-vertex limit, including radial samples. `nif.encodeGrid` keeps each row on
the two-local-unit lattice (16 world units), including the outer rows. Endpoints
use the circle intersection `sqrt(g*g - row*row)` instead of CSSE's outward-offset
Bresenham endpoints, keeping all geometry inside the fading circle. Each
row is subdivided into 16 independent segment pairs (32 vertices). Vertex alpha
is `0.2 * (1 - smoothstep(distance / g))`, clamped to zero at the circle's radius
`g`, using distance from the world grid origin rather than the shared model-bound
center. Segment interpolation produces a smooth radial fade across all four
rotated line sets. The zero-offset row draws only its positive-axis half, so
opposite rotations complete the center axes without drawing them twice. This
keeps their thickness and opacity consistent with other lines. The outermost row
remains disabled, and no segment connects
separate rows. Four `NiLines` nodes,
rotated by 0, 90, 180 and 270 degrees, share one `NiLinesData` block. Their
shared data is serialized after all four geometry nodes. The initial data-first
layout passed byte validation but crashed on the first native render: the dump
showed the last `NiLines` with the grid root in its controller and extra-data
links, despite both links being null in the NIF. The loader now also checks each
native child's type, null controller/extra-data links, and vertex count before
the grid enters the world scene. A malformed result is rejected before reaching
`NiLines::Display`, where `pcall` cannot catch an access violation. The byte-layout
and loaded-graph checks have separate regressions.
The grid properties match `gridRoot` in CSSE's `widgets.nif`: white vertex colors at 0.2
alpha at the center, decreasing radially to zero at the circle's edge, emissive vertex lighting,
material alpha 0.5, and source-alpha blending
without alpha testing. Depth testing is enabled and depth writes are disabled,
so mannequin geometry still occludes the grid.
MWSE's Lua bindings expose no `NiLines` constructor or writable segment flags.
The module therefore writes a small temporary NIF under `meshes/pose/h/c`, loads
it uncached, and immediately removes the file, including after load/write errors.
It reuses the loaded geometry while the vertex count is unchanged and replaces
it when pose bounds cross a grid step. A native load/validation failure during
resizing retains the last validated mesh, logs the rejection, and skips that
failed size on subsequent renders. A later valid size can replace it normally.
An initial load failure logs the rejection and continues focus with an empty
collision-disabled floor, preserving the pose, IK locks, symmetry and history.
The failed count is not retried each frame. A later size change can load a grid
normally, and toggling focus off/on retries the initial size. Lighting and
cleanup also work with the empty floor. Other activation failures still restore
the captured settings through the session's existing error path.
The underlying native link corruption remains unconfirmed; reordering the stream
did not prevent resize or initial-load rejections reported in game. Oversized
bounds retain any existing grid, as in CSSE. A collision-disabled wrapper under the world root uses the
inverse parent transform and CSSE's half-spacing scale to remain horizontal at
the session's original grounding plane. Property propagation runs after mesh
attachment. Isolation retains the grid, and cleanup detaches it on focus exit,
including partial activation failures.
Undo/redo ends an active gesture before swapping snapshots. A changed left drag
already owns one history entry, so undo restores its starting pose and redo
captures its partial result. An unchanged left drag restores its prior undo/redo
lists first. Camera gestures release without creating pose history. Only the
resulting pose is checkpointed; later mouse-axis and mouse-up events cannot
reuse the released drag's targets, starting rotation, or constraints.
Focus creates a temporary [niPointLight](https://mwse.github.io/MWSE/types/niPointLight/)
with neutral ambient fill (0.45) and diffuse illumination (0.75), attached as an
effect to the mannequin scene and grid floor. It has no scene parent, so its translation
is the world-space camera position. Each render updates its position and radius
to cover both sets of bounds, then uses constant attenuation to keep brightness
steady with camera distance. `setRadius` also fills the specular field used by
Morrowind/MGE for point-light coverage. Reattaching the effect and propagating
`updateEffects` repairs native lighting rebuilds without duplicating the light.
The light is owned before setup/attachment writes; cleanup disables it, detaches
both the effect and affected-node links, and refreshes each scene independently.
Existing lighting effects and material properties are preserved.
Focus finds `MenuMulti` with [tes3ui.findMenu](https://mwse.github.io/MWSE/apis/tes3ui/#tes3uifindmenu)
and hides it through its [visible](https://mwse.github.io/MWSE/types/tes3uiElement/#visible)
property, preserving help-layer
controls, the pointer, and modal dialogs. Each render observes the current HUD,
hides it again if the engine shows it, and captures any replacement menu's own
visibility. Cleanup restores the captured state only if that menu still exists.
Focus captures `tes3.worldController.audioController.volumeMaster` and sets it
to zero on each update, muting all non-music mixes: effects, voices, footsteps,
weather, and UI clicks. Morrowind's music mix uses `volumeMusic` directly and is
independent of master volume, so music playback and its volume are preserved.
The MWSE setter adjusts tracked looping effects, but Morrowind's routine at
`0x5A1E10` only walks the data handler's sound lists and skips native weather
buffers. Focus therefore also reapplies each cached weather sound's unchanged
`volume`: that setter directly updates its buffer with the current master/effects
mix. This covers ambient loops, Rain/Thunderstorm rain loops, and all four thunder
sounds, including buffers replaced or reset during focus. Cleanup independently
restores the original master volume and then refreshes each weather buffer,
including an already muted channel, after toggle-off or any session exit. Other
audio volume settings and individual weather sound definitions are preserved.
While focused, `enterFrame` also applies the pose and validates the reference/cell
so editor updates and cleanup do not depend on simulation events.
The `cameraControl` hook originates in the player's scene update, so focus also
applies the same camera transforms on `enterFrame` and just before `render`.
It writes the local transforms of `worldCamera.cameraRoot`, `armCamera.cameraRoot`,
and `shadowCamera.cameraRoot`, matching MWSE's camera hook, then calls `update`
with controllers disabled. The arm camera retains its independent scale. Original
gameplay transforms are captured once and restored through the normal exit path.
Handle projection is refreshed after the final camera update. Modal menus skip
direct camera writes and input handling.

Both preview and OAAB's direct pose playback update Bip01 first, then the entire
mannequin scene, with animation controllers disabled. Body-part and outfit meshes
can sit outside the skeleton branch, including before it in the scene's children.
A skeleton-only update leaves their skin bounds at the previous pose; an ordinary
scene pass can also encounter those meshes before updating their bones. The two
passes ensure every mesh's culling sphere uses the finished pose and current
reference scale before rendering. This also applies when restoring a cancelled edit.

`highlight.lua` groups each live skinned shape by its strongest bone weight and
groups rigid attachments by their nearest captured bone. For a bone that only
contributes a small weight, such as a finger, it chooses its most affected mesh
piece. Rigid attachment matching uses the bone name to locate the captured node,
then native node equality to verify it. MWSE can return distinct Lua wrappers
for the same node, so wrappers cannot serve as lookup-table keys. The native
comparison also prevents same-named bones in equipped models from overriding
the nearest captured ancestor. This covers unskinned heads, sleeves, and trouser
legs, including nested attachment offsets and models with multiple shapes.
The tint is applied to a cloned material on that shape, leaving other
shapes that share the original material untouched. After updating the overlay,
the session previews the hovered bone's body tint without changing selection,
pose history, or checkpoints. Leaving hover restores the selected bone's tint;
dialogs and drags also restore it. Focus rendering refreshes the tint after its
final camera projection. When a prop has transform focus, the retained bone's
shapes use the same inactive blue tint as its node, and bone hover does not replace
that selection. Switching focus back to the same bone restores amber; tint state
participates in the highlight cache so changing active/inactive status is detected.
Selection changes, cancel,
and save restore the original material property before the scene is replaced.
Highlighting is at the mesh-piece level; it cannot color only the finger vertices
within a single skinned hand mesh.

## Ground Feet

`ground.lua` prepares an independent pose using Relaxed foot transforms loaded
through the existing pose reader. The session captures the skeleton parent's
frame at entry and caches the Relaxed ground reference on first use. Per-foot
ankle heights include the offsets above the original sole plane, adjusted to
the current foot's world scale without moving the saved plane. The root's
world-Z correction is converted through the inverse parent rotation and scale;
reference placement, orientation, and all other bone translations stay intact.
Foot rotations are compared in the Relaxed world basis, retaining the relative
Z heading while clearing X/Y tilt, then converted back into each current
parent's local frame. This avoids treating the rig's downward foot-local X as
world X. A singular heading projection falls back to the second horizontal axis.

For both feet, the lowest support height determines the root shift. Only the
higher foot's thigh/calf chain receives a vertical IK target at its original
horizontal position. A failed reach check rejects the prepared result without
changing bones, locks, history, or drafts. On success, one undo snapshot and
checkpoint cover the entire command. Existing anchors rebase to the explicit
result, and symmetry remains an editing setting for later manual edits. The T
shortcut and `ground_menu.lua` follow the other modifier dialogs' native input,
cancel, delayed activation, and cleanup lifecycle.
Rest keybinds and the native Rest/Wait menu remain blocked throughout an active
session, including the frame between releasing player controls and activating
a modifier dialog. Modal text input and Escape still reach their native menus;
normal Rest/Wait behavior resumes when the editor exits.

## References consulted

- [MWSE loadAnimation](https://mwse.github.io/MWSE/apis/tes3/#tes3loadanimation)
- [MWSE cameraControl](https://mwse.github.io/MWSE/events/cameraControl/)
- [MWSE camera hook implementation](https://github.com/MWSE/MWSE/blob/master/MWSE/TES3MobilePlayer.cpp)
  and [loaded landscape root](https://mwse.github.io/MWSE/types/tes3dataHandler/#worldlandscaperoot)
- [MWSE AI/world rendering flags](https://mwse.github.io/MWSE/types/tes3uiMenuController/)
  and [simulation time scalar](https://mwse.github.io/MWSE/types/tes3worldController/#simulationtimescalar)
- [MWSE MGE render features](https://mwse.github.io/MWSE/types/mgeRenderFeatures/)
  and [render event](https://mwse.github.io/MWSE/events/render/)
- [MWSE native node wrapper creation](https://github.com/MWSE/MWSE/blob/master/SharedSE/NIObject.cpp)
  and [native pointer equality](https://github.com/MWSE/MWSE/blob/master/SharedSE/NIPointer.h)
- [MWSE native water bindings](https://github.com/MWSE/MWSE/blob/master/MWSE/TES3WaterControllerLua.cpp)
- [MWSE master volume](https://mwse.github.io/MWSE/types/tes3audioController/#volumemaster)
  and [mix/volume implementation](https://github.com/MWSE/MWSE/blob/master/MWSE/TES3AudioController.cpp)
- [MWSE native sound volume setter](https://github.com/MWSE/MWSE/blob/master/MWSE/TES3Sound.cpp)
  and [weather sound fields](https://mwse.github.io/MWSE/types/tes3weatherRain/)
- [MWSE keyDown](https://mwse.github.io/MWSE/events/keyDown/) and
  [keyUp](https://mwse.github.io/MWSE/events/keyUp/)
- [MWSE niAVObject.update](https://mwse.github.io/MWSE/types/niAVObject/#update)
- [MWSE loadMesh](https://mwse.github.io/MWSE/apis/tes3/#tes3loadmesh),
  [scene nodes](https://mwse.github.io/MWSE/types/niNode/), and
  [world camera scene root](https://mwse.github.io/MWSE/types/tes3worldControllerRenderCamera/)
- [MWSE element alpha](https://mwse.github.io/MWSE/types/tes3uiElement/#alpha)
  and [fixed help-layer frames](https://mwse.github.io/MWSE/apis/tes3ui/#tes3uicreatehelplayermenu)
- [MWSE UI images](https://mwse.github.io/MWSE/types/tes3uiElement/#createimage)
- [MWSE native slider and change event](https://mwse.github.io/MWSE/types/tes3uiElement/#createslider),
  [slider value](https://mwse.github.io/MWSE/types/tes3uiSlider/#current), and
  [scrolling pose lists](https://mwse.github.io/MWSE/types/tes3uiElement/#createverticalscrollpane)
- [MWSE NiZBufferProperty](https://mwse.github.io/MWSE/types/niZBufferProperty/)
  and [depth test functions](https://mwse.github.io/MWSE/references/ni/z-buffer-property-test-functions/)
- [MWSE niKeyframeController](https://mwse.github.io/MWSE/types/niKeyframeController/)
- [MWSE source](https://github.com/MWSE/MWSE): locally available source and generated
  API definitions, especially TES3UtilLua, TES3MobilePlayer, NITimeControllerLua,
  TES3UIManager, TES3VectorsLua, and the input/camera event definitions.
- [ExportSphere](https://github.com/MWSE/morrowind-nexus-lua-dump/blob/8b4fb38a7383328911aa563d7ff88a82846993cd/lua/Morrowind%20Interiors%20Project%20Guide/exportSphere-52245-1-0-1675468010/mwse/mods/exportSphere/main.lua):
  scene export and `saveBinary`, read as a reference; code was not copied.
- [Tatau bone mapping](https://github.com/MWSE/morrowind-nexus-lua-dump/blob/8b4fb38a7383328911aa563d7ff88a82846993cd/lua/Tatau%20-%20The%20Tattoo%20Framework/Tatau%20-%20The%20Tattoo%20Framework-52748-23-04-27-1682896536/Data%20Files/MWSE/lib/sb_tatau/data.lua):
  confirmed TES3's left/right bone naming.
- [PyFFI](https://github.com/niftools/pyffi): local NIF XML schema and independent
  test reader. PyFFI is a development-only dependency, not shipped or needed at runtime.

Command menus share `dialog.lua` for creation, Escape handling, destruction,
and deferred menu-mode activation. Reset, Mirror, Symmetry, Ground Feet, and
Save retain their own actions and content.

Exports use complete OAAB templates exclusively. Template patches collect
fixed-offset replacements and assemble the output once, preserving the bytes
outside those transforms and keys. Saves use descriptive fields with a stable
ID; nil fields are reserved for temporary checkpoints. Filename-derived names
remain available for imported NIFs without descriptive metadata.
