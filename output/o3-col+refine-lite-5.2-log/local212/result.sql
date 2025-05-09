WITH daily_deliveries AS (
    SELECT
        d."driver_id",
        substr(o."order_moment_delivered", 1, instr(o."order_moment_delivered", ' ') - 1) AS "delivery_date",
        COUNT(*) AS "daily_count"
    FROM "deliveries" AS d
    JOIN "orders"     AS o
         ON d."delivery_order_id" = o."order_id"
    WHERE o."order_moment_delivered" IS NOT NULL
      AND d."driver_id" IS NOT NULL
      AND d."driver_id" <> ''
    GROUP BY
        d."driver_id",
        "delivery_date"
),
avg_per_driver AS (
    SELECT
        "driver_id",
        AVG("daily_count") AS "avg_daily_deliveries"
    FROM daily_deliveries
    GROUP BY "driver_id"
)
SELECT
    "driver_id",
    "avg_daily_deliveries"
FROM avg_per_driver
ORDER BY
    "avg_daily_deliveries" DESC,
    "driver_id" ASC
LIMIT 5;