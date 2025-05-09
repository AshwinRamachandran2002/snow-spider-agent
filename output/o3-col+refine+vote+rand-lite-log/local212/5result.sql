WITH "daily_counts" AS (
    SELECT
        d."driver_id",
        o."order_created_year",
        o."order_created_month",
        o."order_created_day",
        COUNT(*) AS "daily_deliveries"
    FROM "deliveries" d
    JOIN "orders" o
      ON o."delivery_order_id" = d."delivery_order_id"
    WHERE d."delivery_status" = 'DELIVERED'
      AND d."driver_id" IS NOT NULL          -- ignore rows without a driver
    GROUP BY
        d."driver_id",
        o."order_created_year",
        o."order_created_month",
        o."order_created_day"
),
"avg_per_driver" AS (
    SELECT
        "driver_id",
        AVG("daily_deliveries") AS "avg_daily_deliveries"
    FROM "daily_counts"
    GROUP BY "driver_id"
)
SELECT
    "driver_id",
    ROUND("avg_daily_deliveries", 4) AS "avg_daily_deliveries"
FROM "avg_per_driver"
ORDER BY "avg_daily_deliveries" DESC
LIMIT 5;