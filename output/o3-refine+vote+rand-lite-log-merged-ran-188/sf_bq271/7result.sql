SELECT
  TO_CHAR(TO_TIMESTAMP(o."created_at"/1000000), 'YYYY-MM')            AS "order_month",
  u."country",
  p."department",
  p."category",
  COUNT(DISTINCT o."order_id")                                        AS "num_orders",
  COUNT(DISTINCT u."id")                                              AS "unique_purchasers",
  SUM(p."retail_price" - p."cost")                                    AS "profit"
FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"     oi
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS" ii ON oi."inventory_item_id" = ii."id"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"          o  ON oi."order_id"          = o."order_id"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"           u  ON o."user_id"            = u."id"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"        p  ON oi."product_id"        = p."id"
WHERE o."created_at" BETWEEN 1609459200000000 AND 1640995200000000   -- orders placed in 2021
  AND u."created_at" BETWEEN 1609459200000000 AND 1640995200000000   -- users registered in 2021
  AND ii."created_at" BETWEEN 1609459200000000 AND 1640995200000000  -- inventory items created in 2021
GROUP BY
  TO_CHAR(TO_TIMESTAMP(o."created_at"/1000000), 'YYYY-MM'),
  u."country",
  p."department",
  p."category"
ORDER BY
  "order_month",
  "country",
  "department",
  "category";