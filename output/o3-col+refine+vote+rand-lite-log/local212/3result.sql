WITH driver_daily AS (
    SELECT
        d."driver_id",
        o."order_created_year",
        o."order_created_month",
        o."order_created_day",
        COUNT(*) AS daily_deliveries
    FROM "deliveries" d
    JOIN "orders" o
      ON o."order_id" = d."delivery_order_id"
    WHERE d."driver_id" IS NOT NULL            -- ignore records without a driver
    GROUP BY
        d."driver_id",
        o."order_created_year",
        o."order_created_month",
        o."order_created_day"
),
driver_avg AS (
    SELECT
        driver_id,
        AVG(daily_deliveries) AS avg_deliveries_per_day
    FROM driver_daily
    GROUP BY driver_id
)
SELECT
    driver_id,
    ROUND(avg_deliveries_per_day, 4) AS avg_daily_deliveries
FROM driver_avg
ORDER BY avg_deliveries_per_day DESC
LIMIT 5;