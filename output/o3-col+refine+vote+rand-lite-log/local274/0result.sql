WITH picked AS (
    SELECT ln.product_id,
           ln.qty
    FROM   picking_line AS ln
    JOIN   picking_log  AS lg
           ON  lg.picklist_id = ln.picklist_id
           AND lg.pickline_no = ln.line_no
           AND lg.activity    = 'P'          -- lines actually picked
    WHERE  ln.order_id = 421
)
SELECT pr.name                         AS product_name,
       ROUND(AVG(p.qty), 2)            AS avg_units_picked
FROM   picked AS p
JOIN   products AS pr ON pr.id = p.product_id
GROUP  BY pr.name;