WITH store_order_counts AS (  -- count total orders per store
    SELECT 
        s."store_id",
        s."store_name",
        COUNT(o."order_id") AS "total_orders"
    FROM DELIVERY_CENTER.DELIVERY_CENTER.ORDERS   o
    JOIN DELIVERY_CENTER.DELIVERY_CENTER.STORES   s
          ON o."store_id" = s."store_id"
    GROUP BY s."store_id", s."store_name"
), 

top_store AS (                -- pick the store with the highest order count
    SELECT *
    FROM store_order_counts
    ORDER BY "total_orders" DESC NULLS LAST
    LIMIT 1
),

top_store_stats AS (          -- for that store, count delivered-status orders
    SELECT 
        ts."store_id",
        ts."store_name",
        ts."total_orders",
        COUNT(DISTINCT CASE 
                          WHEN d."delivery_status" = 'DELIVERED' 
                          THEN o."order_id" 
                     END)           AS "delivered_orders"
    FROM top_store                         ts
    JOIN DELIVERY_CENTER.DELIVERY_CENTER.ORDERS      o
          ON o."store_id" = ts."store_id"
    LEFT JOIN DELIVERY_CENTER.DELIVERY_CENTER.DELIVERIES d
           ON o."delivery_order_id" = d."delivery_order_id"
    GROUP BY ts."store_id", ts."store_name", ts."total_orders"
)

SELECT
    "store_id",
    "store_name",
    "total_orders",
    "delivered_orders",
    ROUND("delivered_orders"::FLOAT / NULLIF("total_orders",0), 4) 
        AS "delivered_to_total_ratio"
FROM top_store_stats;