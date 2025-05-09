WITH users_2019 AS (
    SELECT 
        "id"          AS "user_id",
        "email"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE EXTRACT(YEAR FROM TO_TIMESTAMP_NTZ("created_at" / 1000000)) = 2019
), 

orders_2019 AS (
    SELECT
        "order_id",
        "user_id",
        "num_of_item"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE EXTRACT(YEAR FROM TO_TIMESTAMP_NTZ("created_at" / 1000000)) = 2019
          AND "status" <> 'Cancelled'          -- keep only fulfilled purchase attempts
), 

order_values AS (
    /* order value = number of items in the order × average sale price of its items */
    SELECT
        o."user_id",
        o."order_id",
        o."num_of_item" * AVG(oi."sale_price") AS "order_value"
    FROM orders_2019            o
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS oi
         ON oi."order_id" = o."order_id"
    WHERE oi."sale_price" IS NOT NULL
    GROUP BY
        o."user_id",
        o."order_id",
        o."num_of_item"
), 

user_avg_order_value AS (
    SELECT
        "user_id",
        AVG("order_value") AS "avg_order_value"
    FROM order_values
    GROUP BY "user_id"
)

SELECT 
    u."email"
FROM user_avg_order_value ua
JOIN users_2019 u
  ON u."user_id" = ua."user_id"
ORDER BY ua."avg_order_value" DESC NULLS LAST
LIMIT 10;