/*  Top-10 2019 users ranked by highest average order value               */
/*  – registered in 2019 and purchased in 2019                            */
/*  – average order value = (Σ  (num_of_item * sale_price) per order)     */
/*                                   ÷ (# of orders)                      */

WITH orders_2019 AS (   -- 2019 orders joined to their line-items
    SELECT  o."order_id",
            o."user_id",
            o."num_of_item",
            oi."sale_price"
    FROM    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS        o
    JOIN    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS   oi
           ON oi."order_id" = o."order_id"
    WHERE   o."created_at" BETWEEN 1546300800000000  -- 2019-01-01
                              AND 1577836799000000   -- 2019-12-31
),
order_totals AS (       -- order-level value for 2019-registered users
    SELECT  u."id"         AS "user_id",
            u."email",
            o."order_id",
            SUM(o."num_of_item" * o."sale_price") AS "order_value"
    FROM    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS  u
    JOIN    orders_2019                                o
           ON o."user_id" = u."id"
    WHERE   u."created_at" BETWEEN 1546300800000000    -- registered in 2019
                               AND 1577836799000000
    GROUP BY u."id", u."email", o."order_id"
),
user_averages AS (      -- average order value per user
    SELECT  "user_id",
            "email",
            SUM("order_value") / COUNT("order_id") AS "avg_order_value"
    FROM    order_totals
    GROUP BY "user_id", "email"
)

SELECT  "email"
FROM    user_averages
ORDER BY "avg_order_value" DESC NULLS LAST
LIMIT 10;