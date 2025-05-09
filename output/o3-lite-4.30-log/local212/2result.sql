WITH daily AS (
    SELECT
        d.driver_id,
        DATE(o.order_moment_delivered) AS delivery_date,
        COUNT(*) AS deliveries_on_day
    FROM deliveries AS d
    JOIN orders AS o
      ON o.order_id = d.delivery_order_id
    WHERE d.delivery_status = 'DELIVERED'
      AND o.order_status = 'FINISHED'
      AND o.order_moment_delivered IS NOT NULL
      AND d.driver_id IS NOT NULL
    GROUP BY d.driver_id,
             DATE(o.order_moment_delivered)
),
avg_daily AS (
    SELECT
        driver_id,
        AVG(deliveries_on_day) AS average_daily_deliveries
    FROM daily
    GROUP BY driver_id
)
SELECT
    driver_id,
    ROUND(average_daily_deliveries, 4) AS average_daily_deliveries
FROM avg_daily
ORDER BY average_daily_deliveries DESC, driver_id
LIMIT 5;