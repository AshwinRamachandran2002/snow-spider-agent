WITH "user_2019" AS (      -- users who registered in 2019
    SELECT 
        "id"      AS "user_id",
        "email"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.USERS
    WHERE EXTRACT(YEAR FROM TO_TIMESTAMP("created_at" / 1000000)) = 2019
),   

"orders_2019" AS (         -- completed orders placed in 2019
    SELECT 
        "order_id",
        "user_id"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE EXTRACT(YEAR FROM TO_TIMESTAMP("created_at" / 1000000)) = 2019
      AND "status" = 'Complete'
),   

"order_totals" AS (        -- total dollar value of each 2019 order
    SELECT 
        oi."order_id",
        SUM(oi."sale_price") AS "order_total"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS  oi
    JOIN "orders_2019"                                    o  ON o."order_id" = oi."order_id"
    WHERE oi."status" = 'Complete'
    GROUP BY oi."order_id"
),   

"user_values" AS (         -- average order value per user
    SELECT 
        o."user_id",
        COUNT(DISTINCT o."order_id")                      AS "num_orders",
        SUM(ot."order_total")                            AS "total_value",
        SUM(ot."order_total") / COUNT(DISTINCT o."order_id") AS "avg_order_value"
    FROM "orders_2019"            o
    JOIN "order_totals"           ot ON ot."order_id" = o."order_id"
    GROUP BY o."user_id"
)    

SELECT 
    u."email"
FROM "user_values"  uv
JOIN "user_2019"     u  ON u."user_id" = uv."user_id"
ORDER BY uv."avg_order_value" DESC NULLS LAST
LIMIT 10;