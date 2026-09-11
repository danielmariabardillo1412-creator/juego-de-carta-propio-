$ErrorActionPreference = 'Stop'

$toolDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$engineDirectory = Split-Path -Parent $toolDirectory
$sourceDirectory = Join-Path $engineDirectory 'docs\fuentes_diseno'
$manifestPath = Join-Path $sourceDirectory 'SOURCE_MANIFEST.json'
$indexPath = Join-Path $sourceDirectory 'README.md'

if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "Falta el manifiesto de fuentes: $manifestPath"
}
if (-not (Test-Path -LiteralPath $indexPath -PathType Leaf)) {
    throw "Falta el índice de fuentes: $indexPath"
}

$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
if ($manifest.schema_version -ne 1) {
    throw "Versión de manifiesto no reconocida: $($manifest.schema_version)"
}
if ($manifest.sources.Count -ne 6) {
    throw "El corpus debe contener seis fuentes; contiene $($manifest.sources.Count)."
}

$keys = @{}
$ids = @{}
$indexText = Get-Content -Raw -LiteralPath $indexPath
foreach ($source in $manifest.sources) {
    if ($keys.ContainsKey($source.key)) { throw "Clave duplicada: $($source.key)" }
    if ($ids.ContainsKey($source.id)) { throw "ID de Drive duplicado: $($source.id)" }
    $keys[$source.key] = $true
    $ids[$source.id] = $true

    $sourcePath = Join-Path $sourceDirectory $source.local_file
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "Falta la copia local $($source.local_file)."
    }
    if ((Get-Item -LiteralPath $sourcePath).Length -lt 256) {
        throw "La copia local parece truncada: $($source.local_file)."
    }
    $sourceText = Get-Content -Raw -LiteralPath $sourcePath
    if (-not $sourceText.Contains($source.id)) {
        throw "La copia $($source.local_file) no declara su ID de Drive."
    }
    if (-not $indexText.Contains($source.key) -or -not $indexText.Contains($source.local_file)) {
        throw "El índice no registra correctamente $($source.key) / $($source.local_file)."
    }
}

Write-Host "FUENTES-DISENO PASS: $($manifest.sources.Count) fuentes, índice y manifiesto coherentes."
Write-Host "Última sincronización declarada: $($manifest.synced_at)"
Write-Host 'Nota: esta comprobación es local; compare modified_time con Drive al iniciar una fase de diseño.'
