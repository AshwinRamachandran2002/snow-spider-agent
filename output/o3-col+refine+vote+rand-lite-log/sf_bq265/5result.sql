WITH users_2019 AS (   -- users who registered during calendar-year 2019
    SELECT "id"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE "created_at" BETWEEN 1546300800000000 AND 1577836800000000   -- 2019-01-01 .. 2019-12-31
),
orders_2019 AS (       -- their 2019 completed orders
    SELECT o."order_id",
           o."user_id",
           o."num_of_item"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS o
    JOIN users_2019 u
         ON o."user_id" = u."id"
    WHERE o."status" = 'Complete'
      AND o."created_at" BETWEEN 1546300800000000 AND 1577836800000000
),
order_values AS (      -- value per order: num_of_item × sale_price
    SELECT o."order_id",
           o."user_id",
           o."num_of_item" * MAX(oi."sale_price") AS "order_value"
    FROM orders_2019                     o
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS oi
         ON o."order_id" = oi."order_id"
    GROUP BY o."order_id", o."user_id", o."num_of_item"
),
per_user AS (          -- each user’s average order value
    SELECT "user_id",
           SUM("order_value") / COUNT(*) AS "avg_order_value"
    FROM order_values
    GROUP BY "user_id"
)
SELECT u."email",
       p."avg_order_value"
FROM   per_user                                   p
JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS  u
       ON p."user_id" = u."id"
ORDER BY p."avg_order_value" DESC NULLS LAST
LIMIT 10;