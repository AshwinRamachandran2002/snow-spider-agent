WITH starting_inventory AS (
    SELECT
        p."id" AS "product_id",
        COALESCE(purchases_before_2019."cumulative_purchases", 0.0) - COALESCE(sales_before_2019."cumulative_sales", 0.0) AS "starting_inventory"
    FROM "ORACLE_SQL"."ORACLE_SQL"."PRODUCTS" p
    LEFT JOIN (
        SELECT "product_id", SUM(CAST("qty" AS FLOAT)) AS "cumulative_purchases"
        FROM "ORACLE_SQL"."ORACLE_SQL"."PURCHASES"
        WHERE "purchased" < '2019-01-01'
        GROUP BY "product_id"
    ) purchases_before_2019 ON p."id" = purchases_before_2019."product_id"
    LEFT JOIN (
        SELECT "product_id", SUM(CAST("qty" AS FLOAT)) AS "cumulative_sales"
        FROM "ORACLE_SQL"."ORACLE_SQL"."MONTHLY_SALES"
        WHERE "mth" < '2019-01-01'
        GROUP BY "product_id"
    ) sales_before_2019 ON p."id" = sales_before_2019."product_id"
),
months AS (
    SELECT DATEADD(month, ROW_NUMBER() OVER (ORDER BY NULL) - 1, '2019-01-01'::DATE) AS "month"
    FROM TABLE(GENERATOR(ROWCOUNT => 12))
),
product_minimums AS (
    SELECT "product_id", "qty_minimum", "qty_purchase"
    FROM "ORACLE_SQL"."ORACLE_SQL"."PRODUCT_MINIMUMS"
),
sales_2019 AS (
    SELECT "product_id", TO_DATE("mth") AS "month", SUM(CAST("qty" AS FLOAT)) AS "sales_qty"
    FROM "ORACLE_SQL"."ORACLE_SQL"."MONTHLY_SALES"
    WHERE "mth" >= '2019-01-01' AND "mth" < '2020-01-01'
    GROUP BY "product_id", "mth"
),
purchases_2019 AS (
    SELECT "product_id", DATE_TRUNC('month', TO_DATE("purchased")) AS "month", SUM(CAST("qty" AS FLOAT)) AS "purchase_qty"
    FROM "ORACLE_SQL"."ORACLE_SQL"."PURCHASES"
    WHERE "purchased" >= '2019-01-01' AND "purchased" < '2020-01-01'
    GROUP BY "product_id", DATE_TRUNC('month', TO_DATE("purchased"))
),
product_months AS (
    SELECT DISTINCT p."product_id", m."month"
    FROM starting_inventory p
    INNER JOIN product_minimums pmn ON p."product_id" = pmn."product_id"
    CROSS JOIN months m
),
inventory_simulation AS (
    /* Anchor member */
    SELECT
        pm."product_id",
        pm."month",
        si."starting_inventory" AS "beginning_inventory",
        COALESCE(pur."purchase_qty", 0.0) AS "purchases",
        COALESCE(s."sales_qty", 0.0) AS "sales",
        si."starting_inventory" + COALESCE(pur."purchase_qty", 0.0) - COALESCE(s."sales_qty", 0.0) AS "ending_inventory_before_restocking",
        CASE WHEN si."starting_inventory" + COALESCE(pur."purchase_qty", 0.0) - COALESCE(s."sales_qty", 0.0) < pmn."qty_minimum" THEN pmn."qty_purchase" ELSE 0.0 END AS "restock_qty",
        (si."starting_inventory" + COALESCE(pur."purchase_qty", 0.0) - COALESCE(s."sales_qty", 0.0)) + CASE WHEN si."starting_inventory" + COALESCE(pur."purchase_qty", 0.0) - COALESCE(s."sales_qty", 0.0) < pmn."qty_minimum" THEN pmn."qty_purchase" ELSE 0.0 END AS "ending_inventory",
        ((si."starting_inventory" + COALESCE(pur."purchase_qty", 0.0) - COALESCE(s."sales_qty", 0.0)) + CASE WHEN si."starting_inventory" + COALESCE(pur."purchase_qty", 0.0) - COALESCE(s."sales_qty",0.0) < pmn."qty_minimum" THEN pmn."qty_purchase" ELSE 0.0 END) - pmn."qty_minimum" AS "difference"
    FROM product_months pm
    INNER JOIN starting_inventory si ON pm."product_id" = si."product_id"
    LEFT JOIN sales_2019 s ON pm."product_id" = s."product_id" AND pm."month" = s."month"
    LEFT JOIN purchases_2019 pur ON pm."product_id" = pur."product_id" AND pm."month" = pur."month"
    INNER JOIN product_minimums pmn ON pm."product_id" = pmn."product_id"
    WHERE pm."month" = '2019-01-01'::DATE

    UNION ALL

    /* Recursive member */
    SELECT
        pm."product_id",
        pm."month",
        is_prev."ending_inventory" AS "beginning_inventory",
        COALESCE(pur."purchase_qty", 0.0) AS "purchases",
        COALESCE(s."sales_qty", 0.0) AS "sales",
        is_prev."ending_inventory" + COALESCE(pur."purchase_qty",0.0) - COALESCE(s."sales_qty",0.0) AS "ending_inventory_before_restocking",
        CASE WHEN is_prev."ending_inventory" + COALESCE(pur."purchase_qty",0.0) - COALESCE(s."sales_qty",0.0) < pmn."qty_minimum" THEN pmn."qty_purchase" ELSE 0.0 END AS "restock_qty",
        (is_prev."ending_inventory" + COALESCE(pur."purchase_qty",0.0) - COALESCE(s."sales_qty",0.0)) + CASE WHEN is_prev."ending_inventory" + COALESCE(pur."purchase_qty",0.0) - COALESCE(s."sales_qty",0.0) < pmn."qty_minimum" THEN pmn."qty_purchase" ELSE 0.0 END AS "ending_inventory",
        ((is_prev."ending_inventory" + COALESCE(pur."purchase_qty",0.0) - COALESCE(s."sales_qty",0.0)) + CASE WHEN is_prev."ending_inventory" + COALESCE(pur."purchase_qty",0.0) - COALESCE(s."sales_qty",0.0) < pmn."qty_minimum" THEN pmn."qty_purchase" ELSE 0.0 END) - pmn."qty_minimum" AS "difference"
    FROM product_months pm
    INNER JOIN inventory_simulation is_prev ON pm."product_id" = is_prev."product_id" AND DATEADD(month, -1, pm."month") = is_prev."month"
    LEFT JOIN sales_2019 s ON pm."product_id" = s."product_id" AND pm."month" = s."month"
    LEFT JOIN purchases_2019 pur ON pm."product_id" = pur."product_id" AND pm."month" = pur."month"
    INNER JOIN product_minimums pmn ON pm."product_id" = pmn."product_id"
)
SELECT
    "product_id",
    TO_CHAR("month", 'YYYY-MM') AS "month",
    ROUND("difference", 4) AS "smallest_difference"
FROM (
    SELECT
        "product_id",
        "month",
        "difference",
        ROW_NUMBER() OVER (PARTITION BY "product_id" ORDER BY "difference" ASC, "month" ASC) AS rn
    FROM inventory_simulation
)
WHERE rn = 1
ORDER BY "product_id";