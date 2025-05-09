WITH RECURSIVE
months(mth) AS (
  SELECT '2019-01-01'
  UNION ALL
  SELECT date(mth, '+1 month')
  FROM months
  WHERE mth < '2019-12-01'
),
initial_inventory AS (
  SELECT pm.product_id, pm.qty_minimum, pm.qty_purchase, SUM(i.qty) AS initial_inventory
  FROM product_minimums pm
  JOIN inventory i ON pm.product_id = i.product_id
  GROUP BY pm.product_id
),
inventory_calculation AS (
  SELECT
    ii.product_id,
    m.mth,
    ii.initial_inventory AS start_inventory,
    ii.initial_inventory - COALESCE(ms.qty, 0) AS end_inventory_before_restock,
    CASE
      WHEN ii.initial_inventory - COALESCE(ms.qty, 0) < ii.qty_minimum
      THEN ii.initial_inventory - COALESCE(ms.qty, 0) + ii.qty_purchase
      ELSE ii.initial_inventory - COALESCE(ms.qty, 0)
    END AS end_inventory,
    ii.qty_minimum,
    ii.qty_purchase,
    ABS(
      (CASE
        WHEN ii.initial_inventory - COALESCE(ms.qty, 0) < ii.qty_minimum
        THEN ii.initial_inventory - COALESCE(ms.qty, 0) + ii.qty_purchase
        ELSE ii.initial_inventory - COALESCE(ms.qty, 0)
      END) - ii.qty_minimum
    ) AS abs_difference
  FROM initial_inventory ii
  JOIN months m ON m.mth = '2019-01-01'
  LEFT JOIN monthly_sales ms ON ms.product_id = ii.product_id AND ms.mth = m.mth

  UNION ALL

  SELECT
    ic.product_id,
    date(ic.mth, '+1 month') AS mth,
    ic.end_inventory AS start_inventory,
    ic.end_inventory - COALESCE(ms.qty, 0) AS end_inventory_before_restock,
    CASE
      WHEN ic.end_inventory - COALESCE(ms.qty, 0) < ic.qty_minimum
      THEN ic.end_inventory - COALESCE(ms.qty, 0) + ic.qty_purchase
      ELSE ic.end_inventory - COALESCE(ms.qty, 0)
    END AS end_inventory,
    ic.qty_minimum,
    ic.qty_purchase,
    ABS(
      (CASE
        WHEN ic.end_inventory - COALESCE(ms.qty, 0) < ic.qty_minimum
        THEN ic.end_inventory - COALESCE(ms.qty, 0) + ic.qty_purchase
        ELSE ic.end_inventory - COALESCE(ms.qty, 0)
      END) - ic.qty_minimum
    ) AS abs_difference
  FROM inventory_calculation ic
  JOIN months m ON m.mth = date(ic.mth, '+1 month')
  LEFT JOIN monthly_sales ms ON ms.product_id = ic.product_id AND ms.mth = m.mth
  WHERE ic.mth < '2019-12-01'
)
SELECT product_id, substr(mth, 1, 7) AS month, ROUND(abs_difference, 4) AS absolute_difference
FROM (
  SELECT product_id, mth, abs_difference,
        ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY abs_difference ASC, mth ASC) AS rn
  FROM inventory_calculation
)
WHERE rn = 1
ORDER BY product_id;