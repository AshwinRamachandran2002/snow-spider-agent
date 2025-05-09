WITH delivered_orders AS (
    SELECT  d."driver_id",
            o."order_created_year",
            o."order_created_month",
            o."order_created_day"
    FROM    "deliveries" AS d
    JOIN    "orders"     AS o
           ON o."delivery_order_id" = d."delivery_order_id"
    WHERE   o."order_moment_delivered" IS NOT NULL
            AND d."driver_id" IS NOT NULL
),
totals AS (
    SELECT  "driver_id",
            COUNT(*) AS "total_deliveries"
    FROM    delivered_orders
    GROUP   BY "driver_id"
),
days AS (
    SELECT  "driver_id",
            COUNT(
                  DISTINCT printf('%04d-%02d-%02d',
                                  "order_created_year",
                                  "order_created_month",
                                  "order_created_day")
                 ) AS "active_days"
    FROM    delivered_orders
    GROUP   BY "driver_id"
)
SELECT  t."driver_id",
        t."total_deliveries",
        d."active_days",
        ROUND(1.0 * t."total_deliveries" / d."active_days", 4) AS "avg_daily_deliveries"
FROM    totals AS t
JOIN    days   AS d
       ON t."driver_id" = d."driver_id"
ORDER BY "avg_daily_deliveries" DESC
LIMIT 5;