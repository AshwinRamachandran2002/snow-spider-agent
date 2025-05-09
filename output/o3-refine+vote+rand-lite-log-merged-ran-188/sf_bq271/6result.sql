/*  Monthly 2021 performance by country / department / category
    – orders placed in 2021
    – purchasers who registered in 2021
    – inventory items created in 2021
*/
SELECT
    TO_CHAR(TO_TIMESTAMP_NTZ(o."created_at" / 1e6), 'YYYY-MM')      AS "order_month",
    u."country",
    p."department",
    p."category",
    COUNT(DISTINCT o."order_id")                                    AS "order_cnt",
    COUNT(DISTINCT o."user_id")                                     AS "unique_purchasers",
    SUM(p."retail_price") - SUM(p."cost")                           AS "profit"
FROM  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"           o
JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"            u   ON o."user_id" = u."id"
JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"      oi  ON o."order_id" = oi."order_id"
JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"  ii  ON oi."inventory_item_id" = ii."id"
JOIN  THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"         p   ON oi."product_id" = p."id"
WHERE
      o."created_at"  BETWEEN 1609459200000000 AND 1640995199000000   -- orders in 2021
  AND u."created_at"  BETWEEN 1609459200000000 AND 1640995199000000   -- users registered in 2021
  AND ii."created_at" BETWEEN 1609459200000000 AND 1640995199000000   -- inventory created in 2021
GROUP BY
    1, 2, 3, 4
ORDER BY
    1, 2, 3, 4;