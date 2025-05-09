SELECT
       pl."product_id",
       AVG(pl."qty") AS avg_picked_qty
FROM "ORACLE_SQL"."ORACLE_SQL"."PICKING_LINE" pl
WHERE pl."order_id" = 421
GROUP BY pl."product_id"
ORDER BY pl."product_id";