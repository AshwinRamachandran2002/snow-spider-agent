WITH
-- all months in 2019 (first day of the month)
months(mth) AS (
    SELECT DATE('2019-01-01')
    UNION ALL
    SELECT DATE(mth,'+1 month')
    FROM   months
    WHERE  mth < '2019-12-01'
),

-- quantity sold (demand) per product per month during 2019
sales AS (
    SELECT
        ol.product_id,
        DATE(o.ordered,'start of month') AS mth,
        SUM(ol.qty)                      AS qty
    FROM   orders      o
    JOIN   orderlines  ol ON ol.order_id = o.id
    WHERE  o.ordered >= '2019-01-01' AND o.ordered < '2020-01-01'
    GROUP  BY ol.product_id,
             DATE(o.ordered,'start of month')
),

-- starting position on 2018‑12‑01 for every product that has a minimum rule
initial AS (
    SELECT
        pm.product_id,
        COALESCE(SUM(i.qty),0) AS start_inv,          -- present stock
        pm.qty_minimum,
        pm.qty_purchase
    FROM   product_minimums pm
    LEFT   JOIN inventory i ON i.product_id = pm.product_id
    GROUP  BY pm.product_id
),

-- recursive monthly inventory evolution, restocking when below minimum
rec AS (
    /* anchor : 2018‑12‑01 */
    SELECT
        product_id,
        DATE('2018-12-01')        AS mth,
        start_inv                 AS ending_inv,
        qty_minimum,
        qty_purchase
    FROM   initial

    UNION ALL

    /* next months */
    SELECT
        r.product_id,
        DATE(r.mth,'+1 month')    AS mth,
        CASE
            WHEN r.ending_inv - COALESCE(s.qty,0) < r.qty_minimum
                 THEN r.ending_inv - COALESCE(s.qty,0) + r.qty_purchase
            ELSE r.ending_inv - COALESCE(s.qty,0)
        END                       AS ending_inv,
        r.qty_minimum,
        r.qty_purchase
    FROM   rec   r
    JOIN   months nxt            ON nxt.mth = DATE(r.mth,'+1 month')
    LEFT   JOIN sales  s         ON s.product_id = r.product_id
                                AND s.mth       = nxt.mth
),

-- absolute differences to the minimum for 2019
diff AS (
    SELECT
        product_id,
        mth,
        ABS(ending_inv - qty_minimum) AS abs_diff
    FROM   rec
    WHERE  mth BETWEEN '2019-01-01' AND '2019-12-01'
),

-- pick the month with the smallest absolute difference per product
ranked AS (
    SELECT
        product_id,
        mth,
        abs_diff,
        ROW_NUMBER() OVER (PARTITION BY product_id
                           ORDER BY abs_diff, mth) AS rn
    FROM   diff
)

SELECT
    product_id,
    mth  AS month,
    abs_diff
FROM   ranked
WHERE  rn = 1
ORDER  BY product_id;