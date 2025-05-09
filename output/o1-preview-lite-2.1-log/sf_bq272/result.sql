SELECT
  TO_CHAR(DATE_TRUNC('month', TO_TIMESTAMP_NTZ(oi."created_at" / 1e6)), 'Mon-YYYY') AS "Month",
  p."name" AS "Product_Name",
  ROUND(SUM(oi."sale_price" - p."cost"), 4) AS "Total_Profit"
FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS" oi
JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS" o
  ON oi."order_id" = o."order_id"
JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" p
  ON oi."product_id" = p."id"
WHERE COALESCE(oi."status", '') NOT IN ('Returned', 'Cancelled', 'Canceled')
  AND COALESCE(o."status", '') NOT IN ('Returned', 'Cancelled', 'Canceled')
  AND TO_TIMESTAMP_NTZ(oi."created_at" / 1e6) >= TO_TIMESTAMP_NTZ('2019-01-01', 'YYYY-MM-DD')
  AND TO_TIMESTAMP_NTZ(oi."created_at" / 1e6) <= TO_TIMESTAMP_NTZ('2022-08-31 23:59:59', 'YYYY-MM-DD HH24:MI:SS')
  AND oi."sale_price" IS NOT NULL
  AND p."cost" IS NOT NULL
GROUP BY p."name", DATE_TRUNC('month', TO_TIMESTAMP_NTZ(oi."created_at" / 1e6))
QUALIFY ROW_NUMBER() OVER (
          PARTITION BY DATE_TRUNC('month', TO_TIMESTAMP_NTZ(oi."created_at" / 1e6))
          ORDER BY SUM(oi."sale_price" - p."cost") DESC
        ) <= 3
ORDER BY DATE_TRUNC('month', TO_TIMESTAMP_NTZ(oi."created_at" / 1e6)), "Total_Profit" DESC NULLS LAST;