/* Minimal sanity check application: blink the status LED and log */

#include <zephyr/kernel.h>
#include <zephyr/logging/log.h>
#include <zephyr/drivers/gpio.h>

LOG_MODULE_REGISTER(main);

static const struct gpio_dt_spec led = GPIO_DT_SPEC_GET(DT_ALIAS(led0), gpios);

int main(void) {
    k_msleep(2000); /* allow USB serial to enumerate */

    LOG_INF("Starting Sanity Check App");

    if (!gpio_is_ready_dt(&led)) {
        LOG_ERR("LED not ready");
        return 0;
    }
    gpio_pin_configure_dt(&led, GPIO_OUTPUT_ACTIVE);

    while (1) {
        gpio_pin_toggle_dt(&led);
        LOG_INF("Blink");
        k_msleep(1000);
    }

    return 0;
}
