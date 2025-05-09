WITH delivered AS (
    SELECT 
        d."driver_id",
        /* take the part before the first blank to represent the calendar day */
        substr(o."order_moment_delivered", 1, instr(o."order_moment_delivered", ' ') - 1) AS "delivered_date"
    FROM "deliveries" AS d
    JOIN "orders"     AS o
         ON d."delivery_order_id" = o."delivery_order_id"
    WHERE d."delivery_status" = 'DELIVERED'
      AND o."order_moment_delivered" IS NOT NULL
      AND d."driver_id" IS NOT NULL
),
daily_counts AS (
    SELECT
        "driver_id",
        "delivered_date",
        COUNT(*) AS "daily_deliveries"
    FROM delivered
    GROUP BY "driver_id", "delivered_date"
),
avg_daily AS (
    SELECT
        "driver_id",
        ROUND(AVG("daily_deliveries"), 2) AS "avg_daily_deliveries"
    FROM daily_counts
    GROUP BY "driver_id"
)
SELECT
    "driver_id",
    "avg_daily_deliveries"
FROM avg_daily
ORDER BY "avg_daily_deliveries" DESC
LIMIT 5;