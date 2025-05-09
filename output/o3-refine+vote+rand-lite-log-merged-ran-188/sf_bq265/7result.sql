WITH user_2019 AS (      -- users who registered in 2019
    SELECT 
        "id"      AS user_id,
        "email"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE YEAR(TO_TIMESTAMP("created_at" / 1000000)) = 2019
),

orders_2019 AS (         -- orders placed in 2019
    SELECT 
        "order_id",
        "user_id",
        "num_of_item"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE YEAR(TO_TIMESTAMP("created_at" / 1000000)) = 2019
),

order_values AS (        -- order‑level value = num_of_item * (avg sale_price within that order)
    SELECT
        o."user_id",
        o."order_id",
        o."num_of_item" * AVG(oi."sale_price")  AS order_value
    FROM orders_2019       o
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS  oi
      ON o."order_id" = oi."order_id"
    GROUP BY 
        o."user_id",
        o."order_id",
        o."num_of_item"
),

user_avg AS (            -- average order value per user
    SELECT
        u."email",
        AVG(ov.order_value) AS avg_order_value
    FROM user_2019   u
    JOIN order_values ov 
      ON u.user_id = ov."user_id"
    GROUP BY u."email"
)

SELECT 
    "email"
FROM user_avg
ORDER BY 
    avg_order_value DESC NULLS LAST,
    "email"
LIMIT 10;