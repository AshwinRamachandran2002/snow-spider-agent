WITH fifo_picks AS (
    /* all pick‑lines for the required order, ordered FIFO:
       first by the time the picking‑list was created,
       then by the line number inside that list               */
    SELECT pl.picklist_id,
           pl.line_no,
           pl.product_id,
           pl.qty
    FROM   picking_line  pl
    JOIN   picking_list  plst
           ON pl.picklist_id = plst.id
    WHERE  pl.order_id = 421
    ORDER  BY plst.created, pl.line_no            -- FIFO order
)
SELECT  fp.product_id,
        p.name                     AS product_name,
        ROUND(AVG(fp.qty),4)       AS avg_units_picked
FROM    fifo_picks fp
JOIN    products    p  ON p.id = fp.product_id
GROUP BY fp.product_id, p.name
ORDER  BY fp.product_id;