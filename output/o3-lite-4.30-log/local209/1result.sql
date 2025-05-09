WITH total AS (
    SELECT store_id,
           COUNT(*) AS total_orders
    FROM orders
    GROUP BY store_id
    ORDER BY total_orders DESC
    LIMIT 1
),
delivered AS (
    SELECT o.store_id,
           COUNT(DISTINCT o.order_id) AS delivered_orders
    FROM orders      AS o
    JOIN deliveries  AS d
         ON d.delivery_order_id = o.delivery_order_id
    WHERE d.delivery_status = 'DELIVERED'
      AND o.store_id = (SELECT store_id FROM total)
    GROUP BY o.store_id
)
SELECT t.store_id,
       ROUND(1.0 * COALESCE(d.delivered_orders, 0) / t.total_orders, 4) AS delivered_to_total_ratio
FROM total     AS t
LEFT JOIN delivered AS d ON d.store_id = t.store_id;