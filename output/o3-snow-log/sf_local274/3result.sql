/*  Average quantity picked per product for order 421 (FIFO order of lines does not change the result) */
SELECT
    "product_id",
    AVG("qty") AS "avg_units_picked"
FROM ORACLE_SQL.ORACLE_SQL."PICKING_LINE"
WHERE "order_id" = 421
GROUP BY "product_id"
ORDER BY "product_id";