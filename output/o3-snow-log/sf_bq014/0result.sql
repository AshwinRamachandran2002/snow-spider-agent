WITH first_orders AS (  -- each shopper’s first non-cancelled / non-returned order
    SELECT  o."order_id",
            o."user_id"
    FROM    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS o
    JOIN   ( SELECT  "user_id",
                     MIN("created_at") AS first_order_time
             FROM    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
             WHERE   "status" <> 'Cancelled'
               AND   "returned_at" IS NULL
             GROUP BY "user_id"
           ) f
           ON  f."user_id" = o."user_id"
           AND f.first_order_time = o."created_at"
    WHERE   o."status" <> 'Cancelled'
      AND   o."returned_at" IS NULL
),
category_first_order_counts AS (  -- how many customers bought each category in that first order
    SELECT  p."category",
            COUNT(DISTINCT fo."user_id") AS customer_cnt
    FROM    first_orders            fo
    JOIN    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS   oi
               ON oi."order_id" = fo."order_id"
              AND oi."status"  <> 'Cancelled'
              AND oi."returned_at" IS NULL
    JOIN    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS      p
               ON p."id" = oi."product_id"
    GROUP BY p."category"
),
top_category AS (  -- pick the category with the highest count of first-time buyers
    SELECT  "category"
    FROM    category_first_order_counts
    ORDER BY customer_cnt DESC NULLS LAST
    LIMIT 1
)
SELECT      SUM(oi."sale_price") AS revenue   -- revenue for that top category (all valid sales)
FROM        THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS  oi
JOIN        THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS     p
               ON p."id" = oi."product_id"
JOIN        top_category  tc
               ON p."category" = tc."category"
WHERE       oi."status" <> 'Cancelled'
  AND       oi."returned_at" IS NULL;