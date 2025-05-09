WITH daily_deliveries AS (
    SELECT
        dl.driver_id,
        o.order_created_year,
        o.order_created_month,
        o.order_created_day,
        COUNT(*) AS deliveries_that_day
    FROM deliveries AS dl
    JOIN orders AS o
        ON o.order_id = dl.delivery_order_id
    WHERE dl.delivery_status = 'DELIVERED'
      AND dl.driver_id IS NOT NULL
    GROUP BY
        dl.driver_id,
        o.order_created_year,
        o.order_created_month,
        o.order_created_day
),
avg_per_driver AS (
    SELECT
        driver_id,
        AVG(deliveries_that_day) AS average_daily_deliveries
    FROM daily_deliveries
    GROUP BY driver_id
)
SELECT
    driver_id,
    ROUND(average_daily_deliveries, 4) AS average_daily_deliveries
FROM avg_per_driver
ORDER BY average_daily_deliveries DESC,
         driver_id
LIMIT 5;