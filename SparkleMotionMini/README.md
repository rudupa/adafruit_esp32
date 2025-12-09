# SparkleMotionMini ESP-IDF Example

This folder now contains a single ESP-IDF application that targets the SparkleMotionMini's ESP32-based design. The firmware toggles the red LED on GPIO12 and emits a heartbeat log over USB CDC so you can validate toolchain setup, flashing, and serial monitoring with a single repo.

## Project Layout

```
SparkleMotionMini/
├── README.md (this file)
└── esp-idf/        # Standard ESP-IDF application skeleton
    ├── main/
    ├── CMakeLists.txt
    ├── sdkconfig.defaults
    └── ...
```

All build artifacts remain under `SparkleMotionMini/esp-idf/build/` and are managed by `idf.py`.

## Prerequisites

- Git with submodule support (`git clone --recurse-submodules <repo-url>`)
- Python 3.x (bundled with ESP-IDF)
- USB cable for the SparkleMotionMini

The ESP-IDF SDK itself is vendored as a submodule in `third_party/esp-idf` and pinned to tag `v5.2.1`. If you cloned without submodules, run:

```pwsh
git submodule update --init --recursive third_party/esp-idf
```

## Quickstart Scripts

The helpers in `toolchain/scripts/` wrap `idf.py` so you do not have to remember the exact command lines. They automatically source/export the ESP-IDF environment before running.

### PowerShell (Windows)

```pwsh
pwsh toolchain/scripts/build.ps1
pwsh toolchain/scripts/flash.ps1 -Port COM6 -Baud 921600
pwsh toolchain/scripts/monitor.ps1 -Port COM6 -Baud 115200
```

### Bash (macOS/Linux/WSL)

```bash
./toolchain/scripts/build.sh
PORT=/dev/ttyUSB0 BAUD=921600 ./toolchain/scripts/flash.sh
PORT=/dev/ttyUSB0 BAUD=115200 ./toolchain/scripts/monitor.sh
```

`flash` automatically programs the bootloader, partition table, and application images using the offsets baked into the project. `monitor` launches the ESP-IDF serial monitor (press `Ctrl+]` to exit).

## Manual `idf.py` Flow

```pwsh
cd d:/repos/adafruit
pwsh third_party/esp-idf/export.ps1

idf.py -C SparkleMotionMini/esp-idf set-target esp32
idf.py -C SparkleMotionMini/esp-idf build
idf.py -C SparkleMotionMini/esp-idf -p COM6 -b 921600 flash
idf.py -C SparkleMotionMini/esp-idf -p COM6 monitor
```

Use `export.sh` when running under Bash. `idf.py` caches the selected target, so subsequent builds can omit `set-target` unless you change MCUs.

## Firmware Behavior

- Logs a banner plus `sparkle: heartbeat N` once per second at 115200 baud.
- Toggles GPIO12 to blink the red indicator LED in sync with the log counter.
- Default behavior is controlled by Kconfig symbols in `main/Kconfig.projbuild` (`CONFIG_SPARKLE_LED_GPIO`, `CONFIG_SPARKLE_HEARTBEAT_MS`, `CONFIG_SPARKLE_SERIAL_BAUD`).

Customize pin assignments or timing in `SparkleMotionMini/esp-idf/main/main.c` and rebuild.

## Troubleshooting

- **ESP-IDF missing**: Re-run `git submodule update --init --recursive third_party/esp-idf`.
- **Python/ESP-IDF tools missing from PATH**: Always execute `export.ps1` / `export.sh` (the helper scripts do this automatically).
- **Serial port busy**: Close any existing monitor sessions before flashing or start `idf.py flash -p <port> -b <baud>` with a different COM device.
- **LED not blinking**: Confirm the board revision routes the red LED to GPIO12 or update `CONFIG_SPARKLE_LED_GPIO` in menuconfig.

Happy hacking! The ESP-IDF project is the single source of truth for this board—no separate CMake/BareMetal flow remains in the repo.
