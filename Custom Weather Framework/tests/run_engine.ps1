param(
    [Parameter(Mandatory = $true)][string]$OpenMWDirectory,
    [Parameter(Mandatory = $true)][string]$MorrowindData
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$runtime = Join-Path $PSScriptRoot ('.runtime/' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
$null = New-Item -ItemType Directory -Path $runtime
$userData = Join-Path $runtime 'userdata'
$null = New-Item -ItemType Directory -Path $userData
$null = New-Item -ItemType Directory -Path (Join-Path $userData 'data')
$cfg = @"
replace=data
replace=content
replace=groundcover
replace=fallback-archive
data="$OpenMWDirectory/resources/vfs-mw"
data="$MorrowindData"
data="$repo/00 OpenMW"
data="$PSScriptRoot/engine"
data-local="$userData/data"
user-data="$userData"
resources="$OpenMWDirectory/resources"
content=Morrowind.esm
content=Tribunal.esm
content=Bloodmoon.esm
content=Weather Adjuster.omwscripts
content=Weather Adjuster Tests.omwscripts
fallback-archive=Morrowind.bsa
fallback-archive=Tribunal.bsa
fallback-archive=Bloodmoon.bsa
"@
Set-Content -LiteralPath (Join-Path $runtime 'openmw.cfg') -Value $cfg -Encoding utf8
Set-Content -LiteralPath (Join-Path $runtime 'settings.cfg') -Encoding utf8 -Value @'
[Video]
fullscreen = false
resolution x = 1024
resolution y = 768
vsync = true
[GUI]
scaling factor = 1.0
[Navigator]
enable = false
[Post Processing]
enabled = false
'@
$exe = Join-Path $OpenMWDirectory 'openmw.exe'
$arguments = '--replace config --config "{0}" --skip-menu --start "Seyda Neen" --no-sound --no-grab' -f $runtime
$process = Start-Process -FilePath $exe -ArgumentList $arguments -PassThru -WindowStyle Hidden `
    -WorkingDirectory $runtime -RedirectStandardOutput (Join-Path $runtime 'stdout.txt') `
    -RedirectStandardError (Join-Path $runtime 'stderr.txt')
Write-Output "Engine smoke test PID $($process.Id); logs: $runtime"
try {
    $deadline = (Get-Date).AddSeconds(90)
    while (-not $process.HasExited -and (Get-Date) -lt $deadline) { Start-Sleep -Seconds 1 }
    if (-not $process.HasExited) { throw 'Engine smoke test timed out after 90 seconds' }
    $logPath = Join-Path $runtime 'openmw.log'
    if (-not (Test-Path -LiteralPath $logPath)) { $logPath = Join-Path $runtime 'stdout.txt' }
    $log = Get-Content -LiteralPath $logPath -Raw
    $log -split "`n" | Select-String 'WEATHER TEST|Lua\[|Error|Exception|Unused|unused'
    if ($log -notmatch '\[WEATHER TEST PASSED\]' -or $log -match '\[WEATHER TEST FAILED\]') {
        throw "Engine smoke test failed. Inspect $runtime"
    }
} finally {
    if (-not $process.HasExited) { Stop-Process -Id $process.Id }
}
