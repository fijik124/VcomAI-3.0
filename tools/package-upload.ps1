param()
$ErrorActionPreference = 'Stop'
$repository = Split-Path -Parent $PSScriptRoot
$project = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'addon-project.json') -Raw | ConvertFrom-Json
$Version = $project.version
$upload = Join-Path $repository 'build/upload'
$mod = Join-Path $upload $project.modFolder
$builtProjectPath = Join-Path $mod 'ADDON-MODULES.json'
if (-not (Test-Path -LiteralPath $builtProjectPath)) { throw 'Build the modular addon before packaging.' }
$builtProject = Get-Content -LiteralPath $builtProjectPath -Raw | ConvertFrom-Json
if (($builtProject | ConvertTo-Json -Depth 8) -ne ($project | ConvertTo-Json -Depth 8)) { throw 'Module definitions changed since the build; rebuild and validate first.' }
foreach ($module in $project.modules) {
    $pboName = $project.prefix + '_' + $module.id + '.pbo'
    if (-not (Test-Path -LiteralPath (Join-Path $mod ('addons/' + $pboName)))) { throw ('Build and validate missing PBO: ' + $pboName) }
    if (-not (Get-ChildItem -LiteralPath (Join-Path $mod 'addons') -Filter ($pboName + '.*.bisign'))) { throw ('Missing signature: ' + $pboName) }
}
# Refresh documentation without rebuilding or changing the validated PBO and its signature.
foreach ($name in @('MIGRATION.md','ROADMAP.md','FEATURES.md')) {
    Copy-Item -LiteralPath (Join-Path $repository $name) -Destination (Join-Path $mod $name) -Force
}
$files = @(Get-ChildItem -LiteralPath $mod -Recurse -File -Force | Where-Object { $_.Name -ne 'BUILD-MANIFEST.json' })
if ($files | Where-Object Extension -EQ '.biprivatekey') { throw 'Private signing key must never be uploaded.' }
if (-not ($files | Where-Object Extension -EQ '.bikey') -or -not ($files | Where-Object Extension -EQ '.bisign')) { throw 'Missing signature or public key.' }
$manifest = [ordered]@{name=$project.name; version=$Version; files=@($files | ForEach-Object {
    [ordered]@{path=$_.FullName.Substring($mod.Length + 1).Replace('\','/'); bytes=$_.Length; sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()}
})}
$manifestText = ($manifest | ConvertTo-Json -Depth 5) + [Environment]::NewLine
[System.IO.File]::WriteAllText((Join-Path $mod 'BUILD-MANIFEST.json'),$manifestText,(New-Object System.Text.UTF8Encoding($false)))
$archive = Join-Path $upload ($project.archiveName + '-' + $Version + '.zip')
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
# Windows PowerShell Compress-Archive writes backslashes into ZIP entry names.
# Use explicit portable paths so Linux server extraction creates real directories.
$archiveStream = [System.IO.File]::Open($archive,[System.IO.FileMode]::Create)
$zipWriter = $null
try {
    $zipWriter = [System.IO.Compression.ZipArchive]::new($archiveStream,[System.IO.Compression.ZipArchiveMode]::Create,$false)
    foreach ($file in Get-ChildItem -LiteralPath $mod -Recurse -File -Force) {
        $entryName = $project.modFolder + '/' + $file.FullName.Substring($mod.Length + 1).Replace('\','/')
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zipWriter,$file.FullName,$entryName,[System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
    }
} finally {
    if ($zipWriter) { $zipWriter.Dispose() }
    $archiveStream.Dispose()
}
$hash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
($hash + '  ' + (Split-Path -Leaf $archive)) | Set-Content -LiteralPath (Join-Path $upload 'SHA256SUMS.txt') -Encoding ASCII
Write-Output ('Upload archive: ' + $archive)
Write-Output ('SHA256: ' + $hash)
