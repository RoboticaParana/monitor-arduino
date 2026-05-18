$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$versionPath = Join-Path $root "version.json"
$monitorPath = Join-Path $root "monitor.py"
$managerPath = Join-Path $root "manager.py"
$setupPath = Join-Path $root "setup.iss"

$versionData = Get-Content -Raw -LiteralPath $versionPath | ConvertFrom-Json
$parts = ([string]$versionData.version).Split(".")

if ($parts.Count -lt 3) {
    throw "Versao invalida em version.json: $($versionData.version)"
}

$major = [int]$parts[0]
$minor = [int]$parts[1]
$patch = [int]$parts[2] + 1
$newVersion = "$major.$minor.$patch"
$newUrl = "https://github.com/RoboticaParana/monitor-arduino/releases/download/v$newVersion/monitor.exe"

function Set-TextFile {
    param(
        [string]$Path,
        [string]$Text
    )
    $normalized = $Text -replace "`r?`n", "`r`n"
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $normalized, $utf8NoBom)
}

$versionJson = @{ version = $newVersion; url = $newUrl } | ConvertTo-Json -Compress
Set-TextFile -Path $versionPath -Text ($versionJson + "`r`n")

$monitorText = Get-Content -Raw -LiteralPath $monitorPath
$monitorText = $monitorText -replace 'VERSION = "[0-9]+\.[0-9]+\.[0-9]+"', "VERSION = `"$newVersion`""
Set-TextFile -Path $monitorPath -Text $monitorText

$managerText = Get-Content -Raw -LiteralPath $managerPath
$managerText = $managerText -replace 'MONITOR_VERSION_EMBUTIDA = "[0-9]+\.[0-9]+\.[0-9]+"', "MONITOR_VERSION_EMBUTIDA = `"$newVersion`""
Set-TextFile -Path $managerPath -Text $managerText

$setupText = Get-Content -Raw -LiteralPath $setupPath
$setupText = $setupText -replace 'AppVersion=[0-9]+\.[0-9]+\.[0-9]+', "AppVersion=$newVersion"
$setupText = $setupText -replace 'OutputBaseFilename=Instalador_AgenteB1n0_v[0-9]+\.[0-9]+\.[0-9]+', "OutputBaseFilename=Instalador_AgenteB1n0_v$newVersion"
Set-TextFile -Path $setupPath -Text $setupText

Write-Output $newVersion
