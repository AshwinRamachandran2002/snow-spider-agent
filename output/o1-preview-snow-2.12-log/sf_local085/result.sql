WITH total_orders_per_employee AS (
    SELECT 
        "employeeid", 
        COUNT("orderid") AS "total_orders"
    FROM "NORTHWIND"."NORTHWIND"."ORDERS"
    GROUP BY "employeeid"
),
late_orders_per_employee AS (
    SELECT 
        "employeeid", 
        COUNT("orderid") AS "late_orders"
    FROM "NORTHWIND"."NORTHWIND"."ORDERS"
    WHERE 
        TRY_TO_DATE("shippeddate", 'YYYY-MM-DD') IS NOT NULL AND
        TRY_TO_DATE("requireddate", 'YYYY-MM-DD') IS NOT NULL AND
        TRY_TO_DATE("shippeddate", 'YYYY-MM-DD') >= TRY_TO_DATE("requireddate", 'YYYY-MM-DD')
    GROUP BY "employeeid"
)
SELECT 
    e."employeeid" AS "EmployeeID",
    COALESCE(l."late_orders", 0) AS "Number_of_Late_Orders",
    ROUND(COALESCE(l."late_orders", 0) * 100.0 / e."total_orders", 4) AS "Late_Order_Percentage"
FROM total_orders_per_employee e
LEFT JOIN late_orders_per_employee l ON e."employeeid" = l."employeeid"
WHERE e."total_orders" > 50
ORDER BY "Late_Order_Percentage" DESC NULLS LAST, "EmployeeID" ASC
LIMIT 3;