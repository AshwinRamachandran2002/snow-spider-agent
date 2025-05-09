WITH "daily_counts" AS (
    SELECT
        d."driver_id",
        DATE_FROM_PARTS(o."order_created_year",
                        o."order_created_month",
                        o."order_created_day") AS "order_date",
        COUNT(*) AS "deliveries_per_day"
    FROM DELIVERY_CENTER.DELIVERY_CENTER.DELIVERIES             d
    JOIN DELIVERY_CENTER.DELIVERY_CENTER.ORDERS                 o
          ON d."delivery_order_id" = o."delivery_order_id"
    WHERE d."driver_id" IS NOT NULL
      AND d."delivery_status" = 'DELIVERED'
    GROUP BY
        d."driver_id",
        DATE_FROM_PARTS(o."order_created_year",
                        o."order_created_month",
                        o."order_created_day")
),
"avg_daily" AS (
    SELECT
        "driver_id",
        AVG("deliveries_per_day") AS "avg_daily_deliveries"
    FROM "daily_counts"
    GROUP BY "driver_id"
)
SELECT
    a."driver_id",
    dvr."driver_modal",
    dvr."driver_type",
    a."avg_daily_deliveries"
FROM "avg_daily"                                   a
LEFT JOIN DELIVERY_CENTER.DELIVERY_CENTER.DRIVERS dvr
       ON a."driver_id" = dvr."driver_id"
ORDER BY a."avg_daily_deliveries" DESC NULLS LAST
LIMIT 5;