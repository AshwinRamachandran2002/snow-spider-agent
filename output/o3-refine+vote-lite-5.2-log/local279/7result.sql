WITH
/* 1.  Minimum stock rules together with the physical stock counted
       on the shelves at the end of December‑2018                        */
product_info AS (
    SELECT  pm.product_id,
            pm.qty_minimum,          -- minimum stock that must be on hand
            pm.qty_purchase,         -- quantity bought every time we restock
            IFNULL( SUM(inv.qty), 0) AS start_qty   -- 31‑Dec‑2018 closing stock
    FROM    product_minimums  pm
    LEFT JOIN inventory       inv ON inv.product_id = pm.product_id
    GROUP BY pm.product_id
),

/* 2.  Outgoing quantity (sales) per product and per 2019 month          */
sales AS (
    SELECT  ol.product_id,
            strftime('%Y-%m-01', o.ordered) AS mth,   -- first day of month
            SUM(ol.qty)                AS sold_qty
    FROM    orderlines  ol
    JOIN    orders      o ON o.id = ol.order_id
    WHERE   o.ordered BETWEEN '2019-01-01' AND '2019-12-31'
    GROUP BY ol.product_id, mth
),

/* 3.  Calendar for the 12 months of 2019                                */
months AS (
    SELECT '2019-01-01' AS mth
    UNION ALL
    SELECT date(mth,'+1 month')
    FROM   months
    WHERE  mth < '2019-12-01'
),

/* 4.  Recursive month‑by‑month stock simulation                         */
recursive_inv AS (
    /* --- January 2019 : uses physical stock counted 31‑Dec‑2018 ------- */
    SELECT  pi.product_id,
            pi.qty_minimum,
            pi.qty_purchase,
            '2019-01-01'            AS mth,
            pi.start_qty            AS start_qty,
            IFNULL(s.sold_qty,0)    AS sold_qty,
            pi.start_qty - IFNULL(s.sold_qty,0)                    AS end_before_restock,
            CASE WHEN (pi.start_qty - IFNULL(s.sold_qty,0)) < pi.qty_minimum
                 THEN pi.qty_purchase ELSE 0 END                   AS restock,
            (pi.start_qty - IFNULL(s.sold_qty,0))
            + CASE WHEN (pi.start_qty - IFNULL(s.sold_qty,0)) < pi.qty_minimum
                   THEN pi.qty_purchase ELSE 0 END                 AS ending
    FROM    product_info  pi
    LEFT JOIN sales       s  ON s.product_id = pi.product_id
                            AND s.mth        = '2019-01-01'

    UNION ALL

    /* --- From February through December: always based on the
           ending stock of the preceding month ------------------------- */
    SELECT  ri.product_id,
            ri.qty_minimum,
            ri.qty_purchase,
            date(ri.mth,'+1 month') AS mth,
            ri.ending               AS start_qty,
            IFNULL(s.sold_qty,0)    AS sold_qty,
            ri.ending - IFNULL(s.sold_qty,0)                         AS end_before_restock,
            CASE WHEN (ri.ending - IFNULL(s.sold_qty,0)) < ri.qty_minimum
                 THEN ri.qty_purchase ELSE 0 END                      AS restock,
            (ri.ending - IFNULL(s.sold_qty,0))
            + CASE WHEN (ri.ending - IFNULL(s.sold_qty,0)) < ri.qty_minimum
                   THEN ri.qty_purchase ELSE 0 END                    AS ending
    FROM    recursive_inv ri
    JOIN    months       m  ON m.mth = date(ri.mth,'+1 month')
    LEFT JOIN sales       s  ON s.product_id = ri.product_id
                            AND s.mth        = m.mth
),

/* 5.  For every product pick the 2019 month whose ending stock
       is closest to the minimum required level                        */
best_month AS (
    SELECT  product_id,
            mth,
            ABS(ending - qty_minimum) AS abs_diff,
            ROW_NUMBER() OVER (PARTITION BY product_id
                               ORDER BY ABS(ending - qty_minimum), mth) AS rn
    FROM    recursive_inv
)

SELECT  product_id,
        mth  AS month_2019,
        abs_diff
FROM    best_month
WHERE   rn = 1
ORDER BY product_id;