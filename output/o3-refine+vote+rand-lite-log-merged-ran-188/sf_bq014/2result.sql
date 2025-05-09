WITH first_valid_order AS (   -- 1. earliest non-cancelled / non-returned order for every user
    SELECT
        "user_id",
        MIN("created_at") AS "first_ts"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS"
    WHERE "status" NOT ILIKE '%Cancelled%'
      AND "returned_at" IS NULL
    GROUP BY "user_id"
), first_order_items AS (     -- 2. items (still good) that belong to those first orders
    SELECT
        o."user_id",
        o."order_id",
        p."category",
        oi."sale_price"
    FROM first_valid_order          fv
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS"       o
         ON o."user_id" = fv."user_id"
        AND o."created_at" = fv."first_ts"
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"  oi
         ON oi."order_id" = o."order_id"
    JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"     p
         ON p."id" = oi."product_id"
    WHERE oi."status" NOT ILIKE '%Cancelled%'
      AND oi."returned_at" IS NULL
), ranked_categories AS (     -- 3. find category with most distinct first-time buyers
    SELECT
        "category",
        COUNT(DISTINCT "user_id") AS "num_customers",
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT "user_id") DESC) AS "rnk"
    FROM first_order_items
    GROUP BY "category"
)
-- 4. revenue for the winner category
SELECT
    foi."category"        AS "product_category",
    ROUND(SUM(foi."sale_price"), 4) AS "total_revenue_in_first_orders"
FROM first_order_items      foi
JOIN ranked_categories      rc
  ON rc."category" = foi."category"
WHERE rc."rnk" = 1
GROUP BY foi."category";