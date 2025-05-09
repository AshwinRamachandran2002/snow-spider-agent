WITH "deliveries_per_day" AS (
    SELECT
        D."driver_id",
        DATE_FROM_PARTS(O."order_created_year",
                        O."order_created_month",
                        O."order_created_day")         AS "delivery_date",
        COUNT(*)                                       AS "daily_deliveries"
    FROM DELIVERY_CENTER.DELIVERY_CENTER.DELIVERIES D
    JOIN DELIVERY_CENTER.DELIVERY_CENTER.ORDERS     O
          ON D."delivery_order_id" = O."delivery_order_id"
    WHERE D."driver_id" IS NOT NULL
      AND D."delivery_status" = 'DELIVERED'
    GROUP BY
        D."driver_id",
        DATE_FROM_PARTS(O."order_created_year",
                        O."order_created_month",
                        O."order_created_day")
),
"driver_avg" AS (
    SELECT
        "driver_id",
        AVG("daily_deliveries") AS "avg_daily_deliveries"
    FROM "deliveries_per_day"
    GROUP BY
        "driver_id"
)
SELECT
    "driver_id",
    ROUND("avg_daily_deliveries", 4) AS "avg_daily_deliveries"
FROM "driver_avg"
ORDER BY
    "avg_daily_deliveries" DESC NULLS LAST
LIMIT 5;