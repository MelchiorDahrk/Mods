# OAAB Mannequin Pose Designer

Create, edit, and share custom poses for OAAB_Data mannequins. Includes a pose library with live previews, props from your inventory, and tools for symmetry, mirroring, blending poses, and grounding feet.

### Features

- **Strike a pose.** Shape your mannequin directly in-game with draggable bone markers, movement arrows, rotation rings, and fine adjustments.
- **Find the perfect stance.** Browse live 3D pose previews, search your collection, and filter by category or source.
- **Put limbs where you want them.** Move hands and feet with IK, adjust elbow and knee bends, lock hands or feet in place, and ground one or both feet.
- **Make symmetry a shortcut.** Mirror edits across both arms, both legs, or all limbs; flip a pose or copy one side to the other.
- **Mix up something new.** Blend two built-in or custom poses with a slider and watch the result take shape live.
- **Add props with personality.** Use visual copies of inventory items, move, rotate, and scale them, then attach them to bones to follow the pose.
- **Step into your own studio.** Focus mode hides the surroundings and freezes time; orbit, pan, and zoom to find your best angle.
- **Experiment freely.** Undo, redo, and reset individual bones, limbs, or the whole pose while you work.
- **Save it. Share it.** Name, describe, and categorize your creations, revise saved poses or save new variants, and share portable NIF/KF bundles with embedded props.
- **Manage poses from the MCM.** Scroll through the full pose list, edit custom names, descriptions, and categories, or delete custom poses without finding a mannequin.

### Requirements

- MGE XE w/ MWSE
- OAAB_Data -- **Core** and **MWSE Functions**

OpenMW is not currently supported.

### MCM settings

Open **Mod Config > OAAB Mannequin Pose Designer > Settings** and enable **Enter Focus Mode by default** to start Create Pose and Edit Pose sessions with the surroundings hidden and time frozen. It is off by default, applies the next time you open the designer, and is saved when you close the MCM. Press **F** while editing to toggle Focus Mode for that session.

Open **Mod Config > OAAB Mannequin Pose Designer > Settings** and enable **Debug mode** to write troubleshooting diagnostics to `mwse.log`. It is off by default, takes effect immediately, and is saved when you close the MCM.

Open **Mod Config > OAAB Mannequin Pose Designer > Poses** to scroll through the full list of built-in and custom poses. Each entry shows its name, source, ID, and file path. The included OAAB API helper also lists poses registered by other mods. Reopen the MCM after installing or removing pose files. Choose **Edit Metadata** to change a custom pose's name, description, or category, then **Save Metadata**. Its ID and filenames stay fixed. **Delete** asks for confirmation before removing the custom pose bundle. With the updated OAAB API helper, loaded mannequins using the deleted pose quietly return to Relaxed; unloaded or portable mannequins do so when loaded or placed. Built-in and registered poses are read-only.

### Installation

- Install the **meshes** and **mwse** folders to Data Files.

### Using the designer

1. Activate an unowned full mannequin and choose **Change Pose**. Dress stands do not have this option.
2. Select a pose card and choose **Apply**. Search, categories, and source filters help find poses.
3. To make a new pose, apply the pose you want to start from, then reopen the library and choose **Create pose**.
4. To change an existing custom pose, select its card and choose **Edit Pose**.

OAAB_Data's built-in poses cannot be overwritten. Use **Create pose** to make a custom copy.

Select a bone or prop by dragging its marker. Drag the gizmo's arrows to move or its rings to rotate. Press **H** to show all controls; the sidebar also shows controls for the current selection.

### Main controls

- **Tab / Shift+Tab** -- next / previous bone
- **G** -- move the root, hands/feet with IK, or a prop
- **R** -- rotate
- **Hold X / Y / Z** -- constrain rotation to a local axis
- **Shift while moving** -- move in depth
- **Ctrl while dragging** -- fine adjustment
- **Alt+left drag** on a hand/foot in G mode -- adjust elbow/knee bend
- **L** -- lock / unlock a hand or foot
- **S** -- choose symmetry mode; scale when a prop is selected
- **M** -- mirror or copy the pose or limbs
- **B** -- blend two built-in or custom poses
- **T** -- ground one or both feet
- **Right drag / Middle drag / Wheel** -- orbit / pan / zoom
- **Ctrl+Z / Ctrl+Y** -- undo / redo
- **Backspace / Shift+Backspace** -- reset selected bone / open reset options
- **F** -- focus mode: hide surroundings and freeze time
- **V** -- show / hide bone and prop markers
- **Enter** -- save a new pose or open save options
- **Ctrl+S** -- save changes when using Edit Pose
- **Esc** -- close controls/dialog or cancel editing

Resets restore the pose from the start of the editing session. Canceling discards unsaved pose edits. Finish or cancel editing before saving the game.

### Props

Press **P** to add a visual copy of an item from your inventory. This does not take the item. Props use the item's ground model; worn armor and clothing are not assembled from body parts. Only static meshes are supported.

With a prop selected:

- **G / R / S** -- move / rotate / scale
- **Tab / Shift+Tab** or **Shift+left click** on a bone -- choose its attachment bone
- **Ctrl+P / Alt+P** -- attach to the selected bone / detach
- **Ctrl+Tab / Ctrl+Shift+Tab** -- next / previous prop
- **Ctrl+D** -- duplicate
- **Shift+P** -- replace with another inventory item
- **Delete** -- remove

Attached props follow their bone as you pose the mannequin.

### Saved poses and sharing

Poses are saved in `Data Files/meshes/pose/k/`. New poses need a name and a unique ID. IDs can contain up to 19 letters, numbers, underscores, or hyphens and must start with a letter or number. An ID such as `guardlean` creates `guardlean.nif`, `xguardlean.nif`, and `xguardlean.kf`.

Use **Save Changes** to update the pose opened with **Edit Pose**, or **Save As** to make a new copy. **Edit Metadata** changes the displayed name, description, and category while keeping the IDs/filenames.

### Changelog

Version 1.2.0
- Improved rotation gizmo visuals (thanks, G7!)

Version 1.1.0
- Added MCM
- Made debugging off by default
- Made pose deletion fall back to relaxed pose more smoothly
- Fixed error from not having OAAB Mannequin Race installed

Version 1.0.0
- Initial Release