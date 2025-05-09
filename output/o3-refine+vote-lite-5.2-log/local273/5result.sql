WITH fifo_inventory AS (               -- 1. FIFO rule : earliest purchase, then smallest qty
    SELECT  i.id       AS inventory_id,
            i.product_id,
            i.qty      AS inv_qty,
            p.purchased,
            ROW_NUMBER() OVER (PARTITION BY i.product_id
                               ORDER BY p.purchased ASC, i.qty ASC, i.id ASC) AS rn
    FROM    inventory  AS i
    JOIN    purchases  AS p  ON p.id = i.purchase_id
),
earliest_inventory AS (                -- 2. keep the FIFO‑chosen inventory row per product
    SELECT  product_id,
            inv_qty
    FROM    fifo_inventory
    WHERE   rn = 1
),
picked_per_line AS (                   -- 3. overlap between what was picked and what is in that FIFO row
    SELECT  pl.order_id,
            pl.product_id,
            CASE 
                WHEN pl.qty < ei.inv_qty THEN pl.qty 
                ELSE ei.inv_qty 
            END                       AS picked_qty
    FROM    picking_line       AS pl
    JOIN    earliest_inventory AS ei USING (product_id)
),
picked_per_order AS (                  -- 4. sum picked quantity per order & product
    SELECT  order_id,
            product_id,
            SUM(picked_qty) AS picked_qty
    FROM    picked_per_line
    GROUP BY order_id, product_id
),
order_reqs AS (                        -- 5. ordered quantity per order & product
    SELECT  order_id,
            product_id,
            qty AS ordered_qty
    FROM    orderlines
),
order_pct AS (                         -- 6. pick‑percentage per order
    SELECT  o.product_id,
            1.0 * COALESCE(p.picked_qty,0) / o.ordered_qty  AS pick_pct
    FROM    order_reqs      AS o
    LEFT JOIN picked_per_order AS p
           ON p.order_id   = o.order_id
          AND p.product_id = o.product_id
),
avg_pct_per_product AS (               -- 7. average pick‑percentage per product
    SELECT  product_id,
            AVG(pick_pct) AS avg_pick_pct
    FROM    order_pct
    GROUP BY product_id
)
SELECT  pr.name                              AS product_name,
        ROUND(ap.avg_pick_pct,4)             AS avg_pick_percentage
FROM    avg_pct_per_product  AS ap
JOIN    products              AS pr  ON pr.id = ap.product_id
ORDER BY pr.name;