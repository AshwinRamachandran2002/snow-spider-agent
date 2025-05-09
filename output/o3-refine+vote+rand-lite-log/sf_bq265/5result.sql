WITH user_2019 AS (
    SELECT 
        "id"      AS user_id,
        "email"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE YEAR(TO_TIMESTAMP_NTZ("created_at" / 1000000)) = 2019
),
orders_2019 AS (
    SELECT
        "order_id",
        "user_id",
        "num_of_item"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    WHERE YEAR(TO_TIMESTAMP_NTZ("created_at" / 1000000)) = 2019
      AND "status" = 'Complete'
),
order_values AS (
    SELECT
        o."order_id",
        o."user_id",
        o."num_of_item",
        AVG(oi."sale_price") AS avg_sale_price
    FROM orders_2019 o
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
      ON oi."order_id" = o."order_id"
     AND oi."status" = 'Complete'
    GROUP BY o."order_id", o."user_id", o."num_of_item"
),
user_metrics AS (
    SELECT
        "user_id",
        SUM("num_of_item" * avg_sale_price)           AS total_spend,
        COUNT(DISTINCT "order_id")                    AS order_count
    FROM order_values
    GROUP BY "user_id"
),
user_aov AS (
    SELECT
        "user_id",
        total_spend / order_count AS avg_order_value
    FROM user_metrics
)
SELECT
    u."email"
FROM user_aov ua
JOIN user_2019 u
  ON u.user_id = ua."user_id"
ORDER BY ua.avg_order_value DESC NULLS LAST, ua."user_id" ASC
LIMIT 10;