WITH
-- 12 months that we have to simulate (given in the right order)
months(mth,rn) AS (
    SELECT '2019-01-01',1 UNION ALL
    SELECT '2019-02-01',2 UNION ALL
    SELECT '2019-03-01',3 UNION ALL
    SELECT '2019-04-01',4 UNION ALL
    SELECT '2019-05-01',5 UNION ALL
    SELECT '2019-06-01',6 UNION ALL
    SELECT '2019-07-01',7 UNION ALL
    SELECT '2019-08-01',8 UNION ALL
    SELECT '2019-09-01',9 UNION ALL
    SELECT '2019-10-01',10 UNION ALL
    SELECT '2019-11-01',11 UNION ALL
    SELECT '2019-12-01',12
),

/* basic product parameters and the “opening balance” we start the
   simulation with (ending inventory of December‑2018, if supplied) */
init AS (
    SELECT
        pm.product_id,
        pm.qty_minimum,
        pm.qty_purchase,
        COALESCE( (SELECT qty
                   FROM monthly_budget
                   WHERE product_id = pm.product_id
                     AND mth = '2018-12-01'), 0.0)          AS start_inv
    FROM product_minimums pm
),

/* sales/usage for each month in 2019 (missing rows are treated as 0) */
sales_full AS (
    SELECT
        i.product_id,
        m.mth,
        m.rn,
        COALESCE( mb.qty , 0.0 )            AS sales_qty
    FROM init i
    CROSS JOIN months  m
    LEFT  JOIN monthly_budget mb
           ON mb.product_id = i.product_id
          AND mb.mth       = m.mth
),

/* recursive walk through the 12 months to calculate ending inventory
   – re‑ordering when the level after consumption falls below minimum */
inv_rec AS (
    /* anchor : first month (January) */
    SELECT
        sf.product_id,
        sf.mth,
        sf.rn,
        CASE
            WHEN (i.start_inv - sf.sales_qty) < i.qty_minimum
                 THEN (i.start_inv - sf.sales_qty) + i.qty_purchase
            ELSE     (i.start_inv - sf.sales_qty)
        END                                          AS ending_inv
    FROM sales_full sf
    JOIN init i USING (product_id)
    WHERE sf.rn = 1

    UNION ALL

    /* subsequent months build on the previous month’s ending_inv */
    SELECT
        sf.product_id,
        sf.mth,
        sf.rn,
        CASE
            WHEN (prev.ending_inv - sf.sales_qty) < i.qty_minimum
                 THEN (prev.ending_inv - sf.sales_qty) + i.qty_purchase
            ELSE     (prev.ending_inv - sf.sales_qty)
        END                                          AS ending_inv
    FROM inv_rec      prev
    JOIN sales_full   sf
         ON sf.product_id = prev.product_id
        AND sf.rn        = prev.rn + 1
    JOIN init i        USING (product_id)
),

/* absolute deviation between ending inventory and minimum requirement */
diffs AS (
    SELECT
        ir.product_id,
        ir.mth,
        ABS( ir.ending_inv - i.qty_minimum ) AS diff
    FROM inv_rec ir
    JOIN init   i USING (product_id)
)

/* pick the month where that deviation is the smallest (earliest on ties) */
SELECT product_id,
       mth  AS month,
       diff AS abs_difference
FROM (
    SELECT
        d.*,
        ROW_NUMBER() OVER (PARTITION BY product_id
                           ORDER BY diff ASC, mth ASC) AS rk
    FROM diffs d
)
WHERE rk = 1
ORDER BY product_id;