WITH users_2019 AS (
    SELECT
        "id"   AS user_id,
        "email"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE EXTRACT(year FROM TO_TIMESTAMP_NTZ("created_at" / 1000000)) = 2019
),
orders_2019 AS (
    SELECT
        "order_id",
        "user_id",
        "num_of_item"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    WHERE EXTRACT(year FROM TO_TIMESTAMP_NTZ("created_at" / 1000000)) = 2019
      AND "status" <> 'Cancelled'
),
avg_price_per_order AS (
    SELECT
        "order_id",
        AVG("sale_price") AS avg_sale_price
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"
    GROUP BY "order_id"
),
order_values AS (
    SELECT
        o."user_id",
        o."order_id",
        o."num_of_item" * p.avg_sale_price AS order_value
    FROM orders_2019 o
    JOIN avg_price_per_order p
      ON o."order_id" = p."order_id"
),
user_avg_order_value AS (
    SELECT
        "user_id",
        SUM(order_value) / COUNT(DISTINCT "order_id") AS avg_order_value
    FROM order_values
    GROUP BY "user_id"
)
SELECT
    u."email"
FROM user_avg_order_value ua
JOIN users_2019 u
  ON ua."user_id" = u.user_id
ORDER BY ua.avg_order_value DESC NULLS LAST
LIMIT 10;