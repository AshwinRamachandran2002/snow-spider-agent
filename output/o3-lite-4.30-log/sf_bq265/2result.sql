WITH order_values AS (
    /* 2019 order totals: items per order × average sale price */
    SELECT
        o."order_id",
        o."user_id",
        o."num_of_item" * AVG(oi."sale_price") AS order_value
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"      o
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
      ON o."order_id" = oi."order_id"
    WHERE o."created_at" BETWEEN 1546300800000000 AND 1577836799000000   -- orders in 2019
    GROUP BY o."order_id", o."user_id", o."num_of_item"
),
user_aov AS (
    /* average order value per user (rounded to 4 decimals) */
    SELECT
        "user_id",
        ROUND(SUM(order_value) / COUNT(*), 4) AS avg_order_value
    FROM order_values
    GROUP BY "user_id"
)
SELECT
    u."email"
FROM user_aov ua
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."USERS" u
  ON u."id" = ua."user_id"
WHERE u."created_at" BETWEEN 1546300800000000 AND 1577836799000000       -- users registered in 2019
ORDER BY ua.avg_order_value DESC NULLS LAST, u."email"
LIMIT 10;