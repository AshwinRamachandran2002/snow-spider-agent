SELECT
    /* month of the order (YYYY-MM) */
    TO_CHAR(
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP_LTZ(o."created_at" / 1000000)   -- micro-sec → sec → timestamp
        ),
        'YYYY-MM'
    )                                                     AS "yyyymm",
    
    /* user & product descriptors */
    u."country",
    prod."department",
    prod."category",
    
    /* required metrics */
    COUNT(DISTINCT o."order_id")                          AS "orders",
    COUNT(DISTINCT u."id")                                AS "unique_purchasers",
    SUM(prod."retail_price" - prod."cost")                AS "profit"
    
FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS"          o
JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS"           u
      ON o."user_id" = u."id"
JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"     oi
      ON o."order_id" = oi."order_id"
JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."INVENTORY_ITEMS" inv
      ON oi."inventory_item_id" = inv."id"
JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"        prod
      ON inv."product_id" = prod."id"

-- keep only 2021 activity along the whole chain
WHERE YEAR(TO_TIMESTAMP_LTZ(o."created_at"   / 1000000)) = 2021   -- orders placed in 2021
  AND YEAR(TO_TIMESTAMP_LTZ(u."created_at"   / 1000000)) = 2021   -- users registered in 2021
  AND YEAR(TO_TIMESTAMP_LTZ(inv."created_at" / 1000000)) = 2021   -- inventory items added in 2021

GROUP BY 1, 2, 3, 4
ORDER BY 1, 2, 3, 4;