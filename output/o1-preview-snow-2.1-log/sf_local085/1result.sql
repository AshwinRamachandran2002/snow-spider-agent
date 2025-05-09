SELECT 
    "employeeid",
    SUM(CASE WHEN "shippeddate" > "requireddate" THEN 1 ELSE 0 END) AS "late_orders",
    COUNT(*) AS "total_orders",
    ROUND((SUM(CASE WHEN "shippeddate" > "requireddate" THEN 1 ELSE 0 END)::FLOAT / COUNT(*) * 100), 4) AS "late_percentage"
FROM 
    "NORTHWIND"."NORTHWIND"."ORDERS"
GROUP BY 
    "employeeid"
HAVING
    COUNT(*) > 50
ORDER BY
    "late_percentage" DESC NULLS LAST
LIMIT 3;