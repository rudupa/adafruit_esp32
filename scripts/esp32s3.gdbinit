# Auto-run commands for Zephyr on ESP32-S3
# Launch via: ./scripts/start_gdb.sh [path/to/zephyr.elf]

set confirm off

target remote :3333
monitor reset halt
thb main
continue

# Handy commands after connection:
# step            # step into functions
# next            # step over functions
# print var_name  # inspect variable values
