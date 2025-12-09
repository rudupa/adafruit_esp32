param(
    [string]$Port = "",
    [int]$Baud = 921600,
    [string]$ProjectDir = "SparkleMotionMini/esp-idf",
    [string]$Target = "esp32"
)

$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$repoRoot = (Resolve-Path "$scriptRoot/../..").Path
$projectPath = Join-Path $repoRoot $ProjectDir
$idfPath = Join-Path $repoRoot "third_party/esp-idf"
$exportScript = Join-Path $idfPath "export.ps1"

if (-not (Test-Path $projectPath)) {
    throw "ESP-IDF project '$projectPath' not found."
}

if (-not (Test-Path $exportScript)) {
    throw "ESP-IDF export script missing. Run 'git submodule update --init --recursive third_party/esp-idf'."
}

. $exportScript | Out-Null

$commonArgs = @('-C', $projectPath)

& idf.py @($commonArgs + @('set-target', $Target))

$flashArgs = @('-C', $projectPath)
if ($Port -ne "") {
    $flashArgs += @('-p', $Port)
}
if ($Baud -gt 0) {
    $flashArgs += @('-b', $Baud)
}
$flashArgs += 'flash'

& idf.py @flashArgs
