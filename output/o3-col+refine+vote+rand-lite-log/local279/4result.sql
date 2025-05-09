WITH RECURSIVE
-- the twelve calendar months of 2019
months(mth) AS (
    SELECT '2019-01-01'
    UNION ALL
    SELECT date(mth,'+1 month')
    FROM   months
    WHERE  mth < '2019-12-01'
),
/* inventory on–hand as of 2018-12-31 (seed for the 2019 model) */
dec18 AS (
    SELECT pm.product_id,
           COALESCE(SUM(i.qty),0) AS end_inv
    FROM   product_minimums pm
    LEFT   JOIN inventory  i ON i.product_id = pm.product_id
    LEFT   JOIN purchases  p ON p.id = i.purchase_id
                             AND p.purchased <= '2018-12-31'
    GROUP  BY pm.product_id
),
/* 2019 sales per product & month (missing rows = zero sales) */
sales AS (
    SELECT ms.product_id,
           ms.mth,
           SUM(ms.qty) AS sales_qty
    FROM   monthly_sales ms
    WHERE  ms.mth BETWEEN '2019-01-01' AND '2019-12-31'
    GROUP  BY ms.product_id, ms.mth
),
rules AS (SELECT * FROM product_minimums),
/* month-by-month inventory projection for 2019 */
inv_cte(product_id, mth, end_inv) AS (
    -- seed row = inventory carried into Jan-2019
    SELECT d.product_id,
           '2019-01-01' AS mth,
           d.end_inv
    FROM   dec18 d
    UNION ALL
    -- step forward one month, subtract that month’s sales, restock if below minimum
    SELECT inv.product_id,
           date(inv.mth,'+1 month')                             AS mth,
           CASE
               WHEN (inv.end_inv - COALESCE(sa.sales_qty,0)) < ru.qty_minimum
                    THEN (inv.end_inv - COALESCE(sa.sales_qty,0)) + ru.qty_purchase
               ELSE (inv.end_inv - COALESCE(sa.sales_qty,0))
           END                                                  AS end_inv
    FROM   inv_cte  inv
    JOIN   rules    ru ON ru.product_id = inv.product_id
    LEFT   JOIN sales sa
           ON  sa.product_id = inv.product_id
           AND sa.mth        = date(inv.mth,'+1 month')
    WHERE  inv.mth < '2019-12-01'      -- stop after projecting December
),
/* pick, per product, the 2019 month closest to its minimum level */
closest AS (
    SELECT i.product_id,
           i.mth,
           i.end_inv,
           ru.qty_minimum,
           ROW_NUMBER() OVER (PARTITION BY i.product_id
                              ORDER BY ABS(i.end_inv - ru.qty_minimum)) AS rn
    FROM   inv_cte i
    JOIN   rules  ru USING (product_id)
    WHERE  i.mth BETWEEN '2019-01-01' AND '2019-12-01'
)
SELECT product_id,
       mth  AS best_month,
       ABS(end_inv - qty_minimum) AS abs_diff_to_min
FROM   closest
WHERE  rn = 1
ORDER  BY product_id;