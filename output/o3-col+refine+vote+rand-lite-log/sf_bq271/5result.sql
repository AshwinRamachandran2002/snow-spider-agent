SELECT
    TO_CHAR(TO_TIMESTAMP(o."created_at" / 1000000), 'YYYY-MM')      AS "order_month",
    u."country",
    p."department",
    p."category",
    COUNT(DISTINCT o."order_id")                                    AS "orders",
    COUNT(DISTINCT o."user_id")                                     AS "unique_purchasers",
    SUM(p."retail_price" - p."cost")                                AS "profit"
FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"       oi
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"            o
      ON oi."order_id" = o."order_id"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"             u
      ON o."user_id" = u."id"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"   ii
      ON oi."inventory_item_id" = ii."id"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"          p
      ON ii."product_id" = p."id"
WHERE
      -- Orders placed during calendar-year 2021
      o."created_at" BETWEEN 1609459200000000 AND 1640995200000000
  AND -- Purchasers who registered in 2021
      u."created_at" BETWEEN 1609459200000000 AND 1640995200000000
  AND -- Inventory items first stocked in 2021
      ii."created_at" BETWEEN 1609459200000000 AND 1640995200000000
GROUP BY
    TO_CHAR(TO_TIMESTAMP(o."created_at" / 1000000), 'YYYY-MM'),
    u."country",
    p."department",
    p."category"
ORDER BY
    "order_month",
    u."country",
    p."department",
    p."category";