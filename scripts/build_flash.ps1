param(
    [string]$Distro = "Ubuntu",
    [string]$RepoPath = "/home/ritesh/repos/adafruit",
    [string]$ExtraArgs = ""
)

# Invokes the Zephyr build+flash helper from PowerShell via WSL.
$cmd = "cd $RepoPath && ./scripts/build_flash.sh $ExtraArgs"
$psi = "bash -lc \"$cmd\""

wsl -d $Distro -- $psi
