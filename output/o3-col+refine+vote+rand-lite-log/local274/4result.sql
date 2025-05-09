SELECT
    p.id   AS product_id,
    p.name AS product_name,
    ROUND(AVG(pl.qty), 2) AS avg_units_picked
FROM picking_line AS pl
JOIN products     AS p ON p.id = pl.product_id
WHERE pl.order_id = 421
GROUP BY p.id, p.name
ORDER BY p.id;