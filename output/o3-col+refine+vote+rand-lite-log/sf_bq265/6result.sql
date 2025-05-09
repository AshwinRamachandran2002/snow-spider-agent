WITH orders_2019 AS (         -- revenue for every 2019 order
    SELECT
        o."order_id",
        o."user_id",
        o."num_of_item" * AVG(oi."sale_price") AS "order_value"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"        o
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"   oi
          ON oi."order_id" = o."order_id"
    WHERE o."created_at" BETWEEN 1546300800000000 AND 1577836799999999     -- orders in 2019
    GROUP BY o."order_id", o."user_id", o."num_of_item"
),
user_aov AS (                 -- AOV for each user (2019 purchases only)
    SELECT
        "user_id",
        SUM("order_value") / COUNT(*) AS "avg_order_value"
    FROM orders_2019
    GROUP BY "user_id"
),
eligible_users AS (           -- keep users who also registered in 2019
    SELECT
        ua."user_id",
        ua."avg_order_value"
    FROM user_aov                      ua
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS" u
         ON u."id" = ua."user_id"
    WHERE u."created_at" BETWEEN 1546300800000000 AND 1577836799999999     -- registered in 2019
)
SELECT
    u."email",
    ROUND(eu."avg_order_value", 4) AS "avg_order_value"
FROM eligible_users                           eu
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS" u
     ON u."id" = eu."user_id"
ORDER BY eu."avg_order_value" DESC NULLS LAST
LIMIT 10;