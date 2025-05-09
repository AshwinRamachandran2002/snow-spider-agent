WITH "USER_2021" AS (        -- users who registered in 2021
    SELECT 
        "id"       AS "user_id",
        "country"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE DATE_TRUNC('year', TO_TIMESTAMP("created_at"/1000000)) = '2021-01-01'
),
"ORDERS_2021" AS (           -- orders placed in 2021
    SELECT 
        "order_id",
        "user_id",
        TO_DATE(TO_TIMESTAMP("created_at"/1000000)) AS "order_date"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    WHERE DATE_TRUNC('year', TO_TIMESTAMP("created_at"/1000000)) = '2021-01-01'
),
"INVENTORY_2021" AS (        -- inventory items created in 2021
    SELECT 
        "id" AS "inventory_item_id"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"
    WHERE DATE_TRUNC('year', TO_TIMESTAMP("created_at"/1000000)) = '2021-01-01'
),
"JOINED" AS (                -- bring everything together
    SELECT 
        o."order_id",
        o."user_id",
        u."country",
        DATE_TRUNC('month', o."order_date")          AS "month_start",
        p."department",
        p."category",
        p."retail_price",
        p."cost"
    FROM "ORDERS_2021" o
    JOIN "USER_2021" u
          ON o."user_id" = u."user_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
          ON oi."order_id" = o."order_id"
    JOIN "INVENTORY_2021" inv
          ON inv."inventory_item_id" = oi."inventory_item_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
          ON p."id" = oi."product_id"
)
SELECT
    TO_CHAR("month_start", 'YYYY-MM')               AS "month",
    "country",
    "department",
    "category",
    COUNT(DISTINCT "order_id")                      AS "orders_cnt",
    COUNT(DISTINCT "user_id")                       AS "unique_purchasers",
    ROUND(SUM("retail_price") - SUM("cost"), 4)     AS "profit"
FROM "JOINED"
GROUP BY
    "month_start",
    "country",
    "department",
    "category"
ORDER BY
    "month_start",
    "country",
    "department",
    "category";