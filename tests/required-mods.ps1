# Shared by native runners: every normal test uses the required CBA/ACE stack.
function Resolve-VcomTestMods {
    param([string]$ArmaDirectory, [string[]]$Mods)
    $selected = @($Mods)
    $steamApps = Split-Path -Parent (Split-Path -Parent $ArmaDirectory)
    $workshop = Join-Path $steamApps 'workshop/content/107410'
    foreach ($dependency in @(
        @{Name='CBA_A3'; Pbo='cba_settings.pbo'; Workshop='450814997'; Folder='@CBA_A3'},
        @{Name='ACE including ACE Medical'; Pbo='ace_medical.pbo'; Workshop='463939057'; Folder='@ace'}
    )) {
        $provided = @($selected | Where-Object { Test-Path -LiteralPath (Join-Path $_ ('addons/' + $dependency.Pbo)) })
        if ($provided.Count -eq 0) {
            $candidate = @(Join-Path $workshop $dependency.Workshop; Join-Path $ArmaDirectory $dependency.Folder) |
                Where-Object { Test-Path -LiteralPath (Join-Path $_ ('addons/' + $dependency.Pbo)) } |
                Select-Object -First 1
            if (-not $candidate) { throw ('Required mod not found: ' + $dependency.Name + '. Supply its directory with -Mods.') }
            $selected += $candidate
        }
    }
    foreach ($mod in $selected) { if (-not (Test-Path -LiteralPath $mod)) { throw "Mod not found: $mod" } }
    # Dependency paths lead the launch list; explicit extra mods retain their order.
    $required = @($selected | Where-Object {
        (Test-Path -LiteralPath (Join-Path $_ 'addons/cba_main.pbo')) -or
        (Test-Path -LiteralPath (Join-Path $_ 'addons/ace_main.pbo'))
    } | Sort-Object { if (Test-Path -LiteralPath (Join-Path $_ 'addons/cba_main.pbo')) { 0 } else { 1 } })
    @($required + $selected | Select-Object -Unique)
}
