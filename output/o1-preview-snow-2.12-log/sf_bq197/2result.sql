WITH monthly_sales AS (
    SELECT
        TO_CHAR(TO_TIMESTAMP(o."created_at" / 1000000), 'Mon-YYYY') AS "Month",
        p."name" AS "Product_Name",
        COUNT(oi."product_id") AS "Sales_Volume",
        SUM(oi."sale_price") AS "Revenue"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS" o
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
        ON o."order_id" = oi."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
        ON oi."product_id" = p."id"
    WHERE o."status" = 'Complete'
        AND TO_CHAR(TO_TIMESTAMP(o."created_at" / 1000000), 'YYYY-MM') <= '2024-06'
    GROUP BY
        TO_CHAR(TO_TIMESTAMP(o."created_at" / 1000000), 'Mon-YYYY'),
        p."name"
)
SELECT
    ms."Month",
    ms."Product_Name",
    ms."Sales_Volume",
    ROUND(ms."Revenue", 4) AS "Revenue"
FROM (
    SELECT
        ms.*,
        ROW_NUMBER() OVER (
            PARTITION BY ms."Month"
            ORDER BY ms."Sales_Volume" DESC, ms."Revenue" DESC
        ) AS "rn"
    FROM monthly_sales ms
) ms
WHERE ms."rn" = 1
ORDER BY TO_DATE(ms."Month", 'Mon-YYYY') DESC NULLS LAST;