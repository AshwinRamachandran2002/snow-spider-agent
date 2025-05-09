WITH daily_counts AS (
    SELECT  d."driver_id",
            o."order_created_year",
            o."order_created_month",
            o."order_created_day",
            COUNT(*) AS daily_deliveries
    FROM    "deliveries" AS d
    JOIN    "orders"     AS o
           ON d."delivery_order_id" = o."delivery_order_id"
    WHERE   o."order_status" = 'FINISHED'
      AND   d."driver_id" IS NOT NULL
      AND   d."driver_id" <> ''
    GROUP BY d."driver_id",
             o."order_created_year",
             o."order_created_month",
             o."order_created_day"
),
avg_per_driver AS (
    SELECT  "driver_id",
            ROUND(AVG(daily_deliveries), 4) AS avg_daily_deliveries
    FROM    daily_counts
    GROUP BY "driver_id"
)
SELECT  "driver_id",
        avg_daily_deliveries
FROM    avg_per_driver
ORDER BY avg_daily_deliveries DESC
LIMIT 5;