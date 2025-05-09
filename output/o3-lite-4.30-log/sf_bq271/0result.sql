SELECT
    TO_CHAR(TO_TIMESTAMP(o."created_at" / 1000000), 'YYYY-MM') AS "month",
    u."country"                                               AS "country",
    ii."product_department"                                   AS "product_department",
    ii."product_category"                                     AS "product_category",
    COUNT(DISTINCT o."order_id")                              AS "number_of_orders",
    COUNT(DISTINCT o."user_id")                               AS "unique_purchasers",
    ROUND(SUM(p."retail_price" - ii."cost"), 4)               AS "profit"
FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS"          o
JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"     oi ON o."order_id" = oi."order_id"
JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."INVENTORY_ITEMS" ii ON oi."inventory_item_id" = ii."id"
JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"        p  ON ii."product_id" = p."id"
JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS"           u  ON o."user_id" = u."id"
WHERE o."created_at"  BETWEEN 1609459200000000 AND 1640995199000000  -- Orders placed in 2021
  AND u."created_at"  BETWEEN 1609459200000000 AND 1640995199000000  -- Users registered in 2021
  AND ii."created_at" BETWEEN 1609459200000000 AND 1640995199000000  -- Inventory items created in 2021
GROUP BY
    TO_CHAR(TO_TIMESTAMP(o."created_at" / 1000000), 'YYYY-MM'),
    u."country",
    ii."product_department",
    ii."product_category"
ORDER BY
    "month",
    "country",
    "product_department",
    "product_category";