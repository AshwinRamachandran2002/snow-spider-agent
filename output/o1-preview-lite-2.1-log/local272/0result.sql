SELECT
    il.product_id,
    l.aisle,
    l.position,
    MIN(ol.qty, il.qty) AS quantity_to_pick
FROM orderlines ol
JOIN inventory il ON ol.product_id = il.product_id
JOIN locations l ON il.location_id = l.id
JOIN purchases p ON il.purchase_id = p.id
WHERE ol.order_id = 423
  AND l.warehouse = 1
  AND il.qty > 0
ORDER BY p.purchased ASC, il.qty ASC
LIMIT 1;