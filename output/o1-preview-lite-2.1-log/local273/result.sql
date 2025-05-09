WITH total_orders AS (
    SELECT product_id, SUM(qty) AS total_ordered_qty
    FROM orderlines
    GROUP BY product_id
),
inventory_ordered AS (
    SELECT
        i.product_id,
        i.qty AS inventory_qty,
        p.purchased
    FROM inventory i
    JOIN purchases p ON i.purchase_id = p.id
),
inventory_cumsum AS (
    SELECT
        inv.product_id,
        inv.inventory_qty,
        inv.purchased,
        SUM(inv.inventory_qty) OVER (
            PARTITION BY inv.product_id
            ORDER BY inv.purchased, inv.inventory_qty
            ROWS UNBOUNDED PRECEDING
        ) AS cumulative_inventory_qty
    FROM inventory_ordered inv
),
inventory_picked AS (
    SELECT
        ic.product_id,
        ic.inventory_qty,
        ic.cumulative_inventory_qty,
        tot_ord.total_ordered_qty,
        CASE
            WHEN ic.cumulative_inventory_qty <= tot_ord.total_ordered_qty THEN ic.inventory_qty
            WHEN ic.cumulative_inventory_qty - ic.inventory_qty < tot_ord.total_ordered_qty THEN tot_ord.total_ordered_qty - (ic.cumulative_inventory_qty - ic.inventory_qty)
            ELSE 0
        END AS picked_qty
    FROM inventory_cumsum ic
    JOIN total_orders tot_ord ON ic.product_id = tot_ord.product_id
),
total_picked AS (
    SELECT
        product_id,
        SUM(picked_qty) AS total_picked_qty
    FROM inventory_picked
    GROUP BY product_id
),
product_pick_percentage AS (
    SELECT
        pr.name AS Product_Name,
        (CAST(tp.total_picked_qty AS REAL) / tot_ord.total_ordered_qty) * 100 AS Average_Pick_Percentage
    FROM total_orders tot_ord
    JOIN total_picked tp ON tot_ord.product_id = tp.product_id
    JOIN products pr ON tot_ord.product_id = pr.id
)
SELECT
    Product_Name,
    ROUND(Average_Pick_Percentage, 4) AS Average_Pick_Percentage
FROM product_pick_percentage;