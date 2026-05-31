# ACA CLI Installer for Windows
param(
    [string]$InstallDir = "$env:USERPROFILE\.aca\bin",
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"
$Repo = "microsoft/azure-container-apps"
$Branch = "main"
$BinaryName = "aca"

function Uninstall-Aca {
    $AcaHome = Split-Path $InstallDir -Parent  # ~/.aca
    $ExePath = Join-Path $InstallDir "$BinaryName.exe"
    if (-not (Test-Path $ExePath) -and -not (Test-Path $AcaHome)) {
        Write-Host "$BinaryName is not installed."
        return
    }

    # Remove PATH entry
    $UserPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($UserPath -like "*$InstallDir*") {
        $NewPath = ($UserPath -split ';' | Where-Object { $_ -ne $InstallDir }) -join ';'
        [Environment]::SetEnvironmentVariable("PATH", $NewPath, "User")
        Write-Host "Removed $InstallDir from PATH."
    }

    # Remove entire .aca directory (binary + config)
    if (Test-Path $AcaHome) {
        Remove-Item -Recurse -Force $AcaHome
        Write-Host "Removed $AcaHome (binary and configuration)."
    }

    Write-Host "$BinaryName uninstalled successfully."
}

function Get-Sha256ExpectedHash {
    param(
        [Parameter(Mandatory)] [string]$Platform,
        [string]$Repo,
        [string]$Branch
    )

    $url = "https://raw.githubusercontent.com/$Repo/$Branch/aca-cli/preview/latest-version.txt"
    try {
        $content = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content
    } catch {
        throw "Could not download $url. Check your network connection."
    }

    $map = @{}
    foreach ($line in ($content -split "(`r`n|`n|`r)")) {
        $trim = $line.Trim()
        if ($trim -eq '' -or $trim.StartsWith('#')) { continue }
        $idx = $trim.IndexOf('=')
        if ($idx -lt 1) { continue }
        $k = $trim.Substring(0, $idx).Trim()
        $v = $trim.Substring($idx + 1).Trim()
        if ($k) { $map[$k] = $v }
    }

    if (-not $map.ContainsKey('version') -or [string]::IsNullOrWhiteSpace($map['version'])) {
        throw "latest-version.txt is missing a 'version=' entry."
    }
    if (-not $map.ContainsKey($Platform)) {
        throw "latest-version.txt has no SHA-256 entry for platform '$Platform'."
    }
    $expected = $map[$Platform].ToLower()
    if ($expected -notmatch '^[0-9a-f]{64}$') {
        throw "SHA-256 for '$Platform' in latest-version.txt is not 64 lowercase hex characters."
    }
    Write-Host "Pinned version: $($map['version'])"

    return [pscustomobject]@{
        Version      = $map['version']
        ExpectedHash = $expected
    }
}

function Install-Aca {
    $Platform = "win-x64"

    $pin = Get-Sha256ExpectedHash -Platform $Platform -Repo $Repo -Branch $Branch
    $Version = $pin.Version
    $Url = "https://github.com/$Repo/releases/download/$Version/$Version-$Platform.zip"

    Write-Host "Downloading $BinaryName from $Url..."

    # Create install directory
    if (-not (Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    }

    $TmpFile = Join-Path $env:TEMP "$BinaryName-$Platform.zip"
    $TmpDir = Join-Path $env:TEMP "$BinaryName-extract"

    try {
        Invoke-WebRequest -Uri $Url -OutFile $TmpFile -UseBasicParsing

        $actual = (Get-FileHash -Algorithm SHA256 $TmpFile).Hash.ToLower()
        if ($actual -ne $pin.ExpectedHash) {
            Remove-Item -Force $TmpFile -ErrorAction SilentlyContinue
            throw "SHA-256 mismatch for $Version-$Platform.zip.`n  expected: $($pin.ExpectedHash)`n  actual:   $actual`nAborting install. The download was not what this release advertises."
        }
        Write-Host "Verified SHA-256: $actual"

        if (Test-Path $TmpDir) { Remove-Item -Recurse -Force $TmpDir }
        Expand-Archive -Path $TmpFile -DestinationPath $TmpDir -Force

        Copy-Item -Path (Join-Path $TmpDir "$BinaryName.exe") -Destination (Join-Path $InstallDir "$BinaryName.exe") -Force
    } finally {
        Remove-Item -Force $TmpFile -ErrorAction SilentlyContinue
        Remove-Item -Recurse -Force $TmpDir -ErrorAction SilentlyContinue
    }

    # Add to PATH if not already there
    $UserPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($UserPath -notlike "*$InstallDir*") {
        [Environment]::SetEnvironmentVariable("PATH", "$UserPath;$InstallDir", "User")
        $env:PATH = "$env:PATH;$InstallDir"
        Write-Host "Added $InstallDir to PATH."
    }

    Write-Host ""
    Write-Host "$BinaryName installed successfully to $InstallDir\$BinaryName.exe"
    Write-Host ""
    Write-Host "Prerequisites:"
    Write-Host "  Azure CLI (az) must be installed and logged in."
    Write-Host "  Run 'az login' if you haven't already."
    Write-Host ""
    Write-Host "Restart your terminal, then run '$BinaryName --help' to get started."
}

if ($Uninstall) {
    Uninstall-Aca
} else {
    Install-Aca
}
