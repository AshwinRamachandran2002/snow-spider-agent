WITH RECURSIVE
/* ---------- closing stock as of 2018‑12‑01 (anchor) ---------- */
opening AS (
    SELECT
        pm.product_id,
        '2018-12-01'                  AS month,
        COALESCE(SUM(i.qty),0)        AS end_qty
    FROM   product_minimums pm
    LEFT   JOIN inventory    i ON i.product_id = pm.product_id
    LEFT   JOIN purchases    p ON p.id = i.purchase_id
                               AND p.purchased <= '2018-12-31'
    GROUP  BY pm.product_id
),

/* ---------- month‑by‑month simulation for 2019 ---------- */
inv AS (
    SELECT product_id, month, end_qty            -- anchor row
    FROM   opening

    UNION ALL

    SELECT
        inv.product_id,
        date(inv.month,'+1 month')               AS month,
        CASE
            WHEN inv.end_qty
                 - COALESCE((
                     SELECT SUM(ol.qty)
                     FROM   orderlines ol
                     JOIN   orders     o ON o.id = ol.order_id
                     WHERE  ol.product_id = inv.product_id
                       AND  strftime('%Y-%m', o.ordered) =
                            strftime('%Y-%m', date(inv.month,'+1 month'))
                 ),0) < pm.qty_minimum
            THEN inv.end_qty
                 - COALESCE((
                     SELECT SUM(ol.qty)
                     FROM   orderlines ol
                     JOIN   orders     o ON o.id = ol.order_id
                     WHERE  ol.product_id = inv.product_id
                       AND  strftime('%Y-%m', o.ordered) =
                            strftime('%Y-%m', date(inv.month,'+1 month'))
                 ),0)
                 + pm.qty_purchase
            ELSE inv.end_qty
                 - COALESCE((
                     SELECT SUM(ol.qty)
                     FROM   orderlines ol
                     JOIN   orders     o ON o.id = ol.order_id
                     WHERE  ol.product_id = inv.product_id
                       AND  strftime('%Y-%m', o.ordered) =
                            strftime('%Y-%m', date(inv.month,'+1 month'))
                 ),0)
        END                                      AS end_qty
    FROM   inv
    JOIN   product_minimums pm ON pm.product_id = inv.product_id
    WHERE  inv.month < '2019-12-01'              -- generate up to 2019‑12‑01
),

/* ---------- deviation from minimum each 2019 month ---------- */
diffs AS (
    SELECT
        inv.product_id,
        inv.month,
        ABS(inv.end_qty - pm.qty_minimum) AS diff
    FROM   inv
    JOIN   product_minimums pm ON pm.product_id = inv.product_id
    WHERE  inv.month BETWEEN '2019-01-01' AND '2019-12-01'
),

/* ---------- smallest deviation per product ---------- */
best AS (
    SELECT product_id,
           MIN(diff) AS best_diff
    FROM   diffs
    GROUP  BY product_id
),

/* ---------- earliest month with that deviation ---------- */
best_month AS (
    SELECT d.product_id,
           MIN(d.month) AS month
    FROM   diffs d
    JOIN   best  b ON b.product_id = d.product_id
                  AND b.best_diff  = d.diff
    GROUP  BY d.product_id
)

/* ---------- final result ---------- */
SELECT
    bm.product_id,
    bm.month,
    printf('%.4f', b.best_diff) AS abs_difference
FROM   best_month bm
JOIN   best       b ON b.product_id = bm.product_id
ORDER  BY bm.product_id;