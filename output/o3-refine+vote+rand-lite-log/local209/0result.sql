WITH store_order_counts AS (
    /* count total orders per store */
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
    /* pick the store with the most orders */
    SELECT
        store_id,
        store_name,
        total_orders
    FROM store_order_counts
    ORDER BY total_orders DESC, store_id       -- tie‑breaker on id
    LIMIT 1
),
delivered_counts AS (
    /* count how many of that store’s orders are in deliveries with status = 'DELIVERED' */
    SELECT
        t.store_id,
        COUNT(d.delivery_id) AS delivered_orders
    FROM top_store AS t
    JOIN orders AS o
        ON o.store_id = t.store_id
    LEFT JOIN deliveries AS d
        ON d.delivery_order_id = o.order_id
       AND d.delivery_status = 'DELIVERED'
    GROUP BY t.store_id
)
SELECT
    t.store_name,
    t.total_orders,
    dc.delivered_orders,
    ROUND(CAST(dc.delivered_orders AS REAL) / t.total_orders, 4) AS delivered_to_total_ratio
FROM top_store AS t
JOIN delivered_counts AS dc
    ON dc.store_id = t.store_id;