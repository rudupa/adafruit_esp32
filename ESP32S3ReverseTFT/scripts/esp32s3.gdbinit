# Auto-run commands for ESP32-S3 Reverse TFT debugging
# Launch via: ./ESP32S3ReverseTFT/scripts/start_gdb.sh [path/to/app.elf]

set confirm off

target remote :3333
#load
break app_main
continue

# Handy commands after connection:
# step            # step into functions
# next            # step over functions
# print var_name  # inspect variable values
