WITH
/* 1.  Orders placed in 2021 */
"ORDERS_2021" AS (
    SELECT
        "order_id",
        "user_id",
        TO_TIMESTAMP("created_at" / 1000000) AS "order_ts"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    WHERE TO_DATE(TO_TIMESTAMP("created_at" / 1000000)) 
          BETWEEN '2021-01-01' AND '2021-12-31'
),

/* 2.  Users who registered in 2021 */
"USERS_2021" AS (
    SELECT
        "id"      AS "user_id",
        "country"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE TO_DATE(TO_TIMESTAMP("created_at" / 1000000)) 
          BETWEEN '2021-01-01' AND '2021-12-31'
),

/* 3.  Inventory items created in 2021 */
"INVENTORY_2021" AS (
    SELECT
        "id" AS "inventory_item_id"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"
    WHERE TO_DATE(TO_TIMESTAMP("created_at" / 1000000)) 
          BETWEEN '2021-01-01' AND '2021-12-31'
)

SELECT
    /* Year-month of the order */
    TO_CHAR(DATE_TRUNC('month', o."order_ts"), 'YYYY-MM')        AS "month",
    u."country"                                                  AS "country",
    p."department"                                               AS "product_department",
    p."category"                                                 AS "product_category",
    COUNT(DISTINCT o."order_id")                                 AS "number_of_orders",
    COUNT(DISTINCT o."user_id")                                  AS "unique_purchasers",
    ROUND(SUM(p."retail_price" - p."cost"), 4)                   AS "profit"
FROM "ORDERS_2021"                 o
JOIN "USERS_2021"                  u  ON o."user_id"          = u."user_id"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi ON oi."order_id" = o."order_id"
JOIN "INVENTORY_2021"              ii ON ii."inventory_item_id" = oi."inventory_item_id"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p  ON p."id"        = oi."product_id"
GROUP BY
    TO_CHAR(DATE_TRUNC('month', o."order_ts"), 'YYYY-MM'),
    u."country",
    p."department",
    p."category"
ORDER BY
    "month",
    "country",
    "product_department",
    "product_category";