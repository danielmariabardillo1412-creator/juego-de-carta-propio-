param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"
$manifestPath = Join-Path $ProjectRoot "MANIFEST.json"
$logDirectory = Join-Path $ProjectRoot "diagnostic_logs"
New-Item -ItemType Directory -Force -Path $logDirectory | Out-Null
$jsonReportPath = Join-Path $logDirectory "package_integrity_latest.json"
$textReportPath = Join-Path $logDirectory "package_integrity_latest.txt"

$report = [ordered]@{
    schema = "zapiti-universal-engine-package-integrity-v1"
    started_utc = [DateTime]::UtcNow.ToString("o")
    project_root = $ProjectRoot
    manifest_path = $manifestPath
    status = "FAIL"
    checked = 0
    missing = @()
    mismatched = @()
    errors = @()
}

try {
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw "MANIFEST.json is missing."
    }

    $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($null -eq $manifest.files) {
        throw "MANIFEST.json has no files collection."
    }

    foreach ($entry in $manifest.files) {
        $relativePath = [string]$entry.path
        $expectedHash = ([string]$entry.sha256).ToLowerInvariant()
        $expectedBytes = [int64]$entry.bytes
        $absolutePath = Join-Path $ProjectRoot ($relativePath -replace '/', [IO.Path]::DirectorySeparatorChar)

        if (-not (Test-Path -LiteralPath $absolutePath -PathType Leaf)) {
            $report.missing += $relativePath
            continue
        }

        $fileInfo = Get-Item -LiteralPath $absolutePath
        $actualHash = (Get-FileHash -LiteralPath $absolutePath -Algorithm SHA256).Hash.ToLowerInvariant()
        $report.checked++
        if ($actualHash -ne $expectedHash -or $fileInfo.Length -ne $expectedBytes) {
            $report.mismatched += [ordered]@{
                path = $relativePath
                expected_sha256 = $expectedHash
                actual_sha256 = $actualHash
                expected_bytes = $expectedBytes
                actual_bytes = $fileInfo.Length
            }
        }
    }

    if ($report.missing.Count -eq 0 -and $report.mismatched.Count -eq 0) {
        $report.status = "PASS"
    }
}
catch {
    $report.errors += $_.Exception.Message
}

$report.finished_utc = [DateTime]::UtcNow.ToString("o")
$report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonReportPath -Encoding UTF8

$lines = @(
    "UNIVERSAL CARD ENGINE PACKAGE INTEGRITY",
    "Status: $($report.status)",
    "Project: $ProjectRoot",
    "Files checked: $($report.checked)",
    "Missing: $($report.missing.Count)",
    "Mismatched: $($report.mismatched.Count)",
    "Errors: $($report.errors.Count)"
)
if ($report.missing.Count -gt 0) {
    $lines += ""
    $lines += "MISSING FILES"
    $lines += $report.missing
}
if ($report.mismatched.Count -gt 0) {
    $lines += ""
    $lines += "MISMATCHED FILES"
    foreach ($item in $report.mismatched) {
        $lines += "$($item.path) expected=$($item.expected_sha256) actual=$($item.actual_sha256)"
    }
}
if ($report.errors.Count -gt 0) {
    $lines += ""
    $lines += "ERRORS"
    $lines += $report.errors
}
$lines | Set-Content -LiteralPath $textReportPath -Encoding UTF8

Write-Host "Package integrity: $($report.status)"
Write-Host "JSON report: $jsonReportPath"
Write-Host "Text report: $textReportPath"
if ($report.status -eq "PASS") { exit 0 }
exit 1
