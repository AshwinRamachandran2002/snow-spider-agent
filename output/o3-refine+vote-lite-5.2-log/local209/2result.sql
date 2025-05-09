WITH store_stats AS (
    SELECT
        s.store_id,
        s.store_name,
        COUNT(*) AS total_orders,
        COUNT(d.delivery_id) AS delivered_orders
    FROM orders  AS o
    JOIN stores  AS s ON s.store_id = o.store_id
    LEFT JOIN deliveries AS d
           ON d.delivery_order_id = o.delivery_order_id
          AND d.delivery_status   = 'DELIVERED'
    GROUP BY s.store_id, s.store_name
),
top_store AS (
    SELECT *
    FROM store_stats
    ORDER BY total_orders DESC, store_id
    LIMIT 1
)
SELECT
    store_name,
    total_orders,
    delivered_orders,
    CAST(delivered_orders AS REAL) / total_orders AS delivered_to_total_ratio
FROM top_store;