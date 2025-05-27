@echo off
copy /y "..\\00 Core\\Graht Morrowind Swamp Trees.esm" "Graht Morrowind Swamp Trees.esm"
.\\merge_to_master.exe %1 "Graht Morrowind Swamp Trees.esm" --overwrite --remove-deleted --apply-moved-references
move /y "Graht Morrowind Swamp Trees.esm" "..\\00 Core\\Graht Morrowind Swamp Trees.esm"
pause