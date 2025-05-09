WITH RECURSIVE
dec_stock AS (
    SELECT i.product_id,
           SUM(i.qty) AS qty
    FROM   inventory  AS i
    JOIN   purchases  AS p
      ON  p.id = i.purchase_id
    WHERE  p.purchased BETWEEN '2018-12-01' AND '2018-12-31'
    GROUP  BY i.product_id
),
start_stock AS (
    SELECT pm.product_id,
           COALESCE(ds.qty, 0.0) AS start_qty
    FROM   product_minimums pm
    LEFT   JOIN dec_stock ds USING (product_id)
),
sales_2019 AS (
    SELECT product_id,
           mth,
           SUM(qty) AS sales_qty
    FROM   monthly_sales
    WHERE  mth BETWEEN '2019-01-01' AND '2019-12-01'
    GROUP  BY product_id, mth
),
running AS (
    SELECT
        ss.product_id,
        '2019-01-01'                            AS mth,
        ss.start_qty                            AS opening,
        ss.start_qty - COALESCE(s.sales_qty,0) AS ending,
        1                                       AS idx
    FROM   start_stock ss
    LEFT   JOIN sales_2019 s
           ON s.product_id = ss.product_id
          AND s.mth        = '2019-01-01'
    UNION ALL
    SELECT
        r.product_id,
        DATE(r.mth,'+1 month')                                                      AS mth,
        CASE WHEN r.ending < pm.qty_minimum
             THEN r.ending + pm.qty_purchase
             ELSE r.ending
        END                                                                         AS opening,
        CASE WHEN r.ending < pm.qty_minimum
             THEN r.ending + pm.qty_purchase - COALESCE(s2.sales_qty,0)
             ELSE r.ending                 - COALESCE(s2.sales_qty,0)
        END                                                                         AS ending,
        r.idx + 1                                                                   AS idx
    FROM   running r
    JOIN   product_minimums pm  ON pm.product_id = r.product_id
    LEFT   JOIN sales_2019   s2 ON s2.product_id = r.product_id
                               AND s2.mth        = DATE(r.mth,'+1 month')
    WHERE  r.idx < 12      -- stop after December‑2019
),
gaps AS (
    SELECT
        r.product_id,
        r.mth,
        ABS(r.ending - pm.qty_minimum) AS gap
    FROM   running r
    JOIN   product_minimums pm USING (product_id)
),
best_month AS (
    SELECT
        product_id,
        mth,
        gap,
        ROW_NUMBER() OVER (PARTITION BY product_id
                           ORDER BY gap, mth) AS rn
    FROM   gaps
)
SELECT
    product_id,
    mth AS month,
    ROUND(gap,4) AS abs_difference
FROM   best_month
WHERE  rn = 1
ORDER  BY product_id;