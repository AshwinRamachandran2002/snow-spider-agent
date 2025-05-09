WITH store_order_counts AS (
    SELECT
        s.store_id,
        s.store_name,
        COUNT(o.order_id) AS total_orders
    FROM orders o
    JOIN stores s ON s.store_id = o.store_id
    GROUP BY s.store_id, s.store_name
),
top_store AS (
    SELECT
        store_id,
        store_name,
        total_orders
    FROM store_order_counts
    ORDER BY total_orders DESC, store_id          -- tie‑breaker on id
    LIMIT 1
),
delivered_counts AS (
    SELECT
        ts.store_id,
        COUNT(*) AS delivered_orders
    FROM top_store ts
    JOIN orders o           ON o.store_id         = ts.store_id
    JOIN deliveries d       ON d.delivery_order_id = o.delivery_order_id
    WHERE d.delivery_status = 'DELIVERED'
)
SELECT
    ts.store_name,
    ts.total_orders,
    COALESCE(dc.delivered_orders, 0) AS delivered_orders,
    ROUND(
        COALESCE(dc.delivered_orders, 0) * 1.0 / ts.total_orders,
        4
    ) AS delivered_to_total_ratio
FROM top_store ts
LEFT JOIN delivered_counts dc USING (store_id);