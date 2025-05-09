SELECT
       ranked_users."email"
FROM (
       SELECT
              u."email",
              SUM(o."num_of_item" * oi."sale_price")
              / NULLIF(COUNT(DISTINCT o."order_id"), 0)      AS "avg_order_value"
       FROM   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."USERS"        u
       JOIN   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS"       o
              ON  o."user_id" = u."id"
       JOIN   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"  oi
              ON  oi."order_id" = o."order_id"
       WHERE  u."created_at" BETWEEN 1546300800000000   -- 2019-01-01 00:00:00
                               AND 1577836799000000   -- 2019-12-31 23:59:59
         AND o."created_at" BETWEEN 1546300800000000
                               AND 1577836799000000
       GROUP BY u."email"
) ranked_users
ORDER BY ranked_users."avg_order_value" DESC NULLS LAST
LIMIT 10;