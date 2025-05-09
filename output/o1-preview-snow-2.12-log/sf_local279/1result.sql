WITH AverageMonthlySales AS (
    SELECT ms."product_id", AVG(ms."qty") AS "avg_monthly_sales"
    FROM "ORACLE_SQL"."ORACLE_SQL"."MONTHLY_SALES" ms
    GROUP BY ms."product_id"
),
StartingInventory AS (
    SELECT inv."product_id", SUM(inv."qty") AS "starting_inventory"
    FROM "ORACLE_SQL"."ORACLE_SQL"."INVENTORY" inv
    GROUP BY inv."product_id"
),
ProductMinimums AS (
    SELECT pm."product_id", pm."qty_minimum", pm."qty_purchase"
    FROM "ORACLE_SQL"."ORACLE_SQL"."PRODUCT_MINIMUMS" pm
),
RecursiveInventory AS (
    SELECT
        si."product_id",
        TO_DATE('2018-12-01') AS "mth",
        si."starting_inventory" AS "ending_inventory",
        si."starting_inventory" AS "adjusted_inventory",
        1 AS "month_number"
    FROM StartingInventory si

    UNION ALL

    SELECT
        ri."product_id",
        DATEADD('month', 1, ri."mth") AS "mth",
        CASE
            WHEN ri."adjusted_inventory" - COALESCE(ams."avg_monthly_sales", 0) < pm."qty_minimum"
            THEN ri."adjusted_inventory" - COALESCE(ams."avg_monthly_sales", 0) + pm."qty_purchase"
            ELSE ri."adjusted_inventory" - COALESCE(ams."avg_monthly_sales", 0)
        END AS "ending_inventory",
        CASE
            WHEN ri."adjusted_inventory" - COALESCE(ams."avg_monthly_sales", 0) < pm."qty_minimum"
            THEN ri."adjusted_inventory" - COALESCE(ams."avg_monthly_sales", 0) + pm."qty_purchase"
            ELSE ri."adjusted_inventory" - COALESCE(ams."avg_monthly_sales", 0)
        END AS "adjusted_inventory",
        ri."month_number" + 1 AS "month_number"
    FROM RecursiveInventory ri
    LEFT JOIN AverageMonthlySales ams ON ri."product_id" = ams."product_id"
    LEFT JOIN ProductMinimums pm ON ri."product_id" = pm."product_id"
    WHERE ri."month_number" < 13  -- Limit recursion to 12 months for 2019
)
SELECT
    final_ri."product_id",
    TO_CHAR(final_ri."mth", 'YYYY-MM') AS "month",
    ROUND(ABS(final_ri."ending_inventory" - pm."qty_minimum"), 4) AS "absolute_difference"
FROM (
    SELECT
        ri."product_id",
        ri."mth",
        ri."ending_inventory",
        pm."qty_minimum",
        ROW_NUMBER() OVER (
            PARTITION BY ri."product_id" 
            ORDER BY ABS(ri."ending_inventory" - pm."qty_minimum") ASC, ri."mth"
        ) AS rn
    FROM RecursiveInventory ri
    JOIN ProductMinimums pm ON ri."product_id" = pm."product_id"
    WHERE ri."mth" >= '2019-01-01' AND ri."mth" < '2020-01-01'
) final_ri
JOIN ProductMinimums pm ON final_ri."product_id" = pm."product_id"
WHERE final_ri.rn = 1
ORDER BY final_ri."product_id";