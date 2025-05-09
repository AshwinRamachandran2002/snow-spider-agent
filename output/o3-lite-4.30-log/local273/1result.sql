WITH demand AS (                     -- total quantity requested in the picking lines
    SELECT product_id,
           SUM(qty) AS demand_qty
    FROM   picking_line
    GROUP  BY product_id
),
/* inventory rows ordered FIFO: earliest purchase date first,
   then the smallest quantity – the order is kept even if we only
   need the summed quantity later                                     */
inv_fifo AS (
    SELECT inv.product_id,
           inv.qty,
           ROW_NUMBER() OVER (PARTITION BY inv.product_id
                              ORDER BY pur.purchased, inv.qty) AS rn
    FROM   inventory AS inv
    JOIN   purchases AS pur
           ON pur.id = inv.purchase_id
),
supply AS (                           -- total quantity currently available
    SELECT product_id,
           SUM(qty) AS supply_qty
    FROM   inv_fifo
    GROUP  BY product_id
),
/* overlap (picked) = the smaller of what is needed vs what is on hand */
pick_calc AS (
    SELECT d.product_id,
           d.demand_qty,
           s.supply_qty,
           CASE
               WHEN s.supply_qty < d.demand_qty
               THEN s.supply_qty
               ELSE d.demand_qty
           END AS picked_qty
    FROM   demand d
    JOIN   supply s USING (product_id)
)
SELECT  pr.name AS product_name,
        ROUND(1.0 * picked_qty / demand_qty, 4) AS average_pick_percentage
FROM    pick_calc pc
JOIN    products  pr
        ON pr.id = pc.product_id
ORDER BY pr.name;