param(
    [Parameter(Mandatory = $true)][string]$OpenMWDirectory,
    [Parameter(Mandatory = $true)][string]$MorrowindData,
    [Parameter(Mandatory = $true)][string]$SssData,
    [Parameter(Mandatory = $true)][string]$H3Data,
    [string]$OutputDirectory = (Join-Path $PSScriptRoot '..\.validation-cache\smoke')
)

$ErrorActionPreference = 'Stop'
$taskRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$taskPackageRoot = Join-Path $taskRoot 'OpenMW'
$taskOpenMW = (Resolve-Path -LiteralPath $OpenMWDirectory).Path
$taskGameData = (Resolve-Path -LiteralPath $MorrowindData).Path
$taskSss = (Resolve-Path -LiteralPath $SssData).Path
$taskH3 = (Resolve-Path -LiteralPath $H3Data).Path
$taskOutput = [IO.Path]::GetFullPath($OutputDirectory)
$taskConfig = Join-Path $taskOutput 'config'
$taskUserData = Join-Path $taskOutput 'user-data'
$taskHarness = Join-Path $PSScriptRoot 'openmw_smoke_test'
$taskEngine = Join-Path $taskOpenMW 'openmw.exe'

foreach ($taskFile in @($taskEngine, (Join-Path $taskSss 'Static Switching System.esp'), (Join-Path $taskH3 'H3lp Yours3lf.esp'))) {
    if (-not (Test-Path -LiteralPath $taskFile -PathType Leaf)) { throw "Missing test dependency: $taskFile" }
}
foreach ($taskMaster in @('Morrowind.esm', 'Tribunal.esm', 'Bloodmoon.esm', 'OAAB_Data.esm', 'Tamriel_Data.esm')) {
    if (-not (Test-Path -LiteralPath (Join-Path $taskGameData $taskMaster) -PathType Leaf)) { throw "Missing master: $taskMaster" }
}

New-Item -ItemType Directory -Path $taskConfig, (Join-Path $taskUserData 'data') -Force | Out-Null
$taskCfgLines = @(
    ('user-data="{0}"' -f $taskUserData.Replace('\', '/')),
    ('data-local="{0}"' -f (Join-Path $taskUserData 'data').Replace('\', '/')),
    ('resources="{0}"' -f (Join-Path $taskOpenMW 'resources').Replace('\', '/'))
)
$taskDataDirectories = @((Join-Path $taskOpenMW 'resources\vfs-mw'), $taskGameData, $taskH3, $taskSss, (Join-Path $taskPackageRoot '00 Visual Replacements'))
foreach ($taskPackage in @('01 OAAB_Data Creature Replacements', '02 Tamriel_Data Creature Replacements', '03 Vanilla Spider Centurions Replacements')) {
    $taskDataDirectories += Join-Path $taskPackageRoot $taskPackage
}
$taskDataDirectories += $taskHarness
foreach ($taskDirectory in $taskDataDirectories) {
    $taskCfgLines += 'data="{0}"' -f $taskDirectory.Replace('\', '/')
}
foreach ($taskArchive in @('Morrowind.bsa', 'Tribunal.bsa', 'Bloodmoon.bsa')) { $taskCfgLines += "fallback-archive=$taskArchive" }
foreach ($taskContent in @('Morrowind.esm', 'Tribunal.esm', 'Bloodmoon.esm', 'OAAB_Data.esm', 'Tamriel_Data.esm', 'H3lp Yours3lf.esp', 'Static Switching System.esp', 'ArachnophobiaPatch_OAAB.ESP', 'arachnophobia-test.omwscripts')) {
    $taskCfgLines += "content=$taskContent"
}
$taskCfgLines += @('no-sound=1', 'no-grab=1', 'skip-menu=1', "start=Balmora, Caius Cosades' House")
Set-Content -LiteralPath (Join-Path $taskConfig 'openmw.cfg') -Value $taskCfgLines -Encoding utf8
Set-Content -LiteralPath (Join-Path $taskConfig 'settings.cfg') -Encoding utf8 -Value @(
    '[Video]', 'fullscreen = false', 'resolution x = 320', 'resolution y = 240',
    'vsync = false', 'window border = false', '[GUI]', 'scaling factor = 1'
)

# Replacing config inheritance keeps the user's normal settings and saves isolated.
$taskStdout = Join-Path $taskOutput 'engine.stdout.log'
$taskStderr = Join-Path $taskOutput 'engine.stderr.log'
$taskProcess = Start-Process -FilePath $taskEngine -ArgumentList @('--replace', 'config', '--config', ('"' + $taskConfig + '"')) -WorkingDirectory $taskOpenMW -WindowStyle Hidden -RedirectStandardOutput $taskStdout -RedirectStandardError $taskStderr -PassThru
if (-not $taskProcess.WaitForExit(45000)) {
    Stop-Process -Id $taskProcess.Id
    throw "OpenMW test timed out. See $taskOutput"
}
$taskLog = (Get-Content -LiteralPath $taskStdout -Raw) + (Get-Content -LiteralPath $taskStderr -Raw)
if ($taskLog -notmatch 'ARACHNOPHOBIA TEST PASSED: 15 replacements' -or $taskLog -match 'ARACHNOPHOBIA TEST FAILED|\[.* E\]') {
    throw "OpenMW validation failed. See $taskOutput"
}
Write-Output "PASS OpenMW: replacements, exclusions, scale, save/load, cell re-entry, saved once-cache. Logs: $taskOutput"
