WITH
-- 1.  Orders placed in 2021
orders_2021 AS (
    SELECT
        "order_id",
        "user_id",
        TO_CHAR(TO_TIMESTAMP_NTZ("created_at" / 1000000), 'YYYY-MM') AS month_key,
        "created_at"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    WHERE TO_DATE(TO_TIMESTAMP_NTZ("created_at" / 1000000))
              BETWEEN '2021-01-01' AND '2021-12-31'
),

-- 2.  Users who registered in 2021
users_2021 AS (
    SELECT
        "id"   AS user_id,
        "country"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE TO_DATE(TO_TIMESTAMP_NTZ("created_at" / 1000000))
              BETWEEN '2021-01-01' AND '2021-12-31'
),

-- 3.  Inventory items created in 2021
inv_2021 AS (
    SELECT
        "id" AS inventory_item_id
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"
    WHERE TO_DATE(TO_TIMESTAMP_NTZ("created_at" / 1000000))
              BETWEEN '2021-01-01' AND '2021-12-31'
)

SELECT
    o.month_key                                   AS "month",
    u."country"                                   AS "country",
    p."department"                                AS "product_department",
    p."category"                                  AS "product_category",
    COUNT(DISTINCT o."order_id")                  AS "number_of_orders",
    COUNT(DISTINCT o."user_id")                   AS "number_of_unique_purchasers",
    SUM(p."retail_price") - SUM(p."cost")         AS "profit"
FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"      oi
JOIN orders_2021                                           o   ON oi."order_id"          = o."order_id"
JOIN users_2021                                            u   ON o."user_id"            = u.user_id
JOIN inv_2021                                              i   ON oi."inventory_item_id" = i.inventory_item_id
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"        p   ON oi."product_id"        = p."id"
GROUP BY
    o.month_key,
    u."country",
    p."department",
    p."category"
ORDER BY
    o.month_key,
    u."country",
    p."department",
    p."category";