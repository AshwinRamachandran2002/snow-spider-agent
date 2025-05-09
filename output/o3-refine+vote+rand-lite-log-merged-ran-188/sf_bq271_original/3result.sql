WITH
/* 1 – orders placed in 2021 */
orders_2021 AS (
    SELECT
        "order_id",
        "user_id",
        TO_TIMESTAMP_LTZ("created_at" / 1000000) AS order_ts
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE EXTRACT(YEAR FROM TO_TIMESTAMP_LTZ("created_at" / 1000000)) = 2021
),

/* 2 – users that registered in 2021 */
users_2021 AS (
    SELECT
        "id"        AS user_id,
        "country"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE EXTRACT(YEAR FROM TO_TIMESTAMP_LTZ("created_at" / 1000000)) = 2021
),

/* 3 – inventory items created in 2021 */
inventory_2021 AS (
    SELECT
        "id"                 AS inventory_item_id,
        "product_id",
        "product_department",
        "product_category"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.INVENTORY_ITEMS
    WHERE EXTRACT(YEAR FROM TO_TIMESTAMP_LTZ("created_at" / 1000000)) = 2021
)

/* 4 – assemble the final result */
SELECT
    DATE_TRUNC('MONTH', o.order_ts)              AS order_month,
    u."country"                                  AS country,
    i."product_department"                       AS product_department,
    i."product_category"                         AS product_category,
    COUNT(DISTINCT o."order_id")                 AS orders,
    COUNT(DISTINCT o."user_id")                  AS unique_purchasers,
    SUM(p."retail_price" - p."cost")             AS profit
FROM orders_2021 o
JOIN users_2021 u
      ON o."user_id" = u.user_id
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS oi
      ON o."order_id" = oi."order_id"
JOIN inventory_2021 i
      ON oi."inventory_item_id" = i.inventory_item_id
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS p
      ON oi."product_id" = p."id"
GROUP BY
    DATE_TRUNC('MONTH', o.order_ts),
    u."country",
    i."product_department",
    i."product_category"
ORDER BY
    order_month,
    country,
    product_department,
    product_category;