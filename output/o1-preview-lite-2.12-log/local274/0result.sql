SELECT pl.product_id,
       p.name AS product_name,
       ROUND(SUM(pl.qty) / COUNT(DISTINCT i.purchase_id), 4) AS average_units_picked_per_batch
FROM picking_line pl
JOIN products p ON pl.product_id = p.id
JOIN inventory i ON pl.location_id = i.location_id AND pl.product_id = i.product_id
WHERE pl.order_id = 421
GROUP BY pl.product_id, p.name;