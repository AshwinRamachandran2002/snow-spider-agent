WITH users_2019 AS (   -- users who registered in 2019
    SELECT
        "id"   AS user_id,
        "email"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE DATE_PART('year', TO_TIMESTAMP("created_at" / 1000000)) = 2019
),

orders_2019 AS (      -- those users’ orders created in 2019 (excluding cancelled)
    SELECT
        "order_id",
        "user_id",
        "num_of_item"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE DATE_PART('year', TO_TIMESTAMP("created_at" / 1000000)) = 2019
      AND "status" <> 'Cancelled'
),

order_item_price AS ( -- average sale price for each order
    SELECT
        "order_id",
        AVG("sale_price") AS sale_price
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS
    GROUP BY "order_id"
),

order_values AS (     -- monetary value of each order
    SELECT
        o."user_id",
        o."order_id",
        o."num_of_item" * COALESCE(p.sale_price, 0) AS order_value
    FROM orders_2019 o
    LEFT JOIN order_item_price p
           ON o."order_id" = p."order_id"
),

user_aov AS (         -- AOV for each user
    SELECT
        u.user_id,
        u."email",
        SUM(ov.order_value)                                  AS total_value,
        COUNT(DISTINCT ov."order_id")                        AS total_orders,
        SUM(ov.order_value) / COUNT(DISTINCT ov."order_id")  AS avg_order_value
    FROM users_2019 u
    JOIN order_values ov
      ON u.user_id = ov."user_id"
    GROUP BY u.user_id, u."email"
)

SELECT
    "email"
FROM user_aov
ORDER BY avg_order_value DESC NULLS LAST
LIMIT 10;