param(
    [string]$ArmaDirectory = "${env:ProgramFiles(x86)}/Steam/steamapps/common/Arma 3",
    [int]$TimeoutSeconds = 240,
    [string[]]$Mods = @()
)
$ErrorActionPreference = 'Stop'
& node (Join-Path $PSScriptRoot 'prepare-multiplayer.mjs')
if ($LASTEXITCODE -ne 0) { throw 'Could not prepare multiplayer mission' }
$repository = Split-Path -Parent $PSScriptRoot
$runtime = Join-Path $repository 'build/multiplayer'
$run = Join-Path $runtime ('run-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
$serverProfiles = Join-Path $run 'server'
New-Item -ItemType Directory -Path $serverProfiles -Force | Out-Null
$executable = Join-Path $ArmaDirectory 'arma3server_x64.exe'
if (-not (Test-Path -LiteralPath $executable)) { throw 'Arma server executable not found' }
foreach ($mod in $Mods) { if (-not (Test-Path -LiteralPath $mod)) { throw "Mod not found: $mod" } }
$missionName = 'VCM_Codex_MP_' + $PID + '.VR'
$missionRoot = [System.IO.Path]::GetFullPath((Join-Path $ArmaDirectory 'MPMissions'))
$missionFolder = [System.IO.Path]::GetFullPath((Join-Path $missionRoot $missionName))
if (Test-Path -LiteralPath $missionFolder) { throw 'Refusing to overwrite an existing mission' }
Copy-Item -LiteralPath (Join-Path $runtime 'VCM_Multiplayer.VR') -Destination $missionFolder -Recurse
$configuration = Join-Path $run 'server.cfg'
$serverConfig = (Get-Content -LiteralPath (Join-Path $runtime 'server.cfg') -Raw) -replace 'template="[^"]+"', ('template="' + $missionName + '"')
Set-Content -LiteralPath $configuration -Value $serverConfig -Encoding ASCII
$modArgument = @()
if ($Mods.Count -gt 0) { $modArgument = @('-mod="' + ($Mods -join ';') + '"') }
$processes = @()
$first = $null
$second = $null
$disconnected = $false
try {
    $serverArguments = @('-ip=127.0.0.1', '-port=2392', '-autoInit', '-noSound', '-noPause', '-world=VR',
        ('-config="' + $configuration + '"'), ('-profiles="' + $serverProfiles + '"')) + $modArgument
    $server = Start-Process -FilePath $executable -ArgumentList $serverArguments -WorkingDirectory $ArmaDirectory -WindowStyle Hidden -PassThru
    $processes += $server
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $text = ''
    while ((Get-Date) -lt $deadline -and -not $server.HasExited) {
        $rpt = Get-ChildItem -LiteralPath $serverProfiles -Filter '*.rpt' | Select-Object -First 1
        if ($rpt) {
            $text = Get-Content -LiteralPath $rpt.FullName -Raw
            if (-not $first -and $text -match 'VCM_MP_SERVER_READY') {
                $clientProfiles = Join-Path $run 'hc1'
                New-Item -ItemType Directory -Path $clientProfiles -Force | Out-Null
                $arguments = @('-client', '-ip=127.0.0.2', '-connect=127.0.0.1', '-port=2392', '-password=vcom-local-tests', '-noSound', '-noPause', '-world=empty', '-name=VCM_HC1', ('-profiles="' + $clientProfiles + '"')) + $modArgument
                $first = Start-Process -FilePath $executable -ArgumentList $arguments -WorkingDirectory $ArmaDirectory -WindowStyle Hidden -PassThru
                $processes += $first
                Write-Output 'Started late-joining HC1.'
            }
            if (-not $second -and $text -match 'VCM_MP_SECOND_READY') {
                $clientProfiles = Join-Path $run 'hc2'
                New-Item -ItemType Directory -Path $clientProfiles -Force | Out-Null
                $arguments = @('-client', '-ip=127.0.0.3', '-connect=127.0.0.1', '-port=2392', '-password=vcom-local-tests', '-noSound', '-noPause', '-world=empty', '-name=VCM_HC2', ('-profiles="' + $clientProfiles + '"')) + $modArgument
                $second = Start-Process -FilePath $executable -ArgumentList $arguments -WorkingDirectory $ArmaDirectory -WindowStyle Hidden -PassThru
                $processes += $second
                Write-Output 'Started later-joining HC2.'
            }
            if (-not $disconnected -and $first -and $text -match 'VCM_MP_DISCONNECT_READY') {
                Stop-Process -Id $first.Id -Force
                $null = $first.WaitForExit(5000)
                $disconnected = $true
                Write-Output 'Disconnected HC1 to test server recovery.'
            }
            if ($text -match 'VCM_MP_DONE:') { break }
            if ($text -match "Can't find mission template:") { break }
        }
        Start-Sleep -Milliseconds 500
    }
    $scriptErrors = $false
    foreach ($log in Get-ChildItem -LiteralPath $run -Filter '*.rpt' -Recurse) {
        Write-Output "RPT: $($log.FullName)"
        $content = Get-Content -LiteralPath $log.FullName -Raw
        Get-Content -LiteralPath $log.FullName | Select-String 'VCM_MP_|Error in expression|Error position|Undefined variable|Error Missing' | ForEach-Object { $_.Line }
        if ($content -match 'Error in expression|Undefined variable|Error Missing') { $scriptErrors = $true }
    }
    if ($text -notmatch 'VCM_MP_DONE:') { throw 'Multiplayer suite did not finish; inspect server and HC logs.' }
    if ($text -match 'VCM_MP_FAIL:' -or $scriptErrors) { throw 'Multiplayer regression failed.' }
    Write-Output 'Multiplayer regression passed.'
} finally {
    foreach ($process in $processes) {
        if (-not $process.HasExited) { Stop-Process -Id $process.Id -Force; $null = $process.WaitForExit(5000) }
        $process.Dispose()
    }
    $resolvedMission = [System.IO.Path]::GetFullPath($missionFolder)
    if ((Split-Path -Parent $resolvedMission) -ne $missionRoot -or
        (Split-Path -Leaf $resolvedMission) -ne $missionName -or
        $missionName -notlike 'VCM_Codex_MP_*.VR') { throw 'Unsafe multiplayer test cleanup path' }
    for ($attempt = 0; $attempt -lt 5; $attempt++) {
        try { Remove-Item -LiteralPath $resolvedMission -Recurse -Force; break }
        catch { if ($attempt -eq 4) { throw }; Start-Sleep -Milliseconds 500 }
    }
}
