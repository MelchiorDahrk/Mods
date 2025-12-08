=============================
 Mage Robes
=============================
by Melchior Dahrk
Version 2.4.1

These robes were originally made for my Lyithdonea project, but I decided to release them as a standalone mod for Modathon 2018. The concept behind the mod is to provide both an immersive experience by giving a uniform to mages guild members as well as to improve gameplay by providing a useful alternative to armor for mages; such as is offered in Skyrim. Many Mages Guild members will now wear the new robes. 


=============================
 Installation
=============================

Wrye Mash
Installation
==============

Archive is set up to use Sub-Packages and the ESP/ESM Filter (especially for the Add-Ons Sub-Package) for Mash Installers:

00 Core --- required files
01 Automatic Add-Ons (MWSE) --- if you use MWSE, this code will automatically patch all qualifying Mages Guild members in your game
01 Static Add-Ons (non-MWSE) --- if you do not use MWSE, I have included specific add-ons for other mods. Select the ESPs which match the mods you use.
02 Vanilla-Style Robe Enchantments --- optional patch (read more in Patches below)


Manual
Installation
==============

00 Core --- Required files

01 Robe Distribution (MWSE) --- Automatically distributes robes to all Mages Guild NPCs in your game (province mods included).

01 Robe Distribution (OpenMW) --- Manually distributes robes to all Mages Guild NPCs on Vvardenfell using plugins which need to be activated separately.

02 Vanilla-Style Robe Enchantments --- This patch lowers the power of the robe enchantments to be more similar to enchantments in the vanilla game. See its ReadMe for details.

03 Normal and Specular Maps for OpenMW --- Install this if you use normal maps in your game.


=============================
 Playing the Plugin
=============================
To toggle your hood, drop the robe and pick it back up. A message will appear giving you the option to use/remove your hood.

Generic robes:
After you join the mages guild, talk to the Wizard of the Guildhall (who you joined with) about "member of the mages guild" to receive your generic novice robes. Once you are a wizard, you can talk to any other wizard about "member of the mages guild" again to receive your Master Robes.

Purchased robes:
After you become at least a Journeyman, you can talk to the new provisioner NPC in the Caldera Guild of Mages to purchase novice robes for each school. Once you are a wizard, you can purchase master robes from the provisioner. You must have a skill level of 20 in each school to purchase novice robes and 70 to purchase master robes.

Quest rewards:
Each of the Mages Guild questgivers will give the player a set of robes once they reach a certain level in their quests. Be sure to look for new topics to make sure you receive your robes (see spoiler section for details). This includes: Ajira (Balmora), Ranis Athrys (Balmora), Edwinna Elbert (Ald'ruhn), Skink-in-Tree's-Shade (Wolverine Hall). Finally, Trebonius has a quest for the player to recover the Arch-Mage's robe (if Trebonius is dead, talk to Flacassia Fauseius -Vivec Guild Guide- after becoming Arch-Mage).


=============================
 Recommended Mods
=============================
Mastering Magicka --- https://www.nexusmods.com/morrowind/mods/42269 --- penalizes mages for wearing armor among other changes to the magic system

Subtle magic Glow --- https://www.nexusmods.com/morrowind/mods/4468 --- to make it so that the new, detailed robes are not obscured by the "shrink wrap" enchantment effect

Magical Missions --- https://www.nexusmods.com/morrowind/mods/38773 --- to provide more to do in the Caldera Guild of Mages

Stav's Mages Guild Aesthetics Overhaul --- https://www.nexusmods.com/morrowind/mods/43561 --- to add more Mages Guild iconography to the game


=============================
 Incompatibilities
=============================
Privileges & Services gives NPCs and the player robes similar to this mod. It's not a hard conflict. But NPCs may choose to wear those robes instead.

The robes on NPCs were added via script and so the NPCs themselves are not edited by this mod for maximum compatibility. No vanilla dialogue was directly edited new topics were slipped in to provide the player with the new robes.


=============================
 Credits
=============================
Arcarias - Normal and Specular Maps for OpenMW
Arcimaestro Antares - mining animation
Cyprinus - for a large amount of feedback as this mod was developed!
Heinrich - Arch-Mage's robe model and several accessories for other robes
Greatness7 - huge help with scripting in the mod!
Lougian - dust motes particles and vine meshes
Mireneye - cave path meshes
Morovir - rock cluster meshes 01 and 04
Mr_Siika - bat creature
NullCascade - MWSE add-on patch
Reizeron - blind slaughterfish
Taddeus - Satchel
The Wanderer - Scroll Case
Cammy - for helping root cause the OpenMW issue

Everyone who has helped improve the mod by reporting issues!


=============================
 Permissions
=============================
You are free to:
Adapt - remix, transform, and build upon the material

Under the following terms:
Attribution - You must give appropriate credit.
Non-Commercial - You may not use the material for commercial purposes (i.e. no payment of monetary compensation as a condition for the download).

If author(s) is/are not able to be contacted through a reasonable effort,
Then you are free to copy and redistribute the material in its entirety for use in The Elder Scrolls III: Morrowind


=============================
 Changelog
=============================
V1.00 - Initial Release
V1.01 - Hotfix removes unfiltered Hit dialogue response. Fixes Staff of Magebane enchantment
V1.02 - Added collision to the water rapids mesh, fixed animation error for Gorluck, fixed some visible gaps in dungeon
V1.03 - Fixed unfiltered dialogue for Gorluck
V1.04 - Missed two unfiltered topics
V1.05 - Fixed "novice robes" and "master robes" dialogue filtering. Made the quest for the Arch-Mage's robe start corectly if Trebonius is dead.
V1.10 - Added "patch" to change robe enchantments to vanilla power levels. Made mod compatible with Caldera Mage's Quarters. Included Add-On for Caldera Mages Guild Expanded.
V1.20 - Added alternate (muted) texture patch for Arch-Mage robe. Added script failsafe if Gorluck does not go through sequence to mine the rock (OpenMW fix). Fixed dialogue filtering for Skink's quest.
V1.21 - Changed file dates of Add-Ons so that they load after the plugins they are patching properly. Verified fix for OpenMW mining sequence not playing.
V1.22 - Fixed visible dust marker model. Optimized Gorluck's script to remove an OpenMW error. Covered visible seam in cavern.
V1.30 - Official fix for OpenMW (updated script to be both MW and OMW compatible). Use latest nightly OpenMW version or look for the 0.45 release
V1.31 - Fixed Caldera Mages Guild Expanded Add-On which duplicated Anja.
V1.40 - Added Add-On for Scrolls of The Nine Barriers. Fixed bug where teleportation would not reenable after leaving Vardarai. Fixed bug where Ranis Athrys gives the player Alchemy robes instead of Restoration. Fixed bug where you would not qualify to buy the novice mysticism robe even if your skill was high enough. If you use "Mage Robes_Weak.ESP", use the latest version (to ensure it loads after the main mod).
V1.41 - Fixed bug where the guild guide didn't have "the Arch-Mage's robe" topic if the player has already become the Arch-Mage. Fixed load order for Scrolls of The Nine Barriers Add-On. Fixed texture paths on the male and female Master Robes.
V1.42 - Gave Flacassia Fauseius a closing statement after you get the Arch-Mage robe instead of repeating the initial comment. Reordered the mod archive so that the patches and add-ons work with Wrye Mash BAIN Installers properly.
V1.43 - installation instructions improved in ReadMe - archive reordered because I'm picky and like the new naming scheme better. Mod itself is unchanged - not required to update.
V1.44 - Fixed dialogue filter issue if you had sufficient Mysticism resulting in infinite loop.
V1.50 - Added automatic compatibility MWSE patch by NullCascade
V1.51 - Fixed Trebonius giving the player multiple robes. Cleaned dialogue.
V1.52 - Blacklisted Trebonius in the MWSE Add-On so that he will not receive a robe (he gets it as part of his quest). Renamed archive folders to standard format.
V1.53 - Fixed syntax error in MWSE code
V1.60 - Fixed Gorluck's spike attack and improved the visual effect.
V1.61 - Cleaned dialogue
V1.7.0 - Added support for Dragonstar Mages Guild
V2.0.0 - Mod now dependent on OAAB_Data for asset sharing and reduced file size. Remade the Arch-Mage's robe to be less bulky. Toned down textures on Arch-Mage's robe. Patch for Privileges & Services version 1.0 to remove its Mage Robes (cannot guarantee support for future P&S updates). Separated the scripted robe placement for Vvardenfell mages into its own ESP for OpenMW so MWSE users don't get that extra bloat. Made Miner's Helm light effect use regular alpha texture to be less buggy on some graphics cards. 
V2.0.1 - Removed robe provisioner from OpenMW Vvardenfell ESP. Added check for Wizard's giving you the novice robes at the Caldera Guildhall for more natural dialogue. Made it so the provisioner only sells hooded robes to keep her shop inventory less cluttered. Gave the Master Robes the correct enchantment. Dialogue typo fixes.
V2.0.2 - Cleaned dirty dialogue topic references.
V2.0.3 - Fixed the Privileges & Services Patch to properly remove the robes.
V2.0.4 - Merged the static "Vvardenfell" addon back into the main ESP. Separating it caused some unintended issues. Vanilla NPCs should wear the same robes as before now.
V2.1.0 - Updated neck area of male and female robes to be compatible with Robert's Bodies (still works with Better Bodies and vanilla). Removed Skink-in-Tree's-Shade from default blacklist. Fixed default blacklist settings. Fixed bug where the Arch-Mage Robes quest would not close properly if Trebonius is already dead. Removed Privileges & Services patch - patch requests should be directed at that mod. Added fomod.
V2.1.1 - Added Ajira to default MWSE blacklist so her Novice Robes quest will still function as intended (she earns her robes).
V2.1.2 - Fixed script error for the robe battle
V2.1.3 - Replaced activator models with invisible markers for better mod compatibility
V2.1.4 - Fixed script error which could cause the scroll to not appear at the end of the Arch-Mage robe quest
V2.2.0 - Added optional module for normal and specular maps for OpenMW by Arcarias
V2.2.1 - Fixed chest portion of male enchanter's robe being invisible in game. Added metadata for MWSE option.
V2.2.2 - Fixed fomod installer.
V2.3.0 - Replaced the Scroll of Return with a 2-way amulet on Lillorne. Fixed some grammatical issues in dialogue. Changed ground mesh for Gorluck's offhand pick so that it shows up on his back properly with Weapon Sheathing. Made Trebonius give you a reward for getting his robes. Added female version of Arch-Mage robes. Added "Antlas Salobar" from Magical Missions to the MWSE blacklist. Added HD texture option.
V2.4.0 - Added 1st person mesh for female arch-mage robe. Added Listien Bierles to the MWSE blacklist. Updated Gorluck's dialogue to allude to the new way to leave the cave. Fixed bug if the player is expelled and tries to talk to Trebonius about the arch-mage robe. Fixed bug where you can keep the arch-mage robe if you are wearing the hooded version when talking to Trebonius.
V2.4.1 - Fixed female arch mage 1st person mesh link to plugin


=============================
 Spoilers
=============================
How to get quest reward robes. See below.




































Spoilers ahead!







































Ajira:
Ajira will give the player Novice Robes of Alchemy once they complete the Stolen Reports quest (you must leave and return to the cell for her to receive her own robes first!). You must talk to her about "novice robes".

Ranis Athrys:
Ranis will give the player Novice Robes of Restoration once they complete the Unsanctioned Training quest. You must talk to her about "training in restoration".

Edwinna Elbert:
Edwinna will give the player Novice Robes of Illusion once they complete the Return Chimarvamidium quest. You must talk to her about "dangerous places".

Skink-in-Tree's-Shade:
Skink will give the player Novice Robes of Mysticism once they complete the Soul of an Ash Ghoul quest. You must talk to him about "soul trapping".

Trebonius Artorius:
Trebonius will send the player on a quest to retriev the Arch-Mage's Robes if they talk to him about "member of the mages guild". If Trebonius is dead, talk to Flacassia Fauseius -Vivec Guild Guide- after becoming Arch-Mage about "the Arch-Mage's robe".