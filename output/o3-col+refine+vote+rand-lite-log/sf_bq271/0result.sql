/*  Monthly 2021 performance by country, department & category for
    orders placed in 2021 by users who registered in 2021
    for inventory items created in 2021                              */

SELECT
    DATE_TRUNC('month', TO_TIMESTAMP_NTZ(o."created_at" / 1e6))        AS "order_month",
    u."country",
    inv."product_department",
    inv."product_category",
    COUNT(DISTINCT o."order_id")                                       AS "num_orders",
    COUNT(DISTINCT o."user_id")                                        AS "unique_purchasers",
    SUM(inv."product_retail_price" - inv."cost")                       AS "profit"
FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"        oi
JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"              o   ON oi."order_id"           = o."order_id"
JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"               u   ON o."user_id"             = u."id"
JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"     inv ON oi."inventory_item_id"  = inv."id"
WHERE  YEAR(TO_TIMESTAMP_NTZ(o."created_at"  / 1e6)) = 2021      -- order placed in 2021
  AND  YEAR(TO_TIMESTAMP_NTZ(u."created_at" / 1e6)) = 2021      -- user registered in 2021
  AND  YEAR(TO_TIMESTAMP_NTZ(inv."created_at" / 1e6)) = 2021    -- inventory item created in 2021
GROUP  BY
    "order_month",
    u."country",
    inv."product_department",
    inv."product_category"
ORDER BY
    "order_month",
    u."country",
    inv."product_department",
    inv."product_category";