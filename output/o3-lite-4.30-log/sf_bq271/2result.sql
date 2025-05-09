SELECT
    TO_CHAR(DATE_TRUNC('month', TO_TIMESTAMP(o."created_at" / 1000000)), 'YYYY-MM') AS "month",
    u."country",
    inv."product_department",
    inv."product_category",
    COUNT(DISTINCT o."order_id")                                                    AS "number_of_orders",
    COUNT(DISTINCT o."user_id")                                                     AS "unique_purchasers",
    ROUND(SUM(inv."product_retail_price" - inv."cost"), 4)                          AS "profit"
FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"           o
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"            u   ON o."user_id"           = u."id"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"      oi  ON oi."order_id"         = o."order_id"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"  inv ON inv."id"              = oi."inventory_item_id"
WHERE o."created_at"  >= 1609459200000000   -- 2021-01-01
  AND o."created_at"  <  1640995200000000   -- 2022-01-01
  AND u."created_at"  >= 1609459200000000
  AND u."created_at"  <  1640995200000000
  AND inv."created_at" >= 1609459200000000
  AND inv."created_at" <  1640995200000000
GROUP BY
    1, 2, 3, 4
ORDER BY
    1, 2, 3, 4;