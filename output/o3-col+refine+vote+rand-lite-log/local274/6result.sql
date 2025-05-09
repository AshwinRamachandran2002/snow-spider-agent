SELECT
        pr.name AS product_name,
        ROUND(AVG(pl.qty), 2) AS avg_units_picked
FROM        picking_log  AS lg
JOIN        picking_line AS pl
           ON  pl.picklist_id = lg.picklist_id
           AND pl.line_no     = lg.pickline_no
JOIN        products     AS pr
           ON  pr.id = pl.product_id
WHERE       pl.order_id = 421          -- only lines belonging to order 421
  AND       lg.activity = 'P'          -- only the actual FIFO pick events
GROUP BY    pr.name
ORDER BY    pr.name;