WITH orders_2019 AS (
    SELECT
        "order_id",
        "user_id",
        "num_of_item"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    WHERE "created_at" BETWEEN 1546300800000000 AND 1577836799999999  -- 2019
),
order_values AS (
    SELECT
        o."user_id",
        o."order_id",
        o."num_of_item" * MIN(oi."sale_price") AS "order_value"        -- AOV per order
    FROM orders_2019 o
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
      ON oi."order_id" = o."order_id"
    WHERE COALESCE(oi."status", '') <> 'Cancelled'                    -- exclude cancelled lines
    GROUP BY o."user_id", o."order_id", o."num_of_item"
),
user_aov AS (
    SELECT
        u."email",
        ROUND(SUM(ov."order_value") / COUNT(*), 4) AS "avg_order_value" -- retain four decimals
    FROM order_values ov
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS" u
      ON u."id" = ov."user_id"
    WHERE u."created_at" BETWEEN 1546300800000000 AND 1577836799999999 -- registered in 2019
    GROUP BY u."email"
)
SELECT
    "email"
FROM user_aov
ORDER BY "avg_order_value" DESC NULLS LAST
LIMIT 10;