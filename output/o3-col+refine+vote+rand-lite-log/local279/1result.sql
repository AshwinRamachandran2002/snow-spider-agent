WITH RECURSIVE
/* ------------------------------------------------------------
   basic lookup tables
   ------------------------------------------------------------ */
products_min AS (        -- only products that have minimum levels
    SELECT product_id,
           qty_minimum,
           qty_purchase
    FROM product_minimums
),
opening AS (             -- stock on hand as of 2018-12-31
    SELECT pm.product_id,
           COALESCE((
               SELECT SUM(inv.qty)
               FROM inventory  inv
               JOIN purchases pur ON pur.id = inv.purchase_id
               WHERE inv.product_id = pm.product_id
                 AND pur.purchased <= '2018-12-31'
           ),0) AS opening_qty
    FROM products_min pm
),
/* ------------------------------------------------------------
   2019 movements (real inflow & outflow)
   ------------------------------------------------------------ */
purch_19 AS (
    SELECT product_id,
           substr(purchased,1,7) AS mth,   -- YYYY-MM
           SUM(qty) AS in_qty
    FROM purchases
    WHERE purchased BETWEEN '2019-01-01' AND '2019-12-31'
    GROUP BY product_id, mth
),
sales_19 AS (
    SELECT ol.product_id,
           substr(o.ordered,1,7) AS mth,
           SUM(ol.qty) AS out_qty
    FROM orderlines ol
    JOIN orders o ON o.id = ol.order_id
    WHERE o.ordered BETWEEN '2019-01-01' AND '2019-12-31'
    GROUP BY ol.product_id, mth
),
mov AS (                  -- combine the 2 lists
    SELECT product_id,
           mth,
           SUM(in_qty)  AS in_qty,
           SUM(out_qty) AS out_qty
    FROM (
        SELECT product_id, mth, in_qty, 0 AS out_qty FROM purch_19
        UNION ALL
        SELECT product_id, mth, 0 AS in_qty, out_qty FROM sales_19
    )
    GROUP BY product_id, mth
),
/* ------------------------------------------------------------
   recursive month-by-month balance with auto-restocking
   ------------------------------------------------------------ */
rec(product_id, mth, ending_qty, qty_minimum, qty_purchase) AS (
    /* ---- first month (2019-01) ---- */
    SELECT
        pm.product_id,
        '2019-01' AS mth,
        CASE
            WHEN (op.opening_qty
                  + COALESCE(mv.in_qty,0)
                  - COALESCE(mv.out_qty,0)) < pm.qty_minimum
            THEN (op.opening_qty
                  + COALESCE(mv.in_qty,0)
                  - COALESCE(mv.out_qty,0)) + pm.qty_purchase
            ELSE (op.opening_qty
                  + COALESCE(mv.in_qty,0)
                  - COALESCE(mv.out_qty,0))
        END                         AS ending_qty,
        pm.qty_minimum,
        pm.qty_purchase
    FROM products_min pm
    LEFT JOIN opening op ON op.product_id = pm.product_id
    LEFT JOIN mov     mv ON mv.product_id = pm.product_id
                        AND mv.mth       = '2019-01'

    UNION ALL
    /* ---- subsequent months up to 2019-12 ---- */
    SELECT
        r.product_id,
        strftime('%Y-%m', date(r.mth||'-01','+1 month')) AS mth,
        CASE
            WHEN (r.ending_qty
                  + COALESCE(mv.in_qty,0)
                  - COALESCE(mv.out_qty,0)) < r.qty_minimum
            THEN (r.ending_qty
                  + COALESCE(mv.in_qty,0)
                  - COALESCE(mv.out_qty,0)) + r.qty_purchase
            ELSE (r.ending_qty
                  + COALESCE(mv.in_qty,0)
                  - COALESCE(mv.out_qty,0))
        END                         AS ending_qty,
        r.qty_minimum,
        r.qty_purchase
    FROM rec r
    LEFT JOIN mov mv
           ON mv.product_id = r.product_id
          AND mv.mth        = strftime('%Y-%m', date(r.mth||'-01','+1 month'))
    WHERE r.mth < '2019-12'
),
/* ------------------------------------------------------------
   pick the month where the gap to the minimum is smallest
   ------------------------------------------------------------ */
diffs AS (
    SELECT product_id,
           mth,
           ABS(ending_qty - qty_minimum) AS diff
    FROM rec
),
min_diff AS (            -- smallest difference per product
    SELECT product_id,
           MIN(diff) AS min_diff
    FROM diffs
    GROUP BY product_id
),
best AS (                -- keep the month(s) that match that minimum
    SELECT d.product_id,
           d.mth,
           d.diff
    FROM diffs d
    JOIN min_diff m
      ON m.product_id = d.product_id
     AND m.min_diff   = d.diff
)
/* ------------------------------------------------------------
   final result
   ------------------------------------------------------------ */
SELECT
    product_id,
    MIN(mth)  AS mth,            -- earliest month if several tie
    MIN(diff) AS abs_difference  -- (same as m.min_diff)
FROM best
GROUP BY product_id
ORDER BY product_id;