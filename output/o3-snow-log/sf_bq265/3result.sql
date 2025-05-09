WITH users_2019 AS (     -- users who registered in 2019
    SELECT 
        "id"      AS "user_id",
        "email"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE EXTRACT(year FROM TO_TIMESTAMP_LTZ("created_at" / 1000000)) = 2019
), 
orders_2019 AS (         -- those users’ orders placed in 2019
    SELECT 
        "order_id",
        "user_id"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE EXTRACT(year FROM TO_TIMESTAMP_LTZ("created_at" / 1000000)) = 2019
), 
order_totals AS (        -- total revenue for every order
    SELECT
        "order_id",
        SUM("sale_price") AS "order_total"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS
    GROUP BY "order_id"
), 
user_order_values AS (   -- link orders to their totals
    SELECT 
        o."user_id",
        ot."order_total"
    FROM orders_2019 o
    JOIN order_totals ot
      ON o."order_id" = ot."order_id"
), 
user_stats AS (          -- compute average order value per user
    SELECT
        u."user_id",
        u."email",
        SUM(uov."order_total")                 AS "total_revenue",
        COUNT(*)                               AS "total_orders",
        SUM(uov."order_total") / COUNT(*)      AS "avg_order_value"
    FROM users_2019 u
    JOIN user_order_values uov
      ON u."user_id" = uov."user_id"
    GROUP BY u."user_id", u."email"
) 
SELECT 
    "email"
FROM user_stats
ORDER BY "avg_order_value" DESC NULLS LAST
LIMIT 10;