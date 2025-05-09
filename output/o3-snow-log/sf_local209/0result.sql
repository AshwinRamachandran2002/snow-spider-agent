/* 1) Find the store with the largest number of orders
   2) For that store calculate how many of its orders have a matching record
      in DELIVERIES with status = 'DELIVERED'
   3) Return the ratio delivered / total                                                  */
WITH total_orders_per_store AS (       -- total orders for every store
    SELECT 
        o."store_id",
        COUNT(*) AS "total_orders"
    FROM DELIVERY_CENTER.DELIVERY_CENTER."ORDERS" o
    GROUP BY o."store_id"
),
top_store AS (                         -- the store with the highest number of orders
    SELECT 
        "store_id",
        "total_orders"
    FROM total_orders_per_store
    ORDER BY "total_orders" DESC NULLS LAST
    LIMIT 1
),
delivered_orders_top_store AS (        -- delivered orders for that store
    SELECT 
        o."store_id",
        COUNT(*) AS "delivered_orders"
    FROM DELIVERY_CENTER.DELIVERY_CENTER."ORDERS"     o
    JOIN DELIVERY_CENTER.DELIVERY_CENTER."DELIVERIES" d
         ON o."delivery_order_id" = d."delivery_order_id"
    WHERE d."delivery_status" = 'DELIVERED'
      AND o."store_id" IN (SELECT "store_id" FROM top_store)
    GROUP BY o."store_id"
)
SELECT 
    ts."store_id",
    s."store_name",
    ts."total_orders",
    COALESCE(dts."delivered_orders",0) AS "delivered_orders",
    ROUND( COALESCE(dts."delivered_orders",0) / ts."total_orders", 4 ) AS "delivered_to_total_ratio"
FROM top_store                     ts
LEFT JOIN delivered_orders_top_store dts ON dts."store_id" = ts."store_id"
LEFT JOIN DELIVERY_CENTER.DELIVERY_CENTER."STORES" s   ON s."store_id" = ts."store_id";