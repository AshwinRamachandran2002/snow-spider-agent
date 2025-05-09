WITH products AS (
    SELECT p."id" AS "product_id", pm."qty_minimum", pm."qty_purchase"
    FROM ORACLE_SQL.ORACLE_SQL.PRODUCTS p
    JOIN ORACLE_SQL.ORACLE_SQL.PRODUCT_MINIMUMS pm ON p."id" = pm."product_id"
),
months AS (
    SELECT TO_DATE('2019-01-01') AS "month"
    UNION ALL
    SELECT DATEADD(MONTH, 1, "month") FROM months WHERE "month" < '2019-12-01'
),
product_months AS (
    SELECT p."product_id", m."month", p."qty_minimum", p."qty_purchase"
    FROM products p CROSS JOIN months m
),
sales AS (
    SELECT "product_id", "mth" AS "month", SUM("qty") AS "sales_qty"
    FROM ORACLE_SQL.ORACLE_SQL.MONTHLY_SALES
    WHERE "mth" >= '2019-01-01' AND "mth" < '2020-01-01'
    GROUP BY "product_id", "mth"
),
initial_inventory AS (
    SELECT "product_id",
        SUM("qty") AS "starting_inventory"
    FROM (
        SELECT "product_id", SUM("qty") AS "qty"
        FROM ORACLE_SQL.ORACLE_SQL.INVENTORY
        GROUP BY "product_id"
        UNION ALL
        SELECT "product_id", SUM("qty") AS "qty"
        FROM ORACLE_SQL.ORACLE_SQL.PURCHASES
        WHERE "purchased" < '2019-01-01'
        GROUP BY "product_id"
        UNION ALL
        SELECT "product_id", -SUM("qty") AS "qty"
        FROM ORACLE_SQL.ORACLE_SQL.MONTHLY_SALES
        WHERE "mth" < '2019-01-01'
        GROUP BY "product_id"
    ) t
    GROUP BY "product_id"
),
cumulative_sales AS (
    SELECT pm."product_id", pm."month", 
        SUM(COALESCE(s."sales_qty", 0)) OVER (PARTITION BY pm."product_id" ORDER BY pm."month") AS "cum_sales"
    FROM product_months pm
    LEFT JOIN sales s ON pm."product_id" = s."product_id" AND pm."month" = s."month"
),
inventory_levels AS (
    SELECT
        cs."product_id",
        cs."month",
        cs."cum_sales",
        p."qty_minimum",
        p."qty_purchase",
        COALESCE(ii."starting_inventory", 0) - cs."cum_sales" AS "inventory_before_restock"
    FROM cumulative_sales cs
    JOIN products p ON cs."product_id" = p."product_id"
    LEFT JOIN initial_inventory ii ON cs."product_id" = ii."product_id"
),
inventory_with_restock AS (
    SELECT
        il.*,
        CASE WHEN "inventory_before_restock" < "qty_minimum" THEN "qty_purchase" ELSE 0 END AS "restock_qty",
        ("inventory_before_restock" + CASE WHEN "inventory_before_restock" < "qty_minimum" THEN "qty_purchase" ELSE 0 END) AS "ending_inventory"
    FROM inventory_levels il
),
differences AS (
    SELECT
        "product_id",
        "month",
        ("ending_inventory" - "qty_minimum") AS "difference"
    FROM inventory_with_restock
),
min_differences AS (
    SELECT
        "product_id",
        "month",
        ROUND("difference", 4) AS "smallest_difference",
        ROW_NUMBER() OVER (PARTITION BY "product_id" ORDER BY ABS("difference")) AS rn
    FROM differences
)
SELECT
    "product_id",
    TO_CHAR("month", 'YYYY-MM') AS "month",
    "smallest_difference"
FROM min_differences
WHERE rn = 1
ORDER BY "product_id";