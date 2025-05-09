WITH inv AS (               -- total on-hand inventory (supply side)
    SELECT  i.product_id,
            pr.name                          AS product_name,
            SUM(i.qty)                       AS total_inv_qty
    FROM    inventory       AS i
    JOIN    products        AS pr ON pr.id = i.product_id
    GROUP BY i.product_id
),
pick AS (                   -- total quantity that has been picked (demand side)
    SELECT  pl.product_id,
            SUM(pl.qty)                      AS total_pick_qty
    FROM    picking_line    AS pl
    GROUP BY pl.product_id
),
sup_dem AS (                -- merge supply & demand per product
    SELECT  inv.product_name,
            inv.total_inv_qty,
            COALESCE(pick.total_pick_qty,0)  AS total_pick_qty
    FROM    inv
    LEFT JOIN pick ON pick.product_id = inv.product_id
)
SELECT  product_name,
        ROUND(
            CASE                     -- FIFO overlap  (cannot exceed 100 %)
                 WHEN total_inv_qty = 0                     THEN 0
                 WHEN total_pick_qty >= total_inv_qty       THEN 100.0
                 ELSE (total_pick_qty * 100.0) / total_inv_qty
            END
        ,2)  AS avg_pick_pct
FROM    sup_dem
ORDER BY product_name;