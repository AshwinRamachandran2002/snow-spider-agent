/*  Monthly orders, purchasers and profit by country, department and category
    – only orders placed in 2021
    – only by users who registered in 2021
    – only for inventory items created in 2021                                   */

SELECT
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ(o."created_at" / 1000000))   AS "order_month",
        u."country"                                                      AS "country",
        ii."product_department"                                          AS "product_department",
        ii."product_category"                                            AS "product_category",
        COUNT(DISTINCT o."order_id")                                     AS "num_orders",
        COUNT(DISTINCT o."user_id")                                      AS "unique_purchasers",
        SUM(ii."product_retail_price" - ii."cost")                       AS "profit"
FROM    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS"          o
JOIN    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS"           u
          ON  u."id" = o."user_id"
          AND DATE_PART('year', TO_TIMESTAMP_NTZ(u."created_at" / 1000000)) = 2021           -- users registered in 2021
          AND DATE_PART('year', TO_TIMESTAMP_NTZ(o."created_at" / 1000000)) = 2021           -- orders placed in 2021
JOIN    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"     oi
          ON  oi."order_id" = o."order_id"
JOIN    "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."INVENTORY_ITEMS" ii
          ON  ii."id" = oi."inventory_item_id"
          AND DATE_PART('year', TO_TIMESTAMP_NTZ(ii."created_at" / 1000000)) = 2021          -- inventory items created in 2021
GROUP BY
        1, 2, 3, 4
ORDER BY
        1, 2, 3, 4;