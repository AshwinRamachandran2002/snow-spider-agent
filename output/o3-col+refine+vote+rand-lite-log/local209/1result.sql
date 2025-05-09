WITH top_store AS (
    SELECT 
        o."store_id",
        s."store_name",
        COUNT(*) AS total_orders
    FROM "orders" AS o
    JOIN "stores" AS s
      ON o."store_id" = s."store_id"
    GROUP BY o."store_id", s."store_name"
    ORDER BY total_orders DESC
    LIMIT 1
)
SELECT
    ts."store_id",
    ts."store_name",
    ts.total_orders,
    SUM(CASE WHEN d."delivery_status" = 'DELIVERED' THEN 1 ELSE 0 END) AS delivered_orders,
    ROUND(1.0 * SUM(CASE WHEN d."delivery_status" = 'DELIVERED' THEN 1 ELSE 0 END) / ts.total_orders, 4) AS delivered_ratio
FROM "orders"      AS o
JOIN top_store     AS ts ON o."store_id" = ts."store_id"
LEFT JOIN "deliveries" AS d
       ON o."delivery_order_id" = d."delivery_order_id"
GROUP BY ts."store_id", ts."store_name", ts.total_orders;