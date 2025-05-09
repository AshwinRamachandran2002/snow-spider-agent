WITH
products AS (
    SELECT "id" AS "product_id", "name" AS "Product_Name"
    FROM "ORACLE_SQL"."ORACLE_SQL"."PRODUCTS"
),
total_ordered AS (
    SELECT
        "product_id",
        SUM("qty") AS "total_ordered_quantity"
    FROM
        "ORACLE_SQL"."ORACLE_SQL"."ORDERLINES"
    GROUP BY
        "product_id"
),
inventories AS (
    SELECT
        i."product_id",
        pu."purchased",
        i."qty" AS "inventory_qty",
        SUM(i."qty") OVER (
            PARTITION BY i."product_id"
            ORDER BY pu."purchased", i."qty"
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS "cumulative_inventory_qty",
        o."total_ordered_quantity"
    FROM
        "ORACLE_SQL"."ORACLE_SQL"."INVENTORY" i
    JOIN
        "ORACLE_SQL"."ORACLE_SQL"."PURCHASES" pu ON i."purchase_id" = pu."id"
    LEFT JOIN
        total_ordered o ON i."product_id" = o."product_id"
),
picked_inventories AS (
    SELECT
        "product_id",
        "inventory_qty",
        "cumulative_inventory_qty",
        "total_ordered_quantity",
        CASE
            WHEN "total_ordered_quantity" IS NULL THEN 0
            WHEN "cumulative_inventory_qty" - "inventory_qty" >= "total_ordered_quantity" THEN 0
            WHEN "cumulative_inventory_qty" >= "total_ordered_quantity" THEN "total_ordered_quantity" - ("cumulative_inventory_qty" - "inventory_qty")
            ELSE "inventory_qty"
        END AS "picked_qty"
    FROM inventories
),
total_picked AS (
    SELECT
        "product_id",
        SUM("picked_qty") AS "total_picked_quantity",
        MAX("total_ordered_quantity") AS "total_ordered_quantity"
    FROM picked_inventories
    GROUP BY "product_id"
),
product_pick_percentage AS (
    SELECT
        p."Product_Name",
        t."total_ordered_quantity",
        t."total_picked_quantity",
        CASE WHEN t."total_ordered_quantity" IS NULL OR t."total_ordered_quantity" = 0 THEN NULL
        ELSE (t."total_picked_quantity" / t."total_ordered_quantity") * 100
        END AS "Average_Pick_Percentage"
    FROM products p
    LEFT JOIN total_picked t ON p."product_id" = t."product_id"
)
SELECT
    "Product_Name",
    COALESCE(ROUND("Average_Pick_Percentage", 4), 0) AS "Average_Pick_Percentage"
FROM product_pick_percentage
ORDER BY "Product_Name"