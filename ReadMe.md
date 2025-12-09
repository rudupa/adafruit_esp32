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
│   └── esp-idf/                      # ESP-IDF application
├── SparkleMotionMini/
│   ├── README.md                     # Board/project-specific notes
│   └── esp-idf/                      # ESP-IDF application
├── third_party/
│   └── esp-idf/                      # ESP-IDF v5.2.1 submodule
└── toolchain/
    └── scripts/
        ├── build.ps1 / build.sh      # idf.py build wrapper
        ├── flash.ps1 / flash.sh      # idf.py flash wrapper
        └── monitor.ps1 / monitor.sh  # idf.py monitor wrapper
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

### PowerShell

```pwsh
pwsh toolchain/scripts/build.ps1
pwsh toolchain/scripts/flash.ps1 -Port COM6 -Baud 921600
pwsh toolchain/scripts/monitor.ps1 -Port COM6 -Baud 115200
```

Reverse TFT example:

```pwsh
pwsh toolchain/scripts/build.ps1 -ProjectDir ESP32S3ReverseTFT/esp-idf -Target esp32s3
pwsh toolchain/scripts/flash.ps1 -ProjectDir ESP32S3ReverseTFT/esp-idf -Target esp32s3 -Port COM7 -Baud 921600
pwsh toolchain/scripts/monitor.ps1 -ProjectDir ESP32S3ReverseTFT/esp-idf -Port COM7 -Baud 115200
```

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

---

## Manual Commands

If you prefer to drive `idf.py` yourself:

```pwsh
cd d:/repos/adafruit
pwsh third_party/esp-idf/export.ps1

# SparkleMotionMini (ESP32)
idf.py -C SparkleMotionMini/esp-idf set-target esp32
idf.py -C SparkleMotionMini/esp-idf build
idf.py -C SparkleMotionMini/esp-idf -p COM6 -b 921600 flash
idf.py -C SparkleMotionMini/esp-idf -p COM6 monitor

# ESP32-S3 Reverse TFT Feather
idf.py -C ESP32S3ReverseTFT/esp-idf set-target esp32s3
idf.py -C ESP32S3ReverseTFT/esp-idf build
idf.py -C ESP32S3ReverseTFT/esp-idf -p COM7 -b 921600 flash
idf.py -C ESP32S3ReverseTFT/esp-idf -p COM7 monitor
```

Use `export.sh` in POSIX shells. Press `Ctrl+]` to exit the ESP-IDF monitor.

---

## FAQ / Troubleshooting

- **`third_party/esp-idf` missing** – Run `git submodule update --init --recursive third_party/esp-idf`.
- **`idf.py` not found** – Make sure you executed `export.ps1`/`export.sh` in the same shell (or rely on the helper scripts which do it automatically).
- **Serial port busy or wrong** – Close any existing monitor instances and double-check `-Port`/`PORT` arguments before flashing or monitoring.
- **Need to customize pins/behavior** – Use `idf.py menuconfig` inside `SparkleMotionMini/esp-idf` to tweak `CONFIG_SPARKLE_*` options, then rebuild.

---

## TODO

- [ ] Add GitHub Actions job that runs `idf.py build` for CI smoke testing.
- [ ] Publish prebuilt `.bin` releases for quick verification.
- [ ] Extend the ESP-IDF example with Wi-Fi and BLE demos.
- [ ] Provide a container/devcontainer for repeatable builds.
- [x] Remove the legacy bare-metal/UF2 toolchain and unify around ESP-IDF.
