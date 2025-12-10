[CmdletBinding()]
param(
    [string]$BusId,
    [string]$Distribution = "Ubuntu",
    [switch]$ListOnly
)

function Assert-UsbipdInstalled {
    if (-not (Get-Command usbipd -ErrorAction SilentlyContinue)) {
        throw "usbipd.exe not found. Install it with 'winget install usbipd' from an elevated PowerShell window."
    }
}

function Show-UsbDevices {
    Write-Host "`nAvailable USB devices for WSL:" -ForegroundColor Cyan
    usbipd wsl list
    Write-Host
}

Assert-UsbipdInstalled

if ($ListOnly) {
    Show-UsbDevices
    return
}

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "usbipd attach typically requires an elevated PowerShell session."
}

if (-not $BusId) {
    Show-UsbDevices
    $BusId = Read-Host "Enter BUSID to attach (for example 1-7)"
}

if (-not $BusId) {
    throw "BUSID is required. Rerun with -BusId <value> or supply it at the prompt."
}

$arguments = @("wsl", "attach", "--busid", $BusId)
if ($Distribution) {
    $arguments += @("--distribution", $Distribution)
}

Write-Host "Attaching BUSID $BusId to WSL distro '$Distribution'..." -ForegroundColor Green

$process = Start-Process -FilePath (Get-Command usbipd).Source -ArgumentList $arguments -Wait -PassThru
if ($process.ExitCode -ne 0) {
    throw "usbipd attach failed with exit code $($process.ExitCode). Run 'usbipd wsl list' to inspect state."
}

Write-Host "USB device attached. It should now appear inside /dev on your WSL distro." -ForegroundColor Green
