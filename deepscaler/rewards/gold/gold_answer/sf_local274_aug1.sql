-- Task: Which products were picked for order 421, and how many units were picked for each product?
SELECT 
    pl."product_id", 
    SUM(pl."qty") AS "picked_qty"
FROM "ORACLE_SQL"."ORACLE_SQL"."PICKING_LINE" pl
WHERE pl."order_id" = 421
GROUP BY pl."product_id";