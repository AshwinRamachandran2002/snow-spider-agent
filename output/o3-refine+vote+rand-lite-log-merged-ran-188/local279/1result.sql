WITH RECURSIVE
/*-------------------------------------------------
1.  The products we have to keep an eye on together
    with their minimum level and the quantity that
    should be purchased whenever we have to restock
    (taken from product_minimums).
    The December‑2018 ending inventory that will be
    our starting point is approximated with the
    quantity that is physically present in the
    inventory table right now (if nothing is there
    we start at 0).
--------------------------------------------------*/
prod AS (
    SELECT  pm.product_id,
            pm.qty_minimum,
            pm.qty_purchase,
            COALESCE( ( SELECT SUM(i.qty)
                        FROM   inventory AS i
                        WHERE  i.product_id = pm.product_id ), 0) AS dec18_stock
    FROM    product_minimums AS pm
),
/*-------------------------------------------------
2.  Generate all months from 2018‑12‑01 up to and
    including 2019‑12‑01.  These strings are used
    all over the place so having them only once
    helps to keep the code readable.
--------------------------------------------------*/
calendar(mth) AS (
    SELECT date('2018-12-01')
    UNION ALL
    SELECT date(mth,'+1 month')
    FROM   calendar
    WHERE  mth < '2019-12-01'
),
/*-------------------------------------------------
3.  Recursive inventory development.
    For every product we keep the running inventory
    month by month, subtract the sales (if any) and
    – if that would bring us below the minimum –
    immediately add the purchase quantity.
--------------------------------------------------*/
inv_run AS (
    /*----- starting point: December 2018 ----------*/
    SELECT  p.product_id,
            '2018-12-01'            AS mth,
            p.dec18_stock           AS end_inv,      -- ending inv. of Dec‑18
            p.qty_minimum,
            p.qty_purchase
    FROM    prod AS p

    UNION ALL

    /*----- one month step‑wise recursion ----------*/
    SELECT  r.product_id,
            date(r.mth,'+1 month')  AS mth,

            /* ending inventory after sales + possible restock */
            CASE
                 WHEN r.end_inv - COALESCE(ms.qty,0) < r.qty_minimum
                 THEN r.end_inv - COALESCE(ms.qty,0) + r.qty_purchase
                 ELSE r.end_inv - COALESCE(ms.qty,0)
            END                      AS end_inv,

            r.qty_minimum,
            r.qty_purchase
    FROM    inv_run AS r
            JOIN calendar  AS cal
                 ON cal.mth = date(r.mth,'+1 month')
            LEFT JOIN monthly_sales AS ms
                 ON ms.product_id = r.product_id
                AND ms.mth        = cal.mth
    WHERE   r.mth < '2019-12-01'      -- stop after producing Dec‑19
),
/*-------------------------------------------------
4.  Absolute difference between ending inventory
    and the minimum level – but only for 2019!
--------------------------------------------------*/
diffs AS (
    SELECT  product_id,
            mth,
            ABS(end_inv - qty_minimum) AS diff
    FROM    inv_run
    WHERE   mth BETWEEN '2019-01-01' AND '2019-12-01'
),
/*-------------------------------------------------
5.  For every product find the smallest difference;
    if several months tie, the earliest month wins.
--------------------------------------------------*/
ranked AS (
    SELECT  d.*,
            ROW_NUMBER() OVER (PARTITION BY product_id
                               ORDER BY diff, mth) AS rn
    FROM    diffs AS d
)
/*-------------------------------------------------
6.  Final answer
--------------------------------------------------*/
SELECT  product_id,
        mth          AS best_month,
        diff         AS abs_difference
FROM    ranked
WHERE   rn = 1
ORDER BY product_id;