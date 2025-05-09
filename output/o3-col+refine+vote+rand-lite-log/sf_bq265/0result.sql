WITH orders_2019 AS (   -- 2019 orders only
    SELECT
        o."order_id",
        o."user_id",
        o."num_of_item"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS" o
    WHERE o."created_at" BETWEEN 1546300800000000 AND 1577836799000000
),
order_values AS (       -- value per 2019 order
    SELECT
        o."order_id",
        o."user_id",
        o."num_of_item" * MAX(oi."sale_price") AS "order_value"
    FROM orders_2019 o
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
          ON oi."order_id" = o."order_id"
    WHERE oi."created_at" BETWEEN 1546300800000000 AND 1577836799000000
    GROUP BY o."order_id", o."user_id", o."num_of_item"
),
user_avg AS (           -- average order value per user
    SELECT
        "user_id",
        ROUND(SUM("order_value") / COUNT(*), 4) AS "avg_order_value"
    FROM order_values
    GROUP BY "user_id"
)
SELECT
    u."email"
FROM user_avg ua
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS" u
      ON u."id" = ua."user_id"
WHERE u."created_at" BETWEEN 1546300800000000 AND 1577836799000000  -- registered in 2019
ORDER BY ua."avg_order_value" DESC NULLS LAST
LIMIT 10;