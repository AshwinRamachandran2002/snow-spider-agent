SELECT
    DATE_TRUNC('month', TO_TIMESTAMP_NTZ("o"."created_at" / 1000000))       AS "order_month",
    "u"."country"                                                          AS "country",
    "p"."department"                                                       AS "product_department",
    "p"."category"                                                         AS "product_category",
    COUNT(DISTINCT "o"."order_id")                                         AS "num_orders",
    COUNT(DISTINCT "o"."user_id")                                          AS "num_unique_purchasers",
    SUM("p"."retail_price" - "p"."cost")                                   AS "profit"
FROM  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"            AS "o"
JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"             AS "u"
      ON "o"."user_id" = "u"."id"
JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"       AS "oi"
      ON "o"."order_id" = "oi"."order_id"
JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"   AS "ii"
      ON "oi"."inventory_item_id" = "ii"."id"
JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"          AS "p"
      ON "oi"."product_id" = "p"."id"
WHERE
      YEAR(TO_TIMESTAMP_NTZ("o"."created_at"  / 1000000)) = 2021   -- orders placed in 2021
  AND YEAR(TO_TIMESTAMP_NTZ("u"."created_at"  / 1000000)) = 2021   -- users registered in 2021
  AND YEAR(TO_TIMESTAMP_NTZ("ii"."created_at" / 1000000)) = 2021   -- inventory items created in 2021
GROUP BY
    DATE_TRUNC('month', TO_TIMESTAMP_NTZ("o"."created_at" / 1000000)),
    "u"."country",
    "p"."department",
    "p"."category"
ORDER BY
    "order_month",
    "country",
    "product_department",
    "product_category";