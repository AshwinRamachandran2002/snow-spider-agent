WITH daily_deliveries AS (
    /* deliveries made by each driver on each calendar day */
    SELECT
        d.driver_id,
        o.order_created_year  AS yr,
        o.order_created_month AS mn,
        o.order_created_day   AS dy,
        COUNT(*) AS deliveries_that_day
    FROM deliveries  d
    JOIN orders      o ON o.order_id = d.delivery_order_id
    WHERE d.delivery_status = 'DELIVERED'
      AND o.order_created_year  IS NOT NULL
      AND o.order_created_month IS NOT NULL
      AND o.order_created_day   IS NOT NULL
    GROUP BY
        d.driver_id,
        o.order_created_year,
        o.order_created_month,
        o.order_created_day
),
driver_average AS (
    /* average daily deliveries for each driver */
    SELECT
        driver_id,
        AVG(deliveries_that_day) AS avg_daily_deliveries
    FROM daily_deliveries
    GROUP BY driver_id
)
SELECT
    driver_id,
    avg_daily_deliveries
FROM driver_average
ORDER BY
    avg_daily_deliveries DESC,
    driver_id            ASC
LIMIT 5;