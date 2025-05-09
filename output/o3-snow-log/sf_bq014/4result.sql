WITH first_valid_orders AS (   -- each customer’s first order that isn’t cancelled or returned
    SELECT  "user_id",
            "order_id"
    FROM (
        SELECT  o.*,
                ROW_NUMBER() OVER (PARTITION BY o."user_id"
                                   ORDER BY o."created_at") AS rn
        FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS" o
        WHERE o."status" <> 'Cancelled'
          AND o."returned_at" IS NULL
    )
    WHERE rn = 1
),
first_order_categories AS (    -- categories bought in those first valid orders
    SELECT  p."category",
            fvo."user_id"
    FROM first_valid_orders            fvo
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
         ON oi."order_id" = fvo."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
         ON p."id"       = oi."product_id"
    WHERE oi."status" <> 'Cancelled'
      AND oi."returned_at" IS NULL
    GROUP BY p."category", fvo."user_id"
),
category_leader AS (           -- find the category with the most distinct first-order customers
    SELECT  "category",
            COUNT(DISTINCT "user_id") AS customer_cnt,
            RANK() OVER (ORDER BY COUNT(DISTINCT "user_id") DESC) AS rnk
    FROM first_order_categories
    GROUP BY "category"
),
top_category AS (              -- keep the leader (or leaders in case of ties)
    SELECT "category"
    FROM category_leader
    WHERE rnk = 1
),
revenue_for_top AS (           -- total revenue for that category (all valid order items)
    SELECT  p."category",
            SUM(oi."sale_price") AS revenue
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
         ON p."id" = oi."product_id"
    JOIN top_category tc
         ON p."category" = tc."category"
    WHERE oi."status" <> 'Cancelled'
      AND oi."returned_at" IS NULL
    GROUP BY p."category"
)
SELECT  "category",
        revenue
FROM revenue_for_top;