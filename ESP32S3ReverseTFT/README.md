# ESP32-S3 Reverse TFT Heartbeat

This directory contains an ESP-IDF application for the Adafruit ESP32-S3 Reverse TFT Feather (board #5691). The firmware blinks the on-board red status LED (Feather pin 13), renders a colorful heartbeat visualization on the integrated 240x135 ST7789 TFT, and prints a heartbeat counter over USB CDC/JTAG so you can quickly validate the ESP-IDF toolchain, flashing, and serial monitor.

## Project Layout

```
ESP32S3ReverseTFT/
├── README.md (this file)
└── esp-idf/
    ├── main/
    ├── CMakeLists.txt
    ├── sdkconfig.defaults
    └── ...
```

All build products live under `ESP32S3ReverseTFT/esp-idf/build/` and are created by `idf.py`.

## Quickstart Scripts

The helper scripts under `toolchain/scripts/` export the ESP-IDF environment and then proxy `idf.py`. Override the defaults to point at this project and target the ESP32-S3 MCU.

### PowerShell

```pwsh
pwsh toolchain/scripts/build.ps1 -ProjectDir ESP32S3ReverseTFT/esp-idf -Target esp32s3
pwsh toolchain/scripts/flash.ps1 -ProjectDir ESP32S3ReverseTFT/esp-idf -Target esp32s3 -Port COM6 -Baud 921600
pwsh toolchain/scripts/monitor.ps1 -ProjectDir ESP32S3ReverseTFT/esp-idf -Port COM6 -Baud 115200
```

### Bash / zsh / WSL

```bash
PROJECT_DIR=ESP32S3ReverseTFT/esp-idf IDF_TARGET=esp32s3 ./toolchain/scripts/build.sh
PORT=/dev/ttyACM0 BAUD=921600 PROJECT_DIR=ESP32S3ReverseTFT/esp-idf IDF_TARGET=esp32s3 ./toolchain/scripts/flash.sh
PORT=/dev/ttyACM0 BAUD=115200 PROJECT_DIR=ESP32S3ReverseTFT/esp-idf ./toolchain/scripts/monitor.sh
```

Pass your local serial port via `-Port`/`PORT` and adjust baud rates as needed.

## Manual `idf.py` Flow

```pwsh
cd d:/repos/adafruit
pwsh third_party/esp-idf/export.ps1

idf.py -C ESP32S3ReverseTFT/esp-idf set-target esp32s3
idf.py -C ESP32S3ReverseTFT/esp-idf build
idf.py -C ESP32S3ReverseTFT/esp-idf -p COM6 -b 921600 flash
idf.py -C ESP32S3ReverseTFT/esp-idf -p COM6 monitor
```

Use `export.sh` when running from Bash-based shells. Once the target is set to `esp32s3`, subsequent invocations can omit `set-target` unless you clean the configuration.

## Firmware Behavior

- Logs board, core, and flash information plus a running `reverse_tft: heartbeat N` counter every 250 ms.
- Toggles GPIO13 (red status LED) in sync with the heartbeat log.
- Renders an animated gradient, sine-wave trace, and sweeping pulse column on the built-in ST7789 TFT (mapped in landscape orientation) so the heartbeat is visible even without the serial monitor.
- Key settings live in `main/Kconfig.projbuild` (`CONFIG_REVTFT_LED_GPIO`, `CONFIG_REVTFT_HEARTBEAT_MS`, `CONFIG_REVTFT_SERIAL_BAUD`, and the `CONFIG_REVTFT_TFT_*` block described below).

Adjust pin assignments, blink rate, or display characteristics via `idf.py menuconfig` or by editing `main/main.c`.

### TFT Configuration Reference

The display driver powers the `TFT_I2C_POWER` rail, turns on the backlight, initializes the SPI bus, and streams a full-screen framebuffer each heartbeat. Override any of these defaults through `idf.py menuconfig` → **ESP32-S3 Reverse TFT configuration**:

| Setting | Default | Description |
| --- | --- | --- |
| `CONFIG_REVTFT_TFT_H_RES` / `CONFIG_REVTFT_TFT_V_RES` | 240 / 135 | Logical display resolution used for the framebuffer. |
| `CONFIG_REVTFT_TFT_COL_OFFSET` / `CONFIG_REVTFT_TFT_ROW_OFFSET` | 40 / 53 | Panel offsets needed for the Reverse TFT carrier. |
| `CONFIG_REVTFT_TFT_SPI_HZ` | 40 MHz | SPI clock driven into the ST7789. |
| `CONFIG_REVTFT_TFT_POWER_GPIO` | 7 | Enables the TFT + STEMMA QT rail (aka `TFT_I2C_POWER`). |
| `CONFIG_REVTFT_TFT_BACKLIGHT_GPIO` | 45 | Controls the TFT backlight transistor. |
| `CONFIG_REVTFT_TFT_CS/DC/RST/MOSI/SCLK_GPIO` | 42/40/41/35/36 | SPI wiring for the ST7789 panel. |

Leave the defaults alone for the stock Feather but tweak them if you repurpose this project for another ST7789 breakout.

## Troubleshooting

- **ESP-IDF missing** – Initialize the submodule via `git submodule update --init --recursive third_party/esp-idf`.
- **Wrong target selected** – Run `idf.py set-target esp32s3` inside this project before building/flashing.
- **Serial monitor silent** – Confirm the USB serial port and baud rate; the default heartbeat prints at 115200 baud.
- **LED not blinking** – Double-check that GPIO13 drives the status LED on your board revision or adjust `CONFIG_REVTFT_LED_GPIO` accordingly.
