WITH joined AS (
    SELECT
        d."driver_id",
        o."order_created_year",
        o."order_created_month",
        o."order_created_day"
    FROM DELIVERY_CENTER.DELIVERY_CENTER.DELIVERIES d
    JOIN DELIVERY_CENTER.DELIVERY_CENTER.ORDERS o
      ON d."delivery_order_id" = o."delivery_order_id"
    WHERE d."driver_id" IS NOT NULL
),
daily_counts AS (
    SELECT
        "driver_id",
        "order_created_year",
        "order_created_month",
        "order_created_day",
        COUNT(*) AS "deliveries_per_day"
    FROM joined
    GROUP BY
        "driver_id",
        "order_created_year",
        "order_created_month",
        "order_created_day"
),
avg_deliveries AS (
    SELECT
        "driver_id",
        AVG("deliveries_per_day") AS "avg_daily_deliveries"
    FROM daily_counts
    GROUP BY "driver_id"
)
SELECT
    "driver_id",
    "avg_daily_deliveries"
FROM avg_deliveries
ORDER BY "avg_daily_deliveries" DESC NULLS LAST
LIMIT 5;