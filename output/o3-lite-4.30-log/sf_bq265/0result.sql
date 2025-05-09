WITH users_2019 AS (          -- customers who registered in 2019
    SELECT "id",
           "email"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE "created_at" BETWEEN 1546300800000000 AND 1577836799000000
), orders_2019 AS (           -- completed orders placed in 2019
    SELECT "order_id",
           "user_id",
           "num_of_item"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE "created_at" BETWEEN 1546300800000000 AND 1577836799000000
      AND "status" = 'Complete'
), order_items_2019 AS (      -- completed order‑items belonging to those orders
    SELECT oi."order_id",
           oi."sale_price"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS oi
    JOIN orders_2019 o
      ON oi."order_id" = o."order_id"
    WHERE oi."status" = 'Complete'
), order_values AS (          -- total value of each 2019 order
    SELECT o."order_id",
           o."user_id",
           SUM(o."num_of_item" * oi."sale_price") AS order_value
    FROM orders_2019 o
    JOIN order_items_2019 oi
      ON oi."order_id" = o."order_id"
    GROUP BY o."order_id", o."user_id"
), aov_per_user AS (          -- average order value per user in 2019
    SELECT "user_id",
           AVG(order_value) AS avg_order_value
    FROM order_values
    GROUP BY "user_id"
)
SELECT u."email"                               AS "email_address",
       ROUND(a.avg_order_value, 4)             AS "average_order_value_2019"
FROM users_2019 u
JOIN aov_per_user a
  ON u."id" = a."user_id"
ORDER BY a.avg_order_value DESC NULLS LAST
LIMIT 10;