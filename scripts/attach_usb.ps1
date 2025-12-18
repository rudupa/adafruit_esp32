param(
    [string]$Distro = "Ubuntu",
    [string]$Pattern = "JTAG",
    [string]$BusId = "",
    [switch]$AutoAttach
)

if (-not (Get-Command usbipd -ErrorAction SilentlyContinue)) {
    Write-Error "usbipd-win is not installed. Install it from https://github.com/dorssel/usbipd-win and rerun this script."
    exit 1
}

function Get-UsbipdDevices {
    usbipd list |
        ForEach-Object {
            if ($_ -match '^Persisted:') { return }
            if ($_ -match '^\s*(?<busid>\d+-\d+)\s+(?<vidpid>[0-9A-Fa-f]{4}:[0-9A-Fa-f]{4})\s+(?<device>.+?)\s{2,}(?<state>.+)$') {
                [PSCustomObject]@{
                    BusId  = $Matches.busid
                    VidPid = $Matches.vidpid
                    Device = $Matches.device.Trim()
                    State  = $Matches.state.Trim()
                }
            }
        }
}

$devices = Get-UsbipdDevices
if (-not $devices) {
    Write-Error "No USB devices visible via usbipd. Plug in the JTAG adapter and try again."
    exit 1
}

if (-not $BusId) {
    $candidate = $devices | Where-Object { $_.Device -match $Pattern -or $_.VidPid -match $Pattern } | Select-Object -First 1
    if (-not $candidate) {
        Write-Error "No USB device matching pattern '$Pattern' found. Available devices:\n$($devices | Format-Table -AutoSize | Out-String)"
        exit 1
    }

    $BusId = $candidate.BusId
}

$target = $devices | Where-Object { $_.BusId -eq $BusId } | Select-Object -First 1
if (-not $target) {
    Write-Error "BusId '$BusId' not found. Available devices:\n$($devices | Format-Table -AutoSize | Out-String)"
    exit 1
}

if ($target.State -match 'Attached' -and -not ($target.State -match [regex]::Escape($Distro))) {
    Write-Warning "BusId $BusId is already attached elsewhere ($($target.State)). Detach it first."
    exit 1
}

$attachArgs = @('attach', '--wsl', $Distro, '--busid', $BusId)
if ($AutoAttach) {
    $attachArgs += '--auto-attach'
}

Write-Host "Attaching $($target.Device) ($BusId) to $Distro..."
usbipd @attachArgs
