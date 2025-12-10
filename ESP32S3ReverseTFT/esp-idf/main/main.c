#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "driver/gpio.h"
#include "driver/spi_master.h"
#include "esp_chip_info.h"
#include "esp_err.h"
#include "esp_flash.h"
#include "esp_heap_caps.h"
#include "esp_lcd_panel_io.h"
#include "esp_lcd_panel_ops.h"
#include "esp_lcd_panel_vendor.h"
#include "esp_lcd_types.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#define LCD_HOST SPI2_HOST
#define LCD_H_RES CONFIG_REVTFT_TFT_H_RES
#define LCD_V_RES CONFIG_REVTFT_TFT_V_RES
#define LCD_PIXELS (LCD_H_RES * LCD_V_RES)

static const char *TAG = "reverse_tft";
static esp_lcd_panel_handle_t s_panel_handle = NULL;
static uint16_t *s_framebuffer = NULL;

static void log_chip_banner(void)
{
    esp_chip_info_t chip_info;
    esp_chip_info(&chip_info);

    uint32_t flash_size = 0;
    esp_flash_get_size(NULL, &flash_size);

    ESP_LOGI(TAG, "ESP32-S3 Reverse TFT Feather heartbeat");
    ESP_LOGI(TAG, "Chip cores: %d, WiFi%s%s, silicon rev %d",
             chip_info.cores,
             (chip_info.features & CHIP_FEATURE_BT) ? ", BT" : "",
             (chip_info.features & CHIP_FEATURE_BLE) ? ", BLE" : "",
             chip_info.revision);
    ESP_LOGI(TAG, "Embedded flash: %lu bytes", (unsigned long)flash_size);
    ESP_LOGI(TAG, "Heartbeat every %d ms on GPIO%d",
             CONFIG_REVTFT_HEARTBEAT_MS,
             CONFIG_REVTFT_LED_GPIO);
    ESP_LOGI(TAG, "TFT: %dx%d @ %d Hz SPI", LCD_H_RES, LCD_V_RES, CONFIG_REVTFT_TFT_SPI_HZ);
}

static void configure_output_gpio(int pin, int level)
{
    if (pin < 0)
    {
        return;
    }

    gpio_config_t cfg = {
        .pin_bit_mask = BIT64(pin),
        .mode = GPIO_MODE_OUTPUT,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .pull_up_en = GPIO_PULLUP_DISABLE,
        .intr_type = GPIO_INTR_DISABLE,
    };
    gpio_config(&cfg);
    gpio_set_level(pin, level);
}

static inline uint16_t rgb565(uint8_t r, uint8_t g, uint8_t b)
{
    return (uint16_t)(((r & 0xF8u) << 8) | ((g & 0xFCu) << 3) | (b >> 3));
}

static void draw_heartbeat_frame(uint32_t heartbeat_count)
{
    const uint8_t phase = (heartbeat_count * 10u) & 0xFFu;
    const uint8_t accent = (heartbeat_count & 0x07u) * 24u;
    const uint16_t wave_color = rgb565(240u, (uint8_t)(40u + accent), (uint8_t)(100u + accent));
    const uint16_t spark_color = rgb565(255u, 255u, 255u);

    for (int y = 0; y < LCD_V_RES; ++y)
    {
        const float lerp = (float)y / (float)(LCD_V_RES - 1);
        const uint8_t base = (uint8_t)(25.0f + lerp * 55.0f);
        const uint8_t r = (uint8_t)(base / 2);
        const uint8_t g = (uint8_t)(base + 30u);
        const uint8_t b = (uint8_t)(base + 60u);
        const uint16_t background = rgb565(r, g, b);
        uint16_t *row = &s_framebuffer[y * LCD_H_RES];
        for (int x = 0; x < LCD_H_RES; ++x)
        {
            row[x] = background;
        }
    }

    for (int x = 0; x < LCD_H_RES; ++x)
    {
        const float radians = (float)x * 0.07f + (float)phase * 0.04f;
        const float normalized = sinf(radians) * 0.45f;
        const int y_center = (int)((normalized + 0.5f) * (float)(LCD_V_RES - 1));
        for (int dy = -3; dy <= 3; ++dy)
        {
            const int row = y_center + dy;
            if (row >= 0 && row < LCD_V_RES)
            {
                s_framebuffer[row * LCD_H_RES + x] = wave_color;
            }
        }
    }

    const int pulse_x = (int)((heartbeat_count * 12u) % LCD_H_RES);
    const int pulse_half_height = LCD_V_RES / 3;
    for (int dx = -3; dx <= 3; ++dx)
    {
        const int column = pulse_x + dx;
        if (column < 0 || column >= LCD_H_RES)
        {
            continue;
        }
        for (int y = 0; y < LCD_V_RES; ++y)
        {
            const int distance = abs(y - (LCD_V_RES / 2));
            if (distance < pulse_half_height)
            {
                s_framebuffer[y * LCD_H_RES + column] = spark_color;
            }
        }
    }
}

static void init_display(void)
{
    configure_output_gpio(CONFIG_REVTFT_TFT_POWER_GPIO, 1);
    configure_output_gpio(CONFIG_REVTFT_TFT_BACKLIGHT_GPIO, 0);

    spi_bus_config_t buscfg = {
        .sclk_io_num = CONFIG_REVTFT_TFT_SCLK_GPIO,
        .mosi_io_num = CONFIG_REVTFT_TFT_MOSI_GPIO,
        .miso_io_num = -1,
        .quadwp_io_num = -1,
        .quadhd_io_num = -1,
        .max_transfer_sz = LCD_PIXELS * sizeof(uint16_t),
    };
    ESP_ERROR_CHECK(spi_bus_initialize(LCD_HOST, &buscfg, SPI_DMA_CH_AUTO));

    esp_lcd_panel_io_spi_config_t io_config = {
        .cs_gpio_num = CONFIG_REVTFT_TFT_CS_GPIO,
        .dc_gpio_num = CONFIG_REVTFT_TFT_DC_GPIO,
        .pclk_hz = CONFIG_REVTFT_TFT_SPI_HZ,
        .lcd_cmd_bits = 8,
        .lcd_param_bits = 8,
        .spi_mode = 0,
        .trans_queue_depth = 10,
        .user_ctx = NULL,
        .on_color_trans_done = NULL,
    };

    esp_lcd_panel_io_handle_t io_handle = NULL;
    ESP_ERROR_CHECK(esp_lcd_new_panel_io_spi((esp_lcd_spi_bus_handle_t)LCD_HOST, &io_config, &io_handle));

    esp_lcd_panel_dev_config_t panel_config = {
        .reset_gpio_num = CONFIG_REVTFT_TFT_RST_GPIO,
        .rgb_ele_order = LCD_RGB_ELEMENT_ORDER_RGB,
        .bits_per_pixel = 16,
    };
    ESP_ERROR_CHECK(esp_lcd_new_panel_st7789(io_handle, &panel_config, &s_panel_handle));

    ESP_ERROR_CHECK(esp_lcd_panel_reset(s_panel_handle));
    ESP_ERROR_CHECK(esp_lcd_panel_init(s_panel_handle));
    ESP_ERROR_CHECK(esp_lcd_panel_invert_color(s_panel_handle, true));
    ESP_ERROR_CHECK(esp_lcd_panel_set_gap(s_panel_handle,
                                          CONFIG_REVTFT_TFT_COL_OFFSET,
                                          CONFIG_REVTFT_TFT_ROW_OFFSET));
    ESP_ERROR_CHECK(esp_lcd_panel_swap_xy(s_panel_handle, true));
    ESP_ERROR_CHECK(esp_lcd_panel_mirror(s_panel_handle, true, false));
    ESP_ERROR_CHECK(esp_lcd_panel_disp_on_off(s_panel_handle, true));

    s_framebuffer = (uint16_t *)heap_caps_malloc(LCD_PIXELS * sizeof(uint16_t), MALLOC_CAP_DMA | MALLOC_CAP_INTERNAL);
    if (s_framebuffer == NULL)
    {
        ESP_LOGE(TAG, "Failed to allocate %d-byte frame buffer", (int)(LCD_PIXELS * sizeof(uint16_t)));
        abort();
    }
    memset(s_framebuffer, 0, LCD_PIXELS * sizeof(uint16_t));

    configure_output_gpio(CONFIG_REVTFT_TFT_BACKLIGHT_GPIO, 1);
}

void app_main(void)
{
    log_chip_banner();
    init_display();

    gpio_config_t io_conf = {
        .pin_bit_mask = BIT64(CONFIG_REVTFT_LED_GPIO),
        .mode = GPIO_MODE_OUTPUT,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .pull_up_en = GPIO_PULLUP_DISABLE,
        .intr_type = GPIO_INTR_DISABLE,
    };
    gpio_config(&io_conf);
    gpio_set_level(CONFIG_REVTFT_LED_GPIO, 0);

    bool led_on = false;
    uint32_t heartbeat_count = 0;

    while (true)
    {
        led_on = !led_on;
        gpio_set_level(CONFIG_REVTFT_LED_GPIO, led_on);
        draw_heartbeat_frame(heartbeat_count);

        esp_err_t draw_err = esp_lcd_panel_draw_bitmap(
            s_panel_handle,
            0,
            0,
            LCD_H_RES,
            LCD_V_RES,
            s_framebuffer);
        if (draw_err != ESP_OK)
        {
            ESP_LOGE(TAG, "draw_bitmap failed: %s", esp_err_to_name(draw_err));
        }

        ESP_LOGI(TAG, "heartbeat %lu", (unsigned long)heartbeat_count++);
        vTaskDelay(pdMS_TO_TICKS(CONFIG_REVTFT_HEARTBEAT_MS));
    }
}
