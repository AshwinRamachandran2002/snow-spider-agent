/* 1. Identify each user's first non‑cancelled, non‑returned order               */
WITH first_good_order AS (    
    SELECT  "user_id",
            "order_id"
    FROM   ( SELECT  "user_id",
                     "order_id",
                     ROW_NUMBER() OVER (PARTITION BY "user_id"
                                        ORDER BY "created_at", "order_id")  AS rn
             FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
             WHERE  "status" <> 'Cancelled'
               AND  "returned_at" IS NULL )
    WHERE  rn = 1
),

/* 2. Product categories bought in those first good orders                      */
first_order_categories AS (
    SELECT  fgo."user_id",
            pr."category"
    FROM    first_good_order                          fgo
    JOIN    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS  oi
               ON oi."order_id" = fgo."order_id"
    JOIN    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS     pr
               ON pr."id"     = oi."product_id"
    WHERE   oi."status" <> 'Cancelled'
      AND   oi."returned_at" IS NULL
    GROUP BY fgo."user_id", pr."category"
),

/* 3. Category with the largest number of customers in their first good order   */
top_category AS (
    SELECT  "category",
            COUNT(DISTINCT "user_id") AS customer_cnt
    FROM    first_order_categories
    GROUP BY "category"
    QUALIFY ROW_NUMBER() OVER (ORDER BY customer_cnt DESC, "category") = 1
),

/* 4. Revenue for that top category across all completed (non‑cancelled, non‑returned) items */
category_revenue AS (
    SELECT  pr."category",
            SUM(oi."sale_price") AS revenue
    FROM    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS  oi
    JOIN    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS     pr
              ON pr."id" = oi."product_id"
    JOIN    top_category tc
              ON pr."category" = tc."category"
    WHERE   oi."status" <> 'Cancelled'
      AND   oi."returned_at" IS NULL
    GROUP BY pr."category"
)

/* 5. Final result                                                              */
SELECT  tc."category"                                          AS product_category,
        tc.customer_cnt                                        AS first_order_customer_count,
        ROUND(cr.revenue, 4)                                   AS total_revenue
FROM    top_category   tc
JOIN    category_revenue cr
          ON cr."category" = tc."category";