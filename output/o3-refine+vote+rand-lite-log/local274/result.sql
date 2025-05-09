WITH pick_events AS (          -- all actual (FIFO‑time‑stamped) pickings for order 421
    SELECT  l.product_id,
            l.qty
    FROM    picking_line  AS l
    JOIN    picking_log   AS g
           ON g.picklist_id = l.picklist_id      -- same picking list
          AND g.activity   = 'P'                 -- the real “pick” event
          AND g.pickline_no= l.line_no           -- same line within the list
    WHERE   l.order_id     = 421
),
avg_per_product AS (           -- average quantity per product
    SELECT  product_id,
            AVG(qty) AS avg_units
    FROM    pick_events
    GROUP BY product_id
)
SELECT  pr.name        AS product_name,
        ROUND(a.avg_units,4) AS avg_units_picked
FROM    avg_per_product AS a
JOIN    products        AS pr
      ON pr.id = a.product_id
ORDER BY pr.name;