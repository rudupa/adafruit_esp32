param(
    [string]$Distro = "Ubuntu",
    [string]$RepoPath = "/home/ritesh/repos/adafruit",
    [int]$AdapterKHz = 5000,
    [string]$Elf = "",
    [string]$Gdb = "",
    [switch]$SkipOpenOCD = $false,
    [int]$WaitSeconds = 2
)

# Prefer the known SDK GDB path when not provided explicitly.
$defaultSdkGdb = "/home/ritesh/zephyr-sdk-0.17.4/xtensa-espressif_esp32s3_zephyr-elf/bin/xtensa-espressif_esp32s3_zephyr-elf-gdb"
if (-not $Gdb) {
    $Gdb = $defaultSdkGdb
}

if (-not $Elf) {
    $Elf = "$RepoPath/build/zephyr/zephyr.elf"
}

# Launch OpenOCD (background window) then attach GDB to Zephyr ELF via WSL.
if (-not $SkipOpenOCD) {
    $openocdCmd = "cd $RepoPath && ./scripts/openocd_esp32s3.sh --adapter-khz $AdapterKHz"
    $proc = Start-Process wsl -ArgumentList @('-d', $Distro, '--', 'bash', '-lc', $openocdCmd) -WindowStyle Minimized -PassThru
    Write-Host "Started OpenOCD (PID=$($proc.Id))"
    Start-Sleep -Seconds $WaitSeconds
}

$gdbCmd = "cd $RepoPath && ./scripts/start_gdb.sh"
if ($Elf) { $gdbCmd += " --elf '$Elf'" }
if ($Gdb) { $gdbCmd += " --gdb '$Gdb'" }

& wsl -d $Distro -- bash -lc $gdbCmd
