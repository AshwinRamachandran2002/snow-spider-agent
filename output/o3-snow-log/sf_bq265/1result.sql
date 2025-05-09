WITH "users_2019" AS (
    SELECT 
        "id"   AS "user_id",
        "email"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE YEAR( TO_TIMESTAMP_NTZ( "created_at" / 1000000 ) ) = 2019
),
"orders_2019" AS (
    SELECT
        o."order_id",
        o."user_id",
        o."num_of_item",
        AVG(oi."sale_price") AS "avg_sale_price"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS        o
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS   oi
          ON o."order_id" = oi."order_id"
    WHERE YEAR( TO_TIMESTAMP_NTZ( o."created_at" / 1000000 ) ) = 2019
    GROUP BY 
        o."order_id",
        o."user_id",
        o."num_of_item"
)
SELECT
    u."email",
    ROUND( SUM( o."num_of_item" * o."avg_sale_price" ) / COUNT( o."order_id" ), 4 ) AS "avg_order_value"
FROM "users_2019" u
JOIN "orders_2019" o
  ON u."user_id" = o."user_id"
GROUP BY u."email"
ORDER BY "avg_order_value" DESC NULLS LAST
LIMIT 10;