WITH RECURSIVE inventory_simulation AS (
    -- Anchor member: select initial inventory level per product at '2019-01-01'
    SELECT
        pm.product_id,
        mb.mth,
        inv.total_inventory AS starting_inventory,
        pm.qty_minimum,
        pm.qty_purchase,
        mb.qty AS sales_qty,
        inv.total_inventory - mb.qty AS ending_inventory_before_restock,
        CASE WHEN (inv.total_inventory - mb.qty) < pm.qty_minimum THEN 1 ELSE 0 END AS needs_restock,
        CASE WHEN (inv.total_inventory - mb.qty) < pm.qty_minimum THEN (inv.total_inventory - mb.qty) + pm.qty_purchase ELSE (inv.total_inventory - mb.qty) END AS ending_inventory,
        ((CASE WHEN (inv.total_inventory - mb.qty) < pm.qty_minimum THEN (inv.total_inventory - mb.qty) + pm.qty_purchase ELSE (inv.total_inventory - mb.qty) END) - pm.qty_minimum) AS difference
    FROM "product_minimums" pm
    JOIN (
        SELECT product_id, SUM(qty) AS total_inventory
        FROM "inventory"
        GROUP BY product_id
    ) inv ON pm.product_id = inv.product_id
    JOIN "monthly_budget" mb ON pm.product_id = mb.product_id
    WHERE mb.mth = '2019-01-01'

    UNION ALL

    -- Recursive member: process next months
    SELECT
        pm.product_id,
        mb_next.mth,
        isim.ending_inventory AS starting_inventory,
        pm.qty_minimum,
        pm.qty_purchase,
        mb_next.qty AS sales_qty,
        isim.ending_inventory - mb_next.qty AS ending_inventory_before_restock,
        CASE WHEN (isim.ending_inventory - mb_next.qty) < pm.qty_minimum THEN 1 ELSE 0 END AS needs_restock,
        CASE WHEN (isim.ending_inventory - mb_next.qty) < pm.qty_minimum THEN (isim.ending_inventory - mb_next.qty) + pm.qty_purchase ELSE (isim.ending_inventory - mb_next.qty) END AS ending_inventory,
        ((CASE WHEN (isim.ending_inventory - mb_next.qty) < pm.qty_minimum THEN (isim.ending_inventory - mb_next.qty) + pm.qty_purchase ELSE (isim.ending_inventory - mb_next.qty) END) - pm.qty_minimum) AS difference
    FROM inventory_simulation isim
    JOIN "product_minimums" pm ON isim.product_id = pm.product_id
    JOIN "monthly_budget" mb_next ON pm.product_id = mb_next.product_id AND mb_next.mth = date(isim.mth, '+1 month')
    WHERE mb_next.mth BETWEEN '2019-02-01' AND '2019-12-01'
)

SELECT "product_id", mth AS "month_in_2019", ROUND(difference, 4) AS "smallest_difference"
FROM (
    SELECT product_id, mth, difference,
    ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY difference ASC, mth ASC) AS rn
    FROM inventory_simulation
    WHERE mth BETWEEN '2019-01-01' AND '2019-12-01'
)
WHERE rn = 1
ORDER BY product_id;