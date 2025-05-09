WITH "orders_2019" AS (   -- orders placed in 2019 with at least one item
    SELECT  o."order_id",
            o."user_id",
            o."num_of_item",
            MIN(oi."sale_price") AS "sale_price"   -- one sale price per order
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"        o
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"   oi
          ON oi."order_id" = o."order_id"
    WHERE TO_TIMESTAMP(o."created_at"/1000000)
          BETWEEN '2019-01-01' AND '2019-12-31'
    GROUP BY o."order_id",
             o."user_id",
             o."num_of_item"
),

"user_avg_order_value" AS (   -- average order value per user (2019 orders)
    SELECT  "user_id",
            SUM("num_of_item" * "sale_price") / COUNT(*) AS "avg_order_value"
    FROM "orders_2019"
    GROUP BY "user_id"
),

"users_2019" AS (   -- users who registered in 2019
    SELECT  "id"   AS "user_id",
            "email"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE TO_TIMESTAMP("created_at"/1000000)
          BETWEEN '2019-01-01' AND '2019-12-31'
)

SELECT  u."email"
FROM    "user_avg_order_value"  ua
JOIN    "users_2019"            u   ON u."user_id" = ua."user_id"
ORDER BY ua."avg_order_value" DESC NULLS LAST
LIMIT 10;