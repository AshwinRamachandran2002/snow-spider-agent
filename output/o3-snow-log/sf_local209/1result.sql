WITH top_store AS (
    /* 1. Identify the store with the highest total number of orders */
    SELECT 
        o."store_id",
        COUNT(*) AS "total_orders"
    FROM DELIVERY_CENTER.DELIVERY_CENTER."ORDERS" o
    GROUP BY o."store_id"
    ORDER BY "total_orders" DESC NULLS LAST
    LIMIT 1
),
delivered_counts AS (
    /* 2. Count how many of that store’s orders appear in DELIVERIES with status = 'DELIVERED' */
    SELECT
        ts."store_id",
        COUNT(*) AS "delivered_orders"
    FROM top_store ts
    JOIN DELIVERY_CENTER.DELIVERY_CENTER."ORDERS" o
      ON o."store_id" = ts."store_id"
    JOIN DELIVERY_CENTER.DELIVERY_CENTER."DELIVERIES" d
      ON o."delivery_order_id" = d."delivery_order_id"
     AND d."delivery_status" = 'DELIVERED'
    GROUP BY ts."store_id"
)
SELECT
    ts."store_id",
    s."store_name",
    ts."total_orders",
    dc."delivered_orders",
    ROUND(dc."delivered_orders" / ts."total_orders", 4) AS "delivered_ratio"
FROM top_store ts
LEFT JOIN delivered_counts dc
  ON ts."store_id" = dc."store_id"
LEFT JOIN DELIVERY_CENTER.DELIVERY_CENTER."STORES" s
  ON ts."store_id" = s."store_id";