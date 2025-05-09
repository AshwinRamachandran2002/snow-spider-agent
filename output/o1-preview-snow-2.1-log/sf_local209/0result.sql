SELECT
  CAST("store_id" AS INT) AS "Store_ID",
  ROUND(COUNT(CASE WHEN "order_status" = 'FINISHED' THEN 1 END)::FLOAT / COUNT("order_id"), 4) AS "Completion_Ratio"
FROM "DELIVERY_CENTER"."DELIVERY_CENTER"."ORDERS"
WHERE "store_id" = (
    SELECT "store_id"
    FROM "DELIVERY_CENTER"."DELIVERY_CENTER"."ORDERS"
    GROUP BY "store_id"
    ORDER BY COUNT("order_id") DESC NULLS LAST
    LIMIT 1
)
GROUP BY "store_id";