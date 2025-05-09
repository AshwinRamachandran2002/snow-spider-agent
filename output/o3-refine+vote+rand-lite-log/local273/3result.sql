WITH order_line AS (
    /* every order‑line with the quantity that was requested          */
    SELECT   ol.order_id,
             ol.product_id,
             ol.qty               AS ordered_qty
    FROM     orderlines AS ol
),
picked_qty AS (
    /* quantity that was actually picked for the same order & product */
    SELECT   pl.order_id,
             pl.product_id,
             SUM(pl.qty)          AS picked_qty
    FROM     picking_line AS pl
    GROUP BY pl.order_id,
             pl.product_id
),
pick_ratio AS (
    /* ratio (picked / ordered) per order‑line                        */
    SELECT   o.product_id,
             COALESCE(p.picked_qty,0)                     AS picked_qty,
             o.ordered_qty,
             /* avoid division by zero                              */
             CASE WHEN o.ordered_qty = 0 
                  THEN 0
                  ELSE 1.0 * COALESCE(p.picked_qty,0) / o.ordered_qty 
             END                             AS pick_pct
    FROM     order_line AS o
    LEFT JOIN picked_qty AS p
           ON p.order_id   = o.order_id
          AND p.product_id = o.product_id
)
SELECT   pr.name                             AS product_name,
         ROUND(AVG(pick_pct)*100,4)          AS avg_pick_percentage
FROM     pick_ratio   AS r
JOIN     products     AS pr
       ON pr.id = r.product_id
GROUP BY pr.name
ORDER BY pr.name;