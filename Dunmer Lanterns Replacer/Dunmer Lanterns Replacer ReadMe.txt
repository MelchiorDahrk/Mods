=============================
 Dunmer Lanterns Replacer
=============================
by Melchior Dahrk
Version 14.0


=====================
 Description
=====================
This mod replaces all of the Dunmer lanterns (including the paper lanterns and streetlight) from the original game with smoother, more detailed versions (yet not with a ridiculous amount of new polies: they're optimized).

Breakdown of what's included:

Light_Ashl_Lantern_01/02/03/04/05/06/07
Light_De_Lantern_01/02/03/04/05/06/07/08/09/10/11/12/13/14
Light_De_streetlight_01
Light_paper_lantern_01/02/off


=====================
 Installation
=====================

Mod Organizer 2
Installation
=============
This mod comes with a fomod installer script. Simply select the 7z archive with MO2 and the installation wizard will walk you through the options.


Wrye Mash
Installation
==============
Archive is set up to use Sub-Packages for BAIN Installers:
	00 Core : The required files for this mod to work (No Glow Effect)
	Optional
		01 Glow Effect - Lanterns will have a subtle glow effect around them. 
		02 Ashlander Lantern (Smoothed Only) : Install if you just want a smoothed version of the ashlander lantern models without the extra details. See pictures.
		02 Ashlander Lantern (Smoothed Only) - Glow Effect : Adds a glow effect around the ashlander lantern models
		03 Ashlander Lanterns Retexture no.1 : Retexture by Pherim. See images.
		03 Ashlander Lanterns Retexture no.2 : Retexture by SWG. See images.
	Patches
		04 Tamriel_Data Patch : Replaces the lanterns in Tamriel Rebuit to match the high quality models from this mod.
		04 Tamriel_Data Patch - Glow Effect : Adds a glow effect around the lanterns in Tamriel Rebuit
	AA Images : Not required for installation. Refer to these images for details on the optional content.


Manual
Installation
==============
To install copy the desired files into the Data Files directory. No plugin to activate, you're ready to play!


=====================
 Permissions
=====================
You are free to:
Adapt - remix, transform, and build upon the material

Under the following terms:
Attribution - You must give appropriate credit.
Non-Commercial - You may not use the material for commercial purposes (i.e. no payment of monetary compensation as a condition for the download).

If author(s) is/are not able to be contacted through a reasonable effort,
Then you are free to copy and redistribute the material for use in The Elder Scrolls III: Morrowind


=====================
 Credits
=====================
Wolli - Made the TR patch
Pherim - For the Ashlander Lantern retexture no.1
starwarsgal9875 - For the Ashlander Lantern retexture no.2
Hemaris - For paving the way on light mesh improvements


=====================
 Changelog
=====================
v1.0-5.0: I don't remember
v6.0: All Ashlander bug lanterns have been replaced
v7.0: Added Light_De_Lantern_01, 07, 11; fixed Ashlander orientation
v8.0: Added Light_De_Lantern_05, 10, 14; fixed candle flame visibility in glass lanterns (thanks papill6n); fixed mesh opening on Light_De_Lantern_01, 07, 11
v9.0: Removed collision from all lanterns (except the Streetlight which had collision before), fixed bounding box issues which were causing floaters when placing lanterns, used papill6n's candle flame visibility tweak on Light_De_Lantern_05, 10, 14 so that the flame should display properly
v10.0: Optimization patch for all models to improve performance, with no loss in quality. Also fixed light source position, shadowbox, and bone offset (for held position) on some lanterns.
v10.1: Fixed misplaced lanterns.
v10.2: Visual improvement for light_de_lantern_02 (added wick and fixed flickering candle bug); repackaged file to be MASH compatible.
v11.0: Fixed the optional smoothed ashlander lantern patch. Removed legacy support for lantern_04 alternates. Added TR patch, courtesy of Wolli. Revised Permissions.
v12.0: Added optional glow effect to lanterns. Minor optimizations and improvements to many models.
v12.1: Fixed mis-named texture path in TR patch
v12.2: Fixed normals on paper lanterns. Minor optimization of all models. Fixed archive format for installer compatibility.
v12.3: Compatibility fix for the glow effect lanterns and The Midnight Oil
v12.4: Added glow effect option for smooth ashlander lanterns. Repackaged archive. Added fomod installer for MO2 users. Still BAIN compatible (for Wrye Mash users).
v12.5: Fixes for Light_De_Lantern_02,06 meshes.
v13.0: Applies light mesh improvements from "Improved Lights for All Shaders" to DLR meshes. Fixed/added AttachLight nodes to lights so the light and/or light shaders are attached in the correct location. Improved vertex normals on candles to reflect light better. Added emissivity to all candle flames so they glow properly. Reduced material brightness on lights and illuminated paper materials so they still "pop" but are less overbrightened in daytime scenes. General optimization of several meshes.
v13.1: Fixed emissive properties on a few meshes. Added OAAB_Data patch.
v13.2: Fixed the OAAB_Data Patch adding glow effect if you select no glow.
v14.0: Updated for Tamriel_Data 10.0. Added OAAB_Data glass lanterns. Optimized a few meshes.