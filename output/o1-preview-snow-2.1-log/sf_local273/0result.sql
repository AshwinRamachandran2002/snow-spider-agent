SELECT
    p."name" AS "Product_Name",
    ROUND(
        CASE WHEN o."total_ordered_qty" > 0 THEN
            (LEAST(o."total_ordered_qty", inv."total_inventory_qty") / o."total_ordered_qty") * 100
        ELSE
            0
        END, 4) AS "Average_Pick_Percentage"
FROM
    ORACLE_SQL.ORACLE_SQL.PRODUCTS p
LEFT JOIN (
    SELECT "product_id", SUM("qty") AS "total_ordered_qty"
    FROM ORACLE_SQL.ORACLE_SQL.ORDERLINES
    GROUP BY "product_id"
) o ON p."id" = o."product_id"
LEFT JOIN (
    SELECT "product_id", SUM("qty") AS "total_inventory_qty"
    FROM ORACLE_SQL.ORACLE_SQL.INVENTORY
    GROUP BY "product_id"
) inv ON p."id" = inv."product_id"
WHERE
    o."total_ordered_qty" > 0;