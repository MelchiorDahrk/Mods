# In-game acceptance pass

Status: pending. Offline tests cannot validate Morrowind's rendering, direct pose
application, camera setup, UI placement, or other installed mods' event interactions.

Start the 0.3.0 pass with [the focused pose library checklist](pose_library.md#focused-in-game-checklist),
then check the existing editor behavior below.

Bone hover checks: move within 18 pixels of a handle without clicking. Only the
closest selectable node should enlarge to 18 pixels and glow pale gold, and its
associated body piece should temporarily glow amber. The selected bone and
sidebar must stay unchanged; moving away restores normal/IK/locked marker colors
and sizes and the selected body's tint. Repeat with overlapping ROOT/Pelvis
pivots, zoom, stationary-pointer camera/pose changes, and Focus on/off. Gizmo
hits take priority. Pose and camera drags, V, and dialogs must clear
hover; returning to editing should resume it. Click the previewed bone and verify
it selects the same node. Save/cancel must restore the original body materials.

Authored gizmo checks: select ROOT and press G; confirm the supplied
NIF's red X_move, green Y_move and blue Z_move arrows. R must reveal its X, Y
and Z circles with their updated proportions and orientations. Compare to the
Construction Set: the transparent sphere must mask the back portions of the
circles, with no opaque sphere visible. Orbit to confirm that the occluded arcs
change with the view. Hover and drag must preserve that masking and alpha
behavior. G shows the arrows and hides the circles and sphere; R restores both
circles and sphere together and hides the arrows. Their shared sorting parent
must remain active in both modes. Repeat G/R switches and V/modal hide/show cycles; the sphere
must never remain hidden when the circles are visible. The sphere must not
select a transform axis. In Focus mode and a dark interior, every idle arrow
and ring must match the authored NIF material, including its emission, after
leaving an amber hover/drag and switching G/R modes. Only the hovered or dragged
component may turn amber. V/modal hide/show and cleanup must restore the original
material as well. The sphere must remain transparent.
Hover and start a drag a few pixels inside/outside a visible ring: both must
select the same ring within the six-pixel margin. Repeat while zooming and near
crossing rings; exact hits should win, otherwise the nearest ring should win.
Clicks well outside the margin or near an arc hidden by the sphere must not
select that arc. The circles' rendered thickness must stay unchanged.
Drag each arrow, checking the actual movement follows the
displayed axes. Repeat for hands/feet with IK, locked limbs, symmetry, free props
and props attached to rotated bones. R must show three colored local rings;
drag each visible ring through several turns, then reverse. Check Ctrl fine
adjustment, undo/redo, changing views, zoom, UI scaling and rotated/scaled
mannequins. Hover/drag should turn only that component amber. Clicking a gizmo
must keep the current bone, including overlapping ROOT/Pelvis pivots. Root drags
must keep the camera fixed until release and avoid repeated movement when the
mouse stops. Bone marker, Shift depth, Alt bend, and held-axis gestures must remain
usable. Test a nearly edge-on ring and an end-on arrow: no NaNs or pose
jumps; expose the component by orbiting slightly. V, modal dialogs, Focus, prop
scale mode, save/cancel and scene replacement must hide/clean up the controls.
Save and reopen a pose: its exported NIF must contain no gizmo branch.

Controls UI checks: start with only the compact sidebar. Confirm friendly bone
names dominate unchanged node names, and mode/axis/angle, Focus, and Symmetry
status remain accurate. Check quick controls change for rotation, root movement,
hand/foot IK, Alt bend drags, right/middle viewing drags, and Blend Poses. The
blend guide should stay left of its dialog, with handles and editing pointer
hidden. Press H: the existing transparent overlay must spread categories between
the left and right edges, with each complete side vertically centered in the
screen and an empty middle for the mannequin. Check each side independently:
the right includes live status above its controls and may be a different height
from the left. Transform, Selection, Edit, and Save / Exit belong on
the left, along with Props; live bone/status labels, Modifiers, and View belong on the right. Keep
the original handles and pointer. No additional help window or duplicate quick
controls should appear. At 1920x1080 and the reported 1653x1324,
1772x1439, 1827x1438/2560x1440 sizes, verify every category, shortcut, action, and note fits
inside the screen, especially the bottom Save / Exit rows. Check that gold key
labels and white actions align cleanly, and that category spacing remains clear
when text wraps. There must be no scroll box or scrollbar. The wheel must zoom even
over the expanded controls, keeping pose mode open. Text must retain the same
pass-through drag behavior as the default sidebar. Pose, undo/redo, focus, and
navigate the camera with controls expanded. All resets belong to Edit, Blend
Poses to Modifiers, and Focus Mode to View. Expanded Modifiers must retain B
while omitting Pose lists A / B, Blend slider, and Use blend; those three controls
must remain in the blend menu's guide. Other dialogs must hide the sidebar
and restore its expanded state when closed. H again or Esc must collapse the
controls to the compact top-right guide and hide all left-side text; holding
that Esc must not cancel editing or open the pause menu. After
release, a fresh Esc must cancel normally. Repeat with focus enabled, different
UI scales, viewport resizing, and session termination while controls are expanded.

1. With updated OAAB_Data alone, verify the four stock poses, Cancel, pickup, and
   placement work. Verify dress stands still have no Change Pose option.
2. Enable the designer. Sneak + activate an unowned full mannequin. Choose Change
   Pose, then Create pose. Confirm the camera frames it, its outfit remains visible,
   and the player/first-person arms are hidden. Confirm no inventory or attacks
   occur while dragging or cycling bones. Test entry from first and third person.
   Aim the reticle at the mannequin before entry, then pan/turn it across the
   reticle while editing. Its name tooltip and nearby world object tooltips must
   stay hidden with focus both off and on, including while naming a pose or
   retrying a failed save. After save or cancel, ordinary reticle tooltips must
   return. Repeat after loading a save or changing cells during an edit.
3. Confirm bone handles use the authored gizmo's `node` shape: white normally,
   cyan for hand/foot IK, green for locked hands/feet, and larger amber markers
   when selected by clicking or Tab. Check that bone markers
   stay centered on their click targets and visible through the body and outfit,
   including in a dark room. Confirm there are no black squares at joints or the
   cursor, and the controls panel shows plain text without a frame. Confirm the
   vanilla arrow cursor is visible, follows the mouse, and selects the bone marker at
   its tip. Press V to hide/show handles; the pointer must remain visible. Open the save-name dialog:
   all handles should hide until editing resumes. The gizmo axes and transparent
   sphere must keep their authored materials when bone marker colors change.
   Select hands/feet by handles and move them in G mode, including Shift depth and
   Alt elbow/knee adjustment. Check reach limits, fully straight limbs, and folded
   targets. Check both sides and differently scaled mannequins.
   Select ROOT with Tab / Shift+Tab, press G, and drag its amber bone marker from either
   side: the overlapping Pelvis must not become selected, and the root translation
   must persist through undo/redo and saving. Repeat with focus on/off and each
   stock pose. Select Pelvis with Tab and confirm dragging the shared bone marker keeps
   Pelvis selected; click a separate handle to confirm normal selection still works.
4. In R mode, rotate Spine, Spine1, Spine2, pelvis, head, hands, and feet
   without an axis key: each must turn in the camera view plane, including after
   tilting and orbiting the camera. Hold X/Y/Z to rotate each local
   axis. Start just right of a joint and circle clockwise/counterclockwise through
   360, 450, and 720 degrees. Cross the left-side atan2 boundary in both directions
   and reverse halfway through a circle: direction and angle must stay continuous.
   Press/release Ctrl during one drag; new angular movement must become finer
   without a jump, while the visible pointer keeps following the mouse.
   Click exactly at the joint center, move outward, and circle; the first outward
   movement must establish the angle without rotating. Cross the center slowly
   and in one fast event; neither path should introduce an artificial half-turn.
   Change held axes during a drag: its axis/label must remain frozen until release,
   and the next drag must use the latest held constraint. Repeat with a rotated
   parent, turned/scaled mannequin, and different camera views. Near edge-on local
   axes may need another viewing angle to see their motion clearly.
   Check taps cannot latch an axis, overlapping held keys use the latest key and
   fall back on release, Ctrl fine adjustment works with each axis, and Ctrl+Z/Y
   undo/redo without changing the axis. Confirm the panel shows Camera or the
   active local axis and accumulated degrees in the compact status panel.
   Undo/redo a completed multi-turn edit and repeat with symmetry and locks enabled.
   Use Tab to reach overlapping handles. Finger, Weapon Bone, Shield Bone, Neck, and both Clavicles
   controls and markers should be absent and skipped by Tab / Shift+Tab.
   Confirm the amber tint follows each selected visible body piece or attachment,
   including while dragging.
   Select Head with an equipped mannequin head, then both UpperArm/Forearm bones
   with a shirt and both Thigh/Calf bones with pants. Confirm rigid head shapes,
   sleeves and trouser legs glow with their own bone and restore on deselection
   and exit, with focus both on and off.
   Inspect clothed, armored, armed, headless, male, and female full mannequins.
   Select each hand/foot and press L: the panel must show [Locked], and its bone marker
   must turn green when deselected. Lock all four limbs, then translate Bip01 and
   rotate the root, pelvis, Spine, Spine1, and Spine2. Within reach, their positions
   and facing must remain fixed. Move beyond reach: limbs must keep their lengths
   and adopt the closest reachable position, holding it on subsequent reachable
   edits. Rotate upper arms, forearms, thighs, and calves directly: the edited
   local rotation must take effect while the remaining joint compensates. Move
   and rotate a locked hand/foot directly, adjust its pole with Alt, and reset
   bones with Backspace. Check anchors/facing follow direct effector edits, while
   other locks remain active. Undo/redo edits and lock toggles. Unlock with L and
   confirm normal inheritance resumes. Repeat on small/large references.
   Pose a thigh, knee (Calf), and foot. Backspace on the knee must restore only
   the knee's local transform. Ctrl+Backspace on the knee must restore the knee
   and foot while keeping the thigh posed. Repeat on a forearm: its hand and
   hidden fingers must reset, while the upper arm and other branches stay posed.
   Open Shift+Backspace and repeat with Reset Bone and Reset Limb. Reset Entire
   Pose and Ctrl+Shift+Backspace must restore the pose displayed at session start,
   including root translation, scale, hidden bones, and any original asymmetry.
   Repeat with all hand/foot locks enabled and Full/Arms/Legs symmetry: limb locks
   must remain enabled at the reset pose, scoped opposite branches must follow,
   and entire-pose reset must reproduce the exact starting pose. Undo/redo each
   reset as a single step, checking lock anchors as well as the pose. Check that
   the full guide groups every reset shortcut/menu under Edit and the compact
   transform guide shows Reset current bone.
   Cancel/Esc in Reset Options must resume editing with focus and history intact;
   keyboard shortcuts and drags must not change the pose while the menu is open.
5. Right drag through 360 degrees: the camera must orbit a stationary mannequin.
   Pan, zoom, tilt and use fine movement. After middle-drag and Shift-middle-drag
   panning, right drag must orbit the current camera focus at the same distance,
   with no jump back to the mannequin. Repeat with Ctrl for fine movement.
   Orbit vertically over the top and
   underneath repeatedly: movement and screen-up must stay continuous through
   both poles. Repeat with focus on, checking that bone markers, pan, zoom, and bone
   editing remain usable at both vertical views.
   Tap Numpad 1/3/7 from several arbitrary angles: front/right/top must always
   match their exact canonical view. Ctrl+1/3/7 must give back/left/bottom. Repeat
   with a mannequin facing another heading, preserving camera distance each time.
   Press Numpad 4 exactly 24 times, then repeat with 6: both must complete one
   full revolution in opposite directions without reversing at angle boundaries.
   Repeat 24 presses with 8 and 2 through both vertical poles. Hold each directional
   key: one immediate step, then a comfortable repeat after a short delay, stopping
   on release, including during focus. Hold Numpad 9: it must invert only once;
   a fresh press must restore the view. Test 9 from a three-quarter elevated view.
   Numpad +/- must change distance without changing orientation, and stop at
   sensible near/far limits. After panning, numpad orbit/view keys must return their
   pivot to the mannequin; numpad zoom must keep the viewing direction while
   centering. Translate the root while posing, then confirm the pivot follows it.
   Test Num Lock both on and off; ordinary number-row and arrow keys must not
   activate camera shortcuts. Every shortcut must pass through unchanged to
   name/numeric fields, sliders, and modal reset/mirror/symmetry/blend menus.
   Open a dialog while holding orbit: closing it must not resume that held repeat.
   Test during a bone drag and after leaving the designer: no camera action.
   Compare mannequin/reference transforms, bones, undo history, and saved pose
   before/after camera-only navigation: all pose data must remain unchanged.
   Confirm the controls panel
   stays on the right, shows the selected bone and mode, and switches between full
   and compact lists with H. Test overlay placement at different resolutions and
   MGE UI scales. Check the player's mesh stays hidden.
   Orbit with locks active: the mannequin and every lock anchor must remain fixed.
   Press F: the panel must show Focus: On, the surrounding world must disappear,
   and the grid floor must appear at the mannequin's original grounding plane.
   It must use CSSE's circular line grid with translucent white lines and 16-unit
   spacing and twice the previous diameter. All lines, including the center
   axes, must have equal thickness. Lines must fade smoothly with
   distance from the circle's center, reaching invisible at the rim, without
   a hard cutoff or connections between rows.
   Check the outer rows from above and oblique views: their spacing must stay
   exactly one grid space, with no detached or protruding edge segments.
   Check small and large grids while orbiting and zooming. Lines behind the mannequin or its props must be hidden
   by their geometry when viewed from above or below. Change the pose's bounds:
   the grid must resize in steps, with a minimum radius of eight grid spaces.
   Game time and surrounding motion must freeze.
   Move the root and turn the mannequin: the grid must remain horizontal and fixed.
   While holding a root drag, press Ctrl+Z: the gesture must stop, the root must
   return to its starting transform, and focus must remain on. Keep moving the
   mouse, then release it: the pose must stay undone. Ctrl+Y must restore the
   partial move. Repeat with a movement arrow, rotation ring, and prop. If a grid
   resize is rejected, the prior grid must remain visible and only a diagnostic
   must appear in MWSE.log; editing, isolation, and muted audio must continue.
   Enable symmetry, move and lock the feet with IK, then toggle focus on. If the
   first grid load is rejected, focus must still open with lighting and isolation;
   the pose, locks, symmetry, undo history and draft must remain intact. The grid
   may be absent, with one diagnostic in MWSE.log and no error popup. Further
   frames must not repeat the failed load. Change the grid size or toggle focus
   off/on: a successful load must restore the grid without resetting the edit.
   Toggle F off and exit while focused: the grid must disappear in both cases.
   Weather wind, rain, ash/blight/blizzard loops, and thunder must fall silent,
   including sounds already playing. Test during a weather transition and open
   the name dialog; all audio except music must stay silent while focused.
   Check voices, footsteps, effects, and UI clicks too. Confirm music continues
   at its prior volume, and it stays off if music was already disabled.
   Confirm Master volume is zero while focused, with the individual audio sliders
   unchanged, and its original value returns when focus ends.
   Check rain already playing stops immediately on F and resumes immediately
   when focus ends, without waiting for a weather change. Repeat with a rain-to-
   thunderstorm transition, saving, canceling, and weather sound mods enabled.
   With MGE XE enabled, distant
   land, distant statics, water, grass, and sky must disappear too. The mannequin
   must remain visible with MWSE's default node-wrapper caching configuration.
   Face the sun during clear daylight: its disc, halo, and glare must disappear
   throughout focus, including while panning, orbiting, and opening the name dialog.
   Toggle focus off and leave the editor by saving or canceling; the sun must return
   immediately with its prior visibility. Repeat with the sun already hidden and
   with MGE disabled, checking that mannequin and outfit lighting stay intact.
   With Sunshafts enabled in MGE XE, verify its additional disc and rays disappear
   on F and return immediately on focus exit. Its prior disabled state must remain
   disabled afterward. Bloom/HDR/SSAO settings must remain unchanged. The focus log
   must report Sunshafts original state=true when that shader was enabled, false
   when disabled, or nil when absent, and native sunglare suppressed=true with MGE.
   The gameplay HUD (status bars, weapon/spell icons, effects, and minimap) must
   disappear while the editor panel and pointer remain usable. Open and cancel
   the name dialog and confirm the HUD stays hidden throughout focus mode.
   Test beside exterior water and check both distant water and the native fallback
   plane/ripples disappear. Repeat with MGE water already off before entering focus.
   Its outfit must remain visible and lit; bone markers, pointer, dragging, and camera
   controls must remain usable. Also test an interior with lamps and equipped lights.
   At night and in a dark interior, confirm the whole mannequin and outfit are
   readable with neutral fill and visible surface shading. Turn it around and
   tilt above/below it; lighting must follow the view and stay steady while zooming.
   Toggle focus off and confirm the original lighting returns immediately. Repeat
   after saving, canceling, opening modal menus, and leaving the cell.
   While focused, pan with middle drag, move in depth with Shift-middle drag, zoom
   with the wheel, and tilt with right drag. Confirm the view and bone marker positions
   update while the world remains frozen. Check nearby loaded terrain disappears,
   including after panning across a cell's landscape. Open the name dialog and
   confirm camera movement stops until it closes.
   Hold F
   and confirm it toggles only once. Press F again and verify original scene,
   HUD, AI, sky/world, native water, MGE settings, master volume, and simulation speed return.
   Repeat with the HUD already hidden and confirm it remains hidden afterward.
   Repeat with Master volume already zero or adjusted. Repeat with AI or world
   rendering already disabled, some MGE features off, and a nondefault simulation
   speed. Focus must start off on entry,
   stay on while naming or retrying a failed save, and restore settings after
   save, Escape, load, a cell change, reference removal, or a scene rebuild.
6. Make an asymmetric pose with a raised arm, bent leg, head turn, and body lean.
   Press M and choose Entire Pose, then Mirror Entire Pose: left and right limbs,
   root movement, and torso/head direction must reflect. Mirror again to restore
   the original. Test Arms and Legs with Mirror, Copy Left -> Right, and Copy
   Right -> Left. Copy must keep the source side, and each scoped command must
   leave the other limbs and torso unchanged. Entire Pose Copy must include both
   arms and legs and keep the torso. Check hands/fingers and feet, equipped weapon
   and shield attachment, and the remembered target when reopening M. Undo/redo
   each operation as one step. Repeat with locks on all four effectors: affected
   anchors must follow the result, with each side's lock still enabled; later
   edits must hold those anchors. Cancel and Escape must return to editing without
   canceling the session. Repeat after turning the view and on scaled mannequins,
   with focus on/off. Confirm menu buttons remain visible and clickable at different
   resolutions/UI scales. Save a mirrored pose and verify it after selecting/loading.
   Press S and select Full Symmetry: rotate each arm/leg joint from either side,
   move hands/feet in G mode, and use Alt to move elbows/knees. The corresponding
   opposite bone or IK chain must follow. Test Arms Only and Legs Only: the other
   limb group must remain unchanged. Off must restore independent edits. Check
   Backspace resets follow the same scope, and each drag/reset undoes/redoes both
   sides in one step. Selecting a mode must keep the current pose; root, torso,
   head, and equipment controls remain directly editable. Confirm the panel shows
   the active symmetry mode in the compact status panel.
   Lock both hands and feet, then repeat IK and direct upper/lower joint rotations.
   Opposite locked anchors must follow the mirrored result; later root/torso edits
   must hold their new positions/facing. Toggling L must still affect only the
   selected side. Repeat after turning/tilting the view, on scaled mannequins,
   and with focus on. Check S's buttons, Cancel/Esc, pending/active modal input,
   and reopen its menu to see the current setting. M must still work normally.
   Start a new editor session and confirm symmetry starts Off. Save a pose edited
   with symmetry and verify it after selection/loading.
   Press B before saving a custom pose. Both lists must include Relaxed,
   Contrapposto, Adlocutio, and Adlocutio II marked (Default). Blend two defaults
   and verify both endpoints, then save two different custom poses. Test a
   default/custom pair with the default on either side, as well as two custom
   poses. Choose one in each list and
   drag the slider between 0%, 50%, and 100%. Endpoints must match their saved
   poses, with smooth translation/scale and shortest-path rotation between them.
   Confirm the mannequin remains visible beside the dialog with focus on/off;
   its camera must stay framed, with bone markers/editor shortcuts disabled. Test a
   large library, both endpoints, the same source in both lists, turned/scaled
   mannequins, and UI scales/resolutions. Use blend must resume editing and undo/
   redo as one step; Cancel/Esc must restore the pre-dialog pose and lock anchors.
   Repeat with all four limbs locked and symmetry enabled: the blend must remain
   exact, anchors must follow an accepted result, and later manual edits must
   honor locks/symmetry. Try an incompatible or removed NIF and confirm an error
   leaves the dialog usable without accepting a failed preview. Import a shared
   main-only NIF. With no saved custom poses, default blending must still work.
   Save an accepted blend, reselect it, and verify save/load persistence. Load a
   game, change cells, or remove/rebuild the mannequin during preview and check
   that the dialog and editor close without leaving controls or focus active.
   Undo/redo several IK edits, then reset a bone. Press Enter and confirm the name
   field is focused immediately and accepts typing; click elsewhere in the input
   box and confirm it can regain focus. Enter a pose name and stable ID,
   and confirm them before any permanent NIF is written. Cancel the metadata dialog
   and check that editing continues. Try empty names and invalid IDs; neither must
   write. Try an existing ID and a case-only variant: the dialog must show an error
   and retain the fields. The existing files must stay unchanged. Save with a valid
   new ID. Repeating a display name with a different ID is allowed. Check
   direct pose application after the editor closes, restored facing, and that the controls
   and first/third person view return to their prior state.
   Repeat from first and third person, canceling with Escape, with focus both on
   and off. The designer must close directly to gameplay without opening the
   pause menu. The original view, player visibility, lighting, HUD, audio, and
   controls must return together. Hold Escape during exit: the menu must remain
   closed. Release it, then press Escape again: the normal pause menu must open.
   Escape in the name, mirror, symmetry, and blend dialogs must still cancel only
   that dialog and return to editing. Also check after saving, then load or change cells after an
   exit to confirm the player is never left hidden.
7. Check the three initial files carry the entered ID and their paths fit Morrowind's
   animation limit. Select a stock pose, then reselect the named pose from the
   menu. Save/load, leave/re-enter the cell, and pick up/place the
   mannequin. Verify the same pose, outfit, and lighting in each case.
   With a raised arm and bent knee, move each limb across every screen edge and
   back into view. Visible mesh pieces must not disappear while their joints or
   the mannequin's center are off-screen. Repeat in the editor, after cancel/save,
   on small/large mannequins, and with clothing/armor equipped.
   Select a custom pose on two mannequins. On one, choose Edit Pose: the overlay
   must identify its name and Enter must offer Save Changes, Save As,
   Edit Metadata and Cancel. Change its arm and Save Changes (also test Ctrl+S). The
   original path must stay selected and, with API v4, both mannequins must receive
   the changed pose immediately and after save/load and pickup/placement.
   Use Enter to access Save As; it must request a new name/ID and select the new
   bundle. An existing ID must be rejected; the saved source must retain its
   transforms and filenames.
   Duplicate must be absent from both the library and save menu. Edit the source's
   metadata, including a case-only display-name change: the ID/path and companion
   animation bytes must remain unchanged, while library and blend menus show the
   new name after reopening. Rename to an already-used display name; this is valid.
   Cancel the editor after metadata editing: those library actions remain while
   unsaved bone edits are discarded. Older poses without descriptive metadata and main-only
   shared NIFs must remain usable and browsing must not modify them.
   Interrupt each dialog by load, cell change, mannequin removal and scene rebuild;
   stale callbacks must not write. Simulate a write or pose-application failure
   during replacement; the full original bundle and selection must survive,
   focus/control state must stay in editing, and retry must succeed. Recheck the
   expanded Save / Exit section at the supported viewport and text sizes.
   Check each baseline (Relaxed, Contrapposto, Adlocutio, Adlocutio II): none may
   offer Edit Pose. Explicit baseline Edit Pose requests must be refused. Enter
   Create pose from each, press Ctrl+S, and verify an error explains that baseline
   poses cannot be overwritten and directs you to Enter / Save As. There must be
   no name dialog, saved output or changed selection, and editing must continue.
   Repeat on a mannequin with no explicit pose selection (implicit Relaxed).
   Enter must still save a distinct custom copy. Ctrl+Shift+S must have no action
   in either a new-pose or custom Edit Pose session and must not open symmetry.
8. Copy only the main NIF to a second test installation's `pose/k` directory. Select
   it with the designer enabled; confirm companions are generated and the pose
   displays identically. Test enough saved poses to exercise menu pagination.
   Confirm custom poses have a Delete action and stock poses do not. Click
   Delete and cancel: the files and selected pose must remain. Confirm deletion: all
   three files must disappear and the list must refresh on the same page. Delete
   the only pose on the last page and check navigation returns to a valid page.
   Delete the selected pose and check the mannequin changes to Relaxed. Test an
   unwritable pose file: show an error and keep the main pose available.
9. Make changes and cancel. Confirm the previous pose and original facing.
   Check that no tint remains on the mannequin or other actors after cancel/save.
   Try saving the game during editing (should be blocked); load a save, change
   cells, or remove the reference. Confirm no controls remain disabled and no Lua
   errors occur. Start and cancel repeatedly.
   Start another session after saving or cancelling: IK locks must start cleared.
10. Test a read-only/unwritable export folder: the previous pose must remain
    selected, the session must either remain editable after a save failure or
    restore controls if initialization/checkpointing fails, and errors must be
    visible. Remove a pose file and confirm OAAB fails gracefully.
11. Disable the designer while retaining the API update and all three animation
    files. Verify already-selected custom poses still reload through OAAB alone.

12. Press T and test Ground Left Foot, Ground Right Foot, and Ground Both Feet
    without opening the game's Rest/Wait menu. Hold T through dialog activation
    and verify Rest/Wait stays closed. Type a T in the pose-name field, cancel
    the editor, and verify the ordinary Rest/Wait shortcut works afterward.
    Test raised and sunken poses, including saved custom poses. Selected soles
    should meet the original ground plane with Relaxed tilt and their original
    Z heading; the root should move only vertically. Raise either foot with IK,
    choose Both Feet, and confirm the higher foot moves vertically down while
    the lower leg keeps its pose. Test rotated/scaled mannequins, enabled locks,
    symmetry, focus, and expanded controls. Undo/redo must restore the whole
    command and lock anchors in one step. Cancel/Esc must leave the pose alone.
    Try an unreachable raised foot: report the error without stretching or
    partially grounding the pose. Move the foot closer and retry. Save a
    grounded pose, reapply it, and confirm the same height and foot orientation.
    Load/change cells/rebuild the mannequin with this menu open and verify
    controls restore and stale callbacks cannot change the pose.

## Props acceptance pass (pending)

Install pose API v5 (`poses.lua` and `pose_props.lua`) and designer 0.2.12. The
automated prop tests use native-contract mocks; the following rendering and native
serialization checks have not been performed by those tests.

1. Add an ordinary sword, shield, book, ingredient, and clutter item directly
   with P while editing bones. Confirm inventory icons and item names, one
   selected visual copy, a stable ID, and unchanged inventory counts. Cancel
   the picker and try an inventory with no eligible items. Verify controls resume.
2. Check each prop's selectable node: the authored bone node shape, 12/16/18-pixel
   normal/selected/hovered sizes, pale-gold hover, and V/dialog visibility. Click
   or drag nodes to select props without a command menu. Duplicate with Ctrl+D;
   use Ctrl+Tab / Ctrl+Shift+Tab to select coincident props. Check G translation
   (including Shift depth), R rotation, S uniform scale, held X/Y/Z constraints,
   and Ctrl fine adjustment. Alt+S/R/G must reset only scale/rotation/translation;
   Delete removes the prop and node. Shift+P opens Replace Prop with the same
   inventory choices; selecting a new item must retain the ID, attachment,
   translation, rotation, scale, selected bone, and transform mode. Check both
   free and attached props, cancel/no-eligible-items, a rejected replacement
   mesh, unavailable original sources, undo/redo, and save/reopen after replacement.
   Undo/redo each operation. Cancel a drag
   with Esc and confirm the transform and pending redo survive.
3. Select a bone, then a prop. The prop node and geometry must be amber; the bone
   node and all its affected shapes must stay blue as the inactive selection.
   Shift-click or Tab / Shift+Tab must choose one attachment bone while keeping
   the prop active. Ctrl+P attaches to that bone. Alt+P detaches and disappears
   from the sidebar when free. Test right/left hands, head, torso, pelvis, and
   both feet. Free -> right hand -> left hand -> free must preserve visible
   position, rotation, and scale on a rotated/scaled mannequin. Undo/redo the
   chain. A normal bone click must restore its amber active tint and transform
   focus without reparenting. Verify Shift-click at a shared bone/prop pivot
   chooses the bone on release, while Shift-drag still moves the prop in depth.
   Import `m/misc_dwrv_artifact50.nif` and confirm its unnamed RootCollisionNode
   branch is skipped while all visual parts remain.
4. Attach a sword to a hand, click a bone normally, and continue posing the arm
   using rotation and IK. The sword must follow through scene parenting.
   A free book beside the mannequin must remain independent of bone motion
   while following reference movement. Test bone resets, symmetry, mirror,
   blending, grounding, and focus with props present. Verify no implicit prop
   collision or imported animation changes the scene.
5. Save multiple props. Confirm the main NIF contains an `OAAB:PoseProps:`
   `NiStringExtraData` with editable definitions,
   plus normal xp NIF/KF companions. Reopen, restart Morrowind, reload the save,
   and reopen again. Match IDs, meshes, local transforms, and attachments.
   Save Changes, Save As, and rename a saved pose. Delete all props,
   save changes, and confirm old embedded geometry does not reappear.
6. Apply the finished pose in ordinary gameplay and to another mannequin.
   Change cells/rebuild the reference, refresh after Save Changes, and switch
   between decorated and plain poses. No duplicates or leftover props should
   appear. Disable the designer and its editor metadata; the baked NIF must
   still display its props using OAAB_Data alone. Check outfits and held equipment.
   Pick up and drop a posed mannequin three times. The saved pose and both hand-
   attached/free props must persist through placement and subsequent animation
   frames. Keep another posed mannequin nearby and verify its pose continues too.
   Check MWSE.log for deleted-userdata errors; repeat after save/reload and with
   an ordinary no-prop pose. Install the updated OAAB v6 compatibility package
   containing the lifecycle fix for this check.
7. Temporarily remove a source mesh before reopening: retain its definition,
   display an unavailable-mesh status, permit deletion/cancel, and refuse a save
   that would silently omit it. Restore the mesh and reopen.
   Also test a pose with geometry but no editable metadata: gameplay and
   skeleton editing should work, and props must survive Save As/Save Changes.
   Individual prop operations must explain that original metadata
   is needed. Test a
   particle/light/skinned mesh and verify a useful logged rejection. Restore
   test assets afterward; do not overwrite an important pose to test failure.
8. Export an ordinary no-prop pose and check its descriptive NIF metadata. The
   xp NIF/KF companions must match the existing patcher for equal bone state; the
   main NIF also contains the new metadata and may be serialized differently. Test normal
   new-pose creation, save/cancel, undo, equipment, controls, and scene cleanup.
   Inspect a real serialized prop NIF independently in NifSkope and confirm all
   bone controllers, prop hierarchies/transforms, textures, and collision switches.
9. Check prop nodes and the compact/expanded sidebar at different UI scales and viewport sizes, with
   focus and expanded controls. Scene rebuild, cell change, load, and exit while
   the native inventory picker is open must release input and ignore stale callbacks.

Record MWSE/MGE versions and `MWSE.log` errors with results before release.
