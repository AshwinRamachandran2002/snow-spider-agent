SELECT
    DATE_TRUNC('month', TO_TIMESTAMP(o."created_at" / 1000000.0))          AS "order_month",
    u."country"                                                           AS "country",
    ii."product_department"                                               AS "product_department",
    ii."product_category"                                                 AS "product_category",
    COUNT(DISTINCT o."order_id")                                          AS "num_orders",
    COUNT(DISTINCT o."user_id")                                           AS "unique_purchasers",
    SUM(ii."product_retail_price" - ii."cost")                            AS "profit"
FROM   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS"           o
JOIN   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS"            u  ON o."user_id" = u."id"
JOIN   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"      oi ON o."order_id" = oi."order_id"
JOIN   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."INVENTORY_ITEMS"  ii ON oi."inventory_item_id" = ii."id"
WHERE  -- orders placed in 2021
       TO_TIMESTAMP(o."created_at" / 1000000.0) >= '2021-01-01'::TIMESTAMP
   AND TO_TIMESTAMP(o."created_at" / 1000000.0) <  '2022-01-01'::TIMESTAMP

   -- users registered in 2021
   AND TO_TIMESTAMP(u."created_at" / 1000000.0) >= '2021-01-01'::TIMESTAMP
   AND TO_TIMESTAMP(u."created_at" / 1000000.0) <  '2022-01-01'::TIMESTAMP

   -- inventory items created in 2021
   AND TO_TIMESTAMP(ii."created_at" / 1000000.0) >= '2021-01-01'::TIMESTAMP
   AND TO_TIMESTAMP(ii."created_at" / 1000000.0) <  '2022-01-01'::TIMESTAMP
GROUP BY
    "order_month",
    u."country",
    ii."product_department",
    ii."product_category"
ORDER BY
    "order_month",
    u."country",
    ii."product_department",
    ii."product_category";