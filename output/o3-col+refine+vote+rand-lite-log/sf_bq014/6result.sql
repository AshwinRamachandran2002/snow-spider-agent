/* revenue for the product category that attracts the most first-time shoppers */
WITH clean_items AS (  -- only keep non-cancelled & non-returned items
    SELECT "user_id",
           "order_id",
           MIN("created_at") AS "first_item_ts"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"
    WHERE "status" NOT ILIKE '%cancel%'
      AND "returned_at" IS NULL
    GROUP BY "user_id", "order_id"
),
first_orders AS (      -- one earliest qualifying order per shopper
    SELECT "user_id",
           "order_id"
    FROM (
        SELECT "user_id",
               "order_id",
               "first_item_ts",
               ROW_NUMBER() OVER (PARTITION BY "user_id" ORDER BY "first_item_ts") AS "rn"
        FROM clean_items
    )
    WHERE "rn" = 1
),
category_stats AS (    -- customers and revenue by product category
    SELECT p."category",
           COUNT(DISTINCT oi."user_id") AS "customer_cnt",
           SUM(oi."sale_price")         AS "revenue"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
    JOIN first_orders fo
      ON fo."order_id" = oi."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
      ON p."id" = oi."product_id"
    WHERE oi."status" NOT ILIKE '%cancel%'
      AND oi."returned_at" IS NULL
    GROUP BY p."category"
)
SELECT "category",
       "revenue"
FROM category_stats
ORDER BY "customer_cnt" DESC NULLS LAST
LIMIT 1;