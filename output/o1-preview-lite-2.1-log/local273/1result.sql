WITH
total_ordered AS (
    SELECT product_id, SUM(qty) AS total_qty_ordered
    FROM orderlines
    GROUP BY product_id
),
total_picked AS (
    SELECT product_id, SUM(qty) AS total_qty_picked
    FROM picking_line
    GROUP BY product_id
),
total_inventory AS (
    SELECT product_id, SUM(qty) AS total_inventory_qty
    FROM inventory
    GROUP BY product_id
),
overlapping_qty AS (
    SELECT toq.product_id,
           toq.total_qty_ordered,
           tiv.total_inventory_qty,
           MIN(toq.total_qty_ordered, tiv.total_inventory_qty) AS overlapping_qty
    FROM total_ordered toq
    JOIN total_inventory tiv ON toq.product_id = tiv.product_id
)
SELECT p.name AS Product_Name,
       ROUND(
           (MIN(COALESCE(tp.total_qty_picked, 0), oq.overlapping_qty) * 100.0 / oq.total_qty_ordered), 4
       ) AS Average_Pick_Percentage
FROM products p
JOIN overlapping_qty oq ON p.id = oq.product_id
LEFT JOIN total_picked tp ON p.id = tp.product_id
GROUP BY p.id, p.name;