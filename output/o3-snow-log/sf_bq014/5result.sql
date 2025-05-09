WITH valid_orders AS (     -- non-cancelled / non-returned orders only
    SELECT "order_id",
           "user_id",
           "created_at"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE "status" NOT IN ('Cancelled','Returned')
      AND "returned_at" IS NULL
),
first_orders AS (          -- first valid order per customer
    SELECT "user_id",
           MIN("created_at") AS "first_created_at"
    FROM valid_orders
    GROUP BY "user_id"
),
user_first_orders AS (     -- bring back the corresponding order_id
    SELECT v."user_id",
           v."order_id"
    FROM valid_orders v
    JOIN first_orders f
      ON v."user_id" = f."user_id"
     AND v."created_at" = f."first_created_at"
),
first_order_items AS (     -- items in each customer’s first valid order
    SELECT oi."user_id",
           oi."product_id",
           p."category",
           oi."sale_price"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS  oi
    JOIN user_first_orders ufo
         ON oi."order_id" = ufo."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS     p
         ON oi."product_id" = p."id"
    WHERE oi."status"      NOT IN ('Cancelled')
      AND oi."returned_at" IS NULL
),
category_user_counts AS (  -- how many customers’ first orders include each category
    SELECT "category",
           COUNT(DISTINCT "user_id") AS "num_customers"
    FROM first_order_items
    GROUP BY "category"
),
top_category AS (          -- category with the most such customers
    SELECT "category"
    FROM category_user_counts
    ORDER BY "num_customers" DESC NULLS LAST
    LIMIT 1
)
-- revenue for that top category across all non-cancelled / non-returned sales
SELECT tc."category",
       ROUND(SUM(oi."sale_price"),4) AS "total_revenue"
FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS  oi
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS     p
     ON oi."product_id" = p."id"
JOIN top_category tc
     ON p."category" = tc."category"
WHERE oi."status"      NOT IN ('Cancelled')
  AND oi."returned_at" IS NULL
GROUP BY tc."category";