SELECT
  TO_CHAR("order_month", 'YYYY-MM') AS "Month",
  ROUND("profit_increase", 4) AS "Profit_Increase"
FROM (
  SELECT
    "order_month",
    "total_profit",
    "total_profit" - LAG("total_profit") OVER (ORDER BY "order_month") AS "profit_increase"
  FROM (
    SELECT
      DATE_TRUNC('month', TO_TIMESTAMP(o."created_at" / 1e6)) AS "order_month",
      SUM(oi."sale_price" - p."cost") AS "total_profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS u
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS o
      ON u."id" = o."user_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS oi
      ON o."order_id" = oi."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS p
      ON oi."product_id" = p."id"
    WHERE u."traffic_source" = 'Facebook'
      AND o."status" = 'Complete'
      AND o."created_at" BETWEEN 1659312000000000 AND 1701302400000000
    GROUP BY DATE_TRUNC('month', TO_TIMESTAMP(o."created_at" / 1e6))
  ) AS monthly_profits
) AS profit_deltas
WHERE "profit_increase" IS NOT NULL
ORDER BY "profit_increase" DESC NULLS LAST
LIMIT 5;