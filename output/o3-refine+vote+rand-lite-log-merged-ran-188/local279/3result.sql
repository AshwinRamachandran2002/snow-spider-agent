WITH
/* -------------------------------------------------
   1.  December‑2018 ending inventory for every item
---------------------------------------------------*/
starting AS (
    SELECT
        pm.product_id,
        /* stock still on hand that was purchased
           on, or before, the end of 2018           */
        COALESCE( SUM(
            CASE
                WHEN pu.purchased <= '2018-12-31' THEN i.qty
                ELSE 0
            END ), 0 )                         AS start_qty,
        pm.qty_minimum,
        pm.qty_purchase
    FROM product_minimums       pm
    /* the pallets that are still in the warehouse */
    LEFT JOIN inventory   i  ON i.product_id = pm.product_id
    /* … and when they originally came in          */
    LEFT JOIN purchases   pu ON pu.id        = i.purchase_id
    GROUP BY pm.product_id
),

/* -------------------------------------------------
   2.  2019 sales per product & month
---------------------------------------------------*/
sales AS (
    SELECT
        ol.product_id,
        /* first day of the month of the order */
        date(substr(o.ordered,1,7) || '-01')  AS mth,
        SUM(ol.qty)                           AS qty_sold
    FROM orderlines  ol
    JOIN orders      o  ON o.id = ol.order_id
    WHERE o.ordered BETWEEN '2019-01-01' AND '2019-12-31'
    GROUP BY ol.product_id, mth
),

/* -------------------------------------------------
   3.  Recursive month‑by‑month stock calculation
---------------------------------------------------*/
rec AS (
    /* seed row  :  2018‑12 closing balance        */
    SELECT
        s.product_id,
        date('2018-12-01')                    AS mth,
        s.start_qty                           AS end_qty,
        s.qty_minimum,
        s.qty_purchase
    FROM starting s

    UNION ALL

    /* next month, until December‑2019            */
    SELECT
        r.product_id,
        date(r.mth,'+1 month')                AS mth,

        /* take away sales then restock if needed */
        CASE
            WHEN r.end_qty - COALESCE(sa.qty_sold,0) < r.qty_minimum
                 THEN r.end_qty - COALESCE(sa.qty_sold,0) + r.qty_purchase
            ELSE r.end_qty - COALESCE(sa.qty_sold,0)
        END                                   AS end_qty,

        r.qty_minimum,
        r.qty_purchase
    FROM rec  r
    /* sales for “next” month                     */
    LEFT JOIN sales sa
           ON sa.product_id = r.product_id
          AND sa.mth        = date(r.mth,'+1 month')
    /* stop the recursion once we have Dec‑2019   */
    WHERE r.mth < '2019-12-01'
),

/* -------------------------------------------------
   4.  Absolute difference to the minimum, 2019
---------------------------------------------------*/
diffs AS (
    SELECT
        product_id,
        mth,
        ABS(end_qty - qty_minimum)            AS abs_diff
    FROM rec
    WHERE mth BETWEEN '2019-01-01' AND '2019-12-01'
),

/* -------------------------------------------------
   5.  Rank months by (difference, month)
---------------------------------------------------*/
ranked AS (
    SELECT
        d.*,
        ROW_NUMBER() OVER (
            PARTITION BY product_id
            ORDER BY abs_diff, mth
        ) AS rn
    FROM diffs d
)

/* -------------------------------------------------
   6.  Result
---------------------------------------------------*/
SELECT
    product_id,
    mth                       AS best_month,
    abs_diff
FROM ranked
WHERE rn = 1
ORDER BY product_id;