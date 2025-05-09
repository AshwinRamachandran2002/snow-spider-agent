WITH "daily_deliveries" AS (
    /* deliveries done by each driver on each calendar day */
    SELECT
        d."driver_id",
        /* build the calendar date using the separated year / month / day columns */
        TO_DATE(
            TO_CHAR(o."order_created_year") || '-' ||
            LPAD(o."order_created_month", 2, '0') || '-' ||
            LPAD(o."order_created_day",   2, '0'),
            'YYYY-MM-DD'
        )                                                    AS "delivery_date",
        COUNT(d."delivery_id")                               AS "deliveries_per_day"
    FROM DELIVERY_CENTER.DELIVERY_CENTER.DELIVERIES d
    JOIN DELIVERY_CENTER.DELIVERY_CENTER.ORDERS     o
          ON d."delivery_order_id" = o."order_id"
    WHERE d."driver_id" IS NOT NULL
    GROUP BY d."driver_id",
             TO_DATE(
                 TO_CHAR(o."order_created_year") || '-' ||
                 LPAD(o."order_created_month", 2, '0') || '-' ||
                 LPAD(o."order_created_day",   2, '0'),
                 'YYYY-MM-DD'
             )
),
"avg_deliveries_per_driver" AS (
    /* average daily deliveries for each driver */
    SELECT
        "driver_id",
        AVG("deliveries_per_day") AS "avg_daily_deliveries"
    FROM "daily_deliveries"
    GROUP BY "driver_id"
)
SELECT
    "driver_id",
    "avg_daily_deliveries"
FROM "avg_deliveries_per_driver"
ORDER BY "avg_daily_deliveries" DESC NULLS LAST
LIMIT 5;