WITH delivered AS (
    SELECT
        de.driver_id,
        DATE(or1.order_moment_delivered) AS delivered_date
    FROM deliveries        AS de
    JOIN orders            AS or1 ON or1.order_id = de.delivery_order_id
    WHERE de.delivery_status = 'DELIVERED'
      AND or1.order_moment_delivered IS NOT NULL
),
daily_totals AS (
    SELECT
        driver_id,
        delivered_date,
        COUNT(*) AS deliveries_per_day
    FROM delivered
    GROUP BY driver_id, delivered_date
),
average_daily AS (
    SELECT
        driver_id,
        AVG(deliveries_per_day) AS avg_daily_deliveries
    FROM daily_totals
    GROUP BY driver_id
)
SELECT
    driver_id,
    ROUND(avg_daily_deliveries, 4) AS avg_daily_deliveries
FROM average_daily
ORDER BY avg_daily_deliveries DESC,
         driver_id
LIMIT 5;