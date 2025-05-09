WITH order_counts AS (
    /* 1. Count total orders per store */
    SELECT 
        o.store_id,
        COUNT(*) AS total_orders
    FROM orders AS o
    GROUP BY o.store_id
),
max_store AS (
    /* 2. Pick the store with the highest number of orders */
    SELECT 
        store_id,
        total_orders
    FROM order_counts
    ORDER BY total_orders DESC, store_id          -- tie‑breaker by store_id
    LIMIT 1
),
delivered_count AS (
    /* 3. Count how many of that store’s orders were delivered */
    SELECT 
        COUNT(*) AS delivered_orders
    FROM orders       AS o
    JOIN deliveries   AS d ON d.delivery_order_id = o.delivery_order_id
    JOIN max_store    AS m ON m.store_id = o.store_id
    WHERE d.delivery_status = 'DELIVERED'
)
SELECT
    s.store_name,
    m.total_orders,
    d.delivered_orders,
    ROUND(1.0 * d.delivered_orders / m.total_orders, 4) AS delivered_to_total_ratio
FROM max_store       AS m
JOIN stores          AS s ON s.store_id = m.store_id
JOIN delivered_count AS d;