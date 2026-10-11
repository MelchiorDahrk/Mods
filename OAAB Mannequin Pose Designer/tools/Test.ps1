[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Lua,
    [string]$OaabRoot = 'D:\Games\Morrowind\Repositories\OAAB_Data',
    [string]$JsonLibrary = 'D:\Games\Morrowind\Data Files\MWSE\core\lib\dkjson.lua',
    [string]$Python = 'python'
)
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
Push-Location -LiteralPath $projectRoot
try {
    New-Item -ItemType Directory -Force -Path '.work' | Out-Null
    $sourcePaths = @(Get-ChildItem -LiteralPath 'MWSE','tests' -Filter '*.lua' -Recurse | ForEach-Object FullName)
    $poseApi = Join-Path $OaabRoot '01 MWSE Functions\MWSE\mods\OAAB\Mannequins\poses.lua'
    $sourcePaths += $poseApi
    $sourcePaths += (Join-Path $OaabRoot '01 MWSE Functions\MWSE\mods\OAAB\Mannequins\pose_props.lua')
    & $Lua 'tests/syntax.lua' @sourcePaths
    if ($LASTEXITCODE -ne 0) { throw 'Lua syntax check failed' }
    $tests = Get-ChildItem -LiteralPath 'tests' -Filter '*.lua' |
        Where-Object { $_.Name -ne 'syntax.lua' -and $_.BaseName -notlike '*_fixture' } | Sort-Object Name
    foreach ($test in $tests) {
        & $Lua $test.FullName $poseApi $JsonLibrary
        if ($LASTEXITCODE -ne 0) { throw "Failed: $($test.Name)" }
    }
    & $Python 'tests/verify_template.py'
    if ($LASTEXITCODE -ne 0) { throw 'Template verification failed' }
    & $Python 'tests/verify_gizmos.py'
    if ($LASTEXITCODE -ne 0) { throw 'Gizmo NIF validation failed' }
    & $Python 'tests/verify_preview_host.py'
    if ($LASTEXITCODE -ne 0) { throw 'Preview canvas NIF validation failed' }
    & $Python 'tests/verify_focus_grid.py'
    if ($LASTEXITCODE -ne 0) { throw 'Focus grid NIF validation failed' }
} finally { Pop-Location }
