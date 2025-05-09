WITH orders_per_store AS (
    SELECT
        o.store_id,
        s.store_name,
        COUNT(*) AS total_orders
    FROM orders AS o
    JOIN stores AS s
        ON s.store_id = o.store_id
    GROUP BY o.store_id
),
top_store AS (
    SELECT
        store_id,
        store_name,
        total_orders
    FROM orders_per_store
    ORDER BY total_orders DESC, store_id
    LIMIT 1
),
delivered_cnt AS (
    SELECT
        ts.store_id,
        COUNT(*) AS delivered_orders
    FROM top_store AS ts
    JOIN orders AS o
        ON o.store_id = ts.store_id
    JOIN deliveries AS d
        ON d.delivery_order_id = o.delivery_order_id
    WHERE d.delivery_status = 'DELIVERED'
)
SELECT
    ts.store_name,
    ROUND( COALESCE(dc.delivered_orders, 0) * 1.0 / ts.total_orders , 4 ) AS delivered_ratio
FROM top_store AS ts
LEFT JOIN delivered_cnt AS dc
    ON dc.store_id = ts.store_id;