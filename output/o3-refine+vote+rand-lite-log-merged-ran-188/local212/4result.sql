WITH daily_counts AS (
    SELECT
        d.driver_id,
        o.order_created_year  AS yr,
        o.order_created_month AS mn,
        o.order_created_day   AS dy,
        COUNT(*)              AS deliveries_in_day
    FROM deliveries AS d
    JOIN orders      AS o ON o.order_id = d.delivery_order_id
    WHERE d.delivery_status = 'DELIVERED'          -- consider only completed deliveries
    GROUP BY d.driver_id, yr, mn, dy
),
driver_avg AS (
    SELECT
        driver_id,
        AVG(deliveries_in_day) AS avg_daily_deliveries
    FROM daily_counts
    GROUP BY driver_id
)
SELECT
    da.driver_id,
    dr.driver_modal,
    dr.driver_type,
    ROUND(da.avg_daily_deliveries, 4) AS avg_daily_deliveries
FROM driver_avg AS da
LEFT JOIN drivers AS dr ON dr.driver_id = da.driver_id
ORDER BY da.avg_daily_deliveries DESC, da.driver_id
LIMIT 5;