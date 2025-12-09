#include <stdio.h>

#include "driver/gpio.h"
#include "esp_chip_info.h"
#include "esp_flash.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

static const char *TAG = "sparkle";

static void log_chip_banner(void)
{
    esp_chip_info_t chip_info;
    esp_chip_info(&chip_info);

    uint32_t flash_size = 0;
    esp_flash_get_size(NULL, &flash_size);

    ESP_LOGI(TAG, "SparkleMotionMini ESP-IDF blinky");
    ESP_LOGI(TAG, "Chip cores: %d, WiFi%s%s, silicon rev %d",
             chip_info.cores,
             (chip_info.features & CHIP_FEATURE_BT) ? ", BT" : "",
             (chip_info.features & CHIP_FEATURE_BLE) ? ", BLE" : "",
             chip_info.revision);
    ESP_LOGI(TAG, "Embedded flash: %lu bytes", (unsigned long)flash_size);
    ESP_LOGI(TAG, "Heartbeat every %d ms on GPIO%d",
             CONFIG_SPARKLE_HEARTBEAT_MS,
             CONFIG_SPARKLE_LED_GPIO);
}

void app_main(void)
{
    log_chip_banner();

    gpio_config_t io_conf = {
        .pin_bit_mask = BIT64(CONFIG_SPARKLE_LED_GPIO),
        .mode = GPIO_MODE_OUTPUT,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .pull_up_en = GPIO_PULLUP_DISABLE,
        .intr_type = GPIO_INTR_DISABLE,
    };
    gpio_config(&io_conf);
    gpio_set_level(CONFIG_SPARKLE_LED_GPIO, 0);

    bool led_on = false;
    uint32_t heartbeat_count = 0;

    while (true)
    {
        led_on = !led_on;
        gpio_set_level(CONFIG_SPARKLE_LED_GPIO, led_on);
        ESP_LOGI(TAG, "heartbeat %lu", (unsigned long)heartbeat_count++);
        vTaskDelay(pdMS_TO_TICKS(CONFIG_SPARKLE_HEARTBEAT_MS));
    }
}
