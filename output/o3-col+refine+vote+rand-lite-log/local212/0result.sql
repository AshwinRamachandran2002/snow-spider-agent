WITH daily_deliveries AS (
    SELECT
        dl."driver_id",
        o."order_created_year",
        o."order_created_month",
        o."order_created_day",
        COUNT(*) AS deliveries_per_day
    FROM "deliveries" AS dl
    JOIN "orders"      AS o ON o."order_id" = dl."delivery_order_id"
    WHERE dl."delivery_status" = 'DELIVERED'
      AND dl."driver_id" IS NOT NULL
    GROUP BY
        dl."driver_id",
        o."order_created_year",
        o."order_created_month",
        o."order_created_day"
),
driver_averages AS (
    SELECT
        driver_id,
        AVG(deliveries_per_day) AS avg_daily_deliveries
    FROM daily_deliveries
    GROUP BY driver_id
)
SELECT
    driver_id,
    ROUND(avg_daily_deliveries, 2) AS avg_daily_deliveries
FROM driver_averages
ORDER BY avg_daily_deliveries DESC
LIMIT 5;