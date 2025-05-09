WITH sales_data AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1e6)) AS "Month",
        oi."sale_price",
        ii."cost",
        (oi."sale_price" - ii."cost") AS "Profit",
        oi."order_id"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS p ON p."id" = oi."product_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.INVENTORY_ITEMS ii ON ii."id" = oi."inventory_item_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS o ON o."order_id" = oi."order_id"
    WHERE
        p."category" = 'Sleep & Lounge'
        AND o."status" = 'Complete'
        AND oi."created_at" >= 1672531200000000
        AND oi."created_at" < 1704067200000000
)
SELECT
    TO_CHAR("Month", 'Mon-YYYY') AS "Month",
    ROUND(SUM("sale_price"), 4) AS "Total_Sales",
    ROUND(SUM("cost"), 4) AS "Total_Costs",
    COUNT(DISTINCT "order_id") AS "Completed_Order_Count",
    ROUND(SUM("Profit"), 4) AS "Profit",
    ROUND((SUM("Profit") / NULLIF(SUM("sale_price"), 0)) * 100, 4) AS "Profit_Margin"
FROM sales_data
GROUP BY "Month"
ORDER BY "Month";