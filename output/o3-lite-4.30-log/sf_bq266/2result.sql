WITH sales_2020 AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ("created_at" / 1000000.0)) AS "month",
        "product_id"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"
    WHERE "status" = 'Complete'
      AND YEAR(TO_TIMESTAMP_NTZ("created_at" / 1000000.0)) = 2020
),
profit_per_product AS (
    SELECT
        s."month",
        p."id"                             AS "product_id",
        p."name"                           AS "product_name",
        p."retail_price" - p."cost"        AS "profit"
    FROM sales_2020 s
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" p
      ON p."id" = s."product_id"
),
min_profit_per_month AS (
    SELECT
        "month",
        MIN("profit") AS "min_profit"
    FROM profit_per_product
    GROUP BY "month"
)
SELECT DISTINCT
    TO_CHAR(mp."month", 'YYYY-MM') AS "month",
    pp."product_name"
FROM min_profit_per_month mp
JOIN profit_per_product pp
  ON pp."month"  = mp."month"
 AND pp."profit" = mp."min_profit"
ORDER BY "month", "product_name";