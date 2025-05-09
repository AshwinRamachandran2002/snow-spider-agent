WITH total_ordered AS (
    SELECT "product_id", SUM("qty") AS "total_ordered_qty"
    FROM "ORACLE_SQL"."ORACLE_SQL"."ORDERLINES"
    GROUP BY "product_id"
),
inventory_ordered AS (
    SELECT
        i."product_id",
        i."qty" AS "inventory_qty",
        p."purchased",
        ROW_NUMBER() OVER (PARTITION BY i."product_id" ORDER BY p."purchased" ASC, i."qty" ASC) AS inv_rank
    FROM
        "ORACLE_SQL"."ORACLE_SQL"."INVENTORY" i
    JOIN
        "ORACLE_SQL"."ORACLE_SQL"."PURCHASES" p
    ON
        i."purchase_id" = p."id"
),
inventory_cumsum AS (
    SELECT
        io."product_id",
        io."inventory_qty",
        io."purchased",
        SUM(io."inventory_qty") OVER (PARTITION BY io."product_id" ORDER BY io.inv_rank) AS "cumulative_inventory"
    FROM
        inventory_ordered io
),
picked_inventory AS (
    SELECT
        ic."product_id",
        CASE
            WHEN total_o."total_ordered_qty" >= ic."cumulative_inventory" THEN ic."inventory_qty"
            WHEN total_o."total_ordered_qty" < ic."cumulative_inventory" - ic."inventory_qty" THEN 0
            ELSE total_o."total_ordered_qty" - (ic."cumulative_inventory" - ic."inventory_qty")
        END AS "picked_qty"
    FROM
        inventory_cumsum ic
    JOIN
        total_ordered total_o ON ic."product_id" = total_o."product_id"
),
total_picked AS (
    SELECT
        "product_id",
        SUM("picked_qty") AS "total_picked_qty"
    FROM
        picked_inventory
    GROUP BY
        "product_id"
),
pick_percentage AS (
    SELECT
        total_o."product_id",
        total_o."total_ordered_qty",
        COALESCE(total_picked."total_picked_qty", 0) AS "total_picked_qty",
        (COALESCE(total_picked."total_picked_qty", 0) / total_o."total_ordered_qty") AS "pick_percentage"
    FROM
        total_ordered total_o
    LEFT JOIN
        total_picked ON total_o."product_id" = total_picked."product_id"
)
SELECT
    p."name" AS "Product_Name",
    ROUND(pp."pick_percentage" * 100, 4) AS "Average_Pick_Percentage"
FROM
    pick_percentage pp
JOIN
    "ORACLE_SQL"."ORACLE_SQL"."PRODUCTS" p ON pp."product_id" = p."id"
ORDER BY
    "Product_Name";