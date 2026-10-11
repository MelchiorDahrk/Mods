# Inventory props: architecture and validation

The existing binary patcher (`nif.lua`), working templates, bone capture, IK,
symmetry, mirror, blend, and focus systems remain intact. `props.lua` owns plain
prop definitions, independent scene wrappers, import sanitization, transform
conversion, live restoration, and main-NIF decoration. `props_menu.lua` owns
only the native inventory picker opened by P (Add Prop) or Shift+P (Replace Prop). Session changes connect
props to lifecycle, node selection, the existing mouse drags, context-sensitive
sidebar hotkeys, and shared history; there is no second transform handler or
prop-specific undo stack.

Each prop's handle clones the same authored `node` shape used for bones.
`markers.lua` synchronizes prop handles by stable ID and projects both kinds
before `bone_picking.lua` resolves clicks and hover with its shared 18-pixel
radius. Handles also follow restored definitions with unavailable source meshes;
V, dialogs, deletion, undo/redo, and cleanup use the same scene lifecycle. Ctrl+Tab
cycles coincident props. One bone remains selected while a prop has transform
focus. Its marker and affected shapes use an inactive blue tint, while the prop
uses the active amber tint. Shift-click and Tab change the attachment bone;
normal bone clicks restore bone transform focus. Shift-click commits on release
so Shift depth drags remain available at a shared bone/prop pivot.

The shared controls catalog describes P (add), Ctrl+P (attach to selected bone),
Alt+P (detach, shown only when attached), Ctrl+D (duplicate), Shift+P (replace), Alt+S/R/G (reset
scale/rotation/translation independently), and Delete. Compact and expanded
sidebar rows use the same availability rules. Actions never open a prop command
or attachment menu. Each mutation creates one ordinary history snapshot and
draft checkpoint; selection creates neither. Reset components use identity in
the current parent's frame and leave the other components intact.

Replace captures the selected prop ID when its inventory picker opens. The chosen
item updates only source ID, name, and mesh; prop ID, attachment, transform, and
focus remain intact. The replacement mesh is cloned and sanitized before the old
visual is removed. Failed construction, attachment, or scene update retains or
restores the old visual without changing metadata or history. Replacing an
unavailable source clears its live error. Cancellation and an empty eligible
inventory create no history/checkpoint; success creates one ordinary snapshot.
Undo/redo and save/reopen use the existing definitions and versioned metadata schema.

Collision branches are skipped before validating their contents, using the native
`RootCollisionNode` type/RTTI as well as the legacy node name. The unnamed
collision branch in `m/misc_dwrv_artifact50.nif` is covered by a regression test.

## State and transforms

Each definition stores `id`, `objectId`, `mesh`, `name`, `attachmentType`, optional
`parentBone`, a three-component translation, a row-major nine-component rotation,
and uniform `scale`. IDs are stable strings, assigned independently of object IDs.
Live nodes, highlights, and load errors are separate session resources. Snapshot
arrays are deep copies of definitions; native objects never enter saved metadata.
Attachments currently accept `root` and `bone`; a later schema version can add
prop IDs as another parent kind without changing the wrapper/transform approach.

An `OAAB Pose Prop <id>` NiNode owns a collision-disabled NiCollisionSwitch and
the cloned original item hierarchy. Editing transforms affect the outer wrapper;
the imported mesh's root translation, rotation, and scale are retained.

Free props use the same skeleton-parent frame as `rig.world(...)[0]`. Bone props
use their named skeleton bone. Runtime rendering and editor bone edits rely on
normal scene parenting. Reparenting reads current native world transforms after
an update, then uses existing vector/matrix utilities:

```
local.translation = transpose(parent.rotation) * (world.translation - parent.translation) / parent.scale
local.rotation = transpose(parent.rotation) * world.rotation
local.scale = world.scale / parent.scale
```

The matrix convention and engine adapters are unchanged from `rig.lua`. Parent
scale must be positive and nonzero. Movement converts the existing camera-space
mouse delta into the parent frame. Rotation uses the existing circular drag and
local-axis method. MWSE supports uniform node scale, so scale remains uniform.

## Export and persistence

```
session bones
  -> library.render / nif.patchTemplate (unchanged)
  -> staged p NIF + xp NIF + xp KF
  -> props.decorate(staged p NIF), for nonempty props or replacement of existing editable props
  -> load generated main scene, clone and attach sanitized meshes
  -> saveBinary to a different temporary NIF
  -> reload; verify skeleton topology/transforms/controllers and prop parents/transforms/shape counts
  -> separate OAAB:PoseProps: NiStringExtraData with editable definitions
  -> existing publish transaction for the NIF/KF bundle
  -> OAAB pose application; rollback the bundle if application fails
```

No-prop exports bypass prop processing and create no new prop metadata entry. Their
animation companions stay byte-identical to the existing patcher output. New
pose-library exports serialize descriptive metadata in the main NIF in a separate
staged pass. Replacing an editable decorated pose with zero props writes an empty
embedded prop list and removes the old prop wrappers from the main NIF. Draft checkpoints retain metadata without importing or
serializing prop meshes, so an unavailable source mesh does not obstruct bone
editing. Rename preserves file identity; saved-pose duplication also copies prop
definitions. Draft, failed-save, and pose deletion remove the NIF/KF bundle.

`OAAB:PoseProps:` prefixes a versioned JSON object (`version=1`, `props=[...]`) in
its own `NiStringExtraData`, distinct from `OAAB:PoseMetadata:`. Definitions are
validated through MWSE's JSON implementation rather than executed as Lua. An empty
embedded list records the removal of all editable props.
Unknown versions or malformed definitions stop editing to avoid data loss. Missing
prop metadata permits skeleton editing while preserving embedded props; individual
prop operations require restoring the original metadata. Missing source meshes
keep their definitions and report an unavailable live prop. Export refuses
unreadable sources and leaves existing outputs untouched. Cancel remains usable.

## Runtime investigation and OAAB integration

OAAB's existing `poses.lua` loads the main NIF and copies static bone transforms
onto the live actor. It does not install the main NIF's geometry, and native
animation replacement is deliberately avoided by the working implementation.
Therefore main-NIF embedding alone would never display props in gameplay.

Pose API v5 adds `OAAB.Mannequins.pose_props`. It copies only reserved prop wrappers
from the main NIF onto matching live bones or the live skeleton parent. It does
not load source inventory meshes or editor metadata, and has no designer
dependency. Repeated application replaces previous wrappers; switching to a
plain pose or clearing selection removes them. A failed attachment restores the
previous wrappers. Existing static bone application, suspension, update order,
save/load state, and reference refresh remain in place. The xp files need no props.

Runtime playback entries retain safe object handles. Simulation and saved-file
refresh discard entries whose native mannequin was deleted before reading any
reference fields; weak table keys alone do not establish native validity. This
prevents pickup from interrupting the dropped mannequin's maintained bone pose
while its prop wrappers remain visible. `pose_lifecycle.lua` exercises the actual
OAAB pickup/place modules with deleted-reference doubles that throw on access,
three portable round trips, both prop attachment modes, another ordinary pose,
suspended entries, refresh, and scene replacement.

## MWSE contracts verified before implementation

Installed autogenerated definitions under `Data Files/MWSE/core/meta` and locally
available MWSE binding/source files were inspected. Official documentation was
checked too:

- [tes3.loadMesh](https://mwse.github.io/MWSE/apis/tes3/#tes3loadmesh): mesh-relative
  path and `false` to bypass cache, including BSA resolution.
- [niObject](https://mwse.github.io/MWSE/types/niObject/): `clone`, type checks,
  `saveBinary(path)` returning success, with an installation-relative output path.
- [niNode](https://mwse.github.io/MWSE/types/niNode/): `new`, `attachChild`,
  `detachChild`; children are sparse and can contain nil slots.
- [niDynamicEffectLinkedList](https://mwse.github.io/MWSE/types/niDynamicEffectLinkedList/):
  `effectList` exposes a non-nil head even for an empty list. Sanitization checks
  each entry's `data`, rather than rejecting the empty list object itself.
- [niAVObject](https://mwse.github.io/MWSE/types/niAVObject/): local transforms,
  `worldTransform`, `update` with controllers disabled by default, property
  detach/attach methods.
- [niObjectNET](https://mwse.github.io/MWSE/types/niObjectNET/):
  `removeAllControllers`; property clones are sanitized too, preserving shared
  source materials.
- [niCollisionSwitch](https://mwse.github.io/MWSE/types/niCollisionSwitch/):
  `new` and `collisionActive=false`. Its visible children are preserved.
- [tes3ui.showInventorySelectMenu](https://mwse.github.io/MWSE/apis/tes3ui/#tes3uishowinventoryselectmenu):
  custom item filter, selected `item`, cancel callback, explicit `leaveMenuMode`,
  and synchronous `noResultsCallback`. No inventory-transfer API is invoked.
- [Object type constants](https://mwse.github.io/MWSE/references/object-types/):
  miscellaneous items use `miscItem`, repair tools use `repairItem`, and arrows/
  bolts have the separate `ammunition` type.

## Testing and limits

`tools/Test.ps1` includes the new Lua tests. `tools/run_lua_tests.py` runs the same
suite through LuaJIT/Lupa with a real-filesystem LuaFileSystem bridge. It uses the
development copy in `.work/lua-test-deps` or an installed Lupa, and accepts optional
pose-API and installed dkjson paths. No dependencies are required by the mod.

Automated checks cover the entire existing regression suite, root/bone parenting
under rotated and scaled reference frames, sword/shield/book/ingredient/clutter
state, static mesh sanitization, native inventory-menu contract, transform input,
one-stack undo/redo, reparenting without a jump, cancel, embedded JSON restore, metadata loss,
unchanged no-prop and xp bytes, transaction rollback, temporary-file cleanup, and
OAAB embedded-prop playback/replacement with the native scene API mocked.

Native `saveBinary` execution, actual item meshes, in-game icons/rendering,
cross-session game restarts, outfits/equipment conflicts, focus lighting, collision,
and ordinary gameplay after disabling the designer need an in-game acceptance
pass. These are explicitly pending in `acceptance.md`; mocked native-contract
tests do not establish that they passed. Unknown/skinned/animated dynamic meshes
are conservatively rejected; they are not silently flattened or stripped.
