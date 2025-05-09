WITH "USERS_2019" AS (            -- users who registered in 2019
    SELECT "id",
           "email"
    FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE  "created_at" BETWEEN 1546300800000000    -- 2019-01-01
                           AND 1577836799999999     -- 2019-12-31
),
"ORDERS_2019" AS (               -- orders created in 2019
    SELECT "order_id",
           "user_id",
           "num_of_item"
    FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    WHERE  "created_at" BETWEEN 1546300800000000
                           AND 1577836799999999
),
"ORDER_VALUES" AS (              -- value of each 2019 order
    SELECT  o."user_id",
            o."order_id",
            o."num_of_item" * AVG(oi."sale_price") AS "order_value"
    FROM    "ORDERS_2019"                                 o
    JOIN    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
           ON o."order_id" = oi."order_id"
    GROUP BY o."user_id",
             o."order_id",
             o."num_of_item"
),
"USER_AVG" AS (                  -- average order value per user
    SELECT  "user_id",
            ROUND(SUM("order_value") / COUNT("order_id"), 2) AS "avg_order_value"
    FROM    "ORDER_VALUES"
    GROUP BY "user_id"
)
SELECT  u."email"
FROM    "USER_AVG" ua
JOIN    "USERS_2019" u
       ON ua."user_id" = u."id"
ORDER BY ua."avg_order_value" DESC NULLS LAST
LIMIT  10;