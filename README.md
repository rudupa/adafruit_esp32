# ESP32-S3 Reverse TFT (Zephyr)

Minimal Zephyr sanity check for the Adafruit ESP32-S3 Reverse TFT Feather (#5691). The firmware blinks the status LED (GPIO13) once per second and prints "Blink" over USB so you can quickly validate power, boot, and serial.

## Layout

- `zephyr_app/` – Zephyr sources and overlay.
- `scripts/` – Helper scripts (build/flash, serial monitor, OpenOCD, GDB).
- `tools/openocd-linux/` – OpenOCD submodule used for JTAG.
- `.gitignore`, `.gitmodules`, `west.yml` – workspace metadata.

## Prerequisites

- Zephyr SDK and `west` available in WSL.
- Install Python `pyserial` in WSL for the serial monitor: `pip install pyserial`.
- For JTAG: initialize the OpenOCD submodule and build it once (`git submodule update --init tools/openocd-linux && cd tools/openocd-linux && ./bootstrap && ./configure --enable-esp32 && make -j`).

## Build & Flash (WSL)

Fast path (defaults to `/dev/ttyACM0`):

```bash
./scripts/build_flash.sh
```

Manual commands:

```bash
west build -p auto -b esp32s3_devkitm zephyr_app
west flash
```

PowerShell wrapper (from Windows):

```powershell
pwsh -ExecutionPolicy Bypass -File scripts/build_flash.ps1
```

## Serial Monitor

- WSL: `python3 -m serial.tools.miniterm /dev/ttyACM0 115200`
- Windows PowerShell: `pwsh -ExecutionPolicy Bypass -File scripts/serial_monitor.ps1`

You should see `Starting Sanity Check App` followed by repeated `Blink` messages.

## OpenOCD + GDB

1) Start OpenOCD for the on-board USB JTAG:

```bash
./scripts/openocd_esp32s3.sh --adapter-khz 5000
```

2) In another terminal, attach GDB to the Zephyr ELF (build first):

```bash
./scripts/start_gdb.sh
```

`esp32s3.gdbinit` connects to `:3333`, halts, and sets a temporary breakpoint on `main`.

## Expected Behavior

- LED on GPIO13 blinks at ~1 Hz.
- USB serial prints `Blink` at 115200 baud.

If both occur, the board and USB path are healthy; re-enable additional peripherals from there.

---

## TODO

- [ ] Add GitHub Actions job that runs `idf.py build` for CI smoke testing.
- [ ] Publish prebuilt `.bin` releases for quick verification.
- [ ] Extend the ESP-IDF example with Wi-Fi and BLE demos.
- [ ] Provide a container/devcontainer for repeatable builds.
- [ ] Create at least one NN inference demo per board (e.g., audio keyword spotting on SparkleMotionMini’s mic and gesture/image classification on the ESP32-S3 Reverse TFT) so we can benchmark them side-by-side.
- [ ] Stand up a lightweight web server in-repo that streams inference results over Wi-Fi/Bluetooth for remote monitoring.
- [x] Remove the legacy bare-metal/UF2 toolchain and unify around ESP-IDF.
