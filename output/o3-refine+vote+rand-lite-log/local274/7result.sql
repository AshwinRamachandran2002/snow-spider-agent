SELECT
        pl.product_id,
        pr.name  AS product_name,
        AVG(pl.qty) AS avg_units_picked
FROM    picking_line   pl
JOIN    products       pr ON pr.id = pl.product_id
WHERE   pl.order_id = 421              -- lines that fulfil order 421
GROUP BY
        pl.product_id,
        pr.name;