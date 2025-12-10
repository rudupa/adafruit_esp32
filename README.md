# ESP-IDF Heartbeat Workspace

This repository now focuses entirely on ESP-IDF heartbeat applications for Adafruit development boards. The previously checked-in bare-metal/CMake flow has been removed to keep the repo lightweight and aligned with Espressif's official tooling.

Currently implemented projects:

- `SparkleMotionMini/esp-idf` – ESP32-based SparkleMotionMini heartbeat (red LED on GPIO12).
- `ESP32S3ReverseTFT/esp-idf` – ESP32-S3 Reverse TFT Feather heartbeat (status LED on GPIO13).

---

## 📂 Repository Layout

```
├── ReadMe.md                         # Top-level overview (this file)
├── ESP32S3ReverseTFT/
│   ├── README.md                     # ESP32-S3 Reverse TFT notes
│   ├── esp-idf/                      # ESP-IDF application
│   └── scripts/                      # Board-specific helpers (build/flash, etc.)
├── SparkleMotionMini/
│   ├── README.md                     # Board/project-specific notes
│   ├── esp-idf/                      # ESP-IDF application
│   └── scripts/                      # Board-specific helpers (build/flash, etc.)
├── third_party/
│   └── esp-idf/                      # ESP-IDF v5.2.1 submodule
└── toolchain/
    └── scripts/
        ├── build.sh                  # idf.py build wrapper
        ├── flash.sh                  # idf.py flash wrapper
        └── monitor.sh                # idf.py monitor wrapper
```

`build/`, `logs/`, and other generated directories were deleted from source control. Run the helper scripts (or plain `idf.py`) to regenerate artifacts locally.

---

## Requirements

- Git with submodule support (clone with `--recurse-submodules`)
- Python 3.x (installed automatically by ESP-IDF's setup tooling)
- ESP-IDF dependencies (managed inside `third_party/esp-idf`)
- USB cable + serial port access to the SparkleMotionMini

Populate the SDK before building:

```pwsh
git clone --recurse-submodules <repo-url>
# or, for an existing clone
git submodule update --init --recursive third_party/esp-idf
```

---

## Quickstart

The scripts automatically source/export the ESP-IDF environment and then forward directly to `idf.py`.

### Bash / zsh / WSL

```bash
./toolchain/scripts/build.sh
PORT=/dev/ttyUSB0 BAUD=921600 ./toolchain/scripts/flash.sh
PORT=/dev/ttyUSB0 BAUD=115200 ./toolchain/scripts/monitor.sh
```

Reverse TFT example:

```bash
PROJECT_DIR=ESP32S3ReverseTFT/esp-idf IDF_TARGET=esp32s3 ./toolchain/scripts/build.sh
PORT=/dev/ttyACM0 BAUD=921600 PROJECT_DIR=ESP32S3ReverseTFT/esp-idf IDF_TARGET=esp32s3 ./toolchain/scripts/flash.sh
PORT=/dev/ttyACM0 BAUD=115200 PROJECT_DIR=ESP32S3ReverseTFT/esp-idf ./toolchain/scripts/monitor.sh
```

By default the scripts target `SparkleMotionMini/esp-idf` and assume the submodule lives in `third_party/esp-idf`. Override the target project with `-ProjectDir <dir> -Target <chip>` in PowerShell or `PROJECT_DIR=<dir> IDF_TARGET=<chip>` (and other environment variables such as `PORT`/`BAUD`) in Bash/zsh. The wrappers always run `idf.py set-target <chip>` before building or flashing.

### WSL build + flash shortcuts

Each board exposes a wrapper that sources ESP-IDF, builds, flashes, and launches the monitor from WSL:

```bash
# SparkleMotionMini target (ESP32)
./SparkleMotionMini/scripts/build_flash.sh            # add --fullclean if you need a deep rebuild

# ESP32-S3 Reverse TFT target
./ESP32S3ReverseTFT/scripts/build_flash.sh            # forces IDF_TARGET=esp32s3 internally
```

Both commands forward all flags to `scripts/wsl_build_flash.sh`, so you can run `--fullclean` or `--project-dir <path>` if you need a custom location. The root helper can also be invoked directly when scripting multiple builds.

---

## WSL 2 Workflow (Recommended for Debugging)

WSL 2 offers better USB handling for OpenOCD debugging.

### 1. Install `usbipd-win` (Windows)
Run in Administrator PowerShell:
```powershell
winget install usbipd
```

### 2. Attach USB to WSL
From an elevated Windows PowerShell prompt on the host, you can run the helper scripts that wrap `usbipd` for quickly attaching the ESP32-S3 JTAG/USB bridge to your distro:
```pwsh
pwsh scripts/wsl_attach_usb.ps1 -BusId <BUSID> -Distribution Ubuntu
```
When you finish debugging, detach the device so Windows reclaims it:
```pwsh
pwsh scripts/wsl_detach_usb.ps1 -BusId <BUSID>
```
Both scripts call `usbipd wsl list` automatically if you omit `-BusId`, so you can copy/paste the displayed ID interactively. They also expose `-ListOnly` if you just want to inspect state.

Prefer to run the raw commands? Use `usbipd` directly:
```powershell
usbipd wsl list
usbipd wsl attach --busid <BUSID> --distribution Ubuntu
```
Detach manually with:
```powershell
usbipd wsl detach --busid <BUSID>
```

### 3. Run OpenOCD (WSL)
Inside your WSL terminal:
```bash
# First time setup (pull submodule + build OpenOCD)
git submodule update --init tools/openocd-linux
bash scripts/wsl_setup_openocd.sh

# Subsequent runs (starts the already-built binary)
bash scripts/wsl_run_openocd.sh
```

### 4. Build & Flash (WSL)
Ensure you have ESP-IDF installed in WSL. Then run:
```bash
# Build
idf.py build

# Flash & Monitor (OpenOCD must be running or USB attached)
idf.py flash monitor
```

### 5. JTAG + GDB debugging

1. Start OpenOCD in one WSL terminal (`bash scripts/wsl_run_openocd.sh`). If the JTAG link is noisy, pass `-c "adapter_khz 500"` or add `adapter_khz 500` inside the relevant cfg (e.g., `esp32s3-builtin.cfg`).
2. In another WSL shell, launch the ESP32-S3-specific helper after building:

```bash
./ESP32S3ReverseTFT/scripts/start_gdb.sh            # add --elf path/to/custom.elf if needed
```

This script runs `xtensa-esp32s3-elf-gdb build/<app>.elf -x ESP32S3ReverseTFT/scripts/esp32s3.gdbinit` so GDB automatically:

- Connects to OpenOCD via `target remote :3333` (CPU0)
- Loads the firmware image with `load`
- Sets `break app_main` and continues execution (`continue`)

Inside GDB you can step (`step`, `next`), inspect variables (`print my_variable`), and use other standard commands. The `.gdbinit` template is checked in at `ESP32S3ReverseTFT/scripts/esp32s3.gdbinit` if you want to customize the sequence.

**Multi-core note:** ESP32-S3 CPU0 listens on port `:3333` while CPU1 is exposed on `:3334`. To debug CPU1, start a second OpenOCD session (already provided by the default config) and in another terminal run:

```bash
xtensa-esp32s3-elf-gdb build/<app>.elf -ex "target remote :3334"
```

You can reuse the same `.gdbinit` file—just override the `target remote` line with `:3334` (or launch `start_gdb.sh --elf ...` and then run `target remote :3334` manually).

---

## Manual Commands

If you prefer to drive `idf.py` yourself:

```bash
cd ~/repos/adafruit
source third_party/esp-idf/export.sh

# SparkleMotionMini (ESP32)
idf.py -C SparkleMotionMini/esp-idf set-target esp32
idf.py -C SparkleMotionMini/esp-idf build
idf.py -C SparkleMotionMini/esp-idf -p /dev/ttyUSB0 -b 921600 flash
idf.py -C SparkleMotionMini/esp-idf -p /dev/ttyUSB0 monitor

# ESP32-S3 Reverse TFT Feather
idf.py -C ESP32S3ReverseTFT/esp-idf set-target esp32s3
idf.py -C ESP32S3ReverseTFT/esp-idf build
idf.py -C ESP32S3ReverseTFT/esp-idf -p /dev/ttyACM0 -b 921600 flash
idf.py -C ESP32S3ReverseTFT/esp-idf -p /dev/ttyACM0 monitor
```

Press `Ctrl+]` to exit the ESP-IDF monitor.

---

## FAQ / Troubleshooting

- **`third_party/esp-idf` missing** – Run `git submodule update --init --recursive third_party/esp-idf`.
- **`idf.py` not found** – Make sure you executed `export.sh` in the same shell (or rely on the helper scripts which do it automatically).
- **Serial port busy or wrong** – Close any existing monitor instances and double-check `-Port`/`PORT` arguments before flashing or monitoring.
- **Need to customize pins/behavior** – Use `idf.py menuconfig` inside `SparkleMotionMini/esp-idf` to tweak `CONFIG_SPARKLE_*` options, then rebuild.

---

## TODO

- [ ] Add GitHub Actions job that runs `idf.py build` for CI smoke testing.
- [ ] Publish prebuilt `.bin` releases for quick verification.
- [ ] Extend the ESP-IDF example with Wi-Fi and BLE demos.
- [ ] Provide a container/devcontainer for repeatable builds.
- [ ] Create at least one NN inference demo per board (e.g., audio keyword spotting on SparkleMotionMini’s mic and gesture/image classification on the ESP32-S3 Reverse TFT) so we can benchmark them side-by-side.
- [ ] Stand up a lightweight web server in-repo that streams inference results over Wi-Fi/Bluetooth for remote monitoring.
- [x] Remove the legacy bare-metal/UF2 toolchain and unify around ESP-IDF.
