SELECT 
    product_id,
    ROUND(AVG(qty), 4) AS average_units_picked
FROM picking_line
WHERE order_id = 421
GROUP BY product_id
ORDER BY product_id;