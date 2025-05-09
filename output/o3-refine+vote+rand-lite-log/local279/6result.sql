WITH
/* minimum level and standard purchase size for each product                */
minima AS (
    SELECT  product_id,
            qty_minimum,
            qty_purchase
    FROM    product_minimums
),

/* quantity on hand on 2018‑12‑31 (the model’s start value)                 */
start_inv AS (
    SELECT  m.product_id,
            COALESCE(SUM(i.qty),0)         AS start_qty
    FROM    minima            AS m
    LEFT JOIN inventory        AS i  ON i.product_id = m.product_id
    GROUP BY m.product_id
),

/* total quantity sold per product per month in 2019                        */
sales AS (
    SELECT  ol.product_id,
            date(strftime('%Y-%m-01',o.ordered))     AS mth,
            SUM(ol.qty)                              AS sold_qty
    FROM    orderlines   AS ol
    JOIN    orders       AS o  ON o.id = ol.order_id
    WHERE   o.ordered BETWEEN '2019-01-01' AND '2019-12-31'
    GROUP BY ol.product_id, mth
),

/* recursive calculation of ending inventory month by month                 */
recur(product_id,mth,end_qty) AS (
    /* --- anchor : January 2019 ----------------------------------------- */
    SELECT  si.product_id,
            '2019-01-01'                                       AS mth,
            CASE
                 WHEN si.start_qty - COALESCE(s.sold_qty,0) < mn.qty_minimum
                 THEN si.start_qty - COALESCE(s.sold_qty,0) + mn.qty_purchase
                 ELSE si.start_qty - COALESCE(s.sold_qty,0)
            END                                                AS end_qty
    FROM    start_inv  AS si
    JOIN    minima     AS mn ON mn.product_id = si.product_id
    LEFT JOIN sales     AS s  ON s.product_id = si.product_id
                               AND s.mth       = '2019-01-01'

    UNION ALL
    /* --- recursive step : next month ----------------------------------- */
    SELECT  r.product_id,
            date(r.mth,'+1 month')                             AS mth,
            CASE
                 WHEN r.end_qty - COALESCE(s.sold_qty,0) < mn.qty_minimum
                 THEN r.end_qty - COALESCE(s.sold_qty,0) + mn.qty_purchase
                 ELSE r.end_qty - COALESCE(s.sold_qty,0)
            END                                                AS end_qty
    FROM    recur      AS r
    JOIN    minima     AS mn ON mn.product_id = r.product_id
    LEFT JOIN sales     AS s ON s.product_id = r.product_id
                              AND s.mth      = date(r.mth,'+1 month')
    WHERE   r.mth < '2019-12-01'   /* stop after December 2019 is produced */
),

/* absolute distance to the minimum for every month                         */
diffs AS (
    SELECT  r.product_id,
            r.mth,
            ABS(r.end_qty - mn.qty_minimum)    AS diff
    FROM    recur  AS r
    JOIN    minima AS mn USING (product_id)
),

/* per product: smallest distance (and earliest month if tie)               */
best_month AS (
    SELECT  d1.product_id,
            MIN(d1.diff)               AS min_diff
    FROM    diffs d1
    GROUP BY d1.product_id
)

/* final answer                                                            */
SELECT  d.product_id,
        MIN(d.mth)      AS month,      -- earliest month when min diff occurs
        d.diff          AS abs_difference
FROM    diffs      AS d
JOIN    best_month AS b
           ON  b.product_id = d.product_id
           AND b.min_diff   = d.diff
GROUP BY d.product_id, d.diff
ORDER BY d.product_id;