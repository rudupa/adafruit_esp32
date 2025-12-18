param(
    [string]$Distro = "Ubuntu",
    [string]$Port = "/dev/ttyACM0",
    [int]$Baud = 115200
)

# Launches pyserial miniterm inside WSL from PowerShell.
$cmd = "python3 -m serial.tools.miniterm $Port $Baud"

& wsl -d $Distro -- bash -lc $cmd
