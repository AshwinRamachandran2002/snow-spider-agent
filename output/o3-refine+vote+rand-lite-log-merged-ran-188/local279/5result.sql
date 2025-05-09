WITH RECURSIVE
/* -----------------------------------------------------------
   1.  Build the month calendar from 2018‑12‑01 to 2019‑12‑01
------------------------------------------------------------ */
months(mth) AS (
    VALUES('2018-12-01')
    UNION ALL
    SELECT date(mth,'+1 month')
    FROM   months
    WHERE  mth < '2019-12-01'
),

/* -----------------------------------------------------------
   2.  Products that have minimum‑stock rules
------------------------------------------------------------ */
prod AS (
    SELECT  product_id,
            qty_minimum,
            qty_purchase
    FROM    product_minimums
),

/* -----------------------------------------------------------
   3.  Planned monthly outflow (sales / consumption)
------------------------------------------------------------ */
sales AS (
    SELECT  product_id,
            mth,
            qty
    FROM    monthly_budget
),

/* -----------------------------------------------------------
   4.  Combine calendar and sales for every product / month
------------------------------------------------------------ */
calendar AS (
    SELECT  p.product_id,
            m.mth,
            COALESCE(s.qty,0)  AS sales_qty,
            p.qty_minimum,
            p.qty_purchase
    FROM    prod p
    CROSS JOIN months m
    LEFT  JOIN sales  s
           ON s.product_id = p.product_id
          AND s.mth       = m.mth
),

/* -----------------------------------------------------------
   5.  Seed: ending inventory on 2018‑12‑31  =  minimum level
------------------------------------------------------------ */
inv_seed AS (
    SELECT  product_id,
            '2018-12-01' AS mth,
            qty_minimum  AS end_inv
    FROM    prod
),

/* -----------------------------------------------------------
   6.  Recursive inventory calculation month by month
------------------------------------------------------------ */
inv AS (
    /* --- seed row (Dec‑2018) --- */
    SELECT  c.product_id,
            c.mth,
            0.0              AS start_inv,
            isd.end_inv      AS end_inv,
            c.qty_minimum,
            c.qty_purchase,
            c.sales_qty
    FROM    calendar  c
    JOIN    inv_seed  isd
           ON isd.product_id = c.product_id
          AND c.mth = '2018-12-01'

    UNION ALL

    /* --- following months --- */
    SELECT  c.product_id,
            c.mth,
            i.end_inv                          AS start_inv,
            CASE
                 WHEN (i.end_inv - c.sales_qty) < c.qty_minimum
                      THEN (i.end_inv - c.sales_qty) + c.qty_purchase
                 ELSE (i.end_inv - c.sales_qty)
            END                                AS end_inv,
            c.qty_minimum,
            c.qty_purchase,
            c.sales_qty
    FROM    inv       i
    JOIN    calendar  c
           ON c.product_id = i.product_id
          AND c.mth       = date(i.mth,'+1 month')
),

/* -----------------------------------------------------------
   7.  Absolute difference between ending inventory and minimum
------------------------------------------------------------ */
diffs AS (
    SELECT  product_id,
            mth,
            ABS(end_inv - qty_minimum) AS diff
    FROM    inv
    WHERE   substr(mth,1,4) = '2019'          -- keep only 2019 months
)

/* -----------------------------------------------------------
   8.  Pick, for each product, the 2019 month with the
       smallest absolute difference (earliest month if tie)
------------------------------------------------------------ */
SELECT  d1.product_id,
        d1.mth,
        d1.diff
FROM    diffs d1
WHERE   d1.mth = (
           SELECT MIN(d2.mth)
           FROM   diffs d2
           WHERE  d2.product_id = d1.product_id
             AND  d2.diff = (
                    SELECT MIN(d3.diff)
                    FROM   diffs d3
                    WHERE  d3.product_id = d1.product_id
                  )
        )
ORDER BY d1.product_id;