param(
    [string]$ArmaDirectory = "${env:ProgramFiles(x86)}/Steam/steamapps/common/Arma 3",
    [int]$TimeoutSeconds = 120,
    [string[]]$Mods = @(),
    [switch]$Visible
)
$ErrorActionPreference = 'Stop'
if (-not $Visible) { throw 'Graphical acceptance needs a visible render window. Run with -Visible after approving a separate test window.' }
$repository = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'required-mods.ps1')
$Mods = @(Resolve-VcomTestMods -ArmaDirectory $ArmaDirectory -Mods $Mods)
$project = Get-Content -LiteralPath (Join-Path $repository 'tools/addon-project.json') -Raw | ConvertFrom-Json
$mod = Join-Path $repository ('build/upload/' + $project.modFolder)
foreach ($module in $project.modules) {
    if (-not (Test-Path -LiteralPath (Join-Path $mod ('addons/' + $project.prefix + '_' + $module.id + '.pbo')))) {
        throw ('Build missing PBO: ' + $module.id)
    }
}
$Mods += $mod
$run = Join-Path $repository ('build/debug/run-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
& node (Join-Path $PSScriptRoot 'prepare-debug.mjs') $run
if ($LASTEXITCODE -ne 0) { throw 'Could not prepare graphical debugger mission' }
$executable = Join-Path $ArmaDirectory 'arma3_x64.exe'
$missionName = 'VCM_Debug_' + $PID + '.VR'
$missionRoot = [IO.Path]::GetFullPath((Join-Path $ArmaDirectory 'Missions'))
$missionFolder = [IO.Path]::GetFullPath((Join-Path $missionRoot $missionName))
if (Test-Path -LiteralPath $missionFolder) { throw 'Refusing to overwrite an existing mission' }
Copy-Item -LiteralPath (Join-Path $run 'VCM_Debug.VR') -Destination $missionFolder -Recurse
$arguments = @('-window','-noSplash','-skipIntro','-noPause','-noSound','-world=empty','-name=VCM_DebugTest',
    ("-init=playMission['','$missionName']"),
    ('-profiles="' + $run + '"'), ('-cfg="' + (Join-Path $run 'Arma3.cfg') + '"'),
    ('-mod="' + ($Mods -join ';') + '"'))
$process = $null
try {
    $windowStyle = if ($Visible) { 'Normal' } else { 'Hidden' }
    $process = Start-Process -FilePath $executable -ArgumentList $arguments -WorkingDirectory $ArmaDirectory -WindowStyle $windowStyle -PassThru
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $text = ''; $log = $null
    while ((Get-Date) -lt $deadline -and -not $process.HasExited) {
        $log = Get-ChildItem -LiteralPath $run -Filter '*.rpt' | Select-Object -First 1
        if ($log) {
            $text = Get-Content -LiteralPath $log.FullName -Raw
            if ($text -match 'VCM_DEBUG_TEST_DONE:|Error in expression|Undefined variable|Error Missing') { break }
        }
        Start-Sleep -Milliseconds 500
    }
    if ($log) {
        $text = Get-Content -LiteralPath $log.FullName -Raw
        Write-Output ('RPT: ' + $log.FullName)
        Get-Content -LiteralPath $log.FullName | Select-String 'VCM_DEBUG_TEST_|Error in expression|Error position|Undefined variable|Error Missing' | ForEach-Object { $_.Line }
    }
    if ($text -notmatch 'VCM_DEBUG_TEST_DONE:') { throw 'Graphical debugger suite did not finish; inspect its isolated profile logs.' }
    if ($text -match 'VCM_DEBUG_TEST_FAIL:|Error in expression|Undefined variable|Error Missing') { throw 'Graphical debugger acceptance failed.' }
    Write-Output 'Graphical debugger acceptance passed.'
} finally {
    if ($process) {
        if (-not $process.HasExited) { Stop-Process -Id $process.Id -Force; $null = $process.WaitForExit(5000) }
        $process.Dispose()
    }
    if ((Split-Path -Parent $missionFolder) -ne $missionRoot -or
        (Split-Path -Leaf $missionFolder) -ne $missionName -or $missionName -notlike 'VCM_Debug_*.VR') {
        throw 'Unsafe graphical test cleanup path'
    }
    Remove-Item -LiteralPath $missionFolder -Recurse -Force
}
