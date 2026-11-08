param([ValidateRange(30,1800)][int]$Seconds = 60, [switch]$Addon)
$ErrorActionPreference = 'Stop'
$rows = @()
foreach ($baseline in @($true,$false)) {
    $arguments = @{Suite='performance'; PerformanceSeconds=$Seconds; Vanilla=$baseline; Addon=$Addon}
    & (Join-Path $PSScriptRoot 'run-runtime.ps1') @arguments
    $runtimeRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'build/runtime'
    $profile = Get-ChildItem -LiteralPath $runtimeRoot -Directory -Filter 'profiles-*' | Sort-Object Name -Descending | Select-Object -First 1
    $log = Get-ChildItem -LiteralPath $profile.FullName -Filter '*.rpt' | Select-Object -First 1
    $line = (Select-String -LiteralPath $log.FullName -Pattern 'VCM_PERF_RESULT:').Line
    if ($line -notmatch 'enabled=(true|false); units=(\d+); meanFPS=([\d.]+); p10FPS=([\d.]+); maxScripts=(\d+); activeGroups=(\d+); elapsed=([\d.]+)') { throw 'Performance result not found' }
    $rows += [pscustomobject]@{VcomEnabled=$Matches[1]; Units=$Matches[2]; MeanFPS=$Matches[3]; P10FPS=$Matches[4]; MaxScripts=$Matches[5]; ActiveGroups=$Matches[6]; Elapsed=$Matches[7]; RPT=$log.FullName}
}
$destination = Join-Path (Split-Path -Parent $PSScriptRoot) 'build/performance.csv'
$rows | Export-Csv -LiteralPath $destination -NoTypeInformation
$rows | Format-Table VcomEnabled,Units,MeanFPS,P10FPS,MaxScripts,ActiveGroups
Write-Output "Report: $destination"
