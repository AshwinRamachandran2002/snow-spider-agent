WITH users_2019 AS (
    SELECT
        "id"        AS user_id,
        "email"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE YEAR(TO_TIMESTAMP_NTZ("created_at" / 1000000)) = 2019
),

orders_2019 AS (
    SELECT
        "order_id",
        "user_id",
        "num_of_item"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE YEAR(TO_TIMESTAMP_NTZ("created_at" / 1000000)) = 2019
),

order_values AS (
    SELECT
        o."user_id",
        o."order_id",
        o."num_of_item" * AVG(oi."sale_price") AS order_value
    FROM orders_2019 o
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS oi
      ON oi."order_id" = o."order_id"
    GROUP BY
        o."user_id",
        o."order_id",
        o."num_of_item"
),

user_aov AS (
    SELECT
        "user_id",
        ROUND(SUM(order_value) / COUNT(DISTINCT "order_id"), 4) AS avg_order_value
    FROM order_values
    GROUP BY "user_id"
)

SELECT
    u."email"
FROM user_aov      a
JOIN users_2019    u ON u.user_id = a."user_id"
ORDER BY
    a.avg_order_value DESC NULLS LAST,
    u."email"
LIMIT 10;