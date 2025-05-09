WITH picked_lines AS (
    /* only the lines that were actually picked (activity = 'P') */
    SELECT DISTINCT pl.*
    FROM picking_line  AS pl
    JOIN picking_log   AS lg
          ON lg.picklist_id = pl.picklist_id
         AND lg.pickline_no = pl.line_no
         AND lg.activity    = 'P'
    WHERE pl.order_id = 421
)
SELECT
       p.id   AS product_id,
       p.name AS product_name,
       ROUND(AVG(pl.qty),4) AS avg_units_picked
FROM   picked_lines AS pl
JOIN   products      AS p  ON p.id = pl.product_id
GROUP  BY p.id, p.name
ORDER  BY p.id;