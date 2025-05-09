WITH months(mth) AS (
    SELECT '2019-01-01' AS mth
    UNION ALL
    SELECT date(mth, '+1 month') FROM months WHERE mth < '2019-12-01'
),
monthly_data AS (
    SELECT
        pm.product_id,
        m.mth,
        pm.qty_minimum,
        pm.qty_purchase,
        COALESCE(ms.qty, 0) AS sales_qty
    FROM
        product_minimums pm
    CROSS JOIN months m
    LEFT JOIN monthly_sales ms ON pm.product_id = ms.product_id AND ms.mth = m.mth
),
inventory AS (
    SELECT
        md.product_id,
        md.mth,
        md.qty_minimum,
        md.qty_purchase,
        md.sales_qty,
        md.qty_minimum + md.qty_purchase AS beginning_inventory,
        (md.qty_minimum + md.qty_purchase) - md.sales_qty AS ending_inventory_before_restock,
        CASE WHEN ((md.qty_minimum + md.qty_purchase) - md.sales_qty) < md.qty_minimum THEN md.qty_purchase ELSE 0 END AS restock_qty,
        ((md.qty_minimum + md.qty_purchase) - md.sales_qty) + CASE WHEN ((md.qty_minimum + md.qty_purchase) - md.sales_qty) < md.qty_minimum THEN md.qty_purchase ELSE 0 END AS ending_inventory,
        ((md.qty_minimum + md.qty_purchase) - md.sales_qty) - md.qty_minimum AS difference
    FROM
        monthly_data md
    WHERE md.mth = '2019-01-01'
    
    UNION ALL
    
    SELECT
        md.product_id,
        md.mth,
        md.qty_minimum,
        md.qty_purchase,
        md.sales_qty,
        inv.ending_inventory AS beginning_inventory,
        inv.ending_inventory - md.sales_qty AS ending_inventory_before_restock,
        CASE WHEN (inv.ending_inventory - md.sales_qty) < md.qty_minimum THEN md.qty_purchase ELSE 0 END AS restock_qty,
        (inv.ending_inventory - md.sales_qty) + CASE WHEN (inv.ending_inventory - md.sales_qty) < md.qty_minimum THEN md.qty_purchase ELSE 0 END AS ending_inventory,
        (inv.ending_inventory - md.sales_qty) - md.qty_minimum AS difference
    FROM
        inventory inv
    JOIN monthly_data md ON inv.product_id = md.product_id AND date(inv.mth, '+1 month') = md.mth
)
SELECT
    product_id,
    month_in_2019,
    ROUND(min_difference, 4) AS smallest_difference
FROM (
    SELECT
        product_id,
        mth AS month_in_2019,
        MIN(difference) AS min_difference
    FROM
        inventory
    WHERE
        mth BETWEEN '2019-01-01' AND '2019-12-01'
    GROUP BY
        product_id, mth
)
GROUP BY
    product_id
ORDER BY
    product_id;