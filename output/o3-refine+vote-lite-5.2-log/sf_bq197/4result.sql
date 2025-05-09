WITH complete_items AS (   -- completed order‑items
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP("created_at" / 1000000)) AS month_start,
        "product_id",
        "sale_price"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"
    WHERE "status" = 'Complete'
),
product_info AS (          -- product attributes (brand must be present)
    SELECT
        "id"        AS product_id,
        "name"      AS product_name,
        "brand"     AS product_brand,
        "category"  AS product_category
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"
    WHERE "brand" IS NOT NULL
),
monthly_product_sales AS ( -- monthly sales metrics per product
    SELECT
        c.month_start,
        p.product_name,
        p.product_brand,
        p.product_category,
        COUNT(*)              AS total_sales,      -- volume
        SUM(c."sale_price")   AS total_revenue     -- value
    FROM complete_items c
    JOIN product_info   p ON p.product_id = c."product_id"
    WHERE c.month_start < DATE '2024-07-01'        -- before July 2024
    GROUP BY
        c.month_start,
        p.product_name,
        p.product_brand,
        p.product_category
),
ranked AS (                -- rank products within each month
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY month_start
                           ORDER BY total_sales DESC,
                                    total_revenue DESC) AS rn
    FROM monthly_product_sales
)
SELECT
    TO_CHAR(month_start, 'YYYY-MM') AS "month",
    product_name,
    product_brand                   AS brand,
    product_category                AS category,
    total_sales,
    ROUND(total_revenue, 2)         AS total_revenue,
    'Complete'                      AS order_status
FROM ranked
WHERE rn = 1                         -- top product per month
ORDER BY month_start;