WITH store_counts AS (
    SELECT 
        o."store_id",
        COUNT(*) AS total_orders,
        SUM(CASE WHEN d."delivery_status" = 'DELIVERED' THEN 1 ELSE 0 END) AS delivered_orders
    FROM "orders" AS o
    LEFT JOIN "deliveries" AS d
           ON d."delivery_order_id" = o."delivery_order_id"
    GROUP BY o."store_id"
),
top_store AS (
    SELECT *
    FROM store_counts
    ORDER BY total_orders DESC
    LIMIT 1
)
SELECT 
    s."store_name",
    ts.total_orders,
    ts.delivered_orders,
    ROUND(1.0 * ts.delivered_orders / ts.total_orders, 4) AS delivered_ratio
FROM top_store AS ts
JOIN "stores" AS s
     ON s."store_id" = ts."store_id";