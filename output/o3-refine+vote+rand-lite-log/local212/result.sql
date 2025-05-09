WITH driver_daily AS (
    SELECT
        d.driver_id,
        printf('%04d-%02d-%02d',
               o.order_created_year,
               o.order_created_month,
               o.order_created_day) AS delivery_date,
        COUNT(*) AS deliveries_count
    FROM deliveries AS d
    JOIN orders     AS o ON o.order_id = d.delivery_order_id
    WHERE d.delivery_status = 'DELIVERED'          -- consider only completed deliveries
    GROUP BY d.driver_id,
             delivery_date
),
driver_avg AS (
    SELECT
        driver_id,
        AVG(deliveries_count) AS avg_daily_deliveries
    FROM driver_daily
    GROUP BY driver_id
)
SELECT
    driver_id,
    ROUND(avg_daily_deliveries, 4) AS avg_daily_deliveries
FROM driver_avg
ORDER BY avg_daily_deliveries DESC,  -- highest average first
         driver_id                   -- tie‑breaker
LIMIT 5;