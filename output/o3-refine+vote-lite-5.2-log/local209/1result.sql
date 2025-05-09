WITH store_order_counts AS (
    SELECT 
        s.store_id,
        s.store_name,
        COUNT(o.order_id) AS total_orders
    FROM orders AS o
    JOIN stores AS s
        ON o.store_id = s.store_id
    GROUP BY s.store_id, s.store_name
),
top_store AS (
    /* store with the highest total number of orders */
    SELECT 
        store_id,
        store_name,
        total_orders
    FROM store_order_counts
    ORDER BY total_orders DESC, store_id
    LIMIT 1
),
delivered_orders AS (
    /* how many of that store's orders were delivered */
    SELECT
        t.store_id,
        COUNT(DISTINCT o.order_id) AS delivered_orders
    FROM top_store AS t
    JOIN orders AS o
        ON o.store_id = t.store_id
    JOIN deliveries AS d
        ON d.delivery_order_id = o.delivery_order_id
    WHERE d.delivery_status = 'DELIVERED'
)
SELECT
    ts.store_name,
    CAST(COALESCE(do.delivered_orders,0) AS FLOAT) /
    CAST(ts.total_orders AS FLOAT)            AS delivered_to_total_ratio
FROM top_store  AS ts
LEFT JOIN delivered_orders AS do
    ON do.store_id = ts.store_id;