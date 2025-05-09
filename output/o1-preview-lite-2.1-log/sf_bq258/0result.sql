WITH category_monthly AS (
    SELECT
        p."category",
        DATE_TRUNC('month', TO_TIMESTAMP(o."delivered_at" / 1000000)) AS "month",
        SUM(oi."sale_price") AS "revenue",
        COUNT(DISTINCT oi."order_id") AS "orders",
        SUM(p."cost") AS "total_cost",
        SUM(oi."sale_price" - p."cost") AS "profit"
    FROM
        THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS oi
        JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDERS o ON oi."order_id" = o."order_id"
        JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS p ON oi."product_id" = p."id"
    WHERE
        o."status" = 'Complete'
        AND o."delivered_at" IS NOT NULL
        AND o."delivered_at" < 1640995200000000
    GROUP BY
        p."category",
        DATE_TRUNC('month', TO_TIMESTAMP(o."delivered_at" / 1000000))
),
category_monthly_with_growth AS (
    SELECT
        "category" AS "Product_Category",
        TO_CHAR("month", 'YYYY-MM') AS "Month",
        "revenue",
        "orders",
        "total_cost",
        "profit",
        "profit" / NULLIF("total_cost", 0) AS "Profit_to_Cost_Ratio",
        LAG("revenue") OVER (PARTITION BY "category" ORDER BY "month") AS "prev_revenue",
        LAG("orders") OVER (PARTITION BY "category" ORDER BY "month") AS "prev_orders"
    FROM category_monthly
),
final AS (
    SELECT
        "Product_Category",
        "Month",
        ROUND( ( ("revenue" - "prev_revenue") / NULLIF("prev_revenue", 0) ) * 100, 2) AS "Revenue_Growth(%)",
        ROUND( ( ("orders" - "prev_orders") / NULLIF("prev_orders", 0) ) * 100, 2) AS "Orders_Growth(%)",
        ROUND("total_cost", 4) AS "Total_Cost",
        ROUND("profit", 4) AS "Profit",
        ROUND("Profit_to_Cost_Ratio", 4) AS "Profit_to_Cost_Ratio"
    FROM category_monthly_with_growth
)
SELECT
    *
FROM
    final
ORDER BY
    "Product_Category",
    "Month";