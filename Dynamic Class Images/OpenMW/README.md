## Dynamic Class Images
by Melchior Dahrk

## Description
This mod makes it so that the class images you see during character creation and when leveling up are specific to your class. No more recycling the vanilla image for custom classes!

This is accomplished by mixing nearly 100 different images based on criteria such as skills, attributes, and specialization. Every one of these images is dynamically generated -not hardcoded- by a complex set of logic. Choose alchemy as a major skill? Expect to see an apparatus or ingredients show up for your class. Major in long blades? There's a good chance that your class will get a longsword in the image. The potential combinations is enormous.

To establish the logic behind this mod, I studied the vanilla classes and created a set of rules based on how Bethesda used items in the vanilla class images.

In addition to dynamically replacing images for custom classes, this mod also packages new HD renders of the vanilla classes which are faithful to the original arrangement.

## Optional integrations

- [Stats Window Extender](https://www.nexusmods.com/morrowind/mods/57727) enables class artwork in the class tooltip.
- [Uncapper](https://www.nexusmods.com/morrowind/mods/58457) enables class artwork in its CustomUI level up menu.

Both mods are optional and work independently. Without either installed, Dynamic Class Images still shows the class preview beside the stat review menu. With only one installed, its corresponding display is available alongside the preview.

## Recommendations
We recommend using this mod with mods that add new classes to the game like:
OAAB Integrations (OAAB Classes) - https://www.nexusmods.com/morrowind/mods/49045
Ahead of the classes - https://www.nexusmods.com/morrowind/mods/50346
Playable NPC classes - https://www.nexusmods.com/morrowind/mods/43428

## Installation
Install this mod's OpenMW files and enable `DynamicClassImages.omwscripts`.
When using Stats Window Extender or Uncapper, load Dynamic Class Images after the installed mods.
For Uncapper integration, this mod packages an edited `scripts/Uncapper/levelup.lua` file which must override the one included in Uncapper. The artwork appears when Uncapper's attribute uncapper is enabled in `CustomUI` mode. Without Uncapper installed, this file is unused.

## Known issues
OpenMW does not expose the class selection menu. So the class images will not live update there like in the MWSE version. Instead, you need to select/create a class and then a new UI will appear next to the stat review menu with your class preview. This preview also works without Uncapper or Stats Window Extender installed.

## Changelog
Version 1.1.0
- Made the Uncapper and Stats Window Extender integrations optional

Version 1.0.0
- Initial release
