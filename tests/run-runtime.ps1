param(
    [string]$ArmaDirectory = "${env:ProgramFiles(x86)}/Steam/steamapps/common/Arma 3",
    [int]$TimeoutSeconds = 300,
    [string[]]$Mods = @(),
    [ValidateSet('all','safety','tactics','vehicle','performance','advanced')][string]$Suite = 'all',
    [switch]$Addon,
    [ValidateRange(30,1800)][int]$PerformanceSeconds = 60,
    [switch]$Vanilla
)
$ErrorActionPreference = 'Stop'
$repository = Split-Path -Parent $PSScriptRoot
$prepareArguments = @((Join-Path $PSScriptRoot 'prepare-runtime.mjs'),$Suite)
if ($Suite -eq 'performance') { $prepareArguments += ('--duration=' + $PerformanceSeconds); $TimeoutSeconds = [Math]::Max($TimeoutSeconds,$PerformanceSeconds + 60) }
if ($Vanilla) { $prepareArguments += '--vanilla' }
if ($Addon) {
    $project = Get-Content -LiteralPath (Join-Path $repository 'tools/addon-project.json') -Raw | ConvertFrom-Json
    $addonMod = Join-Path (Join-Path $repository 'build/upload') $project.modFolder
    foreach ($module in $project.modules) {
        if (-not (Test-Path -LiteralPath (Join-Path $addonMod ('addons/' + $project.prefix + '_' + $module.id + '.pbo')))) { throw ('Build missing PBO: ' + $module.id) }
    }
    $Mods = @($addonMod) + $Mods
    $prepareArguments += '--addon'
}
& node @prepareArguments
if ($LASTEXITCODE -ne 0) { throw 'Could not prepare regression mission' }
$runtime = Join-Path $repository 'build/runtime'
$profiles = Join-Path $runtime ('profiles-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Path $profiles -Force | Out-Null
$executable = Join-Path $ArmaDirectory 'arma3server_x64.exe'
if (-not (Test-Path -LiteralPath $executable)) { throw "Server executable not found: $executable" }
$missionName = 'VCM_Codex_Regression_' + $PID + '.VR'
$missionRoot = [System.IO.Path]::GetFullPath((Join-Path $ArmaDirectory 'MPMissions'))
$missionFolder = [System.IO.Path]::GetFullPath((Join-Path $missionRoot $missionName))
if (Test-Path -LiteralPath $missionFolder) { throw 'Refusing to overwrite an existing test mission' }
Copy-Item -LiteralPath (Join-Path $runtime 'VCM_Regression.VR') -Destination $missionFolder -Recurse
$configuration = Join-Path $runtime 'server.cfg'
$serverConfig = Get-Content -LiteralPath $configuration -Raw
$serverConfig = $serverConfig -replace 'template="[^"]+"', ('template="' + $missionName + '"')
Set-Content -LiteralPath $configuration -Value $serverConfig -Encoding ASCII
$arguments = @(
    '-ip=127.0.0.1', '-port=2392', '-autoInit', '-noSound', '-noPause', '-world=VR',
    ('-config="' + (Join-Path $runtime 'server.cfg') + '"'),
    ('-profiles="' + $profiles + '"')
)
if ($Mods.Count -gt 0) {
    foreach ($mod in $Mods) { if (-not (Test-Path -LiteralPath $mod)) { throw "Mod not found: $mod" } }
    $arguments += '-mod="' + ($Mods -join ';') + '"'
}
$serverProcess = $null
try {
    $serverProcess = Start-Process -FilePath $executable -ArgumentList $arguments -WorkingDirectory $ArmaDirectory -WindowStyle Hidden -PassThru
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $rpt = $null
    $text = ''
    while ((Get-Date) -lt $deadline -and -not $serverProcess.HasExited) {
        $rpt = Get-ChildItem -LiteralPath $profiles -Filter '*.rpt' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($rpt) {
            $text = Get-Content -LiteralPath $rpt.FullName -Raw
            if ($text -match 'VCM_TEST_DONE:') { break }
            if ($text -match "Can't find mission template:") { break }
            if ($text -match 'Warning Message: Script .* not found|Error in expression|Undefined variable') { break }
        }
        Start-Sleep -Milliseconds 500
    }
    if ($rpt) {
        $text = Get-Content -LiteralPath $rpt.FullName -Raw
        Write-Output "RPT: $($rpt.FullName)"
        Get-Content -LiteralPath $rpt.FullName | Select-String 'VCM_TEST_ENV:|VCM_TEST_FAIL:|VCM_TEST_DONE:|VCM_BOUND_RESULT:|VCM_COVER_RESULT:|VCM_TACTICAL_RESULT:|VCM_PERF_RESULT:|Error in expression|Error position|Undefined variable|Error Missing|Warning Message:' | ForEach-Object { $_.Line }
    }
    if ($text -notmatch 'VCM_TEST_DONE:') { throw 'Regression mission did not finish before the deadline; inspect the RPT.' }
    if ($serverProcess.HasExited -and $serverProcess.ExitCode -ne 0) { throw "Arma server exited unexpectedly with code $($serverProcess.ExitCode)." }
    if ($text -match 'VCM_TEST_FAIL:|Error in expression|Undefined variable|Error Missing') { throw 'Runtime regression failed; inspect the RPT.' }
    Write-Output 'Runtime regression passed.'
} finally {
    if ($serverProcess) {
        if (-not $serverProcess.HasExited) {
            Stop-Process -Id $serverProcess.Id -Force
            $null = $serverProcess.WaitForExit(5000)
        }
        $serverProcess.Dispose()
    }
    # Validate the absolute deletion target, then remove only this run's generated mission.
    $resolvedMission = [System.IO.Path]::GetFullPath($missionFolder)
    if ((Split-Path -Parent $resolvedMission) -ne $missionRoot -or
        (Split-Path -Leaf $resolvedMission) -ne $missionName -or
        $missionName -notlike 'VCM_Codex_Regression_*.VR') { throw 'Unsafe test cleanup path' }
    for ($attempt = 0; $attempt -lt 5; $attempt++) {
        try { Remove-Item -LiteralPath $resolvedMission -Recurse -Force; break }
        catch { if ($attempt -eq 4) { throw }; Start-Sleep -Milliseconds 500 }
    }
}
