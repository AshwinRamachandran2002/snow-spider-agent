WITH first_inv AS (          -- 1. FIFO: pick the inventory that was bought first and, within that day, has the least stock
    SELECT  i.product_id,
            i.location_id,
            i.qty,
            p.purchased,
            ROW_NUMBER() OVER (PARTITION BY i.product_id
                               ORDER BY p.purchased,      -- earliest purchase date first
                                        i.qty) AS rn      -- smallest qty first (tie‑breaker)
    FROM    inventory  i
    JOIN    purchases  p  ON p.id = i.purchase_id
),

earliest_inv AS (           -- 2. keep only the row picked by FIFO for every product
    SELECT product_id,
           location_id,
           qty            AS inv_qty
    FROM   first_inv
    WHERE  rn = 1
),

order_picks AS (            -- 3. quantities ordered vs. picked, but only when the pick comes from the FIFO location
    SELECT  ol.product_id,
            ol.order_id,
            ol.qty                 AS ordered_qty,
            SUM(pl.qty)            AS picked_qty,
            ei.inv_qty
    FROM   orderlines    ol
    JOIN   picking_line  pl  ON pl.order_id  = ol.order_id
                            AND pl.product_id = ol.product_id
    JOIN   earliest_inv  ei  ON ei.product_id = ol.product_id
                            AND ei.location_id = pl.location_id
    GROUP BY ol.product_id, ol.order_id
),

pick_pct_per_order AS (     -- 4. pick % for each order/product, capped to the overlap of order, pick and inventory
    SELECT  product_id,
            order_id,
            CASE
                 WHEN ordered_qty = 0 THEN 0
                 ELSE (
                       CASE                         -- min(ordered_qty , picked_qty , inv_qty)
                             WHEN ordered_qty <= picked_qty AND ordered_qty <= inv_qty THEN ordered_qty
                             WHEN picked_qty  <= ordered_qty AND picked_qty  <= inv_qty THEN picked_qty
                             ELSE inv_qty
                       END
                      ) * 1.0 / ordered_qty
            END AS pick_pct
    FROM    order_picks
)

SELECT  pr.name                              AS product_name,
        ROUND(AVG(pp.pick_pct), 4)           AS avg_pick_percentage
FROM    pick_pct_per_order pp
JOIN    products          pr ON pr.id = pp.product_id
GROUP BY pr.name
ORDER BY pr.name;