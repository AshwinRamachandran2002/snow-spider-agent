WITH order_items_filtered AS (      -- 1. Complete items before July-2024
    SELECT
        TO_CHAR(DATE_TRUNC('month',
                TO_TIMESTAMP("created_at" / 1000000) ), 'YYYY-MM')  AS "month",
        "product_id",
        "status",
        "sale_price"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS
    WHERE "status" = 'Complete'
      AND TO_TIMESTAMP("created_at" / 1000000) < '2024-07-01'
),

product_info AS (                   -- 2. Product details with non-null brands
    SELECT
        "id"          AS "product_id",
        "name"        AS "product_name",
        "brand",
        "category"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS
    WHERE "brand" IS NOT NULL
),

monthly_product_sales AS (          -- 3. Monthly sales & revenue per product
    SELECT
        oi."month",
        p."product_name",
        p."brand",
        p."category",
        COUNT(*)                       AS "total_sales",
        SUM(oi."sale_price")           AS "total_revenue",
        MAX(oi."status")               AS "order_status"   -- always 'Complete'
    FROM order_items_filtered  oi
    JOIN product_info          p  ON oi."product_id" = p."product_id"
    GROUP BY
        oi."month",
        p."product_name",
        p."brand",
        p."category"
),

ranked AS (                         -- 4. Pick top product per month
    SELECT
        *,
        RANK() OVER (
            PARTITION BY "month"
            ORDER BY "total_sales" DESC,
                     "total_revenue" DESC
        ) AS rnk
    FROM monthly_product_sales
)

SELECT
    "month",
    "product_name",
    "brand",
    "category",
    "total_sales",
    ROUND("total_revenue", 2) AS "total_revenue",
    "order_status"
FROM ranked
WHERE rnk = 1
ORDER BY "month";