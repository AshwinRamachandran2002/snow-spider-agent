WITH RECURSIVE
/* constants for every product that has a minimum-stock rule */
pm(product_id ,qty_minimum ,qty_purchase) AS (
    SELECT product_id ,qty_minimum ,qty_purchase
    FROM   product_minimums
),

/* ----------------------------------------------------------
   Monthly inventory projection for 2019.
   ending_qty for each month = start – sold  (+ purchase_qty once
   if the provisional ending falls below the minimum).
-----------------------------------------------------------*/
inv_flow(product_id ,mth ,ending_qty ,qty_minimum ,qty_purchase) AS (
    /* ---------- anchor row : January 2019 ---------- */
    SELECT
        pm.product_id,
        '2019-01-01'                             AS mth,

        /* ending quantity after January sales + possible restock */
        CASE
            WHEN ( COALESCE( (SELECT SUM(qty)
                              FROM inventory i
                              WHERE i.product_id = pm.product_id), 0 )
                   -
                   COALESCE( (SELECT SUM(ol.qty)
                              FROM orderlines  ol
                              JOIN orders o ON o.id = ol.order_id
                              WHERE ol.product_id = pm.product_id
                                AND o.ordered >= '2019-01-01'
                                AND o.ordered <  '2019-02-01'), 0 ) )
                 < pm.qty_minimum
            THEN
                 ( COALESCE( (SELECT SUM(qty)
                              FROM inventory i
                              WHERE i.product_id = pm.product_id), 0 )
                   -
                   COALESCE( (SELECT SUM(ol.qty)
                              FROM orderlines  ol
                              JOIN orders o ON o.id = ol.order_id
                              WHERE ol.product_id = pm.product_id
                                AND o.ordered >= '2019-01-01'
                                AND o.ordered <  '2019-02-01'), 0 ) )
                 + pm.qty_purchase
            ELSE
                 ( COALESCE( (SELECT SUM(qty)
                              FROM inventory i
                              WHERE i.product_id = pm.product_id), 0 )
                   -
                   COALESCE( (SELECT SUM(ol.qty)
                              FROM orderlines  ol
                              JOIN orders o ON o.id = ol.order_id
                              WHERE ol.product_id = pm.product_id
                                AND o.ordered >= '2019-01-01'
                                AND o.ordered <  '2019-02-01'), 0 ) )
        END                                         AS ending_qty,

        pm.qty_minimum,
        pm.qty_purchase
    FROM pm

    UNION ALL

    /* ---------- recursive step : the rest of 2019 ---------- */
    SELECT
        f.product_id,
        date(f.mth,'+1 month')                     AS mth,

        CASE
            WHEN ( f.ending_qty
                   -
                   COALESCE( (SELECT SUM(ol.qty)
                              FROM orderlines  ol
                              JOIN orders o ON o.id = ol.order_id
                              WHERE ol.product_id = f.product_id
                                AND o.ordered >= date(f.mth,'+1 month')
                                AND o.ordered <  date(f.mth,'+2 month')), 0 ) )
                 < f.qty_minimum
            THEN
                 ( f.ending_qty
                   -
                   COALESCE( (SELECT SUM(ol.qty)
                              FROM orderlines  ol
                              JOIN orders o ON o.id = ol.order_id
                              WHERE ol.product_id = f.product_id
                                AND o.ordered >= date(f.mth,'+1 month')
                                AND o.ordered <  date(f.mth,'+2 month')), 0 ) )
                 + f.qty_purchase
            ELSE
                 ( f.ending_qty
                   -
                   COALESCE( (SELECT SUM(ol.qty)
                              FROM orderlines  ol
                              JOIN orders o ON o.id = ol.order_id
                              WHERE ol.product_id = f.product_id
                                AND o.ordered >= date(f.mth,'+1 month')
                                AND o.ordered <  date(f.mth,'+2 month')), 0 ) )
        END                                         AS ending_qty,

        f.qty_minimum,
        f.qty_purchase
    FROM inv_flow f
    WHERE f.mth < '2019-12-01'                     -- generate up to Dec-2019
),

/* absolute difference to the minimum each month */
diffs AS (
    SELECT
        product_id,
        mth,
        ABS(ending_qty - qty_minimum) AS abs_diff
    FROM   inv_flow
    WHERE  mth >= '2019-01-01'
      AND  mth <  '2020-01-01'
),

/* smallest absolute difference per product */
min_diff AS (
    SELECT product_id,
           MIN(abs_diff) AS min_abs
    FROM   diffs
    GROUP BY product_id
)

/* ----------------------------------------------------------
   Final result : for each product the (earliest) 2019 month
   where the distance to its minimum was smallest.
-----------------------------------------------------------*/
SELECT
    d.product_id,
    MIN(d.mth) AS closest_month,   -- earliest if a tie occurs
    d.abs_diff
FROM   diffs     d
JOIN   min_diff  m
  ON   m.product_id = d.product_id
 AND   m.min_abs    = d.abs_diff
GROUP BY d.product_id, d.abs_diff
ORDER BY d.product_id;