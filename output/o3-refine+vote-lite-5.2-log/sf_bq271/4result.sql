SELECT
    DATE_TRUNC('month',
               TO_DATE(TO_TIMESTAMP("o"."created_at" / 1000000))
              )                                       AS "order_month",
    "u"."country"                                    AS "country",
    "i"."product_department"                         AS "product_department",
    "i"."product_category"                           AS "product_category",
    COUNT(DISTINCT "o"."order_id")                   AS "num_orders",
    COUNT(DISTINCT "u"."id")                         AS "unique_purchasers",
    SUM("i"."product_retail_price" - "i"."cost")     AS "profit"
FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS          AS "o"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS     AS "oi"
  ON "o"."order_id" = "oi"."order_id"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.INVENTORY_ITEMS AS "i"
  ON "oi"."inventory_item_id" = "i"."id"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS           AS "u"
  ON "o"."user_id" = "u"."id"
WHERE DATE_PART('year', TO_TIMESTAMP("o"."created_at" / 1000000)) = 2021          -- orders placed in 2021
  AND DATE_PART('year', TO_TIMESTAMP("u"."created_at" / 1000000)) = 2021          -- users registered in 2021
  AND DATE_PART('year', TO_TIMESTAMP("i"."created_at" / 1000000)) = 2021          -- inventory items created in 2021
GROUP BY
    DATE_TRUNC('month', TO_DATE(TO_TIMESTAMP("o"."created_at" / 1000000))),
    "u"."country",
    "i"."product_department",
    "i"."product_category"
ORDER BY
    "order_month",
    "country",
    "product_department",
    "product_category";