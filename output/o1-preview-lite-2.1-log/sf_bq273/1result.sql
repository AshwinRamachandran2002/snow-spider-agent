WITH monthly_profit AS (
  SELECT
    DATE_TRUNC('month', TO_TIMESTAMP_NTZ(o."created_at" / 1e6)) AS "Month",
    SUM(oi."sale_price" - p."cost") AS "total_profit"
  FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
  JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS" o
    ON oi."order_id" = o."order_id"
  JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS" u
    ON o."user_id" = u."id"
  JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
    ON oi."product_id" = p."id"
  WHERE u."traffic_source" = 'Facebook'
    AND o."status" = 'Complete'
    AND TO_TIMESTAMP_NTZ(o."created_at" / 1e6) BETWEEN '2022-08-01' AND '2023-11-30'
  GROUP BY "Month"
)
SELECT
  "Month",
  ROUND("total_profit" - LAG("total_profit") OVER (ORDER BY "Month"), 4) AS "Profit_Increase"
FROM monthly_profit
QUALIFY LAG("total_profit") OVER (ORDER BY "Month") IS NOT NULL
ORDER BY "Profit_Increase" DESC NULLS LAST
LIMIT 5;