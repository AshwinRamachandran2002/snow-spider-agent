WITH
open AS (                       -- opening quantity = inventory at 2018‑12‑31
    SELECT pm.product_id,
           COALESCE(SUM(i.qty),0) AS opening_qty
    FROM   product_minimums pm
    LEFT   JOIN inventory i USING(product_id)
    GROUP  BY pm.product_id
),
calendar(mth) AS (              -- the 12 months of 2019
    SELECT '2019-01-01'
    UNION ALL
    SELECT date(mth,'+1 month') FROM calendar WHERE mth < '2019-12-01'
),
tx AS (                         -- movements: sales (‑) and purchases (+)
    SELECT product_id,
           mth,
           -qty AS delta
    FROM   monthly_sales
    WHERE  mth BETWEEN '2019-01-01' AND '2019-12-01'
    UNION ALL
    SELECT product_id,
           date(purchased,'start of month') AS mth,
           qty AS delta
    FROM   purchases
    WHERE  purchased BETWEEN '2019-01-01' AND '2019-12-31'
),
deltas AS (                     -- net movement per product / month
    SELECT pm.product_id,
           cal.mth,
           COALESCE(SUM(tx.delta),0) AS net_delta
    FROM   product_minimums pm
    CROSS  JOIN calendar cal
    LEFT   JOIN tx
           ON tx.product_id = pm.product_id
          AND tx.mth       = cal.mth
    GROUP  BY pm.product_id, cal.mth
),
rec(product_id, mth, ending_qty) AS (   -- recursive inventory model
    SELECT d.product_id,
           d.mth,
           open.opening_qty + d.net_delta
    FROM   deltas d
    JOIN   open ON open.product_id = d.product_id
    WHERE  d.mth = '2019-01-01'
    UNION ALL
    SELECT d.product_id,
           d.mth,
           (CASE
                WHEN r.ending_qty < pm.qty_minimum
                     THEN r.ending_qty + pm.qty_purchase
                ELSE r.ending_qty
            END) + d.net_delta
    FROM   rec  r
    JOIN   deltas d  ON d.product_id = r.product_id
                    AND d.mth       = date(r.mth,'+1 month')
    JOIN   product_minimums pm USING(product_id)
),
diffs AS (                      -- absolute gap to minimum each month
    SELECT product_id,
           mth,
           ABS(ending_qty - pm.qty_minimum) AS abs_diff
    FROM   rec
    JOIN   product_minimums pm USING(product_id)
),
ranked AS (                     -- pick month with smallest gap
    SELECT product_id,
           mth,
           abs_diff,
           ROW_NUMBER() OVER (PARTITION BY product_id
                              ORDER BY abs_diff, mth) AS rn
    FROM   diffs
)
SELECT product_id,
       mth  AS month,
       ROUND(abs_diff,4) AS abs_difference
FROM   ranked
WHERE  rn = 1
ORDER  BY product_id;