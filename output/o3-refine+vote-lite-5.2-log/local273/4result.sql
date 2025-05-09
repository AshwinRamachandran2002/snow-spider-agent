WITH earliest_inv AS (                      -- 1. FIFO : earliest purchase date, then smallest qty
    SELECT  i.location_id,
            i.product_id,
            i.qty                       AS inv_qty,
            p.purchased                 AS purchase_date,
            ROW_NUMBER() OVER (PARTITION BY i.location_id, i.product_id
                               ORDER BY p.purchased, i.qty) AS rn
    FROM    inventory        i
    JOIN    purchases        p  ON p.id = i.purchase_id
),
order_qty AS (                             -- 2. total ordered quantity per (order,product)
    SELECT  ol.order_id,
            ol.product_id,
            SUM(ol.qty) AS ordered_qty
    FROM    orderlines ol
    GROUP BY ol.order_id, ol.product_id
),
pick_qty AS (                              -- 3. qty picked from inventory that really overlaps
    SELECT  pl.order_id,
            pl.product_id,
            SUM(
                CASE
                     WHEN ei.purchase_date <= o.ordered                -- inventory already in stock
                     THEN CASE                                          -- overlap: lesser of pick vs. inventory
                              WHEN pl.qty < ei.inv_qty THEN pl.qty
                              ELSE ei.inv_qty
                          END
                     ELSE 0
                END
            ) AS picked_qty
    FROM            picking_line pl
    JOIN            orders       o  ON o.id = pl.order_id
    JOIN            earliest_inv ei ON ei.location_id = pl.location_id
                                    AND ei.product_id = pl.product_id
                                    AND ei.rn = 1                       -- only the FIFO‑chosen inventory row
    GROUP BY        pl.order_id, pl.product_id
),
pick_pct AS (                              -- 4. pick‑percentage per (order,product)
    SELECT  oq.product_id,
            oq.order_id,
            oq.ordered_qty,
            COALESCE(pq.picked_qty,0)                         AS picked_qty,
            1.0 * COALESCE(pq.picked_qty,0) / oq.ordered_qty  AS pick_percent
    FROM    order_qty oq
    LEFT JOIN pick_qty pq
           ON pq.order_id   = oq.order_id
          AND pq.product_id = oq.product_id
),
avg_pct AS (                               -- 5. average pick‑percentage per product
    SELECT  product_id,
            AVG(pick_percent) AS avg_pick_percent
    FROM    pick_pct
    GROUP BY product_id
)
SELECT  pr.name                     AS product_name,
        ROUND(ap.avg_pick_percent,4) AS avg_pick_percent
FROM    avg_pct  ap
JOIN    products pr ON pr.id = ap.product_id
ORDER BY pr.name, pr.id;