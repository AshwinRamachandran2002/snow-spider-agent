WITH deliveries_per_day AS (
    SELECT 
        D."driver_id",
        DATE_FROM_PARTS(O."order_created_year",
                         O."order_created_month",
                         O."order_created_day")            AS "order_date"
    FROM DELIVERY_CENTER.DELIVERY_CENTER.DELIVERIES D
    JOIN DELIVERY_CENTER.DELIVERY_CENTER.ORDERS     O
      ON D."delivery_order_id" = O."order_id"
    WHERE D."delivery_status" = 'DELIVERED'
      AND D."driver_id" IS NOT NULL
),
daily_driver_counts AS (
    SELECT
        "driver_id",
        "order_date",
        COUNT(*)                                        AS daily_deliveries
    FROM deliveries_per_day
    GROUP BY "driver_id", "order_date"
),
avg_daily_deliveries AS (
    SELECT
        "driver_id",
        AVG(daily_deliveries)                           AS avg_daily_deliveries
    FROM daily_driver_counts
    GROUP BY "driver_id"
)
SELECT
    "driver_id",
    ROUND(avg_daily_deliveries, 4) AS avg_daily_deliveries
FROM avg_daily_deliveries
ORDER BY avg_daily_deliveries DESC NULLS LAST
LIMIT 5;