WITH "daily_counts" AS (
    SELECT
        CAST(d."driver_id" AS NUMBER)                                        AS "driver_id",
        TO_DATE(
            CONCAT(
                o."order_created_year", '-',
                LPAD(o."order_created_month", 2, '0'), '-',
                LPAD(o."order_created_day",   2, '0')
            )
        )                                                                    AS "delivery_date",
        COUNT(*)                                                             AS "deliveries_count"
    FROM DELIVERY_CENTER.DELIVERY_CENTER.DELIVERIES AS d
    JOIN DELIVERY_CENTER.DELIVERY_CENTER.ORDERS     AS o
      ON d."delivery_order_id" = o."delivery_order_id"
    WHERE d."delivery_status" = 'DELIVERED'
      AND d."driver_id" IS NOT NULL
    GROUP BY
        CAST(d."driver_id" AS NUMBER),
        TO_DATE(
            CONCAT(
                o."order_created_year", '-',
                LPAD(o."order_created_month", 2, '0'), '-',
                LPAD(o."order_created_day",   2, '0')
            )
        )
),
"driver_avg" AS (
    SELECT
        "driver_id",
        AVG("deliveries_count") AS "avg_daily_deliveries"
    FROM "daily_counts"
    GROUP BY "driver_id"
)
SELECT
    "driver_id",
    ROUND("avg_daily_deliveries", 4) AS "avg_daily_deliveries"
FROM "driver_avg"
ORDER BY "avg_daily_deliveries" DESC NULLS LAST
LIMIT 5;