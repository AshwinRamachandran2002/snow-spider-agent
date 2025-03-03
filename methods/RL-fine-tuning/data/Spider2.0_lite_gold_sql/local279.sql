WITH RECURSIVE
starting_inventory AS (
  SELECT
    pm.product_id,
    (IFNULL(pt.total_purchased, 0) - IFNULL(st.total_sold, 0)) AS starting_inventory,
    pm.qty_minimum,
    pm.qty_purchase
  FROM product_minimums pm
  LEFT JOIN (
    SELECT product_id, SUM(qty) AS total_purchased
    FROM purchases
    WHERE purchased <= '2018-12-31'
    GROUP BY product_id
  ) pt ON pm.product_id = pt.product_id
  LEFT JOIN (
    SELECT product_id, SUM(qty) AS total_sold
    FROM monthly_sales
    WHERE mth <= '2018-12-01'
    GROUP BY product_id
  ) st ON pm.product_id = st.product_id
),
inventory(product_id, mth, beginning_inventory, sales_qty, ending_inventory_before_restocking, restocked_qty, ending_inventory_after_restocking, qty_minimum, qty_purchase) AS (
  -- Base case for January 2019
  SELECT
    si.product_id,
    '2019-01-01' AS mth,
    si.starting_inventory AS beginning_inventory,
    IFNULL(ms.qty, 0) AS sales_qty,
    si.starting_inventory - IFNULL(ms.qty, 0) AS ending_inventory_before_restocking,
    CASE WHEN si.starting_inventory - IFNULL(ms.qty, 0) < si.qty_minimum THEN si.qty_purchase ELSE 0 END AS restocked_qty,
    (si.starting_inventory - IFNULL(ms.qty, 0)) + CASE WHEN si.starting_inventory - IFNULL(ms.qty, 0) < si.qty_minimum THEN si.qty_purchase ELSE 0 END AS ending_inventory_after_restocking,
    si.qty_minimum,
    si.qty_purchase
  FROM starting_inventory si
  LEFT JOIN monthly_sales ms ON si.product_id = ms.product_id AND ms.mth = '2019-01-01'
  UNION ALL
  -- Recursive computation for subsequent months
  SELECT
    inv.product_id,
    date(inv.mth, '+1 month') AS mth,
    inv.ending_inventory_after_restocking AS beginning_inventory,
    IFNULL(ms.qty, 0) AS sales_qty,
    inv.ending_inventory_after_restocking - IFNULL(ms.qty, 0) AS ending_inventory_before_restocking,
    CASE WHEN inv.ending_inventory_after_restocking - IFNULL(ms.qty, 0) < inv.qty_minimum THEN inv.qty_purchase ELSE 0 END AS restocked_qty,
    (inv.ending_inventory_after_restocking - IFNULL(ms.qty, 0)) + CASE WHEN inv.ending_inventory_after_restocking - IFNULL(ms.qty, 0) < inv.qty_minimum THEN inv.qty_purchase ELSE 0 END AS ending_inventory_after_restocking,
    inv.qty_minimum,
    inv.qty_purchase
  FROM inventory inv
  LEFT JOIN monthly_sales ms ON inv.product_id = ms.product_id AND ms.mth = date(inv.mth, '+1 month')
  WHERE inv.mth < '2019-12-01'
)
SELECT
  product_id,
  SUBSTR(mth, 1, 7) AS month,
  ROUND(ABS(ending_inventory_after_restocking - qty_minimum), 4) AS absolute_difference
FROM (
  SELECT
    i.product_id,
    i.mth,
    i.ending_inventory_after_restocking,
    i.qty_minimum,
    ROW_NUMBER() OVER (PARTITION BY i.product_id ORDER BY ABS(i.ending_inventory_after_restocking - i.qty_minimum) ASC, i.mth) AS rn
  FROM inventory i
)
WHERE rn = 1;