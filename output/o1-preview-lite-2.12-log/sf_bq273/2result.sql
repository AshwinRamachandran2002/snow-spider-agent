SELECT
  "Month",
  ROUND("Profit_Increase", 4) AS "Profit_Increase"
FROM (
  SELECT
    "Month",
    "Profit",
    LAG("Profit") OVER (ORDER BY "Month") AS "Previous_Month_Profit",
    ("Profit" - LAG("Profit") OVER (ORDER BY "Month")) AS "Profit_Increase"
  FROM (
    SELECT
      DATE_TRUNC('month', TO_TIMESTAMP_NTZ("o"."created_at" / 1e6)) AS "Month",
      ROUND(SUM("oi"."sale_price" - "p"."cost"), 4) AS "Profit"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS" AS "oi"
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS" AS "o"
      ON "oi"."order_id" = "o"."order_id"
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" AS "p"
      ON "oi"."product_id" = "p"."id"
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS" AS "u"
      ON "o"."user_id" = "u"."id"
    WHERE "o"."status" = 'Complete'
      AND "u"."traffic_source" = 'Facebook'
      AND TO_TIMESTAMP_NTZ("o"."created_at" / 1e6) >= '2022-08-01'
      AND TO_TIMESTAMP_NTZ("o"."created_at" / 1e6) <= '2023-11-30'
      AND "o"."delivered_at" IS NOT NULL
    GROUP BY "Month"
  ) AS "Monthly_Profits"
) AS "Profit_Changes"
WHERE "Profit_Increase" IS NOT NULL
ORDER BY "Profit_Increase" DESC NULLS LAST
LIMIT 5;