WITH RECURSIVE
months(mth) AS (
    SELECT '2019-01-01' AS mth
    UNION ALL
    SELECT date(mth, '+1 month') FROM months WHERE mth < '2019-12-01'
),
initial_products AS (
    SELECT pm.product_id, pm.qty_minimum, pm.qty_purchase
    FROM product_minimums pm
),
initial_inventory AS (
    SELECT i.product_id, COALESCE(SUM(i.qty), 0) AS initial_inventory
    FROM inventory i
    GROUP BY i.product_id
),
sales_data AS (
    SELECT ms.product_id, ms.mth, SUM(ms.qty) AS sales_qty
    FROM monthly_sales ms
    WHERE ms.mth BETWEEN '2019-01-01' AND '2019-12-01'
    GROUP BY ms.product_id, ms.mth
),
inventory_cte AS (
    -- Initial step for each product in January 2019
    SELECT
        p.product_id,
        '2019-01-01' AS mth,
        COALESCE(ii.initial_inventory, 0) AS inventory,
        COALESCE(s.sales_qty, 0) AS sales_qty,
        -- Calculate inventory after sales
        COALESCE(ii.initial_inventory, 0) - COALESCE(s.sales_qty, 0) AS inventory_after_sales,
        -- Determine restocked quantity
        CASE
            WHEN (COALESCE(ii.initial_inventory, 0) - COALESCE(s.sales_qty, 0)) < p.qty_minimum
            THEN p.qty_purchase
            ELSE 0
        END AS restocked_qty,
        -- Inventory after restocking
        (COALESCE(ii.initial_inventory, 0) - COALESCE(s.sales_qty, 0)) + CASE
            WHEN (COALESCE(ii.initial_inventory, 0) - COALESCE(s.sales_qty, 0)) < p.qty_minimum
            THEN p.qty_purchase
            ELSE 0
        END AS inventory_after_restock,
        -- Calculate difference from minimum required level
        ((COALESCE(ii.initial_inventory, 0) - COALESCE(s.sales_qty, 0)) + CASE
            WHEN (COALESCE(ii.initial_inventory, 0) - COALESCE(s.sales_qty, 0)) < p.qty_minimum
            THEN p.qty_purchase
            ELSE 0
        END) - p.qty_minimum AS difference
    FROM initial_products p
    LEFT JOIN initial_inventory ii ON ii.product_id = p.product_id
    LEFT JOIN sales_data s ON s.product_id = p.product_id AND s.mth = '2019-01-01'

    UNION ALL

    -- Recursive step for subsequent months
    SELECT
        ic.product_id,
        date(ic.mth, '+1 month') AS mth,
        ic.inventory_after_restock AS inventory,
        COALESCE(s.sales_qty, 0) AS sales_qty,
        -- Inventory after subtracting sales
        ic.inventory_after_restock - COALESCE(s.sales_qty, 0) AS inventory_after_sales,
        -- Determine restocked quantity
        CASE
            WHEN (ic.inventory_after_restock - COALESCE(s.sales_qty, 0)) < p.qty_minimum
            THEN p.qty_purchase
            ELSE 0
        END AS restocked_qty,
        -- Inventory after restocking
        (ic.inventory_after_restock - COALESCE(s.sales_qty, 0)) + CASE
            WHEN (ic.inventory_after_restock - COALESCE(s.sales_qty, 0)) < p.qty_minimum
            THEN p.qty_purchase
            ELSE 0
        END AS inventory_after_restock,
        -- Calculate difference from minimum required level
        ((ic.inventory_after_restock - COALESCE(s.sales_qty, 0)) + CASE
            WHEN (ic.inventory_after_restock - COALESCE(s.sales_qty, 0)) < p.qty_minimum
            THEN p.qty_purchase
            ELSE 0
        END) - p.qty_minimum AS difference
    FROM inventory_cte ic
    JOIN months m ON m.mth = date(ic.mth, '+1 month') AND m.mth <= '2019-12-01'
    JOIN initial_products p ON p.product_id = ic.product_id
    LEFT JOIN sales_data s ON s.product_id = ic.product_id AND s.mth = m.mth
)
SELECT
    t.product_id,
    t.month_in_2019,
    ROUND(t.smallest_difference, 4) AS smallest_difference
FROM (
    SELECT
        product_id,
        mth AS month_in_2019,
        difference AS smallest_difference,
        ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY difference ASC, mth) AS rn
    FROM inventory_cte
    WHERE mth BETWEEN '2019-01-01' AND '2019-12-01'
    -- Ensure difference is calculated correctly
) t
WHERE t.rn = 1;