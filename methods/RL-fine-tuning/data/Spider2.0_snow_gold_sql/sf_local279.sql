WITH initial_inventory AS (
    SELECT ii."product_id", SUM(ii."qty") AS "inventory"
    FROM "ORACLE_SQL"."ORACLE_SQL"."INVENTORY" ii
    JOIN "ORACLE_SQL"."ORACLE_SQL"."PRODUCT_MINIMUMS" pm ON ii."product_id" = pm."product_id"
    GROUP BY ii."product_id"
),
product_minimums AS (
    SELECT "product_id", "qty_minimum", "qty_purchase"
    FROM "ORACLE_SQL"."ORACLE_SQL"."PRODUCT_MINIMUMS"
),
sales_2019 AS (
    SELECT
        ms."product_id",
        DATEADD(year, 1, ms."mth") AS "mth",
        ms."qty"
    FROM "ORACLE_SQL"."ORACLE_SQL"."MONTHLY_SALES" ms
    WHERE ms."mth" >= DATE '2018-01-01' AND ms."mth" <= DATE '2018-12-01' AND ms."product_id" IN (SELECT "product_id" FROM product_minimums)
),
months AS (
    SELECT DISTINCT DATEADD(year, 1, ms."mth") AS "mth"
    FROM "ORACLE_SQL"."ORACLE_SQL"."MONTHLY_SALES" ms
    WHERE ms."mth" >= DATE '2018-01-01' AND ms."mth" <= DATE '2018-12-01'
    ORDER BY "mth"
),
all_months AS (
    SELECT pm."product_id", m."mth"
    FROM product_minimums pm
    CROSS JOIN months m
),
sales_data AS (
    SELECT am."product_id", am."mth", COALESCE(s."qty", 0) AS "qty"
    FROM all_months am
    LEFT JOIN sales_2019 s ON am."product_id" = s."product_id" AND am."mth" = s."mth"
),
recursive_inventory AS (
    SELECT
        s."product_id",
        s."mth",
        ii."inventory" AS "starting_inventory",
        ii."inventory" - s."qty" AS "ending_inventory",
        CASE WHEN ii."inventory" - s."qty" < pm."qty_minimum" THEN pm."qty_purchase" ELSE 0 END AS "restocked_qty",
        CASE WHEN ii."inventory" - s."qty" < pm."qty_minimum" THEN ii."inventory" - s."qty" + pm."qty_purchase" ELSE ii."inventory" - s."qty" END AS "new_inventory"
    FROM sales_data s
    JOIN initial_inventory ii ON s."product_id" = ii."product_id"
    JOIN product_minimums pm ON s."product_id" = pm."product_id"
    WHERE s."mth" = (SELECT MIN("mth") FROM months)
    
    UNION ALL
    
    SELECT
        s."product_id",
        s."mth",
        ri."new_inventory" AS "starting_inventory",
        ri."new_inventory" - s."qty" AS "ending_inventory",
        CASE WHEN ri."new_inventory" - s."qty" < pm."qty_minimum" THEN pm."qty_purchase" ELSE 0 END AS "restocked_qty",
        CASE WHEN ri."new_inventory" - s."qty" < pm."qty_minimum" THEN ri."new_inventory" - s."qty" + pm."qty_purchase" ELSE ri."new_inventory" - s."qty" END AS "new_inventory"
    FROM sales_data s
    JOIN recursive_inventory ri ON s."product_id" = ri."product_id" AND s."mth" = DATEADD(month, 1, ri."mth")
    JOIN product_minimums pm ON s."product_id" = pm."product_id"
),
final_inventory AS (
    SELECT
        ri."product_id",
        ri."mth",
        ri."ending_inventory",
        ri."restocked_qty",
        ri."new_inventory",
        pm."qty_minimum",
        ABS(ri."ending_inventory" - pm."qty_minimum") AS "abs_difference"
    FROM recursive_inventory ri
    JOIN product_minimums pm ON ri."product_id" = pm."product_id"
)
SELECT
    fi."product_id",
    TO_CHAR(fi."mth", 'YYYY-MM') AS "month",
    ROUND(fi."abs_difference", 4) AS "absolute_difference"
FROM (
    SELECT
        fi.*,
        ROW_NUMBER() OVER (PARTITION BY fi."product_id" ORDER BY fi."abs_difference" ASC, fi."mth") AS rn
    FROM final_inventory fi
) fi
WHERE fi.rn = 1
ORDER BY fi."product_id";