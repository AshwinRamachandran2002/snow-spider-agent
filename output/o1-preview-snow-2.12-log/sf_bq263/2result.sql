SELECT
  TO_CHAR(DATE_TRUNC('month', TO_TIMESTAMP("o"."created_at" / 1000000)), 'Mon-YYYY') AS "Month",
  ROUND(SUM("oi"."sale_price"), 4) AS "Total_Sales",
  ROUND(SUM("p"."cost"), 4) AS "Total_Cost",
  COUNT(DISTINCT "o"."order_id") AS "Number_of_Complete_Orders",
  ROUND(SUM("oi"."sale_price" - "p"."cost"), 4) AS "Total_Profit",
  ROUND(SUM("oi"."sale_price" - "p"."cost") / NULLIF(SUM("p"."cost"), 0), 4) AS "Profit_to_Cost_Ratio"
FROM
  "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS" AS "o"
JOIN
  "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS" AS "oi"
  ON "o"."order_id" = "oi"."order_id"
JOIN
  "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" AS "p"
  ON "oi"."product_id" = "p"."id"
WHERE
  "o"."status" = 'Complete'
  AND "o"."created_at" BETWEEN 1672531200000000 AND 1704067199000000
  AND "p"."category" = 'Sleep & Lounge'
GROUP BY
  "Month"
ORDER BY
  MIN("o"."created_at")
;