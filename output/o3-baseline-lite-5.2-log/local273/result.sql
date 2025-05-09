WITH
-- all inventory lots together with their purchase date
inv AS (
    SELECT  i.id          AS inv_id,
            i.product_id,
            i.qty         AS inv_qty,
            p.purchased   AS purchased
    FROM    inventory i
    JOIN    purchases p
           ON p.id = i.purchase_id
),
-- order‑lines (what has been ordered)
ol AS (
    SELECT  id            AS ol_id,
            product_id,
            qty           AS order_qty
    FROM    orderlines
),
-- pair every order‑line with every inventory lot of the same product
pairs AS (
    SELECT  ol.ol_id,
            ol.product_id,
            ol.order_qty,
            inv.inv_id,
            inv.inv_qty,
            inv.purchased
    FROM    ol
    JOIN    inv
           ON inv.product_id = ol.product_id
),
-- FIFO order: first by earliest purchase date, then by the smallest lot
running AS (
    SELECT  *,
            SUM(inv_qty) OVER (
                    PARTITION BY ol_id
                    ORDER BY purchased, inv_qty, inv_id
                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            )            AS run_sum
    FROM    pairs
),
-- quantity from each lot that is actually picked for the order
picked_lots AS (
    SELECT  ol_id,
            product_id,
            CASE
                 WHEN run_sum - inv_qty >= order_qty THEN 0
                 WHEN run_sum <= order_qty           THEN inv_qty
                 ELSE order_qty - (run_sum - inv_qty)
            END         AS picked_qty
    FROM    running
),
-- total picked quantity per order‑line
picked_per_ol AS (
    SELECT  ol_id,
            product_id,
            SUM(picked_qty) AS picked_qty
    FROM    picked_lots
    GROUP BY ol_id, product_id
),
-- combine picked information with every order‑line (missing → 0)
ol_with_pick AS (
    SELECT  o.product_id,
            COALESCE(p.picked_qty,0) AS picked_qty,
            o.order_qty
    FROM    ol  AS o
    LEFT JOIN picked_per_ol p
           ON p.ol_id = o.ol_id
)
SELECT  pr.name                                             AS product_name,
        ROUND(AVG(1.0 * picked_qty / order_qty),4)          AS avg_pick_percentage
FROM    ol_with_pick  ow
JOIN    products     pr ON pr.id = ow.product_id
GROUP BY pr.name
ORDER BY pr.name;