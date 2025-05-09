WITH reg19 AS (                             -- users who registered during calendar‑year 2019
    SELECT "id",
           "email"
    FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE  "created_at" BETWEEN 1546300800000000 AND 1577836800000000
),
orders19 AS (                               -- orders placed during calendar‑year 2019
    SELECT "order_id",
           "user_id",
           "num_of_item"
    FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    WHERE  "created_at" BETWEEN 1546300800000000 AND 1577836800000000
),
order_vals AS (                             -- value of each 2019 order
    SELECT  o."order_id",
            o."user_id",
            o."num_of_item" * MAX(oi."sale_price") AS "order_value"
    FROM    orders19                               o
    JOIN    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
           ON oi."order_id" = o."order_id"
    GROUP BY o."order_id",
             o."user_id",
             o."num_of_item"
),
user_avgs AS (                              -- each user’s 2019 average order value
    SELECT  "user_id",
            SUM("order_value") / COUNT(*) AS "avg_order_value"
    FROM    order_vals
    GROUP BY "user_id"
)
SELECT  r."email"
FROM    user_avgs  u
JOIN    reg19      r ON r."id" = u."user_id"
ORDER BY u."avg_order_value" DESC NULLS LAST,
         r."email"
LIMIT 10;