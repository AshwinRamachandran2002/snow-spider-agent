SELECT
    s.store_name,
    ROUND(1.0 * SUM(CASE WHEN d.delivery_status = 'DELIVERED' THEN 1 ELSE 0 END) 
          / COUNT(*), 4) AS delivered_to_total_ratio
FROM orders   AS o
JOIN stores   AS s ON s.store_id = o.store_id
LEFT JOIN deliveries AS d ON d.delivery_order_id = o.delivery_order_id
GROUP BY s.store_id, s.store_name
ORDER BY COUNT(*) DESC, s.store_id          -- store with most orders
LIMIT 1;