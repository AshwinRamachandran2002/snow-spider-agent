WITH OrderedOrders AS (
    SELECT
        ol."order_id",
        ol."product_id",
        ol."qty" AS "ordered_qty",
        SUM(ol."qty") OVER (PARTITION BY ol."product_id" ORDER BY ol."order_id") AS "cumulative_ordered_qty"
    FROM ORACLE_SQL.ORACLE_SQL.ORDERLINES ol
),
OrderedInventory AS (
    SELECT
        i."product_id",
        p."purchased",
        i."qty" AS "inventory_qty",
        SUM(i."qty") OVER (PARTITION BY i."product_id" ORDER BY p."purchased", i."qty") AS "cumulative_inventory_qty"
    FROM ORACLE_SQL.ORACLE_SQL.INVENTORY i
    JOIN ORACLE_SQL.ORACLE_SQL.PURCHASES p ON i."purchase_id" = p."id"
),
OrderInventoryMatch AS (
    SELECT
        o."order_id",
        o."product_id",
        o."ordered_qty",
        o."cumulative_ordered_qty",
        i."cumulative_inventory_qty",
        LEAST(
            o."ordered_qty",
            GREATEST(
                0,
                i."cumulative_inventory_qty" - (o."cumulative_ordered_qty" - o."ordered_qty")
            )
        ) AS "picked_qty"
    FROM OrderedOrders o
    LEFT JOIN (
        SELECT
            "product_id",
            MAX("cumulative_inventory_qty") AS "cumulative_inventory_qty"
        FROM OrderedInventory
        GROUP BY "product_id"
    ) i ON o."product_id" = i."product_id"
),
OrderPickPercentage AS (
    SELECT
        oim."product_id",
        oim."order_id",
        oim."ordered_qty",
        oim."picked_qty",
        CASE
            WHEN oim."ordered_qty" > 0 THEN (oim."picked_qty" / oim."ordered_qty") * 100
            ELSE 0
        END AS "pick_percentage"
    FROM OrderInventoryMatch oim
)
SELECT
    p."name" AS "Product_Name",
    ROUND(AVG("pick_percentage"), 4) AS "Average_Pick_Percentage"
FROM OrderPickPercentage opp
JOIN ORACLE_SQL.ORACLE_SQL.PRODUCTS p ON opp."product_id" = p."id"
GROUP BY p."name"
ORDER BY p."name" NULLS LAST;