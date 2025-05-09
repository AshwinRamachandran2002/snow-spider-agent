WITH base_data AS (
    SELECT
        p."category",
        DATE_TRUNC('month', TO_TIMESTAMP(oi."created_at" / 1000000)) AS "month",
        oi."sale_price",
        p."cost",
        oi."order_id",
        oi."product_id"
    FROM
        THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
    JOIN
        THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
        ON oi."product_id" = p."id"
    WHERE
        oi."status" = 'Complete'
        AND TO_TIMESTAMP(oi."delivered_at" / 1000000) < '2022-01-01'
        AND oi."delivered_at" IS NOT NULL
),
monthly_data AS (
    SELECT
        "category",
        "month",
        SUM("sale_price") AS total_revenue,
        COUNT(DISTINCT "order_id") AS total_orders,
        SUM("cost") AS total_cost,
        SUM("sale_price" - "cost") AS profit,
        CASE WHEN SUM("cost") <> 0 THEN SUM("sale_price" - "cost") / SUM("cost") ELSE NULL END AS profit_to_cost_ratio
    FROM
        base_data
    GROUP BY
        "category",
        "month"
),
final_data AS (
    SELECT
        "category",
        "month",
        total_revenue,
        total_orders,
        total_cost,
        profit,
        profit_to_cost_ratio,
        LAG(total_revenue) OVER (PARTITION BY "category" ORDER BY "month") AS previous_revenue,
        LAG(total_orders) OVER (PARTITION BY "category" ORDER BY "month") AS previous_orders
    FROM
        monthly_data
)
SELECT
    "category" AS Product_Category,
    TO_CHAR("month", 'YYYY-MM') AS "Month",
    ROUND(((total_revenue - previous_revenue) / NULLIF(previous_revenue, 0)) * 100, 4) AS "Revenue_Growth(%)",
    ROUND(((total_orders - previous_orders) / NULLIF(previous_orders, 0)) * 100, 4) AS "Orders_Growth(%)",
    ROUND(total_cost, 4) AS Total_Cost,
    ROUND(profit, 4) AS Profit,
    ROUND(profit_to_cost_ratio, 4) AS Profit_to_Cost_Ratio
FROM
    final_data
ORDER BY
    "category",
    "month";