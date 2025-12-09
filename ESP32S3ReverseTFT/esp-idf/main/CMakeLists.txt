idf_component_register(SRCS "main.c"
                       INCLUDE_DIRS "."
                       REQUIRES driver esp_lcd esp_system esp_hw_support spi_flash)
