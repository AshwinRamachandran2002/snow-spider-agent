WITH non_cancel_orders AS (   -- all orders that were neither cancelled nor returned
    SELECT 
        "order_id",
        "user_id",
        "created_at"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
    WHERE "status" <> 'Cancelled'
      AND "returned_at" IS NULL
), 

first_orders AS (            -- each customer’s first qualified order
    SELECT 
        "user_id",
        "order_id"
    FROM (
        SELECT 
            "user_id",
            "order_id",
            "created_at",
            ROW_NUMBER() OVER (PARTITION BY "user_id" ORDER BY "created_at") AS rn
        FROM non_cancel_orders
    )
    WHERE rn = 1
), 

first_order_items AS (       -- items within those first orders with their categories
    SELECT 
        oi."order_id",
        oi."user_id",
        oi."sale_price",
        p."category"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS  oi
    JOIN first_orders fo
      ON oi."order_id" = fo."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS p
      ON p."id" = oi."product_id"
), 

category_customer_counts AS ( -- how many unique customers bought something in each category
    SELECT
        "category",
        COUNT(DISTINCT "user_id") AS customer_cnt
    FROM first_order_items
    GROUP BY "category"
), 

top_category AS (            -- the category with the most first‑time customers
    SELECT 
        "category"
    FROM (
        SELECT 
            "category",
            customer_cnt,
            ROW_NUMBER() OVER (ORDER BY customer_cnt DESC, "category") AS rn
        FROM category_customer_counts
    )
    WHERE rn = 1
)

SELECT
    foi."category",
    ROUND(SUM(foi."sale_price"), 4) AS revenue          -- revenue generated in those first orders
FROM first_order_items foi
JOIN top_category tc
  ON foi."category" = tc."category"
GROUP BY foi."category";