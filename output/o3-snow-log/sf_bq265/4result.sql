WITH registered_2019 AS (   -- users who signed-up in 2019
    SELECT 
        "id"    AS user_id,
        "email"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE YEAR( TO_TIMESTAMP_NTZ("created_at" / 1000000) ) = 2019
),
orders_2019 AS (            -- orders placed in 2019 with their values
    SELECT
        o."order_id",
        o."user_id",
        o."num_of_item",
        o."num_of_item" * AVG(oi."sale_price") AS order_value   -- #items × sale-price
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS       o
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS  oi
         ON o."order_id" = oi."order_id"
    WHERE YEAR( TO_TIMESTAMP_NTZ(o."created_at" / 1000000) ) = 2019
    GROUP BY o."order_id", o."user_id", o."num_of_item"
),
user_aov AS (               -- average order value per user
    SELECT
        "user_id",
        SUM(order_value)                              AS total_value,
        COUNT("order_id")                             AS total_orders,
        ROUND(SUM(order_value) / NULLIF(COUNT("order_id"),0), 4) AS avg_order_value
    FROM orders_2019
    GROUP BY "user_id"
)
SELECT
    r."email"
FROM user_aov        ua
JOIN registered_2019 r
     ON ua."user_id" = r.user_id
ORDER BY ua.avg_order_value DESC NULLS LAST
LIMIT 10;