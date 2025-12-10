[CmdletBinding()]
param(
    [string]$BusId,
    [switch]$ListOnly
)

function Assert-UsbipdInstalled {
    if (-not (Get-Command usbipd -ErrorAction SilentlyContinue)) {
        throw "usbipd.exe not found. Install it with 'winget install usbipd' from an elevated PowerShell window."
    }
}

function Show-UsbDevices {
    Write-Host "`nCurrent usbipd assignments:" -ForegroundColor Cyan
    usbipd wsl list
    Write-Host
}

Assert-UsbipdInstalled

if ($ListOnly) {
    Show-UsbDevices
    return
}

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "usbipd detach typically requires an elevated PowerShell session."
}

if (-not $BusId) {
    Show-UsbDevices
    $BusId = Read-Host "Enter BUSID to detach (for example 1-7)"
}

if (-not $BusId) {
    throw "BUSID is required. Rerun with -BusId <value> or supply it at the prompt."
}

$arguments = @("wsl", "detach", "--busid", $BusId)

Write-Host "Detaching BUSID $BusId from all WSL distros..." -ForegroundColor Yellow

$process = Start-Process -FilePath (Get-Command usbipd).Source -ArgumentList $arguments -Wait -PassThru
if ($process.ExitCode -ne 0) {
    throw "usbipd detach failed with exit code $($process.ExitCode). Run 'usbipd wsl list' to inspect state."
}

Write-Host "USB device detached. It is now back under Windows control." -ForegroundColor Green
