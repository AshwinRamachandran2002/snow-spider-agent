SELECT sub."month", sub."product_id", sub."total_cost", sub."total_profit"
FROM (
   SELECT DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1e6)) AS "month", oi."product_id",
          ROUND(SUM(p."cost"), 4) AS "total_cost",
          ROUND(SUM(oi."sale_price" - p."cost"), 4) AS "total_profit",
          RANK() OVER (
            PARTITION BY DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1e6))
            ORDER BY SUM(oi."sale_price" - p."cost") DESC NULLS LAST
          ) AS "profit_rank"
   FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS" AS oi
   JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" AS p
     ON oi."product_id" = p."id"
   WHERE TO_TIMESTAMP(oi."created_at" / 1e6) < '2024-01-01'
   GROUP BY "month", oi."product_id"
) AS sub
WHERE sub."profit_rank" = 1
ORDER BY sub."month" ASC;