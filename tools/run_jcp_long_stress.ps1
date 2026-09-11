param(
    [int]$TotalGames = 10000,
    [int]$Workers = 8,
    [int]$StartSeed = 1000000,
    [int]$RuntimeGames = 25
)

$ErrorActionPreference = 'Stop'
$ProjectPath = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$GodotPath = 'C:\Godot\4.7\Godot_v4.7-stable_win64_console.exe'
$LogPath = Join-Path $ProjectPath 'diagnostic_logs'
$StatusPath = Join-Path $LogPath 'jcp_long_stress_status.json'
$RunId = 'long_{0}' -f (Get-Date -Format 'yyyyMMdd_HHmmss')

if (-not (Test-Path -LiteralPath $GodotPath -PathType Leaf)) {
    throw "Godot no existe en $GodotPath"
}
if ($TotalGames -lt 1 -or $Workers -lt 1 -or $RuntimeGames -lt 0) {
    throw 'TotalGames y Workers deben ser positivos; RuntimeGames no puede ser negativo.'
}

function Write-Status {
    param([hashtable]$Value)
    $Value['updated_at'] = (Get-Date).ToString('o')
    $temporary = "$StatusPath.tmp"
    $Value | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $temporary -Encoding UTF8
    Move-Item -LiteralPath $temporary -Destination $StatusPath -Force
}

$baseCount = [math]::Floor($TotalGames / $Workers)
$remainder = $TotalGames % $Workers
$cursor = $StartSeed
$jobs = @()

for ($index = 0; $index -lt $Workers; $index++) {
    $count = $baseCount + $(if ($index -lt $remainder) { 1 } else { 0 })
    if ($count -le 0) { continue }
    $tag = '{0}_w{1:D2}' -f $RunId, ($index + 1)
    $stdout = Join-Path $LogPath "$tag.stdout.log"
    $stderr = Join-Path $LogPath "$tag.stderr.log"
    $arguments = @(
        '--headless', '--path', '.',
        '--script', 'res://tools/run_jcp_rule_stress.gd', '--',
        "--games=$count", "--start-seed=$cursor", "--report-tag=$tag"
    )
    $process = Start-Process -FilePath $GodotPath -ArgumentList $arguments -WorkingDirectory $ProjectPath -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    $jobs += [pscustomobject]@{
        process = $process
        tag = $tag
        games = $count
        start_seed = $cursor
        summary = Join-Path $LogPath "jcp_rule_stress_$tag.json"
        stdout = $stdout
        stderr = $stderr
    }
    $cursor += $count
}

Write-Status @{
    status = 'RUNNING_RULE_BATCHES'
    run_id = $RunId
    total_games = $TotalGames
    runtime_games = $RuntimeGames
    workers = $jobs.Count
    start_seed = $StartSeed
    process_ids = @($jobs | ForEach-Object { $_.process.Id })
}

while (@($jobs | Where-Object { -not $_.process.HasExited }).Count -gt 0) {
    $completedReports = @($jobs | Where-Object { Test-Path -LiteralPath $_.summary }).Count
    Write-Status @{
        status = 'RUNNING_RULE_BATCHES'
        run_id = $RunId
        total_games = $TotalGames
        completed_batches = $completedReports
        workers = $jobs.Count
        running_process_ids = @($jobs | Where-Object { -not $_.process.HasExited } | ForEach-Object { $_.process.Id })
    }
    Start-Sleep -Seconds 15
    foreach ($job in $jobs) { $job.process.Refresh() }
}

$reports = @()
$failedJobs = @()
foreach ($job in $jobs) {
    # El binario *_console.exe de Godot crea un proceso hijo y su wrapper puede
    # devolver un codigo no representativo. El informe JSON es la autoridad:
    # solo existe al terminar y contiene PASS/FAIL del simulador real.
    if (-not (Test-Path -LiteralPath $job.summary)) {
        $failedJobs += $job
        continue
    }
    $report = Get-Content -LiteralPath $job.summary -Raw | ConvertFrom-Json
    if ($report.status -ne 'PASS') { $failedJobs += $job } else { $reports += $report }
}

if ($failedJobs.Count -gt 0) {
    Write-Status @{
        status = 'FAIL'
        stage = 'RULE_BATCHES'
        run_id = $RunId
        failed_tags = @($failedJobs | ForEach-Object { $_.tag })
    }
    exit 1
}

$runtimeReport = $null
if ($RuntimeGames -gt 0) {
    $runtimeTag = "${RunId}_runtime"
    Write-Status @{
        status = 'RUNNING_UCE_SAMPLE'
        run_id = $RunId
        rule_games_completed = $TotalGames
        runtime_games = $RuntimeGames
    }
    $runtimeStdout = Join-Path $LogPath "$runtimeTag.stdout.log"
    $runtimeStderr = Join-Path $LogPath "$runtimeTag.stderr.log"
    $runtimeArgs = @(
        '--headless', '--path', '.',
        '--script', 'res://tools/run_jcp_stress_matches.gd', '--',
        "--games=$RuntimeGames", "--start-seed=$cursor", "--report-tag=$runtimeTag"
    )
    $runtimeProcess = Start-Process -FilePath $GodotPath -ArgumentList $runtimeArgs -WorkingDirectory $ProjectPath -WindowStyle Hidden -PassThru -Wait -RedirectStandardOutput $runtimeStdout -RedirectStandardError $runtimeStderr
    $runtimeSummaryPath = Join-Path $LogPath "jcp_stress_$runtimeTag.json"
    if (-not (Test-Path -LiteralPath $runtimeSummaryPath)) {
        Write-Status @{ status = 'FAIL'; stage = 'UCE_SAMPLE'; run_id = $RunId; exit_code = $runtimeProcess.ExitCode }
        exit 1
    }
    $runtimeReport = Get-Content -LiteralPath $runtimeSummaryPath -Raw | ConvertFrom-Json
    if ($runtimeReport.status -ne 'PASS') {
        Write-Status @{ status = 'FAIL'; stage = 'UCE_SAMPLE'; run_id = $RunId; report_status = $runtimeReport.status }
        exit 1
    }
}

$actionCounts = @{}
foreach ($report in $reports + @($runtimeReport)) {
    if ($null -eq $report) { continue }
    foreach ($property in $report.action_counts.PSObject.Properties) {
        $actionCounts[$property.Name] = [int64]($actionCounts[$property.Name] + $property.Value)
    }
}

$ruleActions = [int64](($reports | Measure-Object -Property total_actions -Sum).Sum)
$ruleTies = [int](($reports | Measure-Object -Property tied_matches -Sum).Sum)
$runtimeActions = if ($null -eq $runtimeReport) { 0 } else { [int64]$runtimeReport.total_actions }
$final = @{
    status = 'PASS'
    run_id = $RunId
    rule_games = $TotalGames
    runtime_games = $RuntimeGames
    total_games = $TotalGames + $RuntimeGames
    rule_actions = $ruleActions
    runtime_actions = $runtimeActions
    total_actions = $ruleActions + $runtimeActions
    tied_matches = $ruleTies + $(if ($null -eq $runtimeReport) { 0 } else { [int]$runtimeReport.tied_matches })
    action_counts = $actionCounts
    seed_first = $StartSeed
    seed_last = $cursor + $RuntimeGames - 1
}
$finalPath = Join-Path $LogPath "jcp_long_stress_${RunId}_final.json"
$final | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $finalPath -Encoding UTF8
$final['final_report'] = $finalPath
Write-Status $final
exit 0
