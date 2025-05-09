WITH top_store AS (
    /* 1. Identify the store with the highest number of orders */
    SELECT 
        o."store_id",
        COUNT(o."order_id") AS "total_orders"
    FROM "DELIVERY_CENTER"."DELIVERY_CENTER"."ORDERS" o
    GROUP BY o."store_id"
    ORDER BY "total_orders" DESC NULLS LAST
    LIMIT 1
)
SELECT
    ts."store_id",
    s."store_name",
    ts."total_orders",
    /* 2. Count how many of those orders have at least one delivery row with status = 'DELIVERED' */
    COUNT(DISTINCT CASE WHEN d."delivery_status" = 'DELIVERED' THEN o."order_id" END) AS "delivered_orders",
    /* 3. Compute the delivered-to-total ratio */
    COUNT(DISTINCT CASE WHEN d."delivery_status" = 'DELIVERED' THEN o."order_id" END)
    / NULLIF(ts."total_orders", 0) AS "delivered_to_total_ratio"
FROM "DELIVERY_CENTER"."DELIVERY_CENTER"."ORDERS"      o
JOIN top_store                                         ts ON o."store_id"           = ts."store_id"
LEFT JOIN "DELIVERY_CENTER"."DELIVERY_CENTER"."DELIVERIES" d 
       ON o."delivery_order_id" = d."delivery_order_id"
LEFT JOIN "DELIVERY_CENTER"."DELIVERY_CENTER"."STORES"     s 
       ON ts."store_id"         = s."store_id"
GROUP BY
    ts."store_id",
    s."store_name",
    ts."total_orders";