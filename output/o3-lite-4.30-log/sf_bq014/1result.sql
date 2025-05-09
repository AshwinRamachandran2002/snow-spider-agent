WITH first_orders AS (
    /* first non‑cancelled & non‑returned order for every customer */
    SELECT "user_id",
           "order_id"
    FROM (
        SELECT "user_id",
               "order_id",
               ROW_NUMBER() OVER (PARTITION BY "user_id"
                                  ORDER BY "created_at") AS rn
        FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS
        WHERE "status" <> 'Cancelled'
          AND "returned_at" IS NULL
    )
    WHERE rn = 1
),
category_metrics AS (
    /* customer count & revenue by product category in those first orders */
    SELECT p."category"                 AS product_category,
           COUNT(DISTINCT fo."user_id") AS customer_count,
           SUM(oi."sale_price")         AS total_revenue
    FROM first_orders fo
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS  oi
      ON fo."order_id" = oi."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS     p
      ON oi."product_id" = p."id"
    GROUP BY p."category"
),
ranked AS (
    /* pick the category with the most first‑order customers */
    SELECT product_category,
           ROUND(total_revenue, 4) AS total_revenue,
           ROW_NUMBER() OVER (ORDER BY customer_count DESC, product_category) AS rk
    FROM category_metrics
)
SELECT product_category,
       total_revenue
FROM ranked
WHERE rk = 1;