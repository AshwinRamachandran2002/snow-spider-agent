WITH users_2019 AS (   -- customers who registered in 2019
    SELECT
        "id"   AS user_id,
        "email"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS"
    WHERE DATE_TRUNC(
              'YEAR',
              TO_TIMESTAMP_NTZ("created_at" / 1000000)
          ) = '2019-01-01'
),
orders_2019 AS (       -- their orders placed in 2019
    SELECT
        o."order_id",
        o."user_id",
        o."num_of_item"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS" o
    JOIN users_2019 u
      ON u.user_id = o."user_id"
    WHERE DATE_TRUNC(
              'YEAR',
              TO_TIMESTAMP_NTZ(o."created_at" / 1000000)
          ) = '2019-01-01'
),
order_sale_price AS (  -- average sale price per order
    SELECT
        "order_id",
        AVG("sale_price") AS sale_price
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"
    WHERE "sale_price" IS NOT NULL
    GROUP BY "order_id"
),
order_totals AS (      -- total value for each order
    SELECT
        o."user_id",
        o."order_id",
        o."num_of_item" * p.sale_price AS order_total
    FROM orders_2019 o
    JOIN order_sale_price p
      ON o."order_id" = p."order_id"
),
user_stats AS (        -- aggregate to user level
    SELECT
        "user_id",
        SUM(order_total)                              AS total_value,
        COUNT(DISTINCT "order_id")                    AS order_count,
        SUM(order_total) / COUNT(DISTINCT "order_id") AS avg_order_value
    FROM order_totals
    GROUP BY "user_id"
)
SELECT
    u."email"
FROM user_stats  s
JOIN users_2019  u
  ON u.user_id = s."user_id"
ORDER BY
    s.avg_order_value DESC NULLS LAST,
    u."email"
LIMIT 10;