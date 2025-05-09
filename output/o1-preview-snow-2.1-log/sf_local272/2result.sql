WITH order_products AS (
    SELECT "product_id", "qty" AS "ordered_qty"
    FROM ORACLE_SQL.ORACLE_SQL.ORDERLINES
    WHERE "order_id" = 423
),
inventory_with_details AS (
    SELECT
        I."product_id",
        I."qty" AS "inventory_qty",
        L."aisle",
        L."position",
        P."purchased" AS "purchase_date"
    FROM ORACLE_SQL.ORACLE_SQL.INVENTORY I
    JOIN ORACLE_SQL.ORACLE_SQL.LOCATIONS L ON I."location_id" = L."id"
    JOIN ORACLE_SQL.ORACLE_SQL.PURCHASES P ON I."purchase_id" = P."id"
    WHERE L."warehouse" = 1
    AND I."product_id" IN (SELECT "product_id" FROM order_products)
),
ordered_inventory AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY "product_id" ORDER BY "purchase_date" ASC, "inventory_qty" ASC) AS rn
    FROM inventory_with_details
),
inventory_cumulative AS (
    SELECT
        oi.*,
        SUM("inventory_qty") OVER (PARTITION BY "product_id" ORDER BY rn) AS cumulative_qty
    FROM ordered_inventory oi
),
to_pick AS (
    SELECT
        ic."product_id",
        ic."aisle",
        ic."position",
        ic."purchase_date",
        ic."inventory_qty",
        CASE
            WHEN ic.cumulative_qty <= op."ordered_qty" THEN ic."inventory_qty"
            WHEN ic.cumulative_qty - ic."inventory_qty" >= op."ordered_qty" THEN 0
            ELSE op."ordered_qty" - (ic.cumulative_qty - ic."inventory_qty")
        END AS "qty_to_pick"
    FROM inventory_cumulative ic
    JOIN order_products op ON ic."product_id" = op."product_id"
    WHERE ic.cumulative_qty - ic."inventory_qty" < op."ordered_qty"
),
final_pick AS (
    SELECT *
    FROM to_pick
    WHERE "qty_to_pick" > 0
)
SELECT "product_id", "aisle", "position", "qty_to_pick"
FROM final_pick
ORDER BY "product_id", "purchase_date", "inventory_qty";