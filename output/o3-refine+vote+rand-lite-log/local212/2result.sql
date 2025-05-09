WITH driver_day_count AS (
    -- how many deliveries each driver made per calendar day
    SELECT 
        d.driver_id,
        o.order_created_year  AS yr,
        o.order_created_month AS mo,
        o.order_created_day   AS dy,
        COUNT(*)              AS deliveries_count
    FROM deliveries AS d
    JOIN orders     AS o
          ON o.delivery_order_id = d.delivery_order_id
    WHERE d.delivery_status = 'DELIVERED'        -- consider only completed deliveries
    GROUP BY d.driver_id,
             o.order_created_year,
             o.order_created_month,
             o.order_created_day
),
driver_avg AS (
    -- average daily deliveries for every driver
    SELECT
        driver_id,
        AVG(deliveries_count) AS avg_daily_deliveries
    FROM driver_day_count
    GROUP BY driver_id
)
SELECT
    da.driver_id,
    dr.driver_modal,
    dr.driver_type,
    ROUND(da.avg_daily_deliveries, 2) AS avg_daily_deliveries
FROM driver_avg AS da
LEFT JOIN drivers AS dr
       ON dr.driver_id = da.driver_id
ORDER BY da.avg_daily_deliveries DESC,
         da.driver_id                -- tie‑breaker
LIMIT 5;