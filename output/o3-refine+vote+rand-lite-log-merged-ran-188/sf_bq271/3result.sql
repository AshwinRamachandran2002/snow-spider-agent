WITH

-- 2021 orders --------------------------------------------------------------
orders_2021 AS (
    SELECT  "order_id",
            "user_id",
            "created_at",
            DATE_TRUNC( 'month'
                      , TO_TIMESTAMP_LTZ( "created_at" / 1000000 ) ) AS month_start
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    WHERE "created_at" BETWEEN 1609459200000000 AND 1640995200000000   -- 2021
),

-- users who registered in 2021 -------------------------------------------
users_2021 AS (
    SELECT  "id",
            "country"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE "created_at" BETWEEN 1609459200000000 AND 1640995200000000   -- 2021
),

-- inventory items created in 2021 ----------------------------------------
inventory_2021 AS (
    SELECT  "id",
            "product_id"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"
    WHERE "created_at" BETWEEN 1609459200000000 AND 1640995200000000   -- 2021
)

-- final aggregation -------------------------------------------------------
SELECT  
        TO_CHAR(o.month_start , 'YYYY-MM')                     AS "month",
        u."country"                                            AS "country",
        p."department"                                         AS "department",
        p."category"                                           AS "category",
        COUNT(DISTINCT o."order_id")                           AS "num_orders",
        COUNT(DISTINCT o."user_id")                            AS "unique_purchasers",
        SUM(p."retail_price" - p."cost")                       AS "profit"
FROM            orders_2021                                   o
JOIN            users_2021                                    u  ON o."user_id" = u."id"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"        oi ON oi."order_id" = o."order_id"
JOIN            inventory_2021                                i  ON i."id"       = oi."inventory_item_id"
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"           p  ON p."id"       = i."product_id"
GROUP BY
        o.month_start,
        u."country",
        p."department",
        p."category"
ORDER BY
        o.month_start,
        u."country",
        p."department",
        p."category";