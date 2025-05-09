SELECT
    TO_CHAR(
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ(o."created_at" / 1000000)),
        'YYYY‑MM'
    )                                                       AS "order_month",
    u."country",
    p."department",
    p."category",
    COUNT(DISTINCT o."order_id")                           AS "orders",
    COUNT(DISTINCT u."id")                                 AS "unique_purchasers",
    SUM(p."retail_price" - ii."cost")                      AS "profit"
FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"      oi
JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS"           o
      ON oi."order_id" = o."order_id"
JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS"            u
      ON oi."user_id" = u."id"
JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."INVENTORY_ITEMS"  ii
      ON oi."inventory_item_id" = ii."id"
JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"         p
      ON ii."product_id" = p."id"
WHERE o."created_at"  >= 1609459200000000   -- 2021‑01‑01
  AND o."created_at"  <  1640995200000000   -- 2022‑01‑01
  AND u."created_at"  >= 1609459200000000
  AND u."created_at"  <  1640995200000000
  AND ii."created_at" >= 1609459200000000
  AND ii."created_at" <  1640995200000000
GROUP BY
    1, 2, 3, 4
ORDER BY
    1,
    2,
    3,
    4;