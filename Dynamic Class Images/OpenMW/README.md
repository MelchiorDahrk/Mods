## Dynamic Class Images
by Melchior Dahrk

## Description
This mod makes it so that the class images you see during character creation and when leveling up are specific to your class. No more recycling the vanilla image for custom classes!

This is accomplished by mixing nearly 100 different images based on criteria such as skills, attributes, and specialization. Every one of these images is dynamically generated -not hardcoded- by a complex set of logic. Choose alchemy as a major skill? Expect to see an apparatus or ingredients show up for your class. Major in long blades? There's a good chance that your class will get a longsword in the image. The potential combinations is enormous.

To establish the logic behind this mod, I studied the vanilla classes and created a set of rules based on how Bethesda used items in the vanilla class images.

In addition to dynamically replacing images for custom classes, this mod also packages new HD renders of the vanilla classes which are faithful to the original arrangement.

## Requirements
Stats Window Extender (used for the class tooltip) - https://www.nexusmods.com/morrowind/mods/57727
Uncapper (used for the level up menu) - https://www.nexusmods.com/morrowind/mods/58457

## Recommendations
We recommend using this mod with mods that add new classes to the game like:
OAAB Integrations (OAAB Classes) - https://www.nexusmods.com/morrowind/mods/49045
Ahead of the classes - https://www.nexusmods.com/morrowind/mods/50346
Playable NPC classes - https://www.nexusmods.com/morrowind/mods/43428

## Installation
This mod must be loaded after Stats Window Extender and Uncapper.
Since Uncapper does not currently have an API for its menu, this mod packages an edited `levelup.lua` file which must replace the one included in Uncapper.

## Known issues
OpenMW does not expose the class selection menu. So the class images will not live update there like in the MWSE version. Instead, you need to select/create a class and then a new UI will appear next to the stat review menu which shows how your class image will appear in the level up (Uncapper) and class tooltip (Stats Window Extender) menus.

## Changelog
Version 1.0.0
- Initial release