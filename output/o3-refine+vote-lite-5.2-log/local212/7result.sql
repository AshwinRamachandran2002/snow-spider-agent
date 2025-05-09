WITH driver_daily AS (
    SELECT
        d.driver_id,
        o.order_created_year,
        o.order_created_month,
        o.order_created_day,
        COUNT(*) AS daily_deliveries
    FROM deliveries d
    JOIN orders o
      ON o.order_id = d.delivery_order_id
    GROUP BY
        d.driver_id,
        o.order_created_year,
        o.order_created_month,
        o.order_created_day
),
driver_avg AS (
    SELECT
        driver_id,
        AVG(daily_deliveries) AS avg_daily_deliveries
    FROM driver_daily
    GROUP BY driver_id
)
SELECT
    driver_id,
    ROUND(avg_daily_deliveries, 4) AS avg_daily_deliveries
FROM driver_avg
ORDER BY
    avg_daily_deliveries DESC,
    driver_id ASC
LIMIT 5;