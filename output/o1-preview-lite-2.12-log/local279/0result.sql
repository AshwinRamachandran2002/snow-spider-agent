WITH RECURSIVE
starting_inventory AS (
  SELECT
    product_id,
    SUM(qty) AS inventory
  FROM inventory
  WHERE product_id IN (SELECT product_id FROM product_minimums)
  GROUP BY product_id
),
inventory_per_month(product_id, mth, prev_inventory, curr_inventory) AS (
  -- Base case: January 2019
  SELECT
    si.product_id,
    '2019-01-01' AS mth,
    si.inventory AS prev_inventory,
    CASE
      WHEN (si.inventory - COALESCE(s.qty, 0)) < pm.qty_minimum THEN
        si.inventory - COALESCE(s.qty, 0) + pm.qty_purchase
      ELSE
        si.inventory - COALESCE(s.qty, 0)
    END AS curr_inventory
  FROM starting_inventory si
  LEFT JOIN monthly_sales s ON si.product_id = s.product_id AND s.mth = '2019-01-01'
  JOIN product_minimums pm ON si.product_id = pm.product_id

  UNION ALL

  -- Recursive step for subsequent months
  SELECT
    ipm.product_id,
    date(ipm.mth, '+1 month') AS mth,
    ipm.curr_inventory AS prev_inventory,
    CASE
      WHEN (ipm.curr_inventory - COALESCE(s.qty, 0)) < pm.qty_minimum THEN
        ipm.curr_inventory - COALESCE(s.qty, 0) + pm.qty_purchase
      ELSE
        ipm.curr_inventory - COALESCE(s.qty, 0)
    END AS curr_inventory
  FROM inventory_per_month ipm
  LEFT JOIN monthly_sales s ON ipm.product_id = s.product_id AND s.mth = date(ipm.mth, '+1 month')
  JOIN product_minimums pm ON ipm.product_id = pm.product_id
  WHERE ipm.mth < '2019-12-01'
),
min_diff AS (
  SELECT
    ipm.product_id,
    MIN(ABS(ipm.curr_inventory - pm.qty_minimum)) AS min_absolute_difference
  FROM inventory_per_month ipm
  JOIN product_minimums pm ON ipm.product_id = pm.product_id
  GROUP BY ipm.product_id
)
SELECT
  ipm.product_id,
  substr(ipm.mth, 1, 7) AS month,
  ROUND(ABS(ipm.curr_inventory - pm.qty_minimum), 4) AS absolute_difference
FROM inventory_per_month ipm
JOIN product_minimums pm ON ipm.product_id = pm.product_id
JOIN min_diff md ON ipm.product_id = md.product_id
WHERE ABS(ipm.curr_inventory - pm.qty_minimum) = md.min_absolute_difference
ORDER BY ipm.product_id;