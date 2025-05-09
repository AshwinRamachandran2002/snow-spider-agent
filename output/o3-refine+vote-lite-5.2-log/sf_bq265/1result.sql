WITH users_2019 AS (  -- users that registered in 2019
    SELECT "id",
           "email"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE EXTRACT(YEAR FROM TO_TIMESTAMP("created_at" / 1000000)) = 2019
),

orders_2019 AS (      -- non‑cancelled orders placed in 2019
    SELECT "order_id",
           "user_id",
           "num_of_item"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    WHERE EXTRACT(YEAR FROM TO_TIMESTAMP("created_at" / 1000000)) = 2019
      AND UPPER("status") <> 'CANCELLED'
),

order_value_per_order AS (  -- order value = num_of_item * avg sale_price in that order
    SELECT o."order_id",
           o."user_id",
           o."num_of_item" * AVG(oi."sale_price") AS order_value
    FROM orders_2019 o
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
      ON o."order_id" = oi."order_id"
    GROUP BY o."order_id",
             o."user_id",
             o."num_of_item"
),

user_avg_order_value AS (   -- average order value per user
    SELECT "user_id",
           SUM(order_value) / COUNT(*) AS avg_order_value
    FROM order_value_per_order
    GROUP BY "user_id"
)

SELECT u."email"
FROM user_avg_order_value ua
JOIN users_2019 u
  ON u."id" = ua."user_id"
ORDER BY ua.avg_order_value DESC NULLS LAST,
         u."email"
LIMIT 10;