SELECT
    p."name"                                      AS "product",
    ROUND(SUM(pl."qty") * 1.0 / COUNT(*), 2)     AS "avg_units_picked"
FROM "picking_line" pl
JOIN "products"    p ON p."id" = pl."product_id"
WHERE pl."order_id" = 421
GROUP BY p."name";