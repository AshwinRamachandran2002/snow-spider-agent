WITH driver_stats AS (
    SELECT
        d."driver_id",
        COUNT(*) AS total_deliveries,
        COUNT(
            DISTINCT printf('%04d-%02d-%02d',
                            o."order_created_year",
                            o."order_created_month",
                            o."order_created_day")
        ) AS active_days
    FROM "deliveries" d
    JOIN "orders" o
      ON o."order_id" = d."delivery_order_id"
    WHERE d."delivery_status" = 'DELIVERED'
      AND d."driver_id" IS NOT NULL
      AND CAST(d."driver_id" AS TEXT) <> ''
    GROUP BY d."driver_id"
),
driver_avg AS (
    SELECT
        "driver_id",
        ROUND(1.0 * total_deliveries / active_days, 4) AS average_daily_deliveries
    FROM driver_stats
    WHERE active_days > 0
)
SELECT
    "driver_id",
    average_daily_deliveries
FROM driver_avg
ORDER BY average_daily_deliveries DESC,
         "driver_id"
LIMIT 5;