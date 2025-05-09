WITH store_stats AS (
    SELECT
        o.store_id,
        s.store_name,
        COUNT(*) AS total_orders,
        SUM(CASE WHEN d.delivery_status = 'DELIVERED' THEN 1 ELSE 0 END) AS delivered_orders
    FROM orders AS o
    JOIN stores      AS s ON s.store_id = o.store_id
    LEFT JOIN deliveries AS d
           ON d.delivery_order_id = o.delivery_order_id
          AND d.delivery_status   = 'DELIVERED'
    GROUP BY o.store_id, s.store_name
),
top_store AS (
    SELECT *
    FROM store_stats
    ORDER BY total_orders DESC
    LIMIT 1
)
SELECT
    store_id,
    store_name,
    ROUND(CAST(delivered_orders AS FLOAT) / total_orders, 4) AS delivered_ratio
FROM top_store;