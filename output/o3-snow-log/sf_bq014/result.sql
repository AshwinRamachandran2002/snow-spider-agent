/* 1. Identify every user’s first order that was not cancelled and not returned
   2. Find the product-category that appears in those first orders for the 
      largest number of distinct users
   3. Return that category’s total revenue (sum of sale_price) from all
      non-cancelled, non-returned order-items in the whole data set           */

WITH valid_orders AS (          -- keep only orders that were really placed
    SELECT "order_id",
           "user_id",
           "created_at"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"
    WHERE "status" <> 'Cancelled'
      AND "returned_at" IS NULL
),
first_orders AS (               -- first valid order per user
    SELECT "user_id",
           "order_id"
    FROM (
        SELECT "user_id",
               "order_id",
               ROW_NUMBER() OVER (PARTITION BY "user_id" ORDER BY "created_at") AS rn
        FROM valid_orders
    )
    WHERE rn = 1
),
category_customer_counts AS (   -- how many customers bought each category in that first order
    SELECT p."category",
           COUNT(DISTINCT fo."user_id") AS customer_cnt
    FROM first_orders               fo
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
         ON oi."order_id" = fo."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
         ON p."id" = oi."product_id"
    WHERE (oi."status" <> 'Cancelled' OR oi."status" IS NULL)
      AND oi."returned_at" IS NULL
    GROUP BY p."category"
),
top_category AS (               -- category with the most first-time customers
    SELECT "category"
    FROM category_customer_counts
    ORDER BY customer_cnt DESC NULLS LAST
    LIMIT 1
)
SELECT tc."category"           AS "CATEGORY",
       SUM(oi."sale_price")    AS "TOTAL_REVENUE"
FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
     ON p."id" = oi."product_id"
JOIN top_category               tc
     ON p."category" = tc."category"
WHERE (oi."status" <> 'Cancelled' OR oi."status" IS NULL)
  AND oi."returned_at" IS NULL
GROUP BY tc."category";