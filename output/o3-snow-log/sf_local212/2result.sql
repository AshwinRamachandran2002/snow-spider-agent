WITH "BASE" AS (
    SELECT
        D."driver_id",
        DATE_FROM_PARTS(O."order_created_year",
                        O."order_created_month",
                        O."order_created_day") AS "order_date"
    FROM DELIVERY_CENTER.DELIVERY_CENTER.DELIVERIES D
    JOIN DELIVERY_CENTER.DELIVERY_CENTER.ORDERS     O
      ON D."delivery_order_id" = O."delivery_order_id"
    WHERE D."driver_id" IS NOT NULL
),
"DAILY_COUNTS" AS (
    SELECT
        "driver_id",
        "order_date",
        COUNT(*) AS "deliveries_per_day"
    FROM "BASE"
    GROUP BY
        "driver_id",
        "order_date"
),
"AVERAGE_PER_DRIVER" AS (
    SELECT
        "driver_id",
        ROUND(AVG("deliveries_per_day"), 4) AS "avg_daily_deliveries"
    FROM "DAILY_COUNTS"
    GROUP BY
        "driver_id"
)
SELECT
    "driver_id",
    "avg_daily_deliveries"
FROM "AVERAGE_PER_DRIVER"
ORDER BY
    "avg_daily_deliveries" DESC NULLS LAST
LIMIT 5;