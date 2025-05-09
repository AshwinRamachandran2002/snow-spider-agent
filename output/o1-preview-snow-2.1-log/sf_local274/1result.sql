SELECT 
    pl."product_id",
    p."name" AS "product_name",
    ROUND(AVG(pl."qty"), 4) AS "average_units_picked_per_batch"
FROM 
    "ORACLE_SQL"."ORACLE_SQL"."PICKING_LINE" pl
JOIN 
    "ORACLE_SQL"."ORACLE_SQL"."INVENTORY" inv
    ON pl."product_id" = inv."product_id" AND pl."location_id" = inv."location_id"
JOIN 
    "ORACLE_SQL"."ORACLE_SQL"."PURCHASES" pur
    ON inv."purchase_id" = pur."id"
JOIN 
    "ORACLE_SQL"."ORACLE_SQL"."PRODUCTS" p
    ON pl."product_id" = p."id"
WHERE 
    pl."order_id" = 421
GROUP BY 
    pl."product_id", p."name"
ORDER BY 
    MIN(pur."purchased") ASC;