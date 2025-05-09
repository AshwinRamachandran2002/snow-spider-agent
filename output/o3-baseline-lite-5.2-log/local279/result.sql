WITH
-- products that have a minimum/ restock rule
prods AS (
    SELECT  pm.product_id ,
            pm.qty_minimum ,
            pm.qty_purchase
    FROM    product_minimums pm
),

-- starting inventory on the last day of 2018
start_inv AS (
    SELECT  p.product_id,
            COALESCE( (SELECT SUM(qty) FROM inventory WHERE product_id = p.product_id), 0 ) AS start_qty,
            p.qty_minimum,
            p.qty_purchase
    FROM    prods p
),

-- a list of months beginning with 2018‑12‑01 and ending with 2019‑12‑01
months(mth) AS (
    SELECT date('2018-12-01')
    UNION ALL
    SELECT date(mth,'+1 month')
    FROM   months
    WHERE  mth < '2019-12-01'
),

---------------------------------------------------------
-- recursive simulation of month‑by‑month inventory
---------------------------------------------------------
inv AS (
    -- base (month_idx = 0 → 2018‑12, inventory = start_qty)
    SELECT  0                       AS month_idx,
            s.product_id            AS product_id,
            '2018-12-01'            AS mth,
            s.start_qty             AS end_qty,     -- inventory after 2018‑12
            s.qty_minimum,
            s.qty_purchase
    FROM    start_inv s

    UNION ALL

    -- next month
    SELECT  i.month_idx + 1                                                        AS month_idx,
            i.product_id                                                           AS product_id,
            date(i.mth,'+1 month')                                                 AS mth,

            /* ---- compute inventory at end of the new month ---- */
            CASE 
                 WHEN i.end_qty - COALESCE(ms.qty,0) < i.qty_minimum
                 THEN
                     /* how many purchase lots are needed? */
                     (i.end_qty - COALESCE(ms.qty,0)) + 
                     (  ( (i.qty_minimum - (i.end_qty - COALESCE(ms.qty,0)) + i.qty_purchase - 1)
                          / i.qty_purchase                                             -- lots (integer division)
                        ) * i.qty_purchase )                                           -- lots * lot_size
                 ELSE
                     i.end_qty - COALESCE(ms.qty,0)
            END                                                                    AS end_qty,

            i.qty_minimum,
            i.qty_purchase
    FROM        inv  i
    JOIN        months m2 
           ON   m2.mth = date(i.mth,'+1 month')         -- keep the generator in step
    LEFT JOIN   monthly_sales ms
           ON   ms.product_id = i.product_id
          AND   ms.mth       = date(i.mth,'+1 month')
    WHERE       m2.mth <= '2019-12-01'                  -- stop after Dec‑2019
),

---------------------------------------------------------
-- absolute difference to the minimum for months in 2019
---------------------------------------------------------
diffs AS (
    SELECT  product_id,
            mth,
            ABS(end_qty - qty_minimum) AS diff
    FROM    inv
    WHERE   mth BETWEEN '2019-01-01' AND '2019-12-01'
),

-- minimum difference (per product) and the month(s) where it happens
best_diff AS (
    SELECT  d.product_id,
            d.mth,
            d.diff,
            ( SELECT MIN(diff)
              FROM   diffs d2
              WHERE  d2.product_id = d.product_id
            ) AS min_diff
    FROM    diffs d
),

-- choose the (earliest) month whose diff = min_diff
chosen AS (
    SELECT  product_id,
            MIN(mth) AS month,
            min_diff AS abs_difference
    FROM    best_diff
    WHERE   diff = min_diff
    GROUP BY product_id
)

SELECT  product_id,
        month,
        abs_difference
FROM    chosen
ORDER BY product_id;