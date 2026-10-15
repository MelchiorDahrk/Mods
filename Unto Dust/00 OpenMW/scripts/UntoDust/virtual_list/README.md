# OpenMW Virtual List

Vendored from https://github.com/Greatness7/openmw_virtual_list
at commit `1d272e10bfdb70e36cb5dc0264b9e68d58931d10` (MIT, Greatness7).
The accompanying LICENSE applies to this directory.

The MCM integration follows the bordered lists and search boxes in
https://github.com/Greatness7/assetReviewTools.

Local changes:

- `VirtualListExt:createSearchBox` accepts `initialText` to retain filters when
  OpenMW Settings rebuilds the renderer after a storage update.
- The wheel handler drops destroyed focused elements during Settings rebuilds.
