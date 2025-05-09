WITH "USER_2019" AS (      -- users who registered in 2019
    SELECT 
        "id"           AS "user_id",
        "email"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE TO_CHAR(TO_TIMESTAMP_NTZ("created_at" / 1000000), 'YYYY') = '2019'
),

"ORDERS_2019" AS (         -- orders placed in 2019
    SELECT 
        "order_id",
        "user_id",
        "num_of_item"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE TO_CHAR(TO_TIMESTAMP_NTZ("created_at" / 1000000), 'YYYY') = '2019'
),

"ORDER_VALUE" AS (         -- value of each order
    SELECT 
        o."user_id",
        o."order_id",
        SUM(o."num_of_item" * oi."sale_price") AS "order_total"
    FROM "ORDERS_2019" o
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS oi
          ON o."order_id" = oi."order_id"
    GROUP BY 
        o."user_id",
        o."order_id"
),

"USER_STATS" AS (          -- average order value per user
    SELECT
        u."email",
        COUNT(DISTINCT ov."order_id")                         AS "total_orders",
        SUM(ov."order_total")                                 AS "total_spent",
        SUM(ov."order_total") / COUNT(DISTINCT ov."order_id") AS "avg_order_value"
    FROM "USER_2019" u
    JOIN "ORDER_VALUE" ov
          ON u."user_id" = ov."user_id"
    GROUP BY u."email"
)

SELECT
    "email"
FROM "USER_STATS"
ORDER BY "avg_order_value" DESC NULLS LAST
LIMIT 10;