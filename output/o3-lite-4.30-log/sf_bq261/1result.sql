SELECT
    TO_CHAR(TO_TIMESTAMP("oi"."created_at" / 1e6), 'YYYY-MM') AS "month",
    CAST("p"."id" AS STRING)                                  AS "product",
    ROUND(SUM("p"."cost"), 4)                                 AS "total_cost",
    ROUND(SUM(COALESCE("oi"."sale_price", 0) - "p"."cost"), 4) AS "total_profit"
FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS" AS "oi"
JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"    AS "p"
  ON "p"."id" = "oi"."product_id"
WHERE TO_TIMESTAMP("oi"."created_at" / 1e6) < DATE '2024-01-01'
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (
          PARTITION BY "month"
          ORDER BY SUM(COALESCE("oi"."sale_price", 0) - "p"."cost") DESC
       ) = 1
ORDER BY "month";