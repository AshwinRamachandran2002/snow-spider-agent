SELECT
        pl.product_id,
        pr.name            AS product_name,
        AVG(pl.qty)        AS avg_units_picked
FROM    picking_line AS pl
JOIN    products     AS pr ON pr.id = pl.product_id
WHERE   pl.order_id = 421
GROUP BY
        pl.product_id,
        pr.name;