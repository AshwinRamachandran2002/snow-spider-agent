SELECT
    p.name  AS product_name,
    AVG(pl.qty) AS avg_units_picked
FROM   picking_line AS pl
JOIN   products     AS p ON p.id = pl.product_id
WHERE  pl.order_id = 421
GROUP  BY p.id, p.name;