WITH "users_2019" AS (   -- users who registered in 2019
    SELECT
        "id"      AS "user_id",
        "email"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE YEAR( TO_TIMESTAMP_NTZ( "created_at" / 1000000 ) ) = 2019
),

"orders_2019" AS (       -- those users’ orders placed in 2019
    SELECT
        "order_id",
        "user_id",
        "num_of_item"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    WHERE YEAR( TO_TIMESTAMP_NTZ( "created_at" / 1000000 ) ) = 2019
),

"order_prices" AS (      -- sale‑price recorded for each order
    SELECT
        "order_id",
        MAX("sale_price") AS "sale_price"     -- assume one price per order
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"
    GROUP BY "order_id"
),

"user_order_values" AS ( -- order value = items × price
    SELECT
        o."user_id",
        o."order_id",
        o."num_of_item" * COALESCE(p."sale_price",0) AS "order_value"
    FROM "orders_2019" o
    JOIN "order_prices" p
      ON o."order_id" = p."order_id"
),

"user_avg_value" AS (    -- average order value per user
    SELECT
        u."user_id",
        u."email",
        AVG(v."order_value") AS "avg_order_value"
    FROM "users_2019"       u
    JOIN "user_order_values" v
      ON u."user_id" = v."user_id"
    GROUP BY u."user_id", u."email"
)

SELECT
    "email"
FROM "user_avg_value"
ORDER BY
    "avg_order_value" DESC NULLS LAST,
    "user_id"
LIMIT 10;