SELECT "driver_id", ROUND(AVG("daily_deliveries"), 4) AS "average_daily_deliveries"
FROM (
    SELECT D."driver_id",
           CAST(TO_TIMESTAMP(O."order_moment_created", 'MM/DD/YYYY HH12:MI:SS AM') AS DATE) AS "order_date",
           COUNT(*) AS "daily_deliveries"
    FROM DELIVERY_CENTER.DELIVERY_CENTER.DELIVERIES D
    JOIN DELIVERY_CENTER.DELIVERY_CENTER.ORDERS O
      ON D."delivery_order_id" = O."delivery_order_id"
    WHERE D."driver_id" IS NOT NULL
      AND D."delivery_order_id" IS NOT NULL
      AND O."order_moment_created" IS NOT NULL
    GROUP BY D."driver_id", "order_date"
) AS daily_counts
GROUP BY "driver_id"
ORDER BY "average_daily_deliveries" DESC NULLS LAST
LIMIT 5;