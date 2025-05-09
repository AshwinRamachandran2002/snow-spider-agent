WITH
/* 1. users who registered in 2019 */
user_2019 AS (
    SELECT
        "id"    AS user_id,
        "email"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE EXTRACT(year FROM TO_TIMESTAMP("created_at" / 1000000)) = 2019
),
/* 2. their orders created in 2019 */
orders_2019 AS (
    SELECT
        o."order_id"   AS order_id,
        o."user_id"    AS user_id,
        o."num_of_item" AS num_of_item
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS o
    WHERE EXTRACT(year FROM TO_TIMESTAMP(o."created_at" / 1000000)) = 2019
),
/* 3. order‑items that were completed (i.e., purchased) */
order_items_complete AS (
    SELECT
        oi."order_id"  AS order_id,
        oi."sale_price" AS sale_price
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS oi
    WHERE oi."status" = 'Complete'
),
/* 4. total value for each order = num_of_item * sale_price */
order_totals AS (
    SELECT
        o.user_id,
        o.order_id,
        (o.num_of_item * oi.sale_price) AS order_total
    FROM orders_2019 o
    JOIN order_items_complete oi
          ON o.order_id = oi.order_id
),
/* 5. average order value per user */
user_aov AS (
    SELECT
        user_id,
        SUM(order_total)                              AS total_value,
        COUNT(DISTINCT order_id)                      AS total_orders,
        SUM(order_total) / COUNT(DISTINCT order_id)   AS avg_order_value
    FROM order_totals
    GROUP BY user_id
)
/* 6. top 10 users by highest average order value */
SELECT
    u."email"
FROM user_aov a
JOIN user_2019 u
      ON a.user_id = u.user_id
ORDER BY a.avg_order_value DESC NULLS LAST, u."email"
LIMIT 10;