WITH users_2019 AS (         -- customers who registered in 2019
    SELECT "id",
           "email"
    FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE  "created_at" BETWEEN 1546300800000000      -- 2019-01-01
                             AND     1577836800000000  -- 2020-01-01 (exclusive)
), 
orders_2019 AS (             -- those users’ orders placed in 2019
    SELECT "order_id",
           "user_id",
           "num_of_item"
    FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE  "created_at" BETWEEN 1546300800000000
                             AND     1577836800000000
), 
order_values AS (            -- value per order = num_of_item × sale_price
    SELECT  o."order_id",
            o."user_id",
            ( o."num_of_item" * MIN(oi."sale_price") ) AS "order_value"
    FROM    orders_2019                       o
    JOIN    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS  oi
           ON oi."order_id" = o."order_id"
    GROUP BY o."order_id",
             o."user_id",
             o."num_of_item"
), 
user_aov AS (                -- total & average order value per user
    SELECT  u."email",
            SUM(ov."order_value")                      AS "total_value",
            COUNT(*)                                   AS "total_orders",
            SUM(ov."order_value") / COUNT(*)           AS "avg_order_value"
    FROM    users_2019  u
    JOIN    order_values ov
           ON ov."user_id" = u."id"
    GROUP BY u."email"
), 
ranked AS (                  -- rank by highest AOV
    SELECT  "email",
            "avg_order_value",
            ROW_NUMBER() OVER (ORDER BY "avg_order_value" DESC NULLS LAST) AS "rn"
    FROM    user_aov
)
SELECT  "email"
FROM    ranked
WHERE   "rn" <= 10           -- top 10 users
ORDER BY "rn";