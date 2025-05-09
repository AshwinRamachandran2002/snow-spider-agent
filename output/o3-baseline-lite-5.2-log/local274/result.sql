SELECT
        pl.product_id,
        pr.name               AS product_name,
        ROUND(AVG(pl.qty),4)  AS avg_units_picked
FROM        picking_line   pl
JOIN        picking_list   plst ON pl.picklist_id = plst.id          -- bring in pick‑list header (FIFO created time)
JOIN        products       pr   ON pr.id          = pl.product_id    -- to show product name
WHERE       pl.order_id    = 421                                     -- the order we are analysing
GROUP BY    pl.product_id, pr.name
ORDER BY    pl.product_id;