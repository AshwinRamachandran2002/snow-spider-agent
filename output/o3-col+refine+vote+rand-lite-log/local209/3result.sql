WITH total_per_store AS (          -- total orders for every store
    SELECT 
        o."store_id",
        COUNT(*) AS total_orders
    FROM "orders" AS o
    GROUP BY o."store_id"
),
top_store AS (                     -- pick the store with the most orders
    SELECT 
        store_id
    FROM total_per_store
    ORDER BY total_orders DESC
    LIMIT 1
)
SELECT
    s."store_name",
    tps.total_orders,
    SUM(CASE WHEN d."delivery_status" = 'DELIVERED' THEN 1 ELSE 0 END)                 AS delivered_orders,
    ROUND(1.0 * SUM(CASE WHEN d."delivery_status" = 'DELIVERED' THEN 1 ELSE 0 END)
          / tps.total_orders, 4)                                                       AS delivered_ratio
FROM            "orders"     AS o
JOIN            top_store    AS ts  ON ts."store_id"      = o."store_id"
JOIN            "stores"     AS s   ON s."store_id"       = o."store_id"
JOIN            total_per_store tps ON tps."store_id"     = o."store_id"
LEFT JOIN       "deliveries"  AS d   ON d."delivery_order_id" = o."delivery_order_id"
GROUP BY        s."store_name", tps.total_orders;