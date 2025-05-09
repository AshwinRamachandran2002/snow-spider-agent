WITH item_sales AS (
    /* 1.  Aggregate monthly sales for completed order-items
          (timestamps in micro-seconds → seconds with /1,000,000) */
    SELECT
        DATE_TRUNC('month',
                   TO_TIMESTAMP_NTZ(oi."created_at" / 1000000))         AS sale_month,
        p."name"                                                     AS product_name,
        p."brand"                                                    AS brand,
        p."category"                                                 AS category,
        COUNT(*)                                                     AS total_sales,
        SUM(oi."sale_price")                                         AS total_revenue
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS   oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS      p
         ON p."id" = oi."product_id"
    WHERE oi."status" = 'Complete'
      AND p."brand"  IS NOT NULL
      AND DATE_TRUNC('month', TO_TIMESTAMP_NTZ(oi."created_at" / 1000000))
            < DATE '2024-07-01'                      -- exclude July-2024 and later
    GROUP BY sale_month, product_name, brand, category
),
ranked_sales AS (
    /* 2.  Rank products within each month:
            ­– highest volume first
            ­– revenue as tie-breaker                                */
    SELECT
        sale_month,
        product_name,
        brand,
        category,
        total_sales,
        ROUND(total_revenue, 2)                       AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY sale_month
                           ORDER BY total_sales DESC,
                                    total_revenue DESC)  AS rn
    FROM item_sales
)
-- 3. Pick the top-ranked product for every month
SELECT
    TO_CHAR(sale_month, 'YYYY-MM')  AS month,
    product_name,
    brand,
    category,
    total_sales,
    total_revenue,
    'Complete'                      AS order_status
FROM ranked_sales
WHERE rn = 1
ORDER BY month;