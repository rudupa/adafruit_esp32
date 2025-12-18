param(
    [string]$Distro = "Ubuntu",
    [string]$Pattern = "JTAG",
    [string]$BusId = ""
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
    Write-Error "No USB devices visible via usbipd."
    exit 1
}

if (-not $BusId) {
    $candidate = $devices |
        Where-Object {
            $_.State -match 'Attached' -and $_.State -match [regex]::Escape($Distro) -and ($_.Device -match $Pattern -or $_.VidPid -match $Pattern)
        } |
        Select-Object -First 1

    if (-not $candidate) {
        Write-Error "No attached device matching pattern '$Pattern' for distro '$Distro'. Current devices:\n$($devices | Format-Table -AutoSize | Out-String)"
        exit 1
    }

    $BusId = $candidate.BusId
}

$target = $devices | Where-Object { $_.BusId -eq $BusId } | Select-Object -First 1
if (-not $target) {
    Write-Error "BusId '$BusId' not found. Current devices:\n$($devices | Format-Table -AutoSize | Out-String)"
    exit 1
}

Write-Host "Detaching $($target.Device) ($BusId) from $Distro..."
usbipd detach --busid $BusId
