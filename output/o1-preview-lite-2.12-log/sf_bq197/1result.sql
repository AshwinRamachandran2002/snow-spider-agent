WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('MONTH', TO_TIMESTAMP(o."created_at"/1e6)) AS "Month",
        p."name" AS "Product_Name",
        COUNT(*) AS "Sales_Volume",
        SUM(oi."sale_price") AS "Revenue"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS" o
      ON oi."order_id" = o."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
      ON oi."product_id" = p."id"
    WHERE o."status" = 'Complete'
      AND DATE_TRUNC('MONTH', TO_TIMESTAMP(o."created_at"/1e6)) <= DATE_TRUNC('MONTH', TO_DATE('2024-06-30'))
    GROUP BY DATE_TRUNC('MONTH', TO_TIMESTAMP(o."created_at"/1e6)), p."name"
)
SELECT
    TO_VARCHAR("Month", 'MON-YYYY') AS "Month",
    "Product_Name",
    "Sales_Volume",
    ROUND("Revenue", 4) AS "Revenue"
FROM (
    SELECT
        "Month",
        "Product_Name",
        "Sales_Volume",
        "Revenue",
        ROW_NUMBER() OVER (
            PARTITION BY "Month"
            ORDER BY "Sales_Volume" DESC NULLS LAST, "Revenue" DESC NULLS LAST
        ) AS rn
    FROM monthly_sales
) t
WHERE rn = 1
ORDER BY "Month" DESC NULLS LAST;