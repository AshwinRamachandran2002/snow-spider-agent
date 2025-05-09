WITH order_need AS (           -- total demand per product for order 423
    SELECT product_id,
           SUM(qty) AS need_qty
    FROM   orderlines
    WHERE  order_id = 423
    GROUP  BY product_id
),
inv AS (                       -- inventory that is in warehouse 1 and relevant
    SELECT  i.id                       AS inventory_id,
            i.product_id,
            i.qty                      AS bin_qty,
            COALESCE(p.purchased,
                     '9999-12-31')     AS purchased,      -- null‑safe for sorting
            l.aisle,
            l.position
    FROM    inventory  i
    JOIN    locations  l ON l.id = i.location_id
    LEFT    JOIN purchases p ON p.id = i.purchase_id
    WHERE   l.warehouse = 1
      AND   i.product_id IN (SELECT product_id FROM order_need)
),
calc AS (                     -- running total (oldest / smallest first)
    SELECT  inv.*,
            oned.need_qty,
            SUM(inv.bin_qty) OVER (
                 PARTITION BY inv.product_id
                 ORDER BY     inv.purchased, inv.bin_qty, inv.inventory_id
                 ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
            ) AS prior_qty                -- stock picked before this bin
    FROM    inv
    JOIN    order_need oned USING (product_id)
),
pick AS (                      -- decide how much to take from each bin
    SELECT  product_id,
            aisle,
            position,
            CASE
                 WHEN COALESCE(prior_qty,0) >= need_qty
                      THEN 0                                  -- already fulfilled
                 WHEN COALESCE(prior_qty,0) + bin_qty <= need_qty
                      THEN bin_qty                            -- take it all
                 ELSE  need_qty - COALESCE(prior_qty,0)       -- take remainder
            END AS pick_qty
    FROM    calc
)
SELECT product_id,
       aisle,
       position,
       printf('%.4f', pick_qty) AS pick_qty
FROM   pick
WHERE  pick_qty > 0                             -- only locations we will visit
ORDER BY product_id,
         CAST(substr(pick_qty,1,10) AS REAL);   -- keeps original priority