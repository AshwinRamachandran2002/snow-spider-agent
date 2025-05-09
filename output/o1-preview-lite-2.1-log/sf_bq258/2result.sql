WITH monthly_data AS (
    SELECT
        p."category" AS "Product_Category",
        DATE_TRUNC('month', TO_TIMESTAMP_LTZ(o."created_at" / 1000000)) AS "Month",
        SUM(oi."sale_price") AS "Monthly_Revenue",
        COUNT(DISTINCT oi."order_id") AS "Monthly_Orders",
        SUM(p."cost") AS "Total_Cost",
        SUM(oi."sale_price") - SUM(p."cost") AS "Profit",
        (SUM(oi."sale_price") - SUM(p."cost")) / NULLIF(SUM(p."cost"), 0) AS "Profit_to_Cost_Ratio"
    FROM
        "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS" AS oi
    JOIN
        "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" AS p
            ON oi."product_id" = p."id"
    JOIN
        "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS" AS o
            ON oi."order_id" = o."order_id"
    WHERE
        oi."status" = 'Complete'
        AND TO_TIMESTAMP_LTZ(oi."delivered_at" / 1000000) < '2022-01-01'
    GROUP BY
        p."category",
        DATE_TRUNC('month', TO_TIMESTAMP_LTZ(o."created_at" / 1000000))
),
monthly_growth AS (
    SELECT
        md."Product_Category",
        md."Month",
        ROUND(
            (
                (md."Monthly_Revenue" - LAG(md."Monthly_Revenue") OVER (PARTITION BY md."Product_Category" ORDER BY md."Month"))
                /
                NULLIF(LAG(md."Monthly_Revenue") OVER (PARTITION BY md."Product_Category" ORDER BY md."Month"), 0)
            ) * 100,
            4
        ) AS "Revenue_Growth(%)",
        ROUND(
            (
                (md."Monthly_Orders" - LAG(md."Monthly_Orders") OVER (PARTITION BY md."Product_Category" ORDER BY md."Month"))
                /
                NULLIF(LAG(md."Monthly_Orders") OVER (PARTITION BY md."Product_Category" ORDER BY md."Month"), 0)
            ) * 100,
            4
        ) AS "Orders_Growth(%)",
        ROUND(md."Total_Cost", 4) AS "Total_Cost",
        ROUND(md."Profit", 4) AS "Profit",
        ROUND(md."Profit_to_Cost_Ratio", 4) AS "Profit_to_Cost_Ratio"
    FROM monthly_data md
)
SELECT
    "Product_Category",
    TO_CHAR("Month", 'YYYY-MM') AS "Month",
    "Revenue_Growth(%)",
    "Orders_Growth(%)",
    "Total_Cost",
    "Profit",
    "Profit_to_Cost_Ratio"
FROM
    monthly_growth
ORDER BY
    "Product_Category",
    "Month";