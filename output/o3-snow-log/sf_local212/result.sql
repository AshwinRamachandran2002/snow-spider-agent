WITH delivered AS (
    SELECT
        d."driver_id",
        TO_DATE( 
            o."order_created_year" || '-' || 
            LPAD(o."order_created_month"::VARCHAR, 2, '0') || '-' || 
            LPAD(o."order_created_day"::VARCHAR , 2, '0')
        ) AS "delivery_date"
    FROM DELIVERY_CENTER.DELIVERY_CENTER.DELIVERIES d
    JOIN DELIVERY_CENTER.DELIVERY_CENTER.ORDERS     o
      ON d."delivery_order_id" = o."order_id"
    WHERE d."delivery_status" = 'DELIVERED'
      AND d."driver_id" IS NOT NULL
),  

daily_counts AS (
    SELECT
        "driver_id",
        "delivery_date",
        COUNT(*) AS "deliveries_per_day"
    FROM delivered
    GROUP BY
        "driver_id",
        "delivery_date"
),  

average_daily AS (
    SELECT
        "driver_id",
        AVG("deliveries_per_day") AS "avg_daily_deliveries"
    FROM daily_counts
    GROUP BY
        "driver_id"
)  

SELECT
    "driver_id",
    ROUND("avg_daily_deliveries", 4) AS "avg_daily_deliveries"
FROM average_daily
ORDER BY
    "avg_daily_deliveries" DESC NULLS LAST
LIMIT 5;