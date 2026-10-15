param(
    [Parameter(Mandatory=$true)][string]$OpenMWDirectory,
    [Parameter(Mandatory=$true)][string]$MorrowindData
)
$ErrorActionPreference = 'Stop'
$taskRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$taskOutput = Join-Path $taskRoot '.validation-cache\openmw'
$taskConfig = Join-Path $taskOutput 'config'
$taskUserData = Join-Path $taskOutput 'user-data'
$taskEngineRoot = (Resolve-Path -LiteralPath $OpenMWDirectory).Path
$taskData = (Resolve-Path -LiteralPath $MorrowindData).Path
New-Item -ItemType Directory -Path $taskConfig, (Join-Path $taskUserData 'data') -Force | Out-Null
$taskLines = @(
    ('user-data="{0}"' -f $taskUserData.Replace('\','/')),
    ('data-local="{0}"' -f (Join-Path $taskUserData 'data').Replace('\','/')),
    ('resources="{0}"' -f (Join-Path $taskEngineRoot 'resources').Replace('\','/'))
)
foreach ($taskDirectory in @((Join-Path $taskEngineRoot 'resources\vfs-mw'), $taskData, (Join-Path $taskRoot '00 Core'), (Join-Path $taskRoot '01 OpenMW'), (Join-Path $PSScriptRoot 'openmw_smoke'))) {
    $taskLines += 'data="{0}"' -f $taskDirectory.Replace('\','/')
}
$taskLines += @('fallback-archive=Morrowind.bsa', 'content=Morrowind.esm', 'content=Keg Drip.ESP', 'content=KegDripSmoke.esp', 'content=Keg Drip.omwscripts', 'content=KegDripSmoke.omwscripts', 'no-sound=1', 'no-grab=1', 'skip-menu=1', "start=Balmora, Caius Cosades' House")
Set-Content -LiteralPath (Join-Path $taskConfig 'openmw.cfg') -Value $taskLines -Encoding utf8
Set-Content -LiteralPath (Join-Path $taskConfig 'settings.cfg') -Encoding utf8 -Value @('[Video]', 'fullscreen = false', 'resolution x = 320', 'resolution y = 240', 'vsync = false', 'window border = false', '[GUI]', 'scaling factor = 1')
$taskStdout = Join-Path $taskOutput 'stdout.log'
$taskStderr = Join-Path $taskOutput 'stderr.log'
$taskProcess = Start-Process -FilePath (Join-Path $taskEngineRoot 'openmw.exe') -ArgumentList @('--replace', 'config', '--config', ('"'+$taskConfig+'"')) -WorkingDirectory $taskEngineRoot -WindowStyle Hidden -RedirectStandardOutput $taskStdout -RedirectStandardError $taskStderr -PassThru
if (-not $taskProcess.WaitForExit(45000)) {
    Stop-Process -Id $taskProcess.Id
    throw "OpenMW test timed out. See $taskOutput"
}
$taskLog = (Get-Content -LiteralPath $taskStdout -Raw) + (Get-Content -LiteralPath $taskStderr -Raw)
if ($taskLog -notmatch 'KEG DRIP TEST PASSED' -or $taskLog -match 'KEG DRIP TEST FAILED|\[.* E\]') {
    throw "OpenMW validation failed. See $taskOutput"
}
$taskSave = Get-ChildItem -LiteralPath (Join-Path $taskUserData 'saves') -File -Recurse -Filter '*.omwsave' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $taskSave) { throw 'OpenMW test did not produce a save.' }
$taskSaveText = [System.Text.Encoding]::ASCII.GetString([System.IO.File]::ReadAllBytes($taskSave.FullName))
if ($taskSaveText -match 'kegpuddle') { throw 'A puddle reference or script was included in the save.' }
Write-Output "PASS OpenMW engine: continuous drips, raycast puddles, growth/cap, cell cleanup, no puddles in save, animation and source preservation. Logs: $taskOutput"
