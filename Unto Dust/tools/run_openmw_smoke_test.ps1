param(
    [Parameter(Mandatory = $true)][string]$OpenMWDirectory,
    [Parameter(Mandatory = $true)][string]$MorrowindData
)

$ErrorActionPreference = 'Stop'
$taskRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$taskOpenMW = (Resolve-Path -LiteralPath $OpenMWDirectory).Path
$taskGameData = (Resolve-Path -LiteralPath $MorrowindData).Path
$taskOutput = Join-Path $taskRoot '.validation-cache\MCM'
$taskConfig = Join-Path $taskOutput 'config'
$taskUserData = Join-Path $taskOutput 'user-data'
$taskEngine = Join-Path $taskOpenMW 'openmw.exe'
foreach ($taskFile in @($taskEngine, (Join-Path $taskGameData 'Morrowind.esm'), (Join-Path $taskGameData 'Morrowind.bsa'))) {
    if (-not (Test-Path -LiteralPath $taskFile -PathType Leaf)) { throw "Missing dependency: $taskFile" }
}

New-Item -ItemType Directory -Path $taskConfig, (Join-Path $taskUserData 'data') -Force | Out-Null
$taskCfgLines = @(
    ('user-data="{0}"' -f $taskUserData.Replace('\', '/')),
    ('data-local="{0}"' -f (Join-Path $taskUserData 'data').Replace('\', '/')),
    ('resources="{0}"' -f (Join-Path $taskOpenMW 'resources').Replace('\', '/'))
)
foreach ($taskDirectory in @((Join-Path $taskOpenMW 'resources\vfs-mw'), $taskGameData, (Join-Path $taskRoot '00 OpenMW'), (Join-Path $taskRoot 'tests\openmw_smoke'))) {
    $taskCfgLines += 'data="{0}"' -f $taskDirectory.Replace('\', '/')
}
$taskCfgLines += @(
    'fallback-archive=Morrowind.bsa', 'content=Morrowind.esm',
    'content=UntoDust.omwscripts', 'content=UntoDustSmoke.omwscripts',
    'no-sound=1', 'no-grab=1', 'skip-menu=1', 'start=Andrano Ancestral Tomb'
)
Set-Content -LiteralPath (Join-Path $taskConfig 'openmw.cfg') -Value $taskCfgLines -Encoding utf8
Set-Content -LiteralPath (Join-Path $taskConfig 'settings.cfg') -Encoding utf8 -Value @(
    '[Video]', 'fullscreen = false', 'resolution x = 640', 'resolution y = 480',
    'vsync = false', 'window border = false', '[GUI]', 'scaling factor = 1',
    '[Post Processing]', 'enabled = true', 'transparent postpass = true'
)

# Replace config inheritance so the test never uses normal settings or saves.
$taskStdout = Join-Path $taskOutput 'engine.stdout.log'
$taskStderr = Join-Path $taskOutput 'engine.stderr.log'
$taskProcess = Start-Process -FilePath $taskEngine -ArgumentList @('--replace', 'config', '--config', ('"' + $taskConfig + '"')) -WorkingDirectory $taskOpenMW -WindowStyle Hidden -RedirectStandardOutput $taskStdout -RedirectStandardError $taskStderr -PassThru
if (-not $taskProcess.WaitForExit(60000)) {
    Stop-Process -Id $taskProcess.Id
    throw "OpenMW test timed out. See $taskOutput"
}
$taskLog = (Get-Content -LiteralPath $taskStdout -Raw) + (Get-Content -LiteralPath $taskStderr -Raw)
if ($taskLog -match 'renderer.*error:|unknown renderer') {
    throw "OpenMW cell picker rendering failed. See $taskOutput"
}
if ($taskProcess.ExitCode -ne 0 -or $taskLog -notmatch 'UNTO DUST SMOKE PASSED' -or $taskLog -notmatch 'UNTO DUST MCM REGISTERED' -or $taskLog -notmatch 'UNTO DUST DENSITY: 0\s' -or $taskLog -notmatch 'UNTO DUST DENSITY: 32\s' -or $taskLog -notmatch 'UNTO DUST DENSITY: 85\s' -or $taskLog -notmatch 'UNTO DUST MCM PERSISTED' -or $taskLog -notmatch 'UNTO DUST FILTERS PERSISTED' -or $taskLog -notmatch 'UNTO DUST LISTS: enabled in balmora' -or $taskLog -notmatch 'UNTO DUST LISTS: disabled in balmora' -or $taskLog -notmatch 'UNTO DUST SHADER: enabled in' -or $taskLog -match 'UNTO DUST SMOKE FAILED|\[.* E\]|glCompileShader.*FAILED|glLinkProgram.*FAILED|failed to load.*(?:dust|texture)|(?:dust|texture).*failed to load') {
    throw "OpenMW test failed. See $taskOutput"
}
Write-Output "PASS OpenMW: MCM registration, live density 0/32/85, whitelist/blacklist edits and priority, both views, cell transitions, save/load persistence. Logs: $taskOutput"
