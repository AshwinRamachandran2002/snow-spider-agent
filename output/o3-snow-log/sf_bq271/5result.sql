/*  Monthly 2021 performance by purchasers’ country, product department & category  */
WITH
  /* users who registered in 2021 */
  users_2021 AS (
    SELECT
      "id",
      "country"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE YEAR( TO_TIMESTAMP_NTZ("created_at" / 1000000) ) = 2021
  ),

  /* inventory items created (received into stock) in 2021 */
  inv_items_2021 AS (
    SELECT
      "id"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"
    WHERE YEAR( TO_TIMESTAMP_NTZ("created_at" / 1000000) ) = 2021
  ),

  /* orders placed in 2021 (created_at) */
  orders_2021 AS (
    SELECT
      "order_id",
      "user_id",
      "created_at"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    WHERE YEAR( TO_TIMESTAMP_NTZ("created_at" / 1000000) ) = 2021
  )

SELECT
  DATE_TRUNC('month', TO_TIMESTAMP_NTZ(o."created_at" / 1000000))       AS "order_month",
  u."country"                                                          AS "country",
  p."department"                                                       AS "department",
  p."category"                                                         AS "category",
  COUNT(DISTINCT o."order_id")                                         AS "num_orders",
  COUNT(DISTINCT o."user_id")                                          AS "num_unique_purchasers",
  ROUND(SUM(p."retail_price" - p."cost"), 4)                           AS "profit"
FROM orders_2021                 o
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"      oi
     ON oi."order_id" = o."order_id"
JOIN users_2021                  u
     ON u."id"       = o."user_id"
JOIN inv_items_2021              ii
     ON ii."id"      = oi."inventory_item_id"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"         p
     ON p."id"       = oi."product_id"
GROUP BY
  DATE_TRUNC('month', TO_TIMESTAMP_NTZ(o."created_at" / 1000000)),
  u."country",
  p."department",
  p."category"
ORDER BY
  "order_month",
  "country",
  "department",
  "category";