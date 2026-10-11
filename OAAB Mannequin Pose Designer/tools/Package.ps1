[CmdletBinding()]
param([string]$OaabRoot = 'D:\Games\Morrowind\Repositories\OAAB_Data')
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$dist = Join-Path $projectRoot 'dist'
New-Item -ItemType Directory -Force -Path $dist | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$package = Join-Path $dist "OAAB-Mannequin-Pose-Designer-$stamp"
$compat = Join-Path $dist "OAAB-Data-Pose-API-$stamp"
New-Item -ItemType Directory -Path $package,$compat | Out-Null
Copy-Item -LiteralPath (Join-Path $projectRoot 'MWSE') -Destination $package -Recurse
Copy-Item -LiteralPath (Join-Path $projectRoot 'meshes') -Destination $package -Recurse
Copy-Item -LiteralPath (Join-Path $projectRoot 'OAAB Mannequin Pose Designer-metadata.toml') -Destination $package
Copy-Item -LiteralPath (Join-Path $projectRoot 'README.md') -Destination $package
Copy-Item -LiteralPath (Join-Path $projectRoot 'docs') -Destination $package -Recurse
$destination = Join-Path $compat 'MWSE\mods\OAAB\Mannequins'
New-Item -ItemType Directory -Force -Path $destination | Out-Null
Copy-Item -LiteralPath (Join-Path $OaabRoot '01 MWSE Functions\MWSE\mods\OAAB\Mannequins\poses.lua') -Destination $destination
Copy-Item -LiteralPath (Join-Path $OaabRoot '01 MWSE Functions\MWSE\mods\OAAB\Mannequins\pose_props.lua') -Destination $destination
Copy-Item -LiteralPath (Join-Path $OaabRoot '01 MWSE Functions\MWSE\mods\OAAB\Mannequins\API.md') -Destination $destination
Compress-Archive -Path (Join-Path $package '*') -DestinationPath ($package + '.zip')
Compress-Archive -Path (Join-Path $compat '*') -DestinationPath ($compat + '.zip')
Write-Output ($package + '.zip')
Write-Output ($compat + '.zip')
