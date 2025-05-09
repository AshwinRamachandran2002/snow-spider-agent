SELECT
    "store_id",
    ROUND(
        COUNT(CASE WHEN "order_status" = 'FINISHED' THEN 1 END) * 1.0 / COUNT("order_id"), 4
    ) AS "Completion_Ratio"
FROM "DELIVERY_CENTER"."DELIVERY_CENTER"."ORDERS"
WHERE "store_id" = (
    SELECT "store_id"
    FROM "DELIVERY_CENTER"."DELIVERY_CENTER"."ORDERS"
    GROUP BY "store_id"
    ORDER BY COUNT("order_id") DESC NULLS LAST
    LIMIT 1
)
GROUP BY "store_id";