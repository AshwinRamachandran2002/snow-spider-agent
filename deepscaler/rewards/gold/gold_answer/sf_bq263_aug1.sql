-- Task: For each month in 2023, for the 'Sleep & Lounge' category, compute the total sales, total cost, and number of complete orders.

WITH d AS (
    SELECT
        a."order_id", 
        TO_CHAR(TO_TIMESTAMP(a."created_at" / 1000000.0), 'YYYY-MM') AS "month",
        b."sale_price", c."cost"
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
)
SELECT 
    "month", 
    SUM("sale_price") AS "total_sales", 
    SUM("cost") AS "total_cost", 
    COUNT(DISTINCT "order_id") AS "number_of_complete_orders"
FROM 
    d
GROUP BY 
    "month"
ORDER BY 
    "month";