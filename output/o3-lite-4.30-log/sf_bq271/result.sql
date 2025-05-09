SELECT
    TO_CHAR(TO_TIMESTAMP_NTZ(o."created_at" / 1e6), 'YYYY-MM') AS "month",
    u."country"                                                AS "country",
    inv."product_department"                                   AS "product_department",
    inv."product_category"                                     AS "product_category",
    COUNT(DISTINCT o."order_id")                               AS "number_of_orders",
    COUNT(DISTINCT o."user_id")                                AS "unique_purchasers",
    ROUND(SUM(inv."product_retail_price" - inv."cost"), 4)     AS "profit"
FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"          o
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"           u  ON o."user_id" = u."id"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"     oi ON o."order_id" = oi."order_id"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS" inv ON oi."inventory_item_id" = inv."id"
WHERE 
      o."created_at"   >= 1609459200000000 AND o."created_at"   < 1640995200000000  -- orders in 2021
  AND u."created_at"   >= 1609459200000000 AND u."created_at"   < 1640995200000000  -- users registered in 2021
  AND inv."created_at" >= 1609459200000000 AND inv."created_at" < 1640995200000000  -- inventory stocked in 2021
GROUP BY 
    TO_CHAR(TO_TIMESTAMP_NTZ(o."created_at" / 1e6), 'YYYY-MM'),
    u."country",
    inv."product_department",
    inv."product_category"
ORDER BY 
    "month",
    "country",
    "product_department",
    "product_category";