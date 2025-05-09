WITH order_totals AS (               -- total number of orders per store
    SELECT
        o."store_id",
        s."store_name",
        COUNT(*) AS "total_orders"
    FROM DELIVERY_CENTER.DELIVERY_CENTER."ORDERS"  o
    LEFT JOIN DELIVERY_CENTER.DELIVERY_CENTER."STORES" s
           ON o."store_id" = s."store_id"
    GROUP BY o."store_id", s."store_name"
),
top_store AS (                       -- keep only the store with the highest total_orders
    SELECT *
    FROM order_totals
    ORDER BY "total_orders" DESC NULLS LAST
    LIMIT 1
),
delivered_totals AS (                -- number of delivered orders for every store
    SELECT
        o."store_id",
        COUNT(*) AS "delivered_orders"
    FROM DELIVERY_CENTER.DELIVERY_CENTER."ORDERS"      o
    JOIN DELIVERY_CENTER.DELIVERY_CENTER."DELIVERIES"  d
          ON o."delivery_order_id" = d."delivery_order_id"
    WHERE d."delivery_status" = 'DELIVERED'
    GROUP BY o."store_id"
)
SELECT
    t."store_id",
    t."store_name",
    t."total_orders",
    COALESCE(d."delivered_orders", 0)               AS "delivered_orders",
    COALESCE(d."delivered_orders", 0) / t."total_orders"::FLOAT AS "delivered_ratio"
FROM top_store t
LEFT JOIN delivered_totals d
       ON t."store_id" = d."store_id";