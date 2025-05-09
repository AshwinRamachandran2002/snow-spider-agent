WITH store_counts AS (
    SELECT 
        o.store_id,
        s.store_name,
        COUNT(*) AS total_orders
    FROM orders o
    JOIN stores s ON s.store_id = o.store_id
    GROUP BY o.store_id
),
top_store AS (
    SELECT 
        store_id,
        store_name,
        total_orders
    FROM store_counts
    ORDER BY total_orders DESC, store_id ASC
    LIMIT 1
),
delivered_counts AS (
    SELECT 
        ts.store_id,
        COUNT(d.delivery_id) AS delivered_orders
    FROM top_store ts
    JOIN orders o
        ON o.store_id = ts.store_id
    LEFT JOIN deliveries d
        ON d.delivery_order_id = o.delivery_order_id
       AND d.delivery_status = 'DELIVERED'
    GROUP BY ts.store_id
)
SELECT
    ts.store_name,
    ts.total_orders,
    dc.delivered_orders,
    ROUND(CAST(dc.delivered_orders AS REAL) / ts.total_orders, 4) AS delivered_ratio
FROM top_store ts
JOIN delivered_counts dc
  ON dc.store_id = ts.store_id;