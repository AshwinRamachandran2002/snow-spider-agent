WITH "users_2019" AS (
    SELECT 
        "id"          AS "user_id",
        "email"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE YEAR( TO_TIMESTAMP( "created_at" / 1000000 ) ) = 2019
), 

"orders_2019" AS (
    SELECT
        "order_id",
        "user_id",
        "num_of_item"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE YEAR( TO_TIMESTAMP( "created_at" / 1000000 ) ) = 2019
          AND "status" = 'Complete'
),

"order_values" AS (
    /*  per‑order value = number of items * average sale price within that order  */
    SELECT
        o."user_id",
        o."order_id",
        o."num_of_item" * AVG(oi."sale_price") AS "order_value"
    FROM "orders_2019" o
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS oi
         ON oi."order_id" = o."order_id"
        AND oi."status"   = 'Complete'
    GROUP BY
        o."user_id",
        o."order_id",
        o."num_of_item"
),

"user_aov" AS (
    /*  average order value per user  */
    SELECT
        "user_id",
        SUM("order_value") / COUNT(DISTINCT "order_id") AS "avg_order_value"
    FROM "order_values"
    GROUP BY "user_id"
)

SELECT 
    u."email"
FROM "user_aov" ua
JOIN "users_2019" u
  ON ua."user_id" = u."user_id"
ORDER BY 
    ua."avg_order_value" DESC NULLS LAST
LIMIT 10;