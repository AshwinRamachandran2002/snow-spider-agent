WITH
  orders_2021 AS (               -- orders placed in 2021
    SELECT
      "order_id",
      "user_id",
      TO_TIMESTAMP("created_at" / 1000000) AS order_ts
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE YEAR(TO_TIMESTAMP("created_at" / 1000000)) = 2021
  ),

  users_2021 AS (                -- users who registered in 2021
    SELECT
      "id"   AS user_id,
      "country"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE YEAR(TO_TIMESTAMP("created_at" / 1000000)) = 2021
  ),

  inventory_2021 AS (            -- inventory items created in 2021
    SELECT
      "id",
      "product_department",
      "product_category",
      "product_retail_price",
      "cost"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.INVENTORY_ITEMS
    WHERE YEAR(TO_TIMESTAMP("created_at" / 1000000)) = 2021
  )

SELECT
  TO_CHAR(DATE_TRUNC('month', o.order_ts), 'YYYY-MM')        AS "order_month",
  u."country"                                                AS "country",
  i."product_department"                                     AS "product_department",
  i."product_category"                                       AS "product_category",
  COUNT(DISTINCT o."order_id")                               AS "num_orders",
  COUNT(DISTINCT o."user_id")                                AS "unique_purchasers",
  SUM(i."product_retail_price" - i."cost")                   AS "profit"
FROM orders_2021               o
JOIN users_2021                u  ON o."user_id"         = u.user_id
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS oi  ON o."order_id"       = oi."order_id"
JOIN inventory_2021            i  ON oi."inventory_item_id" = i."id"
GROUP BY
  "order_month",
  "country",
  "product_department",
  "product_category"
ORDER BY
  "order_month",
  "country",
  "product_department",
  "product_category";