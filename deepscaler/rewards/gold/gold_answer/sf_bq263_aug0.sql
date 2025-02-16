-- Task: Please create a month-by-month report for the year 2023 focusing on the 'Sleep & Lounge' category, showing for each month the total sales (sum of "sale_price"), total cost (sum of "cost"), number of distinct complete orders, total profit (sum of "sale_price" - "cost"), and the profit-to-cost ratio (sum of ("sale_price" - "cost") divided by "cost"). Ensure that only orders marked as 'Complete' are included, with creation dates between January 1, 2023, and December 31, 2023, and that the cost data is accurately associated with the corresponding products through the order items.

WITH d AS (
    SELECT
        a."order_id", 
        TO_CHAR(TO_TIMESTAMP(a."created_at" / 1000000.0), 'YYYY-MM') AS "month",  -- formatted as Year-Month
        TO_CHAR(TO_TIMESTAMP(a."created_at" / 1000000.0), 'YYYY') AS "year",  -- formatted as Year
        b."product_id", 
        b."sale_price", 
        c."category", 
        c."cost"
    FROM 
        "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS" AS a
    JOIN 
        "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS" AS b
        ON a."order_id" = b."order_id"
    JOIN 
        "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS" AS c
        ON b."product_id" = c."id"
    WHERE 
        a."status" = 'Complete'
        AND TO_TIMESTAMP(a."created_at" / 1000000.0) BETWEEN TO_TIMESTAMP('2023-01-01') AND TO_TIMESTAMP('2023-12-31')
        AND c."category" = 'Sleep & Lounge'
),

e AS (
    SELECT 
        "month", 
        "year", 
        "sale_price", 
        "category", 
        "cost",
        SUM("sale_price") OVER (PARTITION BY "month", "category") AS "TPV",
        SUM("cost") OVER (PARTITION BY "month", "category") AS "total_cost",
        COUNT(DISTINCT "order_id") OVER (PARTITION BY "month", "category") AS "TPO",
        SUM("sale_price" - "cost") OVER (PARTITION BY "month", "category") AS "total_profit",
        SUM(("sale_price" - "cost") / "cost") OVER (PARTITION BY "month", "category") AS "Profit_to_cost_ratio"
    FROM 
        d
)

SELECT DISTINCT 
    "month", 
    "category", 
    "TPV", 
    "total_cost", 
    "TPO", 
    "total_profit", 
    "Profit_to_cost_ratio"
FROM 
    e
ORDER BY 
    "month";